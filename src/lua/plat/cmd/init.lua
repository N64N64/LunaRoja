PATH = '.'
LUAPATH = 'src/lua'
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

emu = Gameboy:new(PATH..'/'..arg[1])
Red:reset()

MAIN_LOOP()

print(startserver())

while true do
    MAIN_LOOP()
    C.usleep(CALCULATE_DT()*1000*1000)
 end
