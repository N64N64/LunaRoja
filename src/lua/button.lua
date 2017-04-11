Button = {
    a = 0,
    b = 1,
    select = 2,
    start = 3,
    dright = 4,
    dleft = 5,
    dup = 6,
    ddown = 7,
    r = 8,
    l = 9,
    x = 10,
    y = 11,
    zl = 14,
    zr = 15,
    touch = 20,
    cstick_right = 24,
    cstick_left = 25,
    cstick_up = 26,
    cstick_down = 27,
    cpad_right = 28,
    cpad_left = 29,
    cpad_up = 30,
    cpad_down = 31,
}
for k,v in pairs(Button) do
    Button[k] = bit.lshift(1, v)
end
Button.right = bit.bor(Button.dright, Button.cpad_right)
Button.left = bit.bor(Button.dleft, Button.cpad_left)
Button.up = bit.bor(Button.dup, Button.cpad_up)
Button.down = bit.bor(Button.ddown, Button.cpad_down)

for k,v in pairs(Button) do
    Button[string.upper(k)] = v
end

Button.KeysHeld = 0
Button.KeysDown = 0
Button.KeysUp = 0

function Button.isdown(key)
    return bit.band(Button.KeysDown, key) ~= 0
end

function Button.isup(key)
    return bit.band(Button.KeysUp, key) ~= 0
end

function Button.isheld(key)
    return bit.band(Button.KeysHeld, key) ~= 0
end

if PLATFORM == 'cmd' then
    function Button.Scan() end
else
    require('plat.'..PLATFORM..'.button')
end

return Button
