local super = require 'bitmap'
Gif = Object.new(super)

function Gif.new(_, self, frames)
    if not(getmetatable(self).__index == Bitmap) then
        error('must be a bitmap')
    end
    assert(math.floor(frames) == frames)
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

function Gif:draw(frame, scr, x, y)
    local off = frame*self.width*self.height*self.channels
    ffi.luared.dumbcopy(
        scr.pix, scr.width, scr.height, x, y,
        self.pix + off, self.width, self.height, 3
    )
end

function Gif:drawaf(frame, scr, x, y, should_flip)
    local off = frame*self.width*self.height*self.channels
    ffi.luared.dumbcopyaf(
        scr.pix, scr.width, scr.height, x, y,
        self.pix + off, self.width, self.height, SPRITE_INVIS_COLOR, should_flip and true or false
    )
end

getmetatable(Gif).__call = Gif.new
return Gif
