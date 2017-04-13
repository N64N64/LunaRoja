local super = Object
Net.Client = Object.new(super)

function Net.Client:new(fd)
    local self = super.new(self)

    self.fd = fd -- optional

    return self
end

function Net.Client:connect(ip, port)
    if self.fd then
        error('connection already established')
    end
    self.remote_ip = ip
    self.remote_port = port
    local fd = C.client_start(ip, tostring(port))
    if fd == -1 then
        error('could not connect: '..ffi.string(C.lr_net_error))
    end
    self.fd = fd
end

function Net.Client:is_connected()
    return self.fd and (PLATFORM == '3ds' or not self.remote_ip or C.client_is_connected(self.fd))
end

function Net.Client:close()
    if not self.fd then return end

    C.closesocket(self.fd)
    self.fd = nil
end

local buf = ffi.new('char[512]')
function Net.Client:recv()
    if not self:is_connected() then
        error('not connected')
    end

    local len = C.recv(self.fd, buf, ffi.sizeof(buf), 0)
    if len == 0 then
        self.fd = nil
        return false
    elseif len ~= -1 then
        local data = ffi.string(buf, len)
        self.backlog = self.backlog or {}
        if self.partialdata then
            data = self.partialdata..data
            self.partialdata = nil
        end
        local parsedlen = 0
        for line in string.gmatch(data, "([^\n]*)\n") do
            parsedlen = #line + 1
            table.insert(self.backlog, line)
        end
        if not(parsedlen == #data) then
            self.partialdata = string.sub(data, parsedlen + 1, #data)
        end
        return true
    end
end

function Net.Client:send(data)
    if not self:is_connected() then
        error('not connected')
    end

    if type(data) == 'string' then
        return C.send(self.fd, data, #data, 0)
    elseif type(data) == 'cdata' then
        return C.send(self.fd, data, ffi.sizeof(data), 0)
    elseif type(data) == 'table' then
        return self:send(data:serialize())
    else
        error('unsupportred type '..type(data))
    end
end
