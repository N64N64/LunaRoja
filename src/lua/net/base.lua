local super = Object
local base = Object.new(super)

local buf = ffi.new('char[512]')
function base:recv(connfd)
    assert(connfd)
    local len = C.recv(connfd, buf, ffi.sizeof(buf), 0)
    if len == 0 then
        return false
    elseif len ~= -1 then
        return ffi.string(buf, len)
    end
end

function base:send(connfd, s)
    assert(connfd)
    C.send(connfd, s, #s, 0)
end

return base
