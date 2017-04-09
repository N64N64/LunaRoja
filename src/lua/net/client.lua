local super = Object
Net.Client = Object.new(super)

function Net.Client:new(connfd)
    local self = super.new(self)

    self.connfd = connfd -- optional

    return self
end

function Net.Client:connect(ip, port)
    if self.connfd then
        error('connection already established')
    end
    self.connfd = C.client_start(ip, tostring(port))
end

function Net.Client:is_connected()
    return self.connfd and C.client_is_connected(self.connfd)
end

function Net.Client:close()
    if not self.connfd then return end

    C.closesocket(self.connfd)
    self.connfd = nil
end

local buf = ffi.new('char[512]')
function Net.Client:recv()
    if not self:is_connected() then
        error('not connected')
    end

    local len = C.recv(self.connfd, buf, ffi.sizeof(buf), 0)
    if len == 0 then
        self.connfd = nil
        return false
    elseif len ~= -1 then
        return ffi.string(buf, len)
    end
end

function Net.Client:send(s)
    if not self:is_connected() then
        error('not connected')
    end
    return C.send(self.connfd, s, #s, 0)
end
