-- gmod
Game = {}

require 'wip.serverbrowser'
RENDER_CALLBACKS = {}
RENDER_CALLBACKS.lua_logo = require 'art.lua_logo'

UPDATE_CALLBACKS = {}

local firstrun = true

local debug_label = UI.Label:new()
function Game.render()
    if emu and not firstrun then
        emu:run()
        if config.render_mgba then
            emu:render(Screen.bottom, 0, 0)
        end

        Red:run()
        Red:render()
    end
    Toggler:render()
    if DEBUG_TEXT or not emu then
        local text
        if emu then
            text = tostring(DEBUG_TEXT)
        else
            text = 'ROM path: '..PATH..'/rom/'
        end
        if not(debug_label.text == text) then
            debug_label.text = text
            debug_label:paint()
        end
        debug_label:render(Screen.bottom, Screen.bottom.width - debug_label.width, Screen.bottom.height - debug_label.fontsize)
    end
    firstrun = false

    for k,v in pairs(RENDER_CALLBACKS) do
        v()
    end
end

return Game
