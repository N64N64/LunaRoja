local super = require 'ui.label'
UI.Button = Object.new(super)

function UI.Button:draw(scr, x, y)
    if Mouse.isup and self:contains_mouse() then
        self:pressed()
    end
    super.draw(self, scr, x, y)
end

return UI.Button
