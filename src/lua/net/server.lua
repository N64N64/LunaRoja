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

function Net.Server:close()
    for _,client in ipairs(self.clients) do
        client:close()
    end
    self.clients = {}
    if self.listenfd then
        C.closesocket(self.listenfd)
        self.listenfd = nil
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

local buf = ffi.new('char[512]')
function Net.Server:run()
    if not self.listenfd then error('not listening') end

    -- get new connections
    local connfd = C.server_listen(self.listenfd)
    if connfd >= 0 then
        print('got connection')
        table.insert(self.clients, Net.Client:new(connfd))
    end

    -- listen on existing connections
    local i = 0
    while i < #self.clients do
        i = i + 1
        local client = self.clients[i]
        local data = client:recv()
        if data == false then
            -- disconnected
            print('disconnected')
            table.remove(self.clients, i)
            i = i - 1
        elseif data then
            client.backlog = client.backlog or {}
            table.insert(client.backlog, data)
        end
    end
end

return Net.Server
