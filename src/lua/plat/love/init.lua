function love.load()
    PLATFORM = 'love'
    PATH='.'
    LUAPATH = 'src/lua'
    package.path = LUAPATH..'/?.lua;'
                 ..LUAPATH..'/?/init.lua;'
                 ..package.path
    require 'preinit'
    require 'plat.love.util'
    require 'init'
    love.window.setMode(Screen.top.width*2, Screen.top.height*2 + Screen.bottom.height)
    love.window.setTitle('3DS Simulator')
end

local DT
function CALCULATE_DT()
    return DT
end

function love.update(dt)
    DT = dt
    if MAIN_LOOP() then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(Screen.top.love, 0, Screen.top.height*2, -math.pi/2, 2, 2)
    love.graphics.draw(Screen.bottom.love, (Screen.top.width - Screen.bottom.width)/2, Screen.top.height*3, -math.pi/2)
end
