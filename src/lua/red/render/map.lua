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
function Red:render_map(scr, map, mapx, mapy, xplayer, yplayer, first_call)
    if first_call then
        already_rendered = {}
    end

    if already_rendered[map] then return end
    already_rendered[map] = true

    local mapheader, mapblocks = getmapheader(map)

    local tileset = mapheader[0]
    if first_call then
        Red.zram.tileset = tileset
        if not(lasttileset == tileset) then
            lasttileset = tileset
            collectgarbage()
        end
    end

    local width = mapheader[2]
    local height = mapheader[1]

    if first_call then
        Red.zram.mapwidth = width
        Red.zram.mapheight = height
        Red.zram.mapblocks = mapblocks
    end

    local lowy = math.max(0, mapy-scrblockheight)
    local highy = math.min(mapy+scrblockheight, height-1)
    local lowx = math.max(0, mapx-scrblockwidth)
    local highx = math.min(mapx+scrblockwidth, width-1)
    for y=lowy,highy do
        for x=lowx, highx do
            local tileno = mapblocks[y*width + x]
            local tile = gettilefromrom(tileset, tileno)
            local x = x*tile.nw.width*2 - xplayer + Red.Camera.x
            local y = y*tile.nw.height*2 - yplayer + Red.Camera.y

            tile.nw:fastdraw(scr, x, y)
            tile.ne:fastdraw(scr, x + 16, y)
            tile.sw:fastdraw(scr, x, y + 16)
            tile.se:fastdraw(scr, x + 16, y + 16)
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
            self:render_map(scr, map, mapx - xoff, mapy + mapheight, xplayer - xoff*32, yplayer + mapheight*32)
        end
        addr = addr + 11
    end
    -- south connection
    if bit.band(connection_flag, bit.lshift(1, 2)) ~= 0 then
        if height*32 - yplayer < Red.Camera.y + 16 then
            local map, xoff, mapwidth, mapheight = getoff(8)
            self:render_map(scr, map, mapx - xoff, -(height - mapy), xplayer - xoff*32, -(height*32 - yplayer))
        end
        addr = addr + 11
    end
    -- west connection
    if bit.band(connection_flag, bit.lshift(1, 1)) ~= 0 then
        if xplayer < Red.Camera.x then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(scr, map, mapx + mapwidth, mapy - yoff, xplayer + mapwidth*32, yplayer - yoff*32)
        end
        addr = addr + 11
    end
    -- east connection
    if bit.band(connection_flag, bit.lshift(1, 0)) ~= 0 then
        if width*32 - xplayer < Red.Camera.x + 16 then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(scr, map, -(width - mapx), mapy - yoff, -(width*32 - xplayer), yplayer - yoff*32)
        end
        addr = addr + 11
    end

    hooked(self, map, mapx, mapy, xplayer, yplayer, first_call) -- tmp.lua
end

Red.tiles = {}

local function closure(bpp, bst, x, y, tileinfo)
    local ts = 16 / Red.Tilesize
    local bs = 32 / Red.Tilesize
    local bmap = BPP(function(i)
        local x = i % ts + x
        local y = math.floor(i / ts) + y
        return bpp + bst[y*bs + x]*16
    end, 16, 16)
    bmap.tileinfo = tileinfo
    return bmap
end
function gettilefromrom(tileset, tile)
    local self = Red

    local header = self.rom.Tilesets + tileset*12
    -- ptr to .bst
    local bst = emu:rom(header[0], tile*16 + header[1] + header[2] * 0x100)
    -- ptr to .2bpp
    local bpp = emu:rom(header[0], header[3] + header[4] * 0x100)

    local nw = tileset*0x100000000 + bst[00]*0x1000000 + bst[01]*0x10000 + bst[04]*0x100 + bst[05]
    local ne = tileset*0x100000000 + bst[02]*0x1000000 + bst[03]*0x10000 + bst[06]*0x100 + bst[07]
    local sw = tileset*0x100000000 + bst[08]*0x1000000 + bst[09]*0x10000 + bst[12]*0x100 + bst[13]
    local se = tileset*0x100000000 + bst[10]*0x1000000 + bst[11]*0x10000 + bst[14]*0x100 + bst[15]

    local result = {
        nw = Red.tiles[nw] or closure(bpp, bst, 0, 0, nw),
        ne = Red.tiles[ne] or closure(bpp, bst, 2, 0, ne),
        sw = Red.tiles[sw] or closure(bpp, bst, 0, 2, sw),
        se = Red.tiles[se] or closure(bpp, bst, 2, 2, se),
    }

    Red.tiles[nw] = result.nw
    Red.tiles[ne] = result.ne
    Red.tiles[sw] = result.sw
    Red.tiles[se] = result.se

    return result
end
