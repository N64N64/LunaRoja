require 'plat.cmd.screen'

local super = {init = Screen.init}

function Screen.init()
    super.init()
    Screen.top.lovedata = love.image.newImageData(Screen.top.height, Screen.top.width)
    Screen.top.love = love.graphics.newImage(Screen.top.lovedata)
    Screen.top.love:setFilter('linear', 'nearest')

    Screen.bottom.lovedata = love.image.newImageData(Screen.bottom.height, Screen.bottom.width)
    Screen.bottom.love = love.graphics.newImage(Screen.bottom.lovedata)
    Screen.bottom.love:setFilter('linear', 'nearest')
end

function Screen.endframe()
    -- need to manually copy the pixelbuffer in one by one D:
    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.top.lovedata:getPointer()), Screen.top.pix, Screen.top.width*Screen.top.height)
    Screen.top.love:refresh()

    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.bottom.lovedata:getPointer()), Screen.bottom.pix, Screen.bottom.width*Screen.bottom.height)
    Screen.bottom.love:refresh()
end
