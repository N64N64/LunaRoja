local path = LUAPATH..'/config/servers.lua'

local ip = UI.Label:new('')
ip.font = Font.MonoSpace
ip:paint()

local options = {}
local saved_ips = {}

local function closure(v)
    return function()
        startclient(v)
        DEBUG_TEXT = 'Connected to '..v
    end
end

Mode.addserver = {}
Mode.addserver.rendercallback = function()
    ip:draw(Screen.top, (Screen.top.width - ip.width)/2, (Screen.top.height - ip.height)/2)
    Keyboard:render()
end
Mode.addserver.keycallback = function(key)
    if key == '\n' then
        table.insert(options, closure(ip.text))
        startclient(ip.text)
        DEBUG_TEXT = 'Connected to '..ip.text
        Mode:changeto('game')
        local found = false
        for i,v in ipairs(saved_ips) do
            if v == ip.text then
                found = true
                break
            end
        end
        if not found then
            table.insert(saved_ips, ip.text)
            local f = io.open(path, 'w')
            f:write('return {\n')
            for i,v in pairs(saved_ips) do
                f:write('    "'..v..'",\n')
            end
            f:write('}\n')
            f:close()
        end
    elseif key == '\b' then
        ip.text = string.sub(ip.text, 1, #ip.text - 1)
        ip:paint()
    elseif #key == 1 then
        ip.text = ip.text..key
        ip:paint()
    end
end

local f = io.open(path, 'r')
if f then
    f:close()
    saved_ips = dofile(path)
    for k,v in pairs(saved_ips) do
        options[v] = closure(v)
    end
end


options['add new'] = function()
    ip.text = ''
    ip:paint()
    Mode:changeto('addserver')
end

ROOT['connect to server'] = options
