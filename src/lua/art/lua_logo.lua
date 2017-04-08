local x = Screen.top.width/2
local y = Screen.top.height/2
local scale = Screen.top.height/4
local moon_radius = 1 - math.sqrt(2)/2

local dist_to_moon = scale/math.sin(math.pi/4)

local period = 25.6 -- seconds it takes for moon to orbit
local angle = 0

LUA_COLOR = {0x45, 0x05, 0x17}

return function()
    angle = angle + DT*2*math.pi/period

    local r, g, b = unpack(LUA_COLOR)

    ffi.luared.draw_set_color(r, g, b)

    -- planet
    Screen.top:circle(x, y, scale)

    -- moon
    local moonx = x + math.cos(angle)*dist_to_moon
    local moony = y + math.sin(angle)*dist_to_moon
    Screen.top:circle(moonx, moony, scale*moon_radius)

    -- crater
    ffi.luared.draw_set_color(r/10, g/10, b/10)
    Screen.top:circle(x + scale*(1-2*moon_radius), y - scale*(1-2*moon_radius), scale*moon_radius)

end
