Red.Dex = {}

-- mons

Red.Dex.Species = {}

for i=1,190 do
    local mon = {}
    mon.species = i
    mon.no = Red.rom.PokedexOrder[mon.species-1]
    mon.name = Red.GetString(Red.rom.MonsterNames + 10*(mon.species-1), nil, nil, 10)

    Red.Dex[mon.no] = mon
    Red.Dex[string.lower(mon.name)] = mon
    Red.Dex[mon.name] = mon
    Red.Dex.Species[mon.species] = mon
end

local mrmime = Red.Dex['MR.MIME']
Red.Dex.mrmime = mrmime
Red.Dex.MRMIME = mrmime

-- moves

Red.Dex.Move = {}
for i=1,165 do
    local move = {}
    move.no = i
    move.name = Red.GetString(Red.rom.MoveNames, i - 1)

    Red.Dex.Move[move.no] = move
    Red.Dex.Move[move.name] = move
    local underscore = string.gsub(move.name, ' ', '_')
    Red.Dex.Move[underscore] = move
    Red.Dex.Move[string.lower(underscore)] = move
end

-- types

Red.Dex.Type = {}
for i=0,0x1a do
    if i <= 0x08 or i >= 0x14 then
        local type = {}
        local rom = Red.rom.TypeNames + i*2
        local rom = emu:rom(Red.sym.TypeNames.bank, rom[0] + rom[1]*0x100)
        type.name = Red.GetString(rom)
        type.no = i

        Red.Dex.Type[type.no] = type
        Red.Dex.Type[type.name] = type
        Red.Dex.Type[string.lower(type.name)] = type
    end
end
