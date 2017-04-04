ROOT['load ROM'] = {}
for _,v in pairs(ls(PATH..'/rom') or {}) do
    if string.has_suffix(v, '.gbc') or string.has_suffix(v, '.gb') then
        ROOT['load ROM'][v] = function()
            emu = Gameboy:new(PATH..'/rom/'..v)
            Red:reset()
        end
    end
end

Screen.init()

local debug_label = UI.Label:new()
debug_label.fontsize = 12

RENDER_CALLBACKS = {}

function render()
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
        debug_label:render(Screen.bottom)
    end
    firstrun = false

    for k,v in pairs(RENDER_CALLBACKS) do
        v()
    end
end
Mode['game'] = {
    keycallback = function(key)
    end,
    rendercallback = render
}
Mode['console'] = Console.mode
--mode[3] = paint.mode

rendercallbacks = {}
Mode:changeto('game')

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

    Screen.startframe()
    Mode:update()

    rendercallbacks.mode()

    if wants_to_exit then
        C.draw_set_color(0x00, 0x00, 0x00)
        Screen.top:rect(0, quit_label.y - 5, Screen.top.width, quit_label.height + cancel_label.height + 10)
        quit_label:render(Screen.top)
        cancel_label:render(Screen.top)
    end

    Screen.endframe()
end

