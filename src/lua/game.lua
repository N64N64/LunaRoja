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
    if not firstrun and not emu then

        if ROMFILE then
            emu = Gameboy:new(ROMFILE)
            Red:reset()
            RENDER_CALLBACKS.lua_logo = nil
        end
    end
    firstrun = false

    for k,v in pairs(RENDER_CALLBACKS) do
        v()
    end
end

return Game
