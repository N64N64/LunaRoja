local super = require 'ui.view'
UI.Label = Object.new(super)

local C_FONTS = {}

function UI.Label:new(text, fontsize, color)
    local self = super.new(self)
    self.text = text
    self.color = color or {0xff, 0xff, 0xff}
    self.background_color = {0x00, 0x00, 0x00}
    self.font = Font.Default
    self.fontsize = fontsize or 12
    return self
end

local intptr = ffi.new('int[2]')
function UI.Label:paint()
    if not self.text then error('text not set') end

    local font = Font:new(self.font) -- TODO cache this?
    local pix, width, height = font:paint(self.text, self.fontsize)
    self.width = width
    self.height = height

    if pix == ffi.NULL then error('wtf') end
    local bmap = Bitmap:new(self.height, self.width)
    ffi.luared.draw_set_color(unpack(self.background_color))
    ffi.luared.draw_rect(bmap.pix, bmap.height, bmap.width, 0, 0, self.width, self.height)
    ffi.luared.draw_set_color(unpack(self.color))
    ffi.luared.rotatecopy(
        bmap.pix, bmap.width, bmap.height, 3, 0, 0,
        pix, self.width, self.height, 1, 0, 0
    )
    self.bmap = bmap
end

function UI.Label:unpaint()
    self.bmap = nil
end

function UI.Label:draw(scr, x, y)
    if not self.bmap then error('label not painted') end

    self.bmap:fastdraw(scr, x, y)
end

return UI.Label
