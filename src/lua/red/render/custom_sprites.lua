Red.CustomSprites = {}
local bikexoffsets = {
    0,
    0,
    1,
    -1,
    -1,
    0
}
Red.CustomSprites.red_on_bike = {
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
return Red.CustomSprites
