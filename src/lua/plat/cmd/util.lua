function ls(dir)
    local i = 0
    local t = {}
    local f = io.popen('ls '..dir)
    for filename in f:lines() do
        i = i + 1
        t[i] = filename
    end
    f:close()
    return t
end
