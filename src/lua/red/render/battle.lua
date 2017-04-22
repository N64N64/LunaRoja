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
        friendbmap:draw(Screen.top, 0, Screen.top.height - friendbmap.height)
    end

    if enemybmap then
        enemybmap:draw(Screen.top, Screen.top.width - enemybmap.width, 0)
    end
end

function getbmon(rom)
    local self = Red
    local pic = Red.Pic:new(rom)
    local bpp = pic:decompress()

    return BPP(bpp, pic.width, pic.height, 'transpose')
end
