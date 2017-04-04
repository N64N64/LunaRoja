local start_menu_open = false

emu:hook(Red.sym.DisplayStartMenu, function()
    if start_menu_open then return end

    RENDER_CALLBACKS.startmenu = function()
        emu:render()
    end
    start_menu_open = true
end)

emu:hook(Red.sym.CloseStartMenu, function()
    if not start_menu_open then return end

    RENDER_CALLBACKS.startmenu = nil
    start_menu_open = false
end)
