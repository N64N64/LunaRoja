Gameboy = {}

function Gameboy:new(rompath)
    local self = setmetatable({}, {__index = self})
    local core = ffi.mgba.mCoreFind(rompath)
    local size = ffi.new('unsigned int[2]')
    if core == ffi.NULL then
        error('file not found')
    end

    ffi.mgba.mCoreInitConfig(core, nil)
    ffi.mgba._GBCoreInit(core)
    ffi.mgba._GBCoreDesiredVideoDimensions(core, size+0, size+1)
    local pix = ffi.new('uint8_t[?]', size[0] * size[1] * 4)
    ffi.mgba._GBCoreSetVideoBuffer(core, pix, size[0])
    local file = ffi.mgba.VFileOpen(rompath, 0)
    if file == ffi.NULL then
        error('file is NULL')
    end
    if not ffi.mgba._GBCoreLoadROM(core, file) then
        local maxsize = tonumber(C.romBufferSize)/1024/1024
        error('ROM too big. must be less than '..maxsize..'MB')
    end
    local savepath
    do
        local t = string.split(rompath, '%.')
        t[#t] = nil
        savepath = table.concat(t, '.')..'.sav'
    end
    local savefile = ffi.mgba.VFileOpen(savepath, bit.bor(O_CREAT, O_RDWR))
    if savefile == ffi.NULL then
        error('savefile is NULL')
    end
    ffi.mgba._GBCoreLoadSave(core, savefile)
    ffi.mgba._GBCoreReset(core)

    self.core = core
    self.pix = pix
    self.width, self.height = size[0], size[1]
    self.gb = ffi.cast('struct GB *', self.core.board)
    self.wram = self.gb.memory.wram - 0xc000
    self.romptr = self.gb.memory.rom

    return self
end

local fbsize = ffi.new('uint16_t[2]')
function Gameboy:run()
    if self.halt then
        ffi.mgba._GBCoreClearKeys(self.core, 0xffffffff)
        return
    end

    if not self.ignore_inputs then
        local kdown = Button.KeysDown
        local kup = Button.KeysUp
        local function yee(x, y)
            if Button.isdown(x) then
                kdown = bit.bor(kdown, y)
            end
            if Button.isup(x) then
                kup = bit.bor(kup, y)
            end
        end

        yee(Button.cpad_right, Button.dright)
        yee(Button.cpad_left, Button.dleft)
        yee(Button.cpad_up, Button.dup)
        yee(Button.cpad_down, Button.ddown)

        ffi.mgba._GBCoreAddKeys(self.core, kdown)
        ffi.mgba._GBCoreClearKeys(self.core, kup)
    else
        ffi.mgba._GBCoreClearKeys(self.core, 0xffffffff)
    end

    ffi.mgba._GBCoreRunFrame(self.core)
end

function Gameboy:render(scr, x, y)
    if not scr then
        scr = Screen.top
        x = (Screen.top.width - emu.width)/2 + 8
        y = (Screen.top.height - emu.height)/2
    end
    ffi.luared.mgbacopy(
        scr.pix, scr.height, scr.width, x, y,
        self.pix, self.width, self.height, 0, 0
    )
end

function Gameboy:rom(bank, addr)
    assert(addr < 0x8000)
    return self.romptr + bit.band(addr, 0x4000 - 1) + bank * 0x4000
end

function Gameboy:resetrom()
    if not self.romcache then
        self.romcache = {}
    end

    for bank=0,0x7f do
        if self.romcache[bank] then
            for addr, val in pairs(self.romcache[bank]) do
                self:rom(bank, addr)[0] = val
            end
        end
        self.romcache[bank] = {}
    end
end

function Gameboy:patcher(sym)
    local t = {}
    setmetatable(t, {
        __index = function(t, k)
            return self:rom(sym.bank, sym.addr)[k]
        end,
        __newindex = function(t, k ,v)
            self:setrom(sym.bank, sym.addr + k, v)
        end,
        __add = function(a, b)
            local x
            if a == t then
                x = b
            else
                x = a
            end
            return self:patcher({bank = sym.bank, addr = sym.addr + x})
        end,
    })
    return t
end

function Gameboy:hook(sym, f)
    PC_HOOK(sym.bank, sym.addr, function()
        local success, result
        if sym.addr < 0x4000 or self.gb.memory.currentBank == sym.bank then
            if PLATFORM == '3ds' then
                success, result = xpcall(f, debug.traceback)
                if not success then
                    ERROR = result
                    SHOULD_QUIT = true
                end
            else
                result = f()
            end
        end
        if result then
            return true
        else
            return false
        end
    end)
end

function Gameboy:setrom(bank, addr, v)
    local rom = self:rom(bank, addr)

    if not self.romcache then
        self.romcache = {}
    end
    if not self.romcache[bank] then
        self.romcache[bank] = {}
    end

    if not self.romcache[bank][addr] then
        self.romcache[bank][addr] = rom[0]
    end
    rom[0] = v
end

Gameboy.InstructionSizes = {
    1, 3, 1, 1, 1, 1, 2, 1, 3, 1, 1, 1, 1, 1, 2, 1,
    2, 3, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1,
    2, 3, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1,
    2, 3, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 3, 3, 3, 1, 2, 1, 1, 1, 3, 1, 3, 3, 2, 1,
    1, 1, 3, 0, 3, 1, 2, 1, 1, 1, 3, 0, 3, 0, 2, 1,
    2, 1, 2, 0, 0, 1, 2, 1, 2, 1, 3, 0, 0, 0, 2, 1,
    2, 1, 2, 1, 0, 1, 2, 1, 2, 1, 3, 1, 0, 0, 2, 1,
}
-- convert from 1-based indexing to 0-based indexing
for i=1,#Gameboy.InstructionSizes do
    Gameboy.InstructionSizes[i - 1] = Gameboy.InstructionSizes[i]
end

function Gameboy.InstructionOffset(ptr, count, total)
    total = total or 0
    if count == 0 then
        return total
    elseif count > 0 then
        local off = Gameboy.InstructionSizes[tonumber(ptr[total])]
        if not off or off == 0 then
            error('invalid instruction')
        end
        return Gameboy.InstructionOffset(ptr, count - 1, total + off)
    else
        error('not yet implemented')
    end
end

return Gameboy
