Screen = {}
local mt = {__index = Screen}
Screen.top = setmetatable({}, mt)
Screen.bottom = setmetatable({}, mt)

require('plat.'..PLATFORM..'.screen')

function Screen:pixel(x, y, r, g, b, a)
    if not USE_LUA_FALLBACK then
        ffi.luared.draw_pixel(self.pix, self.width, self.height, x, y)
        return
    end

    if x < 0 or x >= self.width or
       y < 0 or y >= self.height
    then
        error('('..x..', '..y..') is out of range ('..self.width..', '..self.height..')')
    end

    x = math.floor(x + 1)
    y = math.floor(y + 1)

    -- the 3ds screen is in a weird format
    local i = self.height*x - y
    i = i*3
    if a then
        self.pix[i + 0] = self.pix[i + 0]*(1-a) + r*a
        self.pix[i + 1] = self.pix[i + 1]*(1-a) + b*a
        self.pix[i + 2] = self.pix[i + 2]*(1-a) + g*a
    else
        self.pix[i + 0] = r
        self.pix[i + 1] = b
        self.pix[i + 2] = g
    end
end

local function pixel(pix, width, height, x, y, r, g, b, a)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    if x < 0 or x >= width or
       y < 0 or y >= height
    then
        return
    end
    pix = pix + 3*(width*y + x)
    if not a then
        pix[0] = r
        pix[1] = g
        pix[2] = b
    else
        pix[0] = pix[0]*(1-a) + r*a
        pix[1] = pix[1]*(1-a) + g*a
        pix[2] = pix[2]*(1-a) + b*a
    end
end

function Screen:line(x1, y1, x2, y2, r, g, b, a, POOP)
    if not POOP and not USE_LUA_FALLBACK then
        ffi.luared.draw_line(self.pix, self.width, self.height, x1, y1, x2, y2)
        return
    end
    local distx = x2 - x1
    local disty = y2 - y1
    local steps = math.abs(distx) > math.abs(disty) and distx or disty
    steps = math.abs(steps)

    local dx = distx / steps
    local dy = disty / steps

    local x = x1
    local y = y1
    for i=1,steps do
        if POOP then
            pixel(self.pix, self.width, self.height, x, y, r, g, b, a)
        else
            self:pixel(x, y, r, g, b, a)
        end
        x = x + dx
        y = y + dy
    end
    if POOP then
        pixel(self.pix, self.width, self.height, x2, y2, r, g, b, a)
    else
        self:pixel(x2, y2, r, g, b, a)
    end
end

function Screen:circle(x, y, r, should_outline)
    ffi.luared.draw_circle(self.pix, self.width, self.height, x, y, r, should_outline and true or false)
end

function Screen:rect(x, y, width, height)
    ffi.luared.draw_rect(self.pix, self.width, self.height, x, y, width, height)
end

return Screen
