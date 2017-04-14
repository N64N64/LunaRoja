LUAPATH = PATH..'/src/lua'
PLATFORM = 'cmd'
package.path = LUAPATH..'/?.lua;'
             ..LUAPATH..'/?/init.lua;'
             ..package.path

require 'preinit'
require 'plat.cmd.util'
require 'init'

function CALCULATE_DT()
    return 1/60
end

MAIN_LOOP()

emu = Gameboy:new(ROMPATH)
Red:reset()

MAIN_LOOP()

print(startserver())

if not(arg[2] == 'test') then
    while true do
        MAIN_LOOP()
        C.usleep(CALCULATE_DT()*1000*1000)
    end
end
