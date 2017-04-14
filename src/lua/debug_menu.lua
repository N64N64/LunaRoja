local super = Object
DebugMenu = Object.new(super)

local debug_label = UI.Label:new()
function DebugMenu.render()
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
end

return DebugMenu
