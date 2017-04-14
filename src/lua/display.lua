DISPLAY = {}

local current
local function swap(new)
    current = new

    for k,v in pairs(DISPLAY) do
        DISPLAY[k] = nil
    end
end
local function call(_, t, ...)
    if not t then return current end
    if not ... then
        swap(t)
        Keyboard.callbacks.display = current.key or function() end
        return
    end

    swap{t, ...}
    Keyboard.callbacks.display = function()
        for _,v in ipairs(current) do
            v()
        end
    end

end

local function map(t, k)
    if not current[1] then
        return current[k]
    end
    local result
    local typ = type(current[1][k])
    if typ == 'function' then
        result = function()
            for _,v in ipairs(current) do
                local f = v[k]
                if f then
                    f(v)
                end
            end
        end
    else
        error('nyi')
    end
    rawset(DISPLAY, k, result)
    return result
end


return setmetatable(DISPLAY, {
    __call = call,
    __index = function(t, k)
        if type(k) == 'number' then
            return current[k]
        else
            return map(t, k)
        end
    end,
    __newindex = function(t, k, v)
        if type(k) == 'number' then
            current[k] = v
            swap(current)
        else
            error('not allowed')
        end
    end,
})
