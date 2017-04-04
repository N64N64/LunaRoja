Red.Dex = {}
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

Red.Dex.mrmime = Red.Dex['MR.MIME']
Red.Dex.MRMIME = Red.Dex.mrmime

Red.Dex.Move = {}
for i=1,165 do
    local move = {}
    move.no = i
    move.name = Red.GetString(Red.rom.MoveNames, i - 1)
    Red.Dex.Move[move.no] = move
    Red.Dex.Move[move.name] = move
    Red.Dex.Move[string.lower(string.gsub(move.name, ' ', '_'))] = move
end
