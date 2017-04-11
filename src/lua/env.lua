Env = {}

-- environments for running untrusted Lua code

function Env.Empty()
    return {}
end

function Env.Basic()
    return table.copy{
        table = table,
        next = next,
        pairs = pairs,
        print = print,
        select = select,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack,
        string = string,
        math = math,
        os = {
            date = os.date,
            clock = os.clock,
            difftime = os.difftime,
            time = os.time,
        }
    }
end
return Env
