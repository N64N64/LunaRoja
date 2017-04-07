local x = Screen.top.width/2
local y = Screen.top.height/2
local r = Screen.top.height/4
local luar = 1 - math.sqrt(2)/2

local dist_to_moon = r/math.sin(math.pi/4)

local period = 25.6 -- seconds it takes for moon to orbit
local angle = 0

return function()
    angle = angle + DT*2*math.pi/period


    ffi.luared.draw_set_color(0x77, 0x00, 0x00)

    -- planet
    Screen.top:circle(x, y, r)

    -- moon
    local moonx = x + math.cos(angle)*dist_to_moon
    local moony = y + math.sin(angle)*dist_to_moon
    Screen.top:circle(moonx, moony, r*luar)

    -- crater
    ffi.luared.draw_set_color(0x00, 0x00, 0x00)
    Screen.top:circle(x + r*(1-2*luar), y - r*(1-2*luar), r*luar)

end
