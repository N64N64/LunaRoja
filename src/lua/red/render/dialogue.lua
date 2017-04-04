-- This entire thing is a hack.
-- It just checks for that little
-- pokeball in the top left corner
-- on the emulator screen. If it's
-- there, then it just redraws the
-- emulator on the top screen.

--[[
    .......
    ...##..
    ..#.##.
    .######
    .#....#
    ..#..#.
    ...##.#
]]
local X = true
local o = false
local check = {
    {o, o, o, X, X},
    {o, o, X, o, X, X},
    {o, X, X, X, X, X, X},
    {o, X, o, o, o, o, X},
    {o, o, X, o, o, X},
    {o, o, o, X, X},
}

local strs = {}

 -- mGBA platform
 -- difference quirk
local black, white
if PLATFORM == '3ds' then
    black = {0, 0}
    white = {223, 255}
else
    black = {0, 0, 0, 0}
    white = {0xff, 0xff, 0xff, 0}
end
assert(#black == #white)
local siz = #black

for _,row in ipairs(check) do
    local s = ffi.new('uint8_t[?]', #row * siz)
    for i,char in ipairs(row) do
        local color
        if char == o then
            color = white
        elseif char == X then
            color = black
        end
        for j=1,siz do
            s[siz*(i - 1) + j - 1] = color[j]
        end
    end
    table.insert(strs, s)
end

function RENDER_DIALOGUE()
    for i,s in ipairs(strs) do
        local y = 97 + i - 1
        local pix = emu.pix + siz*y*emu.width
        if not(C.memcmp(pix, s, ffi.sizeof(s)) == 0) then
            return
        end
    end

    emu:render()
end
