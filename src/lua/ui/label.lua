local super = require 'ui.view'
UI.Label = Object.new(super)

local C_FONTS = {}

function UI.Label:new(text, fontsize, color)
    local self = super.new(self)
    self.text = text
    self.color = color or {0xff, 0xff, 0xff}
    self.background_color = {0x00, 0x00, 0x00}
    self.font = Font.Default
    self.fontsize = fontsize or 14
    return self
end

local intptr = ffi.new('int[2]')
function UI.Label:paint()
    if not self.text then error('text not set') end

    local cfont = C_FONTS[self.font]
    if not cfont then
        cfont = ffi.luared.font_create(PATH..'/res/font/'..self.font)
        if cfont == ffi.NULL then error('wtf') end
        C_FONTS[self.font] = cfont
    end

    local pix = ffi.luared.font_render(cfont, self.text, self.fontsize, intptr+0, intptr+1)
    self.width = intptr[0]
    self.height = intptr[1]
    if pix == ffi.NULL then error('wtf') end
    local bmap = Bitmap:new(self.height, self.width)
    ffi.luared.draw_set_color(unpack(self.background_color))
    ffi.luared.draw_rect(bmap.pix, bmap.height, bmap.width, 0, 0, self.width, self.height)
    ffi.luared.draw_set_color(unpack(self.color))
    ffi.luared.rotatecopy(
        bmap.pix, bmap.width, bmap.height, 3, 0, 0,
        pix, self.width, self.height, 1, 0, 0
    )
    if not(ffi.os == 'Windows') then
        -- this crashes Windows. TODO dont leak memory
        C.free(pix)
    end
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
