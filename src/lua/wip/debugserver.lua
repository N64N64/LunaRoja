local debugserver = {}

local buf
local connfd = -1
local hostname = ffi.new('char[200]')
C.gethostname(hostname, ffi.sizeof(hostname))
hostname = ffi.string(hostname)
local port = 27716

function disconnect()
    C.closesocket(connfd)
    connfd = -1
    buf = nil
end

function debugserver:run()
    if connfd == -1 then
        buf = ffi.new('char[512]')
        connfd = C.server_getconnection(port)
        write('get', 0, 21)
    elseif buf then
        C.recv(connfd, buf, ffi.sizeof(buf), 0)
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
            write(tostring(result), 0, 24)
        else
            write('lerr: '..err, 0, 24)
        end
    end

    write(hostname..':'..port, 0, 20)
    write('  connfd: '..connfd, 0, 22)
    write('listenfd: '..C._listenfd, 0, 23)
end

return debugserver
