Bitmap = {}
local mt = {__index = Bitmap}

-- convert num channels to a format
-- e.g. formats[self.channels]
local formats = {'g', 'ga', 'rgb', 'rgba'}

local loaded_bitmaps
function Bitmap.reset_cache()
    loaded_bitmaps = setmetatable({}, {__mode = 'v'})
end
Bitmap.reset_cache()

local ptr = ffi.new('int[3]')
function Bitmap:new(arg1, arg2, arg3, arg4)
    local self = setmetatable({}, mt)
    if type(arg1) == 'string' then
        local path = arg1
        if loaded_bitmaps[path] then
            return loaded_bitmaps[path]
        else
            loaded_bitmaps[path] = self
        end

        -- init
        local cpix = C.stbi_load(PATH..'/pic/'..path, ptr + 0, ptr + 1, ptr + 2, arg2 or 0)
        if cpix == ffi.NULL then
            error(ffi.string(C.stbi_failure_reason())..' (path: '..path..')')
        end
        self.width, self.height, self.channels = ptr[0], ptr[1], ptr[2]

        -- copy external C data into something garbage collectable
        if arg3 == 'prerotate' then
            self.pix = cpix
            self:prerotate()
        else
            self.pix = ffi.new('uint8_t[?]', self.width*self.height*self.channels)
            ffi.copy(self.pix, cpix, ffi.sizeof(self.pix))
        end
        C.free(cpix)

        self:makebgr()
        self.path = path
    elseif type(arg1) == 'table' and not arg2 then
        self = arg1
        setmetatable(self, mt)
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

function Bitmap:draw(scr, x, y, tx, ty, width, height)
    x = x or 0
    y = y or 0
    tx = tx or 0
    ty = ty or 0
    width = width or self.width
    height = height or self.height

    C.rotatecopy(
        scr.pix, scr.height, scr.width, 3, x, y,
        self.pix, width, height, self.channels or 3, tx, ty
    )
end

function Bitmap:fastdraw(scr, x, y)
    C.fastcopy(
        scr.pix, scr.height, scr.width, x, y,
        self.pix, self.width, self.height
    )
end

function Bitmap:scale(scale)
    local pix = ffi.new('uint8_t[?]', self.width*self.height*self.channels*scale*scale)
    for y=0,self.height-1 do
        for x=0,self.width-1 do
            local outidx = scale*(y*self.width*scale + x)
            local ii = y*self.width + x
            ii = ii*self.channels
            for yy=0,scale-1 do
                for xx=0,scale-1 do
                    local oi = outidx + yy*self.width*scale + xx
                    oi = oi*self.channels
                    for c=0,self.channels-1 do
                        pix[oi + c] = self.pix[ii + c]
                    end
                end
            end
        end
    end
    self.pix = pix
    self.width = self.width * scale
    self.height = self.height * scale
end

function Bitmap:force3channels()
    for i=0,self.width*self.height-1 do
        self.pix[i*3 + 0] = self.pix[i*4 + 0]
        self.pix[i*3 + 1] = self.pix[i*4 + 1]
        self.pix[i*3 + 2] = self.pix[i*4 + 2]
    end
end

function Bitmap:prerotate()
    local pix = ffi.new('uint8_t[?]', self.width*self.height*3)
    C.rotatecopy(
        pix, self.height, self.width, 3, 0, 0,
        self.pix, self.width, self.height, 3, 0, 0
    )
    self.pix = pix
    --self.width, self.height = self.height, self.width
end

function Bitmap:makebgr()
    if PLATFORM == '3ds' then
        C.makebgr(self.pix, self.width, self.height, self.channels)
    end
end

function Bitmap:newpixels(way)
    if way == 'horizontal' then
        local pix = ffi.new('uint8_t[?]', ffi.sizeof(self.pix))
        for y=0,self.height-1 do
            for x=0,self.width-1 do
                local newi = self.channels * (y*self.width + x)
                local oldi = self.channels * (y*self.width + self.width - x - 1)
                for off=0,self.channels-1 do
                    pix[newi + off] = self.pix[oldi + off]
                end
            end
        end
        return pix
    else
        error('horiz only supported')
    end
end

function Bitmap:flip(way)
    if way == 'vertical' then
        local row_size = self.channels*self.width
        local row_buffer = ffi.new('uint8_t[?]', row_size)
        local halfway = math.floor(self.height/2)
        for i=0,halfway-1 do
            local row = self.pix + i*row_size
            local opposite_row = self.pix + (self.height - i - 1)*row_size

            ffi.copy(row_buffer, row, row_size)
            ffi.copy(row, opposite_row, row_size)
            ffi.copy(opposite_row, row_buffer, row_size)
        end
    else
        error('"vertical" only supported atm (got '..tostring(way)..')')
    end
end


return Bitmap
