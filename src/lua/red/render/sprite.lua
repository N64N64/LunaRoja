local spritex = {}
local spritey = {}

local function getspriteptr(id)
    local self = Red

    local bank, addr, count
    local def = Red.CustomSprites[id]
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

    if Red.CustomSprites[id] then
        local f = Red.CustomSprites[id].postprocess
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
                x = Red.Camera.x
                y = Red.Camera.y - 4
            else
                x = (xblk-dx)*16 + math.floor(spritex[i]/2) - playerx + Red.Camera.x
                y = (yblk-dy)*16 - 4 + math.floor(spritey[i]/2) - playery + Red.Camera.y
            end

            C.fastcopyaf(
                bufpix, bufheight, bufwidth, x, y + 16 - spritemap.spriteheight,
                spritemap.pix + offset*spritemap.width*spritemap.spriteheight*3, spritemap.spriteheight, spritemap.width, SPRITE_INVIS_COLOR, should_flip
            )
        end
    end
end
