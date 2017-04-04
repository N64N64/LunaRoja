-- translated from pokered/extras/pokemontools/pic.py

local function bitflip(x, n)
    local r = 0
    while n > 0 do
        r = bit.bor(bit.lshift(r, 1), bit.band(x, 1))
        x = bit.rshift(x, 1)
        n = n - 1
    end
    return r
end

local table1 = {}
for i=0,16-1 do
    table1[i] = bit.lshift(2, i) - 1
end
local table2 = {
    [0] = {0x0, 0x1, 0x3, 0x2, 0x7, 0x6, 0x4, 0x5, 0xf, 0xe, 0xc, 0xd, 0x8, 0x9, 0xb, 0xa},
    [1] = {0xf, 0xe, 0xc, 0xd, 0x8, 0x9, 0xb, 0xa, 0x0, 0x1, 0x3, 0x2, 0x7, 0x6, 0x4, 0x5}, -- prev ^ 0xf
    [2] = {0x0, 0x8, 0xc, 0x4, 0xe, 0x6, 0x2, 0xa, 0xf, 0x7, 0x3, 0xb, 0x1, 0x9, 0xd, 0x5},
    [3] = {0xf, 0x7, 0x3, 0xb, 0x1, 0x9, 0xd, 0x5, 0x0, 0x8, 0xc, 0x4, 0xe, 0x6, 0x2, 0xa}, -- prev ^ 0xf
}
for row=0,3 do
    for i=1,#table2[row] do
        table2[row][i-1] = table2[row][i]
        table2[row][i] = nil
    end
end
local table3 = {}
for i=0,16-1 do
    table3[i] = bitflip(i, 4)
end

Red.Pic = {}

function Red.Pic:new(arg1, mirror, planar)
    local self = setmetatable({}, {__index=self})
    if type(arg1) == 'string' then
        local f = io.open(arg1, 'r')
        local s = f:read('*all')
        self.rom = ffi.new('uint8_t[?]', #s, s)
        f:close()
    elseif type(arg1) == 'cdata' then
        self.rom = arg1
    end
    self.byteoff = 0
    self.bitoff = 0
    self.mirror = mirror
    if not(planar == nil) then
        self.planar = planar
    else
        self.planar = true
    end
    return self
end

local function decompress(self)
    local rams = {
        [0] = {},
        [1] = {},
    }
    self.width = self:readint(4) * Red.Tilesize
    self.height = self:readint(4)

    self.size = self.width * self.height

    local ramorder = self:readbit()

    local r1 = ramorder
    local r2 = bit.bxor(ramorder, 1)
    self:fillram(rams[r1])
    local mode = self:readbit()
    if mode ~= 0 then
        mode = mode + self:readbit()
    end
    self:fillram(rams[r2])

    rams[0] = self:bitgroups_to_bytes(rams[0])
    rams[1] = self:bitgroups_to_bytes(rams[1])

    if mode == 0 then
        self:decode(rams[0])
        self:decode(rams[1])
    elseif mode == 1 then
        self:decode(rams[r1])
        self:xor(rams[r1], rams[r2])
    elseif mode == 2 then
        self:decode(rams[r2], false) --mirror = false
        self:decode(rams[r1])
        self:xor(rams[r1], rams[r2])
    else
        error('invalid deinterlace mode')
    end

    local data = ffi.new('uint8_t[?]', #rams[0]*2)
    if self.planar then
        for i=1,#rams[0] do
            data[2*(i-1) + 0] = rams[0][i]
            data[2*(i-1) + 1] = rams[1][i]
        end
    else
        error('not yet implemented')
    end
    return data
end

function Red.Pic:decompress()
    local data = decompress(self)
    collectgarbage()
    self.height = self.height * Red.Tilesize
    return data
end

function Red.Pic:fillram(ram)
    local mode = self:readbit() == 0 and 'rle' or 'data'
    local size = self.size * 4
    while #ram < size do
        if mode == 'rle' then
            self:read_rle_chunk(ram)
            mode = 'data'
        elseif mode == 'data' then
            self:read_data_chunk(ram, size)
            mode = 'rle'
        end
    end
    if #ram > size then
        error('fuckd up: '..size..', '..(#ram))
    end
    local deinterlaced = self:deinterlace_bitgroups(ram)
    for i=1,#ram do
        ram[i] = nil
    end
    for i,v in ipairs(deinterlaced) do
        table.insert(ram, v)
    end
end

function Red.Pic:read_rle_chunk(ram)
    local i = 0
    while self:readbit() ~= 0 do
        i = i + 1
    end
    local n = table1[i]
    local a = self:readint(i + 1)
    n = n + a
    for i=1,n do
        table.insert(ram, 0)
    end
end

function Red.Pic:read_data_chunk(ram, size)
    while true do
        local bitgroup = self:readint(2)
        if bitgroup == 0 then
            break
        end
        table.insert(ram, bitgroup)
        if size <= #ram then
            break
        end
    end
end

function Red.Pic:decode(ram, mirror)
    if mirror == nil then
        mirror = self.mirror
    end

    for x=0,self.width-1 do
        local z = 0
        for y=0,self.height-1 do
            local i = y*self.width + x
            local v = ram[i+1]
            local a = bit.band(bit.rshift(v, 4), 0xf)
            local b = bit.band(v, 0xf)

            a = table2[z][a]
            z = bit.band(a, 1)
            if mirror then
                a = table3[a]
            end
            b = table2[z][b]
            z = bit.band(b, 1)
            if mirror then
                b = table3[b]
            end
            ram[i+1] = bit.bor(bit.lshift(a, 4), b)
        end
    end
end

function Red.Pic:xor(ram1, ram2, mirror)
    if mirror == nil then
        mirror = self.mirror
    end

    for i,v in ipairs(ram2) do
        if mirror then
            local a = bit.band(bit.rshift(v, 4), 0xf)
            local b = bit.band(v, 0xf)
            a = table3[a]
            b = table3[b]
            ram2[i] = bit.bor(bit.lshift(a, 4), b)
        end
        ram2[i] = bit.bxor(ram2[i], ram1[i])
    end
end

function Red.Pic:deinterlace_bitgroups(bits)
    local l = {}
    for y=0,self.height-1 do
        for x=0,self.width-1 do
            local i = 4*y*self.width + x
            for j=1,4 do
                table.insert(l, bits[i+1])
                i = i + self.width
            end
        end
    end
    return l
end

function Red.Pic:readint(count)
    local n = 0
    while count > 0 do
        n = bit.lshift(n, 1)
        n = bit.bor(n, self:readbit())
        count = count - 1
    end
    return n
end

function Red.Pic:readbit()
    local c = self.rom[self.byteoff]
    local result = bit.band(1, bit.rshift(c, 8 - self.bitoff - 1))
    self.bitoff = self.bitoff + 1
    if self.bitoff == 8 then
        self.byteoff = self.byteoff + 1
        self.bitoff = 0
    end
    return result
end

function Red.Pic:bitgroups_to_bytes(bits)
    local l = {}
    for i=0,#bits - 3-1,4 do
        i = i + 1
        local n = bit.bor(
            bit.lshift(bits[i+0], 6),
            bit.lshift(bits[i+1], 4),
            bit.lshift(bits[i+2], 2),
            bit.lshift(bits[i+3], 0)
        )
        table.insert(l, n)
    end
    return l
end

return Red.Pic
