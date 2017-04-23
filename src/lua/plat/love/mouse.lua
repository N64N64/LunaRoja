function Mouse.Scan()
    local washeld = Mouse.isheld

    local isheld = love.mouse.isDown(1)

    if isheld then
        local xpad = Screen.bottom.width/4
        local ypad = Screen.top.height

        Mouse.x = love.mouse.getX() - xpad
        Mouse.y = love.mouse.getY() - ypad

        if Mouse.x < 0 or Mouse.x > Screen.bottom.width or Mouse.y < 0 then
            isheld = false
        end
    end


    Mouse.isheld = isheld
    Mouse.isdown = Mouse.isheld and not washeld
    Mouse.isup = washeld and not Mouse.isheld
end
