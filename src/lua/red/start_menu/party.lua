local show_party_hax

local function label(str)
    local label = UI.Label:new(str)
    label.color = {0x00, 0x00, 0x00}
    label.background_color = {0xff, 0xff, 0xff}
    label:paint()
    return label
end

function show_party_hax(idx)
    local party = {}
    for i=0,Red.wram.wPartyCount-1 do
        local species = Red.wram.wPartySpecies[i]
        local pic = getpic(species, 'front')
        local bmap = getbmon(pic)
        local dex = Red.Dex.Species[species]

        local nick = Red.wram.wPartyMonNicks[i]
        local mon = Red.wram.wPartyMons[i]
        local moves = ''
        for i=0,3 do
            local move = Red.Dex.Move[mon.box.Moves[i]]
            if not move then
                moves = string.sub(moves, 1, #moves - 2)
                break
            end
            moves = moves..move.name..', '
        end
        if not(nick == dex.name) then
            nick = nick..' ('..dex.name..')'
        end
        local labels = {
            label(nick),
            label('Lvl '..mon.Level),
            label('Moves: '..moves),
        }
        table.insert(party, {labels = labels, bmap = bmap})
    end
    RENDER_CALLBACKS.partymenu = function()
        if Button.isdown(Button.b) then
            RENDER_CALLBACKS.partymenu = nil
            emu.halt = false
        end
        C.draw_set_color(0xff, 0xff, 0xff)
        Screen.top:rect(0, 0, Screen.top.width, Screen.top.height)
        local y = 0
        for i,v in ipairs(party) do
            v.bmap:draw(Screen.top, 0, y)
            for i,label in ipairs(v.labels) do
                local y = y + label.fontsize*(i-1)
                label:draw(Screen.top, v.bmap.width, y)
            end
            y = y + v.bmap.height
        end
    end
end




local party_open = false

emu:hook(Red.sym.RedisplayStartMenu, function()
    party_open = false
end)

emu:hook(Red.sym.StartMenu_Pokemon, function()
    if party_open then return end
    party_open = true

    Button.KeysDown = 0
    show_party_hax(1)

    emu.halt = true
    return true
end)
