function UI.Button(self, f, txt)
    local orig = self.draw or function() end
    function self:draw(scr, x, y)
        if Mouse.isup and self:contains_mouse() then
            self:pressed()
        end
        orig(self, scr, x, y)
    end
    self.pressed = f or self.pressed

    if txt then
        local label = UI.Label:new(txt)
        label.font = Font.Default
        label.fontsize = 12
        label.background_color = false
        label:paint()
        label.x = (self.width - label.width)/2
        label.y = (self.height - label.height)/2
        self.label = label
        self:add_subview(label)
    end
    return self
end

return UI.Button
