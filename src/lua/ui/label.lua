local super = require 'ui.view'
UI.Label = Object.new(super)

local C_FONTS = {}

--[[
local back_button = ui.button:new('< Back')
back_button.x = 0
back_button.y = 0
back_button.font = Font.Default
back_button.fontsize = 20
function back_button:pressed()
    DISPLAY[2] = DebugMenu
end
]]

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

    if not(self.lasttext == self.text) then
        self.cfont = Font:new(self.font)
        local pix, width, height = self.cfont:paint(self.text, self.fontsize)
        self.width = width
        self.height = height

        if pix == ffi.NULL then error('wtf') end
        self.rawbmap = Bitmap:new{
            pix = pix,
            width = width,
            height = height,
            channels = 1,
        }
    end

    if self.background_color == false then
        self.bmap = self.rawbmap
    else
        local w,h = self.width,self.height
        local bmap = Bitmap:new(w, h)
        ffi.luared.draw_set_color(unpack(self.background_color))
        ffi.luared.draw_rect(bmap.pix, w, h, 0, 0, w, h)
        ffi.luared.draw_set_color(unpack(self.color))
        ffi.luared.purealphacopy(
            bmap.pix, w, h, 0, 0,
            self.rawbmap.pix, w, h
        )
        self.bmap = bmap
    end
    self.lasttext = self.text
end

function UI.Label:unpaint()
    self.bmap = nil
end

function UI.Label:draw(scr, x, y)
    if not self.bmap then error('label not painted') end

    if self.background_color == false then
        C.draw_set_color(unpack(self.color))
        ffi.luared.purealphacopy(
            scr.pix, scr.width, scr.height, x, y,
            self.bmap.pix, self.bmap.width, self.bmap.height
        )
    else
        self.bmap:fastdraw(scr, x, y)
    end
end

return UI.Label
