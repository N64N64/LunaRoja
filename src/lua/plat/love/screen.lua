function Screen.init()
    Screen.top.width = 400
    Screen.top.height = 240
    Screen.top.lovedata = love.image.newImageData(Screen.top.height, Screen.top.width)
    Screen.top.love = love.graphics.newImage(Screen.top.lovedata)
    Screen.top.love:setFilter('linear', 'nearest')
    Screen.top.pix = ffi.new('uint8_t[?]', Screen.top.width*Screen.top.height*3)

    Screen.bottom.width = 320
    Screen.bottom.height = 240
    Screen.bottom.lovedata = love.image.newImageData(Screen.bottom.height, Screen.bottom.width)
    Screen.bottom.love = love.graphics.newImage(Screen.bottom.lovedata)
    Screen.bottom.love:setFilter('linear', 'nearest')
    Screen.bottom.pix = ffi.new('uint8_t[?]', Screen.bottom.width*Screen.bottom.height*3)
end

function Screen.startframe()
    C.memset(Screen.top.pix, 0, ffi.sizeof(Screen.top.pix))
    C.memset(Screen.bottom.pix, 0, ffi.sizeof(Screen.bottom.pix))
end

function Screen.endframe()
    -- need to manually copy the pixelbuffer in one by one D:
    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.top.lovedata:getPointer()), Screen.top.pix, Screen.top.width*Screen.top.height)
    Screen.top.love:refresh()

    ffi.luared.lovecopy(ffi.cast('uint8_t *', Screen.bottom.lovedata:getPointer()), Screen.bottom.pix, Screen.bottom.width*Screen.bottom.height)
    Screen.bottom.love:refresh()
end
