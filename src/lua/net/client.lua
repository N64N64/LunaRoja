local super = require 'net.base'
Net.Client = Object.new(super)

function Net.Client:new(ip, port)
    local self = super.new(self)

    self.ip = ip
    self.port = port

    return self
end

function Net.Client:start()
    self.connfd = C.client_start(self.ip, tostring(self.port))
end

function Net.Client:run()
    if not self.connfd then return end
    self.connected = C.client_is_connected(self.connfd)
    if not self.connected then return end

    local data = self:recv(self.connfd)
    if data == false then
        -- disconnected
        self.connfd = nil
    elseif data then
        print(tostring(data))
    end
end

function Net.Client:recv()
    if not self.connected or not self.connfd then
        error('not connected')
    end
    return super.recv(self, self.connfd)
end

function Net.Client:send(s)
    if not self.connected or not self.connfd then
        error('not connected')
    end
    return super.send(self, self.connfd, s)
end
