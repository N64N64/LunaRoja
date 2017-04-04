local t = {}
t.OakSpeechText1 = 'o hai there. welcome to pokemon. im oak'

local hash = {}
for k,v in pairs(t) do
    local sym = Red.sym[k]
    hash[sym.bank * 0x10000 + sym.addr] = v
end

function Red.GetTranslation(bank, addr)
    return hash[bank * 0x10000 + addr]
end
