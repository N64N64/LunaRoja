local intptr = ffi.new('int[2]')
if PLATFORM == '3ds' then
    scrblockwidth = 4
    scrblockheight = 2
else
    scrblockwidth = 7
    scrblockheight = 4
end
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

customtiles = {}
function customtile(map, x, y, v)
    if not v then
        return customtiles[map*0x10000 + x*0x100 + y]
    else
        customtiles[map*0x10000 + x*0x100 + y] = v
    end
end

local function coord()
    local x = math.floor(Red.wram.wXCoord/2)
    local y = math.floor(Red.wram.wYCoord/2)
    return x, y
end

ROOT['new custom tile'] = function()
    local x,y = coord()
    customtile(Red.wram.wCurMap, x, y, Block())
end

local pickup = nil
ROOT['drop'] = function()
    local x, y = coord()
    customtile(Red.wram.wCurMap, x, y, pickup)
end

local function getit(x, y)
    local mapheader, mapblocks = getmapheader(Red.wram.wCurMap)
    local width = mapheader[2]
    local tileset = mapheader[0]
    local tileno = mapblocks[y*width + x]
    return gettilefromrom(tileset, tileno)
end

ROOT['pickup'] = function()
    local x, y = coord()
    pickup = customtile(Red.wram.wCurMap, x, y) or getit(x, y)
end



function Red:drawmap(scr, mapid, x, y)
    local map = Red.Map:new(mapid)
    map:draw(scr, x, y)
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
    local dx = Red.Camera.x - xplayer
    local dy = Red.Camera.y - yplayer
    for y=lowy,highy do
        for x=lowx, highx do
            local tileno = mapblocks[y*width + x]
            local tile = customtile(map, x, y) or gettilefromrom(tileset, tileno)
            local x = x*32 + dx
            local y = y*32 + dy

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

    hooked(self, scr, map, mapx, mapy, xplayer, yplayer, first_call) -- tmp.lua
end

Red.tiles = {}
Red.blocks = {}

function savetiles(folder)
    if not(PLATFORM == '3ds') then
        print('WARNING: YOU MUST CREATE THE DIRECTORY TODO TODO TODO')
    end
    C.mkdir(PATH..'/tile', tonumber(700, 8))
    folder = PATH..'/tile/'..folder
    C.mkdir(folder, tonumber(700, 8))
    for k,v in pairs(Red.tiles) do
        v:save(folder..'/'..string.format('%.10x', k)..'.png')
    end
end

local ptr = ffi.new('int[3]')
function loadtiles(folder)
    Red.tiles = {}
    Red.blocks = {}
    folder = PATH..'/tile/'..folder
    for _,filename in ipairs(ls(folder)) do
        if string.has_suffix(filename, '.png') then
            local path = folder..'/'..filename
            local bmap = Bitmap:new(path)
            local idx = string.match(filename, '(%w+)%.png')
            idx = tonumber(idx, 16)
            Red.tiles[idx] = bmap
        end
    end
end

ROOT['load tileset'] = {}
for _,v in pairs(ls(PATH..'/tile') or {}) do
    ROOT['load tileset'][v] = function()
        loadtiles(v)
    end
end

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

function Block(nw, ne, sw, se)
    if not nw then
        return {
            nw = Bitmap:new(16, 16),
            ne = Bitmap:new(16, 16),
            sw = Bitmap:new(16, 16),
            se = Bitmap:new(16, 16),
        }
    end
    return {
        nw=nw,ne=ne,sw=sw,se=se,
    }
end

function gettilefromrom(tileset, tile)
    local self = Red

    local block = Red.blocks[tileset * 0x100 + tile]
    if block then
        return block
    end

    local header = self.rom.Tilesets + tileset*12
    -- ptr to .bst
    local bst = emu:rom(header[0], tile*16 + header[1] + header[2] * 0x100)
    -- ptr to .2bpp
    local bpp = emu:rom(header[0], header[3] + header[4] * 0x100)

    local nw = tileset*0x100000000 + bst[00]*0x1000000 + bst[01]*0x10000 + bst[04]*0x100 + bst[05]
    local ne = tileset*0x100000000 + bst[02]*0x1000000 + bst[03]*0x10000 + bst[06]*0x100 + bst[07]
    local sw = tileset*0x100000000 + bst[08]*0x1000000 + bst[09]*0x10000 + bst[12]*0x100 + bst[13]
    local se = tileset*0x100000000 + bst[10]*0x1000000 + bst[11]*0x10000 + bst[14]*0x100 + bst[15]

    if not Red.tiles[nw] then
        Red.tiles[nw] = closure(bpp, bst, 0, 0, nw)
    end
    if not Red.tiles[ne] then
        Red.tiles[ne] = closure(bpp, bst, 2, 0, ne)
    end
    if not Red.tiles[sw] then
        Red.tiles[sw] = closure(bpp, bst, 0, 2, sw)
    end
    if not Red.tiles[se] then
        Red.tiles[se] = closure(bpp, bst, 2, 2, se)
    end

    local block = Block(Red.tiles[nw], Red.tiles[ne], Red.tiles[sw], Red.tiles[se])

    Red.blocks[tileset * 0x100 + tile] = block
    return block
end
