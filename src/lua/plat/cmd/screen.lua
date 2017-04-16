function Screen.init()
    Screen.top.width = 400
    Screen.top.height = 240
    Screen.top.size = Screen.top.width*Screen.top.height*3
    Screen.top.pix = ffi.new('uint8_t[?]', Screen.top.size)

    Screen.bottom.width = 320
    Screen.bottom.height = 240
    Screen.bottom.size = Screen.bottom.width*Screen.bottom.height*3
    Screen.bottom.pix = ffi.new('uint8_t[?]', Screen.bottom.size)
end

function Screen.startframe()
    C.memset(Screen.top.pix, 0, Screen.top.size)
    C.memset(Screen.bottom.pix, 0, Screen.bottom.size)
end

function Screen.endframe()
end
