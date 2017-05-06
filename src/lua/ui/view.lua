local super = require 'object'
UI.View = Object.new(super)

function UI.View:new(x, y, width, height)
    local self = super.new(self)
    self.x = x or 0
    self.y = y or 0
    self.width = width
    self.height = height
    self.subviews = {}
    return self
end

function UI.View:absolute_coords()
    if self.superview then
        local x, y = self.superview:absolute_coords()
        return self.x + x, self.y + y
    else
        return self.x, self.y
    end
end

function UI.View:contains_point(x, y)
    local absx, absy = self:absolute_coords()

    return x > absx and y > absy and
            x < absx + self.width and y < absy + self.height
end

function UI.View:contains_mouse()
    return self:contains_point(Mouse.x, Mouse.y)
end

function UI.View:add_subview(subview)
    self.subviews[#self.subviews + 1] = subview
    subview.superview = self
end

function UI.View:remove_from_superview()
    local subviews = self.superview.subviews
    for i=1,#subviews do
        if subviews[i] == self then
            table.remove(subviews, i)
            return
        end
    end
    error('superview doesnt have this subview? something weird is going on')
end

function UI.View:draw(scr, x, y)
    if self.background_color then
        ffi.luared.draw_set_color(unpack(self.background_color))
        scr:rect(x, y, self.width, self.height)
    end
end

function UI.View:postdraw(scr, x, y)
end

function UI.View:render(scr, x, y)
    if self.hidden then return end
    assert(scr)

    x = (x or 0) + self.x
    y = (y or 0) + self.y

    self:draw(scr, x, y)

    for i=1,#self.subviews do
        self.subviews[i]:render(scr, x, y)
    end

    self:postdraw(scr, x, y)

end

return UI.View
