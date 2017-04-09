local super = Object
Net.Server = Object.new(super)

function Net.Server:new(port)
    local self = super.new(self)

    self.s = ffi.new('struct lr_server')
    self.s.listenfd = -1
    self.s.connfd = -1
    self.s.port = 27716

    local hostname = ffi.new('char[200]')
    C.gethostname(hostname, ffi.sizeof(hostname))
    self.hostname = ffi.string(hostname)

    return self
end

function Net.Server:disconnect()
    C.closesocket(self.s.connfd)
    self.s.connfd = -1
    self.disconnected = true
end

local buf = ffi.new('char[512]')
function Net.Server:run()
    if self.s.connfd == -1 then
        C.server_start(self.s)
        print('get')
    elseif not self.disconnected then
        C.recv(self.s.connfd, buf, ffi.sizeof(buf), 0)
        local len = 0
        for i=0,ffi.sizeof(buf)-1 do
            if buf[i] == string.byte('\n') then
                len = i
                break
            end
        end
        local f, err = load(ffi.string(buf, len))
        if f then
            local success, result = pcall(f)
            if not success then
                result = 'err: '..result
            end
            print(result)
        else
            print('lerr: '..err)
        end
    end

    print(self.hostname..':'..self.s.port)
    print('  connfd: '..self.s.connfd)
    print('listenfd: '..self.s.listenfd)
end

return Net.Server
