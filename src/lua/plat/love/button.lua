local citra = {
    a = Button.a,
    s = Button.b,
    up = Button.cpad_up,
    down = Button.cpad_down,
    left = Button.cpad_left,
    right = Button.cpad_right,
    m = Button.start,
    n = Button.select,
    t = Button.dup,
    g = Button.ddown,
    f = Button.dleft,
    h = Button.dright,
    i = Button.cstick_up,
    k = Button.cstick_down,
    j = Button.cstick_left,
    l = Button.cstick_right,
    z = Button.x,
    x = Button.y,
    ['1'] = Button.zl,
    ['2'] = Button.zr,
}

function Button.Scan()
    local lastheld = Button.KeysHeld

    Button.KeysHeld = 0
    Button.KeysDown = 0
    Button.KeysUp = 0

    for k,v in pairs(citra) do
        if love.keyboard.isDown(k) then
            Button.KeysHeld = bit.bor(Button.KeysHeld, v)
            if not(bit.band(lastheld, v) ~= 0) then -- wasnt held last frame
                Button.KeysDown = bit.bor(Button.KeysDown, v)
            end
        elseif bit.band(lastheld, v) ~= 0 then -- was held last frame
            Button.KeysUp = bit.bor(Button.KeysUp, v)
        end
    end
end
