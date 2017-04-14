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
        if config.render_mgba then
            emu:render(Screen.bottom, 0, 0)
        end

        Red:run()
        Red:render()
    end
    firstrun = false

    for k,v in pairs(RENDER_CALLBACKS) do
        v()
    end
end

return Game
