local size = ffi.new('uint16_t[2]')
function Screen.init()
    C.gfxInitDefault()
    --C.consoleInit(GFX_TOP, nil)
    C.lua_initted_gfx = true

    C.gfxGetFramebuffer(GFX_TOP,    GFX_LEFT, size+0, size+1)
    Screen.top.width = size[1]
    Screen.top.height = size[0]

    C.gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, size+0, size+1)
    Screen.bottom.width = size[1]
    Screen.bottom.height = size[0]
end

function Screen.startframe()
    Screen.top.pix    = C.gfxGetFramebuffer(GFX_TOP,    GFX_LEFT, size+0, size+1)
    C.memset(Screen.top.pix, 0, Screen.top.width * Screen.top.height * 3)

    Screen.bottom.pix = C.gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, size+0, size+1)
    C.memset(Screen.bottom.pix, 0, Screen.bottom.width * Screen.bottom.height * 3)
end

function Screen.endframe()
    C.gfxFlushBuffers()
    C.gfxSwapBuffers()
    C.gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)
end
