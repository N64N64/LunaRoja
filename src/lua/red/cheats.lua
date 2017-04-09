function Red:patch_cheats()
    if cheats.hide_pokemon_logo then
        local rom = emu:patcher(self.sym.DisplayTitleScreen)
        rom = rom + Gameboy.InstructionOffset(rom, 23)
        rom[0] = 0x00 -- nop
        rom[1] = 0x00
        rom[2] = 0x00
    end
    if cheats.skip_follow_oak then
        local rom = emu:patcher(self.sym.PalletTownScript0)
        rom[0] = 0xc9 -- ret
    end
    if cheats.walk_thru_walls then
        local rom = emu:patcher(self.sym.CollisionCheckOnLand)
        rom[0] = 0xa7 -- and a
        rom[1] = 0xc9 -- ret
    end
    if cheats.invisible2trainers then
        local rom = emu:patcher(self.sym.CheckSpriteCanSeePlayer)
        rom[0] = 0xc3 -- jp
        rom[1] = 0xe1
        rom[2] = 0x69
    end
    if cheats.skip_oak_speech then
        -- skip the speech
        local rom = emu:patcher(self.sym.OakSpeech)
        rom = rom + Gameboy.InstructionOffset(rom, 23)
        rom[0] = 0xc9 -- ret

        -- ninten/sony is cute, but no.
        local rom = emu:patcher(self.sym.NintenText)
        rom[0] = string.byte('R') + Red.CharOffset
        rom[1] = string.byte('E') + Red.CharOffset
        rom[2] = string.byte('D') + Red.CharOffset
        rom[3] = 80

        local rom = emu:patcher(self.sym.SonyText)
        rom[0] = string.byte('B') + Red.CharOffset
        rom[1] = string.byte('L') + Red.CharOffset
        rom[2] = string.byte('U') + Red.CharOffset
        rom[3] = string.byte('E') + Red.CharOffset
        rom[4] = 80
    end
    if cheats.instawarp then
        local rom = emu:patcher(self.sym.PlayMapChangeSound)
        rom[0] = 0xc9 -- ret
    end

    if cheats.fastwalk then
        local rom = emu:patcher(self.sym['OverworldLoopLessDelay.moveAhead'])
        rom = rom + Gameboy.InstructionOffset(rom, 11) -- maybe should be 7?
        rom[0] = 0x3e -- ld a,
        rom[1] = 0x01 --       $01
        rom[2] = 0x00 -- nop
    end
    if cheats.skip_intro then
        -- gamefreak/gengar battle
        local rom = emu:patcher(self.sym.Init)
        rom = rom + Gameboy.InstructionOffset(rom, 72)
        for i=0,4 do
            rom[i] = 0x00 -- nop
        end

        -- ash + charmander
        local rom = emu:patcher(self.sym.SetDefaultNamesBeforeTitlescreen)
        rom = rom + Gameboy.InstructionOffset(rom, 26)
        rom[0] = 0xc3 -- jp
        rom[1] = 0x68
        rom[2] = 0x44
    end
end
