SpriteEditor = {}


local back_button = UI.Button:new('< Back')
back_button.x = 0
back_button.y = 0
back_button.font = Font.Default
back_button.fontsize = 20
back_button:paint()
function back_button:pressed()
    DISPLAY[2] = DebugMenu
end

function SpriteEditor.render()
    back_button:render(Screen.bottom)
end

return SpriteEditor
