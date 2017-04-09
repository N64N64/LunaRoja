local super = require 'net.base'
Net.Server = Object.new(super)

function Net.Server:new(port)
    local self = super.new(self)

    self.connfds = {}
    self.port = port

    local hostname = ffi.new('char[200]')
    C.gethostname(hostname, ffi.sizeof(hostname))
    self.hostname = ffi.string(hostname)

    return self
end

function Net.Server:start()
    if self.listenfd then
        error('server already started')
    end

    local listenfd = C.server_start(self.port)
    if listenfd ~= -1 then
        self.listenfd = listenfd
    else
        error('couldnt start server')
    end
end

function Net.Server:stop()
    for _,connfd in ipairs(self.connfds) do
        C.closesocket(connfd)
    end
    self.connfds = {}
    if self.listenfd then
        C.closesocket(self.listenfd)
        self.listenfd = nil
    end
end

local function runcode(s)
    local f, err = load(s)
    if not f then
        return 'err: '..err
    end
    local success, result = pcall(f)
    if not success then
        return 'err: '..result
    end
    return result
end

local buf = ffi.new('char[512]')
function Net.Server:run()
    if not self.listenfd then error('not listening') end

    -- get new connections
    local connfd = C.server_listen(self.listenfd)
    if connfd >= 0 then
        print('got connection')
        table.insert(self.connfds, connfd)
    end

    -- listen on existing connections
    local i = 0
    while i < #self.connfds do
        i = i + 1
        local connfd = self.connfds[i]
        local data = self:recv(connfd)
        if data == false then
            -- disconnected
            print('disconnected')
            table.remove(self.connfds, i)
            i = i - 1
        elseif data then
            print('got some shit')
            local s = tostring(runcode(data))
            self:send(connfd, s)
            print(s)
        end
    end
end

return Net.Server
