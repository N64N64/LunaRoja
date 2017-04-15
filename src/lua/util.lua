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

-- garbage collector metamethod hax
function SETGC(t, f)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    mt.__gc = f
    mt.__index = t
    mt.__newindex = t
    return proxy
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

function populate(dest, src, attrs)
    for _,v in ipairs(attrs) do
        dest[v] = src[v]
    end
end

local function sugar(t)
    if type(t) == 'table' then
        if t.__class then
            local class = _G[t.__class]
            return class.Decode(t)
        else
            for k,v in pairs(t) do
                t[k] = sugar(v)
            end
        end
    end
    return t
end

local gsub = string.gsub

function decode(s, raw)
    s = string.gsub(s, '\\NEWLINE', '\n') -- TODO figure out something better
    s = string.gsub(s, '\\\\', '\\')
    local f = setfenv(load(s), Env.Empty())
    if raw then
        return f()
    else
        return sugar(f())
    end
end

local function strescape(s)
    s = string.gsub(s, '"', '\\"')
    s = string.gsub(s, '\n', '\\n')
    return s
end

function serialize(t, indent)
    if type(t) == 'string' then
        return '"'..strescape(t)..'"'
    elseif t == nil or type(t) == 'number' or type(t) == 'boolean' then
        return tostring(t)
    elseif type(t) == 'table' then
        if t.serialize then
            return t:serialize()
        else
            local s = {}
            for k,v in pairs(t) do
                s[#s + 1] = '['..serialize(k)..'] = '..serialize(v)
            end
            return '{'..table.concat(s, ',')..'}'
        end
    else
        error('unsupported type '..type(t))
    end
end

function encode(t, raw)
    local pre = serialize(t)
    local s = 'return '..pre
    if raw then return s end
    s = string.dump(load(s), true)
    s = string.gsub(s, '\\', '\\\\')
    s = string.gsub(s, '\n', '\\NEWLINE') -- TODO figure out something better
    return s
end
