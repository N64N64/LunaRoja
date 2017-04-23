local pix
function Screen.init()
    Screen.top.width = 600
    Screen.top.height = 400
    Screen.top.size = Screen.top.width*Screen.top.height*3
    Screen.top.pix = ffi.new('uint8_t[?]', Screen.top.size)

    Screen.bottom.width = 320
    Screen.bottom.height = 240
    Screen.bottom.size = Screen.bottom.width*Screen.bottom.height*3
    Screen.bottom.pix = ffi.new('uint8_t[?]', Screen.bottom.size)

    Screen.top.lovedata = love.image.newImageData(Screen.top.height, Screen.top.width)
    Screen.top.love = love.graphics.newImage(Screen.top.lovedata)
    Screen.top.love:setFilter('linear', 'nearest')

    Screen.bottom.lovedata = love.image.newImageData(Screen.bottom.height, Screen.bottom.width)
    Screen.bottom.love = love.graphics.newImage(Screen.bottom.lovedata)
    Screen.bottom.love:setFilter('linear', 'nearest')

    pix = ffi.new('uint8_t[?]', math.max(ffi.sizeof(Screen.top.pix), ffi.sizeof(Screen.bottom.pix)))
end

function Screen.startframe()
    C.memset(Screen.top.pix, 0, Screen.top.size)
    C.memset(Screen.bottom.pix, 0, Screen.bottom.size)
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
