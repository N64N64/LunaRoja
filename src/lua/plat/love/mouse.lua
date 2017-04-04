function Mouse.Scan()
    local washeld = Mouse.isheld

    local x, y
    local isheld = love.mouse.isDown(1)

    if isheld then
        local xpad = (Screen.top.width - Screen.bottom.width)/2
        local ypad = Screen.top.height*2

        x = love.mouse.getX() - xpad
        y = love.mouse.getY() - ypad

        if x < 0 or x > Screen.bottom.width or y < 0 then
            isheld = false
            x, y = nil, nil
        end
    end


    Mouse.x, Mouse.y = x, y
    Mouse.isheld = isheld
    Mouse.isdown = Mouse.isheld and not washeld
    Mouse.isup = washeld and not Mouse.isheld
end
