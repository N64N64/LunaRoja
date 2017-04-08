local super = Object
Rom = Object.new(super)

function Rom:new(path, romptr)
    local self = super.new(self)

    self.path = path

    if not romptr then
        self.path = path
        local f = C.fopen(self.path, 'rb')
        if f == ffi.NULL then
            error('file '..self.path..' not found')
        end
        C.fseek(f, 0, SEEK_END)
        local siz = C.ftell(f)
        C.fseek(f, 0, SEEK_SET) -- same as rewind(f)
        romptr = ffi.new('uint8_t[?]', siz)
        C.fread(romptr, siz, 1, f)
        C.fclose(f)
    end

    self.romptr = romptr

    -- parse symfile
    local t = string.split(self.path, '%.')
    t[#t] = nil
    local sympath = table.concat(t, '.')..'.sym'
    local f = io.open(sympath)
    if not f then
        error('You must place your symfile in '..sympath)
    end
    self.sym = {}
    for line in f:lines() do
        local bank, addr, name = string.match(line, '(%w%w)%:(%w%w%w%w) (.+)')
        if bank and addr and name then
            bank = tonumber(bank, 16)
            addr = tonumber(addr, 16)
            local t = {bank = bank, addr = addr, name = name}
            self.sym[name] = t
            self.sym[bank*0x10000 + addr] = t
        end
    end
    f:close()

    -- rom metatable
    self.rom = setmetatable({}, {
        __index = function(t, k)
            local sym = self.sym[k]
            return sym and self:lookup(sym.bank, sym.addr)
        end,
        __newindex = function()
            error('not allowed')
        end,
    })

    return self
end

function Rom:lookup(bank, addr)
    assert(addr < 0x8000)
    return self.romptr + bit.band(addr, 0x4000 - 1) + bank * 0x4000
end

return Rom
