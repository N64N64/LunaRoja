function UI.Button(self, f)
    local orig = self.draw or function() end
    function self:draw(scr, x, y)
        if Mouse.isup and self:contains_mouse() then
            self:pressed()
        end
        orig(self, scr, x, y)
    end
    self.pressed = f or self.pressed
    return self
end

return UI.Button
