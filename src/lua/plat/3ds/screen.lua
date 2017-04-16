local size = ffi.new('uint16_t[2]')
function Screen.init()
    C.gfxInitDefault()
    C.lua_initted_gfx = true

    C.gfxGetFramebuffer(GFX_TOP,    GFX_LEFT, size+0, size+1)
    Screen.top.width = size[1]
    Screen.top.height = size[0]
    Screen.top.size = Screen.top.width*Screen.top.height*3
    Screen.top.pix = ffi.new('uint8_t[?]', Screen.top.size)

    C.gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, size+0, size+1)
    Screen.bottom.width = size[1]
    Screen.bottom.height = size[0]
    Screen.bottom.size = Screen.bottom.width*Screen.bottom.height*3
    Screen.bottom.pix = ffi.new('uint8_t[?]', Screen.bottom.size)
end

function Screen.startframe()
    C.memset(Screen.top.pix, 0, Screen.top.size)
    C.memset(Screen.bottom.pix, 0, Screen.bottom.size)
end

function Screen.endframe()
    local pix = C.gfxGetFramebuffer(GFX_TOP,    GFX_LEFT, size+0, size+1)
    C.lastcopy(pix, Screen.top.pix, Screen.top.width, Screen.top.height)
    local pix = C.gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, size+0, size+1)
    C.lastcopy(pix, Screen.bottom.pix, Screen.bottom.width, Screen.bottom.height)
    C.gfxFlushBuffers()
    C.gfxSwapBuffers()
    C.gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)
end
