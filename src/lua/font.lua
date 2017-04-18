local super = Object
Font = Object.new(super)

local freetype = require 'cdef.freetype'
Font.Monospace = 'SourceCodePro-Medium.ttf'
Font.Default = 'NotoSans-Regular.ttf'
Font.Bold = 'NotoSans-Bold.ttf'
Font.Path = PATH..'/res/font'

local created = setmetatable({}, {__mode = 'v'})

function Font:new(name)
    name = name or Font.Default
    if created[name] then
        return created[name]
    end

    local self = super.new(self)

    self.name = name
    self.path = Font.Path..'/'..self.name

    if NO_FREETYPE then return self end

    self.ft = freetype.new()
    if ffi.os == 'Windows' then
        -- TODO figure out why io.readbin doesnt work on windows
        self.face = self.ft:new_face(self.path)
    else
        self.bin = io.readbin(self.path)
        self.face = self.ft:new_memory_face(self.bin, ffi.sizeof(self.bin))
    end

    self = SETGC(self, function()
        --[[
        self.face:free()
        self.ft:free()
        self.face = nil
        self.ft = nil
        ]]
    end)

    created[name] = self
    return self
end

function Font:paint(text, size)
    if NO_FREETYPE then return ffi.new('uint8_t[9]'), 3, 3 end
    local len = #text
    local str = ffi.cast('const char *', text)
    local face = self.face

    face:set_pixel_sizes(size)

    local minusx = 0
    local outwidth = 0
    local outheight = 0

    for i=0,len-1 do
        face:load_char(str[i], freetype.FT_LOAD_RENDER)
        local x = face.glyph.bitmap_left
        local y = face.glyph.bitmap_top
        local width = face.glyph.bitmap.width
        local height = face.glyph.bitmap.rows
        local advance = bit.rshift(tonumber(face.glyph.advance.x), 6)
        if i == 0 and x < 0 then
            minusx = -x
            outwidth = outwidth + minusx
        end
        if i == len - 1 then
            outwidth = outwidth + math.max(advance, math.abs(x) + width)
        else
            outwidth = outwidth + advance
        end
        outheight = math.max(-y + size + height, outheight)
    end

    outwidth = outwidth + 1 -- no idea why this is necessary

    local outpix = ffi.new('uint8_t[?]', outwidth*outheight)
    C.memset(outpix, 0, ffi.sizeof(outpix))

    local x0 = 0

    for i=0,len-1 do
        face:load_char(str[i], freetype.FT_LOAD_RENDER)
        local width = face.glyph.bitmap.width
        local height = face.glyph.bitmap.rows
        local pix = face.glyph.bitmap.buffer
        local x = face.glyph.bitmap_left + minusx
        local y = face.glyph.bitmap_top
        local advance = bit.rshift(tonumber(face.glyph.advance.x), 6)

        if x0 + x + width > outwidth or x0 + x < 0 then
            error('bad x coords')
        elseif size - y + height > outheight or size - y < 0 then
            error('bad y coords')
        else
            ffi.luared.dumbcopy(
                outpix, outwidth, outheight, x0 + x, size - y,
                pix, width, height, 1
            )

            x0 = x0 + advance
        end
    end

    return outpix, outwidth, outheight
end




return Font
