ROOT = {}
local path = LUAPATH..'/config/preautorun.lua'
local f = io.open(path, 'r')
if f then
    f:close()
    dofile(path)
end

ffi = require 'ffi'
bit = require 'bit'

require 'object'

require 'config'
require 'cdef'
require 'util'
require 'env'

require 'font'
require 'bitmap'

Net = {}
require 'net.server'
require 'net.client'

UI = {}
require 'ui.view'
require 'ui.label'
require 'ui.picker'
require 'ui.button'

require 'screen'
require 'button'
require 'mouse'

require 'keyboard'
require 'display'
require 'gameboy'
require 'console'
require 'toggler'
require 'rom'
require 'red'
require 'tile_editor'
require 'player'
require 'ogg'
