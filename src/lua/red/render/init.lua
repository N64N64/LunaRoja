require 'red.render.dialogue'

-- this code is disgusting, needs refactor

SPRITE_INVIS_COLOR = 0x01

local halfscrwidth = Screen.top.width/2 - 8
local halfscrheight = Screen.top.height/2 - 8

local screen_top_width = Screen.top.width
local screen_top_height = Screen.top.height
local function badcheck(x, y)
    x = x - playerx + halfscrwidth
    y = y - playery + halfscrheight
    return x + 32 < 0 or
           y + 32 < 0 or
           x >= screen_top_width or
           y >= screen_top_height
end


local redtile = {
    width = 16,
    height = 16,
    r = 0xff,
    g = 0,
    b = 0xff,
}
local spritex = {}
local spritey = {}

local spritedefs = {}
local bikexoffsets = {
    0,
    0,
    1,
    -1,
    -1,
    0
}
spritedefs.red_on_bike = {
    addr = {0x05, 0x4000, 0xc0},
    postprocess = function(oldpix)
        -- custom sprite frankensteining...
        -- making it so that the hat isn't
        -- cut off at the top due to the
        -- 16x16 px restraint
        local redpix = getspritefromrom(1, true)
        local newpix = ffi.new('uint8_t[?]', 16*17*6*3)
        C.memset(newpix, SPRITE_INVIS_COLOR, ffi.sizeof(newpix))
        for i=0,6-1 do
            local xoffset = bikexoffsets[i+1]
            local outpix = newpix + 16*17*3*i
            local bikepix = oldpix + 16*16*3*i
            local redpix = redpix + 16*16*3*(i % 3)
            -- red's head
            for y=0,6-1 do
                for x=0,14-1 do
                    local outpix = outpix + 16*3*y + 3*(x + 1 + xoffset)
                    local redpix = redpix + 16*3*y + 3*(x + 1)
                    outpix[0] = redpix[0]
                    outpix[1] = redpix[1]
                    outpix[2] = redpix[2]
                end
            end
            -- bike body
            for y=0,17-6-1 do
                C.memcpy(outpix + 16*3*(y + 6), bikepix + 16*3*(y + 5), 16*3)
            end
        end
        return newpix, 17, 17*6
    end,
}

local function getspriteptr(id)
    local self = Red

    local bank, addr, count
    local def = spritedefs[id]
    if def and def.addr then
        bank, addr, count = unpack(def.addr)
    else
        id = id - 1 -- IDs start at 1, not 0. need to account for offset
        local rom = self.rom.SpriteSheetPointerTable + id*4
        addr = rom[0] + rom[1] * 0x100
        count = rom[2]
        bank = rom[3]
    end
    return emu:rom(bank, addr), count
end

function getspritefromrom(id, raw)
    if not raw and Red.sprites[id] then
        return Red.sprites[id]
    end

    local bpp, count = getspriteptr(id)
    local width = 16
    local spriteheight = 16
    local height = count/2
    local pix = ffi.new('uint8_t[?]', width*height*3)
    for i=0,count/Red.Tilesize-1 do
        BPP_CONV(pix, bpp + i*16, i, 2, not raw, true)
    end

    if spritedefs[id] then
        local f = spritedefs[id].postprocess
        if f then
            pix, spriteheight, height = f(pix)
        end
    end

    if raw then return pix end

    local finalpix = ffi.new('uint8_t[?]', ffi.sizeof(pix))
    for i=0,height/spriteheight-1 do
        C.rotatecopy(
            finalpix + i*width*spriteheight*3, spriteheight, width, 3, 0, 0,
            pix + i*width*spriteheight*3, width, spriteheight, 3, 0, 0
        )
    end
    pix = finalpix
    collectgarbage()
    local bmap = Bitmap:new{
        -- bitmap stuff
        pix = pix,
        width = width,
        height = height,
        channels = 3,
        -- custom fields
        spriteheight = spriteheight,
    }
    --bmap:prerotate()
    bmap:makebgr()
    Red.sprites[id] = bmap

    return bmap
end

local hidden_sprites = {}
function Red:render_sprites(framebuffer)
    local bufpix, bufheight, bufwidth = Screen.top.pix, Screen.top.height, Screen.top.width
    for i=0,self.wram.wNumSprites do
        hidden_sprites[i] = false
    end
    for i=0,math.huge do
        local miss = self.wram.wMissableObjectList[i]
        if miss.id == 0xff or miss.id == 0x00 then break end

        -- this doesnt work
        -- try this in oak's lab after you battle gary,
        -- some sprites will show when they shouldnt
        -- and some sprites that should show dont
--      local k = bit.band(self.wram.wMissableObjectFlags[math.floor(miss.index/8)], bit.rshift(0x100, miss.index%8 + 1))
--      hidden_sprites[miss.id] = k ~= 0
        -- temorary workaround until i figure out the above.
        hidden_sprites[miss.id] = true
    end
    for i=0,self.wram.wNumSprites do
        local is_player = i == 0
        local s1 = self.wram.wSpriteStateData1[i]
        local s2 = self.wram.wSpriteStateData2[i]
        local xblk, yblk = s2.MapX - 4, s2.MapY - 4
        local pictureid = s1.PictureID
        if not(pictureid == 0) and (is_player or (xblk >= 0 and yblk >= 0)) and (config.show_hidden_sprites or not(s1.SpriteImageIdx == 0xff) or not hidden_sprites[i]) then
            local dx, dy
            local offset
            local dir = s1.FacingDirection
            local anim = s1.AnimFrameCounter
            local should_flip = false
            if dir == 0 then
                dx, dy = 0, 1
                if anim == 1 then
                    offset = 3
                elseif anim == 3 then
                    should_flip = true
                    offset = 3
                else
                    offset = 0
                end
            elseif dir == 4 then
                dx, dy = 0, -1
                if anim == 1 then
                    offset = 4
                elseif anim == 3 then
                    should_flip = true
                    offset = 4
                else
                    offset = 1
                end
            elseif dir == 8 then
                dx, dy = -1, 0
                if anim == 0 or anim == 2 then
                    offset = 2
                else
                    offset = 5
                end
            else--if dir == 0xc then
                dx, dy = 1, 0
                should_flip = true
                if anim == 0 or anim == 2 then
                    offset = 2
                else
                    offset = 5
                end
            end
            if s1.MovementStatus == 3 then
                spritex[i] = math.max(-32, math.min(32, dx + (spritex[i] or 0)))
                spritey[i] = math.max(-32, math.min(32, dy + (spritey[i] or 0)))
            else
                dx, dy = 0, 0
                spritex[i] = 0
                spritey[i] = 0
            end

            if is_player and self.wram.wWalkBikeSurfState == 1 then
                pictureid = 'red_on_bike'
            end

            local spritemap = getspritefromrom(pictureid)
            -- this should be the right way to do it
            -- but ball/omanyte/clipboard/etc overflows
            -- when it "turns"
            offset = math.min(offset, spritemap.height/16 - 1)
            -- so this hack becomes necessary
            if 2*spritemap.height == 0x40 then
                offset = 0
                should_flip = false
            end

            local x, y
            if is_player then
                x = halfscrwidth
                y = halfscrheight - 4
            else
                x = (xblk-dx)*16 + math.floor(spritex[i]/2) - playerx + halfscrwidth
                y = (yblk-dy)*16 - 4 + math.floor(spritey[i]/2) - playery + halfscrheight
            end

            C.fastcopyaf(
                bufpix, bufheight, bufwidth, x, y + 16 - spritemap.spriteheight,
                spritemap.pix + offset*spritemap.width*spritemap.spriteheight*3, spritemap.spriteheight, spritemap.width, SPRITE_INVIS_COLOR, should_flip
            )
        end
    end
end

local lastwalkcount
local sevencount = 0
function Red:prep_render_player()
    local walkcount = self.wram.wWalkCounter
    if walkcount == 7 then
        -- wWalkCounter is 7 three times when biking
        -- and 2 times while walking
        sevencount = sevencount + 1
    end
    if walkcount == 0 then
        walkcount = 8
        lastwalkcount = 8
        sevencount = 0
    elseif walkcount == lastwalkcount then
        -- get dat sexy 60fps
        if not(sevencount == 3) or walkcount == 7 then -- walking (or still in 7s)
            walkcount = walkcount - 0.5
        else -- biking
            walkcount = walkcount - 1
        end
    else
        lastwalkcount = walkcount
    end
    local speed = (8 - walkcount)*2

    local dir = self.wram.wPlayerMovingDirection
    local diffx, diffy = 0, 0
    if dir == 8 then -- up
        diffy = -speed
    elseif dir == 4 then -- down
        diffy = speed
    elseif dir == 2 then -- left
        diffx = -speed
    elseif dir == 1 then -- right
        diffx = speed
    end

    playerx = math.floor(self.wram.wXCoord * 16 + diffx)
    playery = math.floor(self.wram.wYCoord * 16 + diffy)
end

local function monbank(num)
    -- game freak was lazy and hardcoded it
    -- so i have to too :(
    if num <= 0x1e then
        return 0x09
    elseif num <= 0x49 then
        return 0x0a
    elseif num <= 0x72 then
        return 0x0b
    elseif num <= 0x98 then
        return 0x0c
    else
        return 0x0d
    end
end


function getpic(species, facing)
    if species < 1 or species > 190 then return end
    local self = Red
    local siz = 28
    local offset
    if facing == 'front' then
        offset = 11
    elseif facing == 'back' then
        offset = 13
    end

    if species == 21 then
        -- mew get special treatment
        local rom = self.rom.MewBaseStats + offset
        local addr = rom[0] + rom[1]*0x100
        return emu:rom(0x01, addr)
    else
        local dex = self.rom.PokedexOrder[species - 1]
        if dex == 0 then return end
        local rom = self.rom.MonBaseStats + (dex - 1)*siz + offset
        local addr = rom[0] + rom[1]*0x100
        return emu:rom(monbank(species), addr)
    end
end

local lastfriend, lastenemy
local friendbmap, enemybmap

function Red:render_battlesprites()
    local friend = self.wram.wBattleMon.Species
    local enemy = self.wram.wEnemyMon.Species

    local friendpic = getpic(friend, 'back')
    local enemypic = getpic(enemy, 'front')

    if not friendpic then
        friendbmap = nil
        lastfriend = nil
    elseif not(lastfriend == friend) then
        lastfriend = friend
        friendbmap = getbmon(friendpic)
    end

    if not enemypic then
        enemybmap = nil
        lastenemy = nil
    elseif not(lastenemy == enemy) then
        lastenemy = enemy
        enemybmap = getbmon(enemypic)
    end

    if friendbmap then
        friendbmap:fastdraw(Screen.top, 0, Screen.top.height - friendbmap.height)
    end

    if enemybmap then
        enemybmap:fastdraw(Screen.top, Screen.top.width - enemybmap.width, 0)
    end
end

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
                tile:fastdraw(Screen.top, x*tile.width - xplayer + halfscrwidth, y*tile.height - yplayer + halfscrheight)
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
    local xoff, yoff = -xplayer + halfscrwidth, -yplayer + halfscrheight
    if bit.band(connection_flag, bit.lshift(1, 3)) ~= 0 then
        if yplayer < halfscrheight then
            local map, xoff, mapwidth, mapheight = getoff(8)
            self:render_map(map, mapx - xoff, mapy + mapheight, xplayer - xoff*32, yplayer + mapheight*32)
        end
        addr = addr + 11
    end
    -- south connection
    if bit.band(connection_flag, bit.lshift(1, 2)) ~= 0 then
        if height*32 - yplayer < halfscrheight + 16 then
            local map, xoff, mapwidth, mapheight = getoff(8)
            self:render_map(map, mapx - xoff, -(height - mapy), xplayer - xoff*32, -(height*32 - yplayer))
        end
        addr = addr + 11
    end
    -- west connection
    if bit.band(connection_flag, bit.lshift(1, 1)) ~= 0 then
        if xplayer < halfscrwidth then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(map, mapx + mapwidth, mapy - yoff, xplayer + mapwidth*32, yplayer - yoff*32)
        end
        addr = addr + 11
    end
    -- east connection
    if bit.band(connection_flag, bit.lshift(1, 0)) ~= 0 then
        if width*32 - xplayer < halfscrwidth + 16 then
            local map, yoff, mapwidth, mapheight = getoff(7)
            self:render_map(map, -(width - mapx), mapy - yoff, -(width*32 - xplayer), yplayer - yoff*32)
        end
        addr = addr + 11
    end
end


function randomizerainbow()
    local function r()
        return math.floor(math.random()*0x100)
    end

    Rainbow = {
        {r(), r(), r()},
        {r(), r(), r()},
        {r(), r(), r()},
        {r(), r(), r()},
    }
end
ROOT.colors = {}
ROOT.colors.randomize = function()
    randomizerainbow()
    cleartiles(Red.tiles)
    if Red then
        Red.sprites = {}
    end
    collectgarbage()
end

local rainbows = require 'config.rainbows'

local current_rainbow
ROOT.colors.cycle = function(first)
    if not current_rainbow or current_rainbow >= #rainbows then
        current_rainbow = 0
    end
    current_rainbow = current_rainbow + 1

    Rainbow = rainbows[current_rainbow]
    if not first then
        cleartiles(Red.tiles)
        Red.sprites = {}
    end
end
ROOT.colors.cycle(true)

ROOT.colors.save = function()
    rainbows[#rainbows + 1] = Rainbow
    local f = io.open(PATH..'/lua/config/rainbows.lua', 'w')
    f:write('return ')
    serialize(f, rainbows)
    f:close()
end

if Toggler then
    Toggler:reload()
end

local switcharoo = {
    0,
    2,
    3,
}

local invis_color = {SPRITE_INVIS_COLOR, SPRITE_INVIS_COLOR, SPRITE_INVIS_COLOR}

function BPP_CONV(pix, bpp, i, width, is_sprite, make_ff_invis_anyway, transpose)
    local yy = Red.Tilesize*math.floor(i/width)
    local xx = Red.Tilesize*math.floor(i%width)
    if transpose then
        local tmp = xx
        xx = yy
        yy = tmp
    end
    for y=0,Red.Tilesize-1 do
        local low = bpp[2*y + 0]
        local high = bpp[2*y + 1]
        for x=0,Red.Tilesize-1 do
            local val = bit.band(1, bit.rshift(low, 7-x))
            val = val + 2*bit.band(1, bit.rshift(high, 7-x))
            val = 3 - val
            --val = math.floor(val*0xff/3)
            if is_sprite then
                val = switcharoo[val + 1]
            elseif make_ff_invis_anyway and val == 3 then
                val = nil
            end
            local idx = (yy+y)*width*8 + x + xx
            local color = val and Rainbow[val+1] or invis_color
            pix[idx*3 + 0] = color[0+1]
            pix[idx*3 + 1] = color[1+1]
            pix[idx*3 + 2] = color[2+1]
        end
    end
end

function getbmon(rom)
    local self = Red
    local pic = Red.Pic:new(rom)
    local bpp = pic:decompress()
    local pix = ffi.new('uint8_t[?]', pic.width*pic.height*3)
    for i=0,(pic.width/Red.Tilesize)*(pic.height/Red.Tilesize)-1 do
        BPP_CONV(pix, bpp + i*16, i, pic.width/Red.Tilesize, nil, nil, true)
    end

    local bmap = Bitmap:new{
        pix = pix,
        width = pic.width,
        height = pic.height,
        channels = 3
    }
    bmap:prerotate()
    bmap:makebgr()

    return bmap
end

function gettilefromrom(tileset, tile)
    local self = Red

    local header = self.rom.Tilesets + tileset*12
    -- ptr to .bst
    local bst = emu:rom(header[0], tile*16 + header[1] + header[2] * 0x100)
    -- ptr to .2bpp
    local bpp = emu:rom(header[0], header[3] + header[4] * 0x100)
    local pix = ffi.new('uint8_t[?]', 32*32*3)

    for i=0,16-1 do
        BPP_CONV(pix, bpp + bst[i]*16, i, 4)
    end

    local bmap = Bitmap:new{
        pix = pix,
        width = 32,
        height = 32,
        channels = 3,
    }
    bmap:prerotate()
    bmap:makebgr()
    return bmap
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

local function init(self)
    init = function() end -- make sure this is only run the first frame

    self.sprites = {}

    self.tiles = cleartiles()
    self.customtiles = cleartiles()
end

function Red:render(framebuffer, dframebuffer)
    init(self)

    if self.wram.wIsInBattle == 0 then
        self:prep_render_player()
        self:render_map(self.wram.wCurMap, math.floor(self.wram.wXCoord/2), math.floor(self.wram.wYCoord/2), playerx, playery, true)
        self:render_sprites(dframebuffer)
        RENDER_DIALOGUE()
    else
        self:render_battlesprites()

        -- temporary: just draw the emulator on top screen
        emu:render()
    end

    SHITTY_DIALOGUE_PRINTER()
end
