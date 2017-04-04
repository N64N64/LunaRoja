-- WIP dialogue reader / printer

local convert_str, update_labels --forward decl

emu:hook(Red.sym.PrintText_NoCreatingTextBox, function()
    local hl = emu.gb.cpu.hl
    local bank = emu.gb.memory.currentBank

    if hl >= 0x8000 then
        -- i have no idea why this is even necessary
        return
    end

    local rom = emu:rom(bank, hl)

    if rom[0] == 0x17 then
        local addr = rom[2] * 0x100 + rom[1]
        local bank = rom[3]
        local rom = emu:rom(bank, addr)
        local str = convert_str(rom + 1)

        update_labels(str)
    end
end)

function convert_str(rom)
    local str = ''
    local i = 0
    while true do
        local x = rom[i]
        if x == 0 or x == 87 then break end

        local conv = Red.CharDecode(x, true)
        if x == 80 and rom[i + 1] == 1 then
            -- apparently 80, then 1 triggers reading from wram??
            local addr = rom[i + 2] + rom[i + 3]*0x100
            str = str..convert_str(emu.wram + addr)
            i = i + 3
        else
            str = str..conv
        end
        i = i + 1
    end
    return str
end


-- Shitty printer

local labels
function update_labels(dialogue)
    labels = {}
    local function doit(s)
        local siz = 45
        if #s > siz then
            doit(string.sub(s, 1, siz))
            doit(string.sub(s, siz+1, #s))
            return
        end

        local label = UI.Label:new(s)
        label:paint()
        table.insert(labels, label)
    end
    for i,s in ipairs(string.split(dialogue, '\n')) do
        doit(s)
    end
end
function SHITTY_DIALOGUE_PRINTER()
    if labels then
        for i,label in ipairs(labels) do
            label:draw(Screen.bottom, 0, emu.height + (i - 1)*label.fontsize)
        end
    end
end
