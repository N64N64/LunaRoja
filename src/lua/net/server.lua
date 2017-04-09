local super = Object
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
    local listenfd = C.server_start(self.port)
    if listenfd ~= -1 then
        self.listenfd = listenfd
    end
end

function Net.Server:disconnect()
    C.closesocket(self.s.connfd)
    self.s.connfd = -1
    self.disconnected = true
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

    if #self.connfds == 0 then
        local connfd = C.server_listen(self.listenfd)
        if connfd >= 0 then
            print('got connection')
            table.insert(self.connfds, connfd)
        end
    elseif not self.disconnected then
        local i = 0
        while i < #self.connfds do
            i = i + 1
            local connfd = self.connfds[i]
            local len = C.recv(connfd, buf, ffi.sizeof(buf), 0)
            if len == 0 then
                table.remove(self.connfds, i)
                i = i - 1
            elseif len ~= -1 then
                local s = tostring(runcode(ffi.string(buf, len)))
                C.send(connfd, s..'\n', #s + 1, 0)
            end
        end
    end
end

return Net.Server
