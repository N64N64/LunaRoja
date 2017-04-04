jit.off()
local oldprint = print
PATH = '/3ds/luared'
LUAPATH = PATH..'/lua'
PLATFORM = '3ds'
package.path = LUAPATH..'/?.lua;'
             ..LUAPATH..'/?/init.lua;'
             ..package.path

local success, err = xpcall(function()
    require 'plat.3ds.main'
end, debug.traceback)

if success and not ERROR then return true end

io.write('\x1b[2J')

local GFX_TOP = 0
local KEY_START = bit.lshift(1, 3)
local GSPGPU_EVENT_VBlank0 = 2

if not C then return err end

if not C.lua_initted_gfx then
    C.gfxInitDefault()
    C.lua_initted_gfx = true
end

C.consoleInit(GFX_TOP, nil)
io.write('\x1b[00;00HLua died :( Press start to exit\n\n')
if not(print == oldprint) then
    print(err or ERROR)
end
io.write(err or ERROR)
io.write('\n')
while C.aptMainLoop() do
    C.hidScanInput()
    local down = C.hidKeysDown()
    if bit.band(down, KEY_START) ~= 0 then
        break
    end
    C.gfxFlushBuffers()
    C.gfxSwapBuffers()
    C.gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)
end

return true
