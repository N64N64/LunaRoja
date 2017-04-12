local gettilefromrom

local intptr = ffi.new('int[2]')
local scrblockwidth = 7
local scrblockheight = 4
local lasttileset
local already_rendered = {}

function getmapheader(map)
    local self = Red

    local mapbank = self.rom.MapHeaderBanks[map]

    local rom = self.rom.MapHeaderPointers + map*2
    local mapheaderaddr = rom[0] + rom[1] * 0x100

    local rom = emu:rom(mapbank, mapheaderaddr + 3)
    local mapblocksaddr = rom[0] + rom[1] * 0x100

    return emu:rom(mapbank, mapheaderaddr), emu:rom(mapbank, mapblocksaddr)
end

local hooked = Red.render_map or function() end -- tmp.lua
function Red:render_map(map, mapx, mapy, xplayer, yplayer, first_call)
    if first_call then
        already_rendered = {}
    end

    if already_rendered[map] then return end
    already_rendered[map] = true

    local mapheader, mapblocks = getmapheader(map)

    local tileset = mapheader[0]
    if first_call and not(lasttileset == tileset) then
        -- because the 3DS has very little memory
        if lasttileset then
            self.tiles[lasttileset] = {}
            self.customtiles[lasttileset] = {}
        end
        lasttileset = tileset
        collectgarbage()
    end

    local math_floor = math.floor
    local tiles = self.tiles
    local width = mapheader[2]
    local height = mapheader[1]

    local bufpix, bufheight, bufwidth = Screen.top.pix, Screen.top.height, Screen.top.width

    local lowy = math.max(0, mapy-scrblockheight)
    local highy = math.min(mapy+scrblockheight, height-1)
    local lowx = math.max(0, mapx-scrblockwidth)
    local highx = math.min(mapx+scrblockwidth, width-1)
    for y=lowy,highy do
        for x=lowx, highx do
            local i = y*width + x
            local tileno = mapblocks[i]
            local tile
            if config.use_custom_tiles then
                tile = self:loadcustomtile(tileset, tileno) or tiles[tileset][tileno]
            else
                tile = tiles[tileset][tileno]
            end
            if tile == nil then
                tile = gettilefromrom(tileset, tileno)
                tiles[tileset][tileno] = tile or false
            end

            if tile then
                tile:fastdraw(Screen.top, x*tile.width - xplayer + Red.Camera.x, y*tile.height - yplayer + Red.Camera.y)
            end
        end
    end

    local connection_flag = mapheader[9]

    local addr = 10
    local function getoff(off)
        local map = mapheader[addr + 0]
        local off = -tonumber(ffi.new('int8_t', mapheader[addr + off]))/2
        local mapheader = getmapheader(map)
        local mapwidth = mapheader[2]
        local mapheight = mapheader[1]
        return map, off, mapwidth, mapheight
    end


    -- north connection
    local xoff, yoff = -xplayer + Red.Camera.x, -yplayer + Red.Camera.y
    if bit.band(connection_flag, bit.lshift(1, 3)) ~= 0 then
        if yplayer < Red.Camera.y then
            local map, xoff, mapwidth, mapheight = getoff(8)
            self:render_map(map, mapx - xoff, mapy + mapheight, xplayer - xoff*32, yplayer + mapheight*32)
        end
        addr = addr + 11
    end
    -- south connection
    if bit.band(connection_flag, bit.lshift(1, 2)) ~= 0 then
        if height*32 - yplayer < Red.Camera.y + 16 then
            local map, xoff, mapwidth, mapheight = getoff(8)
            self:render_map(map, mapx - xoff, -(height - mapy), xplayer - xoff*32, -(height*32 - yplayer))
        end
        addr = addr + 11
    end
    -- west connection
    if bit.band(connection_flag, bit.lshift(1, 1)) ~= 0 then
        if xplayer < Red.Camera.x then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(map, mapx + mapwidth, mapy - yoff, xplayer + mapwidth*32, yplayer - yoff*32)
        end
        addr = addr + 11
    end
    -- east connection
    if bit.band(connection_flag, bit.lshift(1, 0)) ~= 0 then
        if width*32 - xplayer < Red.Camera.x + 16 then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(map, -(width - mapx), mapy - yoff, -(width*32 - xplayer), yplayer - yoff*32)
        end
        addr = addr + 11
    end

    hooked(self, map, mapx, mapy, xplayer, yplayer, first_call) -- tmp.lua
end

function gettilefromrom(tileset, tile)
    local self = Red

    local header = self.rom.Tilesets + tileset*12
    -- ptr to .bst
    local bst = emu:rom(header[0], tile*16 + header[1] + header[2] * 0x100)
    -- ptr to .2bpp
    local bpp = emu:rom(header[0], header[3] + header[4] * 0x100)

    return BPP(function(i)
        return bpp + bst[i]*16
    end, 32, 32)
end

function Red:loadcustomtile(itileset, itile)
    local tile = self.customtiles[itileset][itile]
    if tile == false then
        return
    elseif tile then
        return tile
    end

    local filename = string.format('tile/%.2x/%.2x.png', itileset, itile)
    local f = io.open(PATH..'/pic/'..filename)
    if f then
        f:close()
        tile = Bitmap:new(filename, 3, 'prerotate')
    else
        tile = false
    end
    self.customtiles[itileset][itile] = tile
    return tile
end

function cleartiles(tiles)
    tiles = tiles or {}
    for itileset=0x00,0x17 do
        tiles[itileset] = {}
    end
    return tiles
end
