local super = require 'bitmap'
Gif = Object.new(super)

function Gif.new(_, self, frames)
    if not(getmetatable(self).__index == Bitmap) then
        error('must be a bitmap')
    end
    getmetatable(self).__index = Gif
    self.frames = frames or 1
    self.height = self.height / frames
    return self
end

function Gif:set_frames(frames)
    local pix = ffi.new('uint8_t[?]', ffi.sizeof(self.pix)*frames/self.frames)
    ffi.copy(pix, self.pix, math.min(ffi.sizeof(self.pix), ffi.sizeof(pix)))
    self.pix = pix
    self.frames = frames
end

function Gif:draw(frame, ...)
    local off = frame*self.width*self.height*self.channels
    self.pix = self.pix + off
    super.draw(self, ...)
    self.pix = self.pix - off
end
Gif.fastdraw = Gif.draw

getmetatable(Gif).__call = Gif.new
return Gif
