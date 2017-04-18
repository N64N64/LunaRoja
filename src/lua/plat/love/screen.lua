require 'plat.cmd.screen'

local super = {init = Screen.init}

local pix
function Screen.init()
    super.init()
    Screen.top.lovedata = love.image.newImageData(Screen.top.height, Screen.top.width)
    Screen.top.love = love.graphics.newImage(Screen.top.lovedata)
    Screen.top.love:setFilter('linear', 'nearest')

    Screen.bottom.lovedata = love.image.newImageData(Screen.bottom.height, Screen.bottom.width)
    Screen.bottom.love = love.graphics.newImage(Screen.bottom.lovedata)
    Screen.bottom.love:setFilter('linear', 'nearest')

    pix = ffi.new('uint8_t[?]', 1000*1000*3)
end

function Screen.endframe()
    -- need to manually copy the pixelbuffer in one by one D:
    ffi.luared.lastcopy(pix, Screen.top.pix, Screen.top.width, Screen.top.height)
    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.top.lovedata:getPointer()), pix, Screen.top.width*Screen.top.height)
    Screen.top.love:refresh()

    ffi.luared.lastcopy(pix, Screen.bottom.pix, Screen.bottom.width, Screen.bottom.height)
    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.bottom.lovedata:getPointer()), pix, Screen.bottom.width*Screen.bottom.height)
    Screen.bottom.love:refresh()
end
