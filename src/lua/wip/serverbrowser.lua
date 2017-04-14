local path = LUAPATH..'/config/servers.lua'

local input = ''
local ip = UI.Label:new('IP: ')
ip.font = Font.MonoSpace
ip:paint()

local cancel = UI.Label:new('Press B to cancel')
cancel:paint()

local options = {}
local saved_ips = {}

local function closure(v)
    return function()
        startclient(v)
        DEBUG_TEXT = 'Connected to '..v
    end
end

ServerBrowser = {}
function ServerBrowser:render()
    if Button.isdown(Button.b) then
        DISPLAY(Game, DebugMenu)
    end
    cancel:draw(Screen.top, 0, 0)
    ip:draw(Screen.top, (Screen.top.width - ip.width)/2, (Screen.top.height - ip.height)/2)
    Keyboard:render()
end
function ServerBrowser.key(key)
    if key == '\n' then
        table.insert(options, closure(input))
        startclient(input)
        DEBUG_TEXT = 'Connected to '..input
        DISPLAY(Game, DebugMenu)
        local found = false
        for i,v in ipairs(saved_ips) do
            if v == input then
                found = true
                break
            end
        end
        if not found then
            table.insert(saved_ips, input)
            local f = io.open(path, 'w')
            f:write('return {\n')
            for i,v in pairs(saved_ips) do
                f:write('    "'..v..'",\n')
            end
            f:write('}\n')
            f:close()
        end
    else
        if key == '\b' then
            input = string.sub(input, 1, #input - 1)
        elseif #key == 1 then
            input = input..key
        end
        ip.text = 'IP: '..input
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
    ip.text = 'IP: '
    ip:paint()
    DISPLAY(ServerBrowser)
end

ROOT['connect to server'] = options
