local line = 0
function console(...)
    local t = {}
    for i,v in ipairs({...}) do
        t[i] = tostring(v)
    end
    io.write('\x1b[0'..line..';00H'..table.concat(t, ', '))
    line = line + 1
    if line > 9 then
        line = 0
    end
end

function write(str, x, y)
    x = x or 0
    y = y or 0
    io.write(string.format('\x1b[%.2d;%.2dH%s', y, x, str))
end

function print(s)
    s = tostring(s)
    return C.svcOutputDebugString(s, #s)
end
