local touch = ffi.new('touchPosition[1]')
function Mouse.Scan()
    Mouse.isdown = Button.isdown(Button.touch)
    Mouse.isup = Button.isup(Button.touch)
    Mouse.isheld = Button.isheld(Button.touch)
    if Mouse.isheld then
        C.hidTouchRead(touch)
        Mouse.x = tonumber(touch[0].px)
        Mouse.y = tonumber(touch[0].py)
    else
        Mouse.x = nil
        Mouse.y = nil
    end
end
