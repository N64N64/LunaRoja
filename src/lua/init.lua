ROOT['load ROM'] = {}
for _,v in pairs(ls(PATH..'/rom') or {}) do
    if string.has_suffix(v, '.gbc') or string.has_suffix(v, '.gb') then
        ROOT['load ROM'][v] = function()
            emu = Gameboy:new(PATH..'/rom/'..v)
            RENDER_CALLBACKS.lua_logo = nil
            Red:reset()
        end
    end
end

ROOT['sprite editor'] = function()
    DISPLAY[2] = SpriteEditor
end

ROOT.console = function()
    DISPLAY(Console)
end
ROOT.quit = function()
    wants_to_exit = true
end

Screen.init()

require 'game'
require 'debug_menu'
DISPLAY(Game, DebugMenu)

local quit_label = UI.Label:new()
quit_label.text = 'Press A to quit'
quit_label.color = {0xdd, 0x22, 0x22}
quit_label.fontsize = 30
quit_label:paint()
quit_label.x = (Screen.top.width - quit_label.width)/2
quit_label.y = (Screen.top.height - quit_label.height)/2

local cancel_label = UI.Label:new()
cancel_label.text = 'Press B to cancel'
cancel_label.color = {0xdd, 0xdd, 0xdd}
cancel_label.fontsize = 20
cancel_label:paint()
cancel_label.x = (Screen.top.width - cancel_label.width)/2
cancel_label.y = quit_label.y + quit_label.height

DT = 0

function MAIN_LOOP()

    DT = CALCULATE_DT(DT)

    if SHOULD_QUIT then
        return true
    end


    Button.Scan()
    Mouse.Scan()
    if wants_to_exit then
        if Button.isdown(Button.a) then
            return true
        elseif Button.isdown(Button.b) then
            wants_to_exit = false
            return
        end
    end

    for k,v in pairs(UPDATE_CALLBACKS) do
        v()
    end

    Screen.startframe()
    DISPLAY.render()

    if wants_to_exit then
        C.draw_set_color(0x00, 0x00, 0x00)
        Screen.top:rect(0, quit_label.y - 5, Screen.top.width, quit_label.height + cancel_label.height + 10)
        quit_label:render(Screen.top)
        cancel_label:render(Screen.top)
    end

    Screen.endframe()
end

require 'tmp'

local path = LUAPATH..'/config/autorun.lua'
local f = io.open(path, 'r')
if f then
    f:close()
    dofile(path)
end
