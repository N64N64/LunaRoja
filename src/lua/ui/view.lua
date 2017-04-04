local super = require 'object'
UI.View = Object.new(super)

function UI.View:new()
    local self = super.new(self)
    self.x = 0
    self.y = 0
    self.subviews = {}
    return self
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
        C.draw_set_color(unpack(self.background_color))
        scr:rect(x, y, self.width, self.height)
    end
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
end

return UI.View
