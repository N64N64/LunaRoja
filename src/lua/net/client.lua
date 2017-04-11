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
    self.remote_ip = ip
    self.remote_port = port
    local connfd = C.client_start(ip, tostring(port))
    if connfd == -1 then
        error('could not connect')
    end
    self.connfd = connfd
end

function Net.Client:is_connected()
    -- PLATFORM == '3ds' prevents 3ds from hanging. TODO fix segfault wherever it is
    return self.connfd and (PLATFORM == '3ds' or not self.remote_ip or C.client_is_connected(self.connfd))
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

function Net.Client:send(s)
    if not self:is_connected() then
        error('not connected')
    end
    return C.send(self.connfd, s, #s, 0)
end
