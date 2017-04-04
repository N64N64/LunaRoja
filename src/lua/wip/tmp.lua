
xx = {}
oo = {}
-- put this in lua/red/render/init.lua:
-- if not xx[i] and not(pictureid == 0) and (is_player or (xblk >= 0 and yblk >= 0)) and (config.show_hidden_sprites or oo[i] or not(s1.SpriteImageIdx == 0xff) or not hidden_sprites[i]) then

function print_missable_sprite_info()
    for i=0,red.wram.wNumSprites do
        local miss = red.wram.wMissableObjectList[i]
        if miss.id == 0xff then break end
        local s1 = red.wram.wSpriteStateData1[miss.id]
        print(string.format('%.2x %.2x %.2x ', miss.id, s1.SpriteImageIdx, miss.index))
    end

    for i=0,4-1 do
        local s = ''
        for x=0,8-1 do
            s = s..string.format('%.2x', red.wram.wMissableObjectFlags[i*8 + x])
        end
        print('')
        print(s)
    end
end
