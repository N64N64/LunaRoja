local super = Object
Bitmap = Object.new(super)

local loaded_bitmaps
function Bitmap.ResetCache()
    loaded_bitmaps = setmetatable({}, {__mode = 'v'})
end
Bitmap.ResetCache()

local ptr = ffi.new('int[3]')
function Bitmap:new(arg1, arg2, arg3, arg4)
    local self = super.new(self)
    if type(arg1) == 'string' then
        local path = arg1
        if loaded_bitmaps[path] then
            return loaded_bitmaps[path]
        else
            loaded_bitmaps[path] = self
        end

        -- init
        local cpix = C.stbi_load(path, ptr + 0, ptr + 1, ptr + 2, arg2 or 0)
        if cpix == ffi.NULL then
            local reason = C.stbi_failure_reason()
            if reason == ffi.NULL then
                error('failed: (path: '..path..')')
            else
                error(ffi.string(C.stbi_failure_reason())..' (path: '..path..')')
            end
        end
        self.width, self.height, self.channels = ptr[0], ptr[1], ptr[2]

        -- copy external C data into something garbage collectable
        self.pix = ffi.new('uint8_t[?]', self.width*self.height*self.channels)
        ffi.copy(self.pix, cpix, ffi.sizeof(self.pix))
        C.free(cpix)

        self.path = path
    elseif type(arg1) == 'table' and not arg2 then
        self = arg1
        setmetatable(self, {__index = Bitmap})
    elseif type(arg1) == 'number' and type(arg2) == 'number' and not arg4 then
        arg3 = arg3 or 3
        self.width, self.height, self.channels = arg1, arg2, arg3
        self.pix = ffi.new('uint8_t[?]', self.width*self.height*self.channels)
    elseif arg1 and arg2 and arg3 and arg4 then
        self.pix, self.width, self.height, self.channels = arg1, arg2, arg3, arg4
    else
        error('invalid args')
    end

    return self
end

function Bitmap:save(path)
    C.stbi_write_png(path, self.width, self.height, self.channels, self.pix, self.width*self.channels)
end

function Bitmap:draw(scr, x, y)
    ffi.luared.dumbcopy(
        scr.pix, scr.width, scr.height, x, y,
        self.pix, self.width, self.height, 3
    )
end

function Bitmap:drawaf(scr, x, y, should_flip)
    ffi.luared.dumbcopyaf(
        scr.pix, scr.width, scr.height, x, y,
        self.pix, self.width, self.height, SPRITE_INVIS_COLOR, should_flip and true or false
    )
end

return Bitmap
