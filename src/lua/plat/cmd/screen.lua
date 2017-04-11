function Screen.init()
    Screen.top.width = 400
    Screen.top.height = 240
    Screen.top.pix = ffi.new('uint8_t[?]', Screen.top.width*Screen.top.height*3)

    Screen.bottom.width = 320
    Screen.bottom.height = 240
    Screen.bottom.pix = ffi.new('uint8_t[?]', Screen.bottom.width*Screen.bottom.height*3)
end

function Screen.startframe()
    C.memset(Screen.top.pix, 0, ffi.sizeof(Screen.top.pix))
    C.memset(Screen.bottom.pix, 0, ffi.sizeof(Screen.bottom.pix))
end

function Screen.endframe()
end
