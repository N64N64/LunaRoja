SpriteEditor = {}
local self = SpriteEditor

local canvas, scale, scaled_canvas

local function init()
    init = function() end
    canvas = Bitmap:new(16, 16)
    scale = math.floor(Screen.bottom.height / canvas.height)
    scaled_canvas = Bitmap:new(canvas.width*scale, canvas.height*scale)

    for i=0,canvas.width*canvas.height-1 do
        canvas.pix[i*3 + 0] = i % 0x100
        canvas.pix[i*3 + 1] = (i*2) % 0x100
        canvas.pix[i*3 + 2] = (i + 50) % 0x100
    end
    SpriteEditor.paint()
end

local back_button = UI.Button:new('< Back')
back_button.x = 0
back_button.y = 0
back_button.font = Font.Default
back_button.fontsize = 16
back_button:paint()
function back_button:pressed()
    DISPLAY[2] = DebugMenu
end

function SpriteEditor.render()
    init()
    back_button:render(Screen.bottom)
    scaled_canvas:fastdraw(Screen.bottom, Screen.bottom.width - scaled_canvas.width, (Screen.bottom.height - scaled_canvas.height)/2)
end

function SpriteEditor.paint()
    ffi.fill(scaled_canvas.pix, ffi.sizeof(scaled_canvas.pix), 0x66)
    ffi.luared.scalecopy(
        scaled_canvas.pix, canvas.pix,
        canvas.width, canvas.height,
        scale
    )
    scaled_canvas:prerotate()
end


return SpriteEditor
