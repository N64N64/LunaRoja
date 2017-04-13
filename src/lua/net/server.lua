local super = Object
Net.Server = Object.new(super)

function Net.Server:new(port)
    local self = super.new(self)

    self.clients = {}
    self.port = port

    local hostname = ffi.new('char[200]')
    C.gethostname(hostname, ffi.sizeof(hostname))
    self.hostname = ffi.string(hostname)

    return self
end

function Net.Server:listen()
    if self.fd then
        error('server already started')
    end

    local fd = C.server_start(self.port)
    if fd ~= -1 then
        self.fd = fd
    else
        error('couldnt start server')
    end
end

function Net.Server:close()
    for i=1,#self.clients do
        self.clients[i]:close()
        self.clients[i] = nil
    end
    if self.fd then
        C.closesocket(self.fd)
        self.fd = nil
    end
end

local function runcode(s)
    local f, err = load(s) -- TODO sandbox this
    if not f then
        return 'err: '..err
    end
    local success, result = pcall(f)
    if not success then
        return 'err: '..result
    end
    return result
end

function Net.Server.onnewclient()
end

local buf = ffi.new('char[512]')
function Net.Server:run()
    if not self.fd then error('not listening') end

    -- get new connections
    local fd = C.server_listen(self.fd)
    if fd >= 0 then
        print('got new client')
        local client = Net.Client:new(fd)
        table.insert(self.clients, client)
        self:onnewclient(client)
    end

    -- listen on existing connections
    local i = 0
    while i < #self.clients do
        i = i + 1
        local client = self.clients[i]
        if client:recv() == false then
            -- disconnected
            print('disconnected')
            table.remove(self.clients, i)
            i = i - 1
        end
    end
end

function Net.Server:send(...)
    for _,client in ipairs(self.clients) do
        client:send(...)
    end
end

return Net.Server
