local f
function log(s)
    f = f or io.open(PATH..'/log.txt', 'a')
    f:write(tostring(s))
    f:write('\n')
    f:flush()
end

function HOOK(tbl, fname, f)
    local oldf = tbl[fname] or function() end
    tbl[fname] = function(...)
        f(...)
    end
    return oldf
end

function io.readbin(path)
    local f = C.fopen(path, 'rb')
    if f == ffi.NULL then
        error('file '..path..' not found')
    end
    ffi.luared.fseek_wrapper(f, 0, SEEK_END)
    local siz = C.ftell(f)
    ffi.luared.fseek_wrapper(f, 0, SEEK_SET) -- same as rewind(f)
    local result = ffi.new('uint8_t[?]', siz)
    C.fread(result, siz, 1, f)
    C.fclose(f)
    return result
end

function table.copy(t, level, trust)
    if level == 0 then
        if trust then
            return t
        else
            return nil
        end
    end
    level = level or -1
    local r = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = table.copy(v, level - 1)
        end
        r[k] = v
    end
    return r
end

function ls(path)
    dir = C.opendir(path)
    if dir == ffi.NULL then return end
    local i = 0
    local t = {}
    local ent = ffi.C.readdir(dir)
    while not(ent == ffi.NULL) do
        local name = ffi.string(ent.d_name)
        if not(name == '.' or name == '..') then
            i = i + 1
            t[i] = ffi.string(ent.d_name)
        end
        ent = ffi.C.readdir(dir)
    end
    C.closedir(dir)
    return t
end

function lognl()
    log('\n')
end

function string.has_suffix(str, suffix)
    local sub = string.sub(str, #str - #suffix + 1, #str)
    return sub == suffix
end

function string.has_prefix(str, prefix)
    local sub = string.sub(str, 1, #prefix)
    return sub == prefix
end

function string.split(inputstr, sep)
    local t = {}
    local i = 1
    local idx = 0
    for str in string.gmatch(inputstr, "(.-)("..sep..")") do
        t[i] = str
        idx = idx + #str + 1
        i = i + 1
    end
    t[i] = string.sub(inputstr, idx + 1, #inputstr)
    return t
end

function serialize(f, t, lvl)
    lvl = lvl or 0
    f:write('{\n')
    local is_numbers = true
    local i = 0
    for k,v in pairs(t) do
        i = i + 1
        if not(i == k) then
            is_numbers = false
            break
        end
    end

    for k, v in pairs(t) do
        for i=0,lvl do
            f:write('    ')
        end
        if not is_numbers then
            if type(k) == 'number' then
                f:write('['..k..']')
            else
                f:write(k)
            end
            f:write(' = ')
        end
        local type = type(v)
        if type == 'table' then
            serialize(f, v, lvl + 1)
        elseif type == 'number' or type == 'boolean' or type == 'nil' then
            f:write(tostring(v))
        elseif type == 'string' then
            f:write('[['..v..']]')
        else
            error(type..' is invalid type')
        end
        f:write(',\n')
    end

    for i=0,lvl-1 do
        f:write('    ')
    end

    f:write('}')

    if lvl == 0 then
        f:write('\n')
    end
end

