-- gmod
Game = {}

require 'wip.serverbrowser'
RENDER_CALLBACKS = {}
RENDER_CALLBACKS.lua_logo = require 'art.lua_logo'

UPDATE_CALLBACKS = {}

local firstrun = true
function Game.render()
    if emu and not firstrun then
        emu:run()

        Red:run()
        Red:render()
    end
    firstrun = false

    for k,v in pairs(RENDER_CALLBACKS) do
        v()
    end
end

return Game
