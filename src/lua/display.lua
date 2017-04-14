DISPLAY = {}

local current
local function swap(new)
    current = new

    for k,v in pairs(DISPLAY) do
        DISPLAY[k] = nil
    end
end
local function call(_, ...)
    if not ... then return current[1] end

    swap{...}
    Keyboard.callbacks.display = function(...)
        for _,v in ipairs(current) do
            v.key(...)
        end
    end

end

local function map(t, k)
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
local function index(t, k)
    if type(k) == 'number' then
        return current[k]
    else
        return map(t, k)
    end
end

local function newindex(t, k, v)
    if type(k) == 'number' then
        current[k] = v
        swap(current)
    else
        error('not allowed')
    end
end

return setmetatable(DISPLAY, {
    __call = call,
    __index = index,
    __newindex = newindex,
})
