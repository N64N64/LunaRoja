function Red.GetString(rom, index, delim, strlen)
    strlen = strlen or math.huge
    index = index or 0
    delim = delim or 80

    local str = ''
    local idx = 0
    for i=0,math.huge do
        if idx == index then
            rom = rom + i
            break
        end
        if rom[i] == delim then
            idx = idx + 1
        end
    end
    for i=0,strlen-1 do
        if rom[i] == delim then break end
        str = str..Red.CharDecode(rom[i], true)
    end
    return str
end

Red.CharOffset = 128 - string.byte('A')
local decode = {}
decode[79] = ' '
decode[81] = '\n'
decode[82] = 'RED'
decode[83] = 'BLUE'
decode[84] = 'POKe'
decode[85] = ' '
decode[127] = ' '
decode[156] = ':'
decode[186] = 'e'
decode[188] = '\'l'
decode[189] = '\'s'
decode[190] = '\'t'
decode[227] = '-'
decode[228] = '\'r'
decode[229] = '\'m'
decode[230] = '?'
decode[231] = '!'
decode[232] = '.'
decode[240] = '$'
decode[244] = ','
local A = string.byte('A')
local a = string.byte('a')
local Z = string.byte('Z')
local z = string.byte('z')
function Red.CharDecode(lol, use_fallback)
    local c = lol - Red.CharOffset
    local i = lol - 246
    if c >= A and c <= Z or c >= a and c <= z then
        return string.char(c)
    elseif i >= 0 and i <= 9 then
        return tostring(i)
    else
        return decode[lol] or (use_fallback and '['..lol..']')
    end
end
