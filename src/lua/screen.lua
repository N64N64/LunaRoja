Screen = {}
local mt = {__index = Screen}
Screen.top = setmetatable({}, mt)
Screen.bottom = setmetatable({}, mt)

require('plat.'..PLATFORM..'.screen')

function Screen:pixel(x, y, r, g, b, a)
    if true then
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

function Screen:line(x1, y1, x2, y2, r, g, b, a)
    if true then
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
        self:pixel(x, y, r, g, b, a)
        x = x + dx
        y = y + dy
    end
    self:pixel(x2, y2, r, g, b, a)
end

function Screen:rect(x, y, width, height)
    ffi.luared.draw_rect(self.pix, self.width, self.height, x, y, width, height)
end

return Screen
