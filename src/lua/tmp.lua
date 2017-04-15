local last_client_count
local function getpos()
    local update = {}
    update[1] = PLAYER:update() and PLAYER or false
    local should_send = not(last_client_count == #server.clients and update[1] == false)
    for i,client in ipairs(server.clients) do
        update[i + 1] = false

        if client.backlog then
            local s = client.backlog[#client.backlog]
            local player = decode(s)
            if player then
                print('got: '..serialize(player))
                client.player = player
                update[i + 1] = player
                should_send = true
            end
            client.backlog = nil
        end
    end
    if should_send then
        server:send(encode(update)..'\n')
    end
    last_client_count = #server.clients
end

PLAYER = Player:new()

local orig, peers
local function hook(...)
    orig(...)
    local _, scr, map, mapx, mapy, xplayer, yplayer = ...
    for _,player in pairs(Player.Peers) do
        if player.map == map then
            if client and client.id == player.id then
            else
                local x = player.x*16
                local y = player.y*16
                local bmap = getspritefromrom(Red.wram.wSpriteStateData1[0].PictureID)
                Red:render_sprite(bmap, x + player.diffx, y + player.diffy, xplayer, yplayer, player.dir, player.anim)
            end
        end
    end
end

function startserver()
    if orig then error('already running') end
    print('starting server')
    PLAYER.id = -1
    server = Net.Server:new(27716)
    server:listen()
    local id = 0
    function server:onnewclient(client)
        client.id = id
        client:send(id..'\n')
        id = id + 1
    end
    peers = server.clients
    UPDATE_CALLBACKS.server = function()
        server:run()
        if Red then
            getpos()
        end
    end
    orig = HOOK(Red, 'render_map', hook)
    return server.hostname
end

function startclient(ip, port)
    if orig then error('already running') end
    peers = {}
    print('starting client')
    client = Net.Client:new()
    client:connect(ip or "127.0.0.1", port or 27716)
    UPDATE_CALLBACKS.client = function()
        local is_connected = not(client:recv() == false)
        if not is_connected then
            --peers = {}
            --UPDATE_CALLBACKS.client = nil
            --client = nil
            return
        end

        if not client.id and client.backlog and #client.backlog > 0 then
            client.id = tonumber(client.backlog[1])
            PLAYER.id = client.id
            if #client.backlog == 1 then
                client.backlog = nil
            else
                table.remove(client.backlog, 1)
            end
        end

        if not PLAYER.id then return end

        if Red and PLAYER:update() then
            client:send(encode(PLAYER, true)..'\n')
        end

        if client.backlog then
            local s = client.backlog[#client.backlog]
            decode(s)
            client.backlog = nil
        end
    end

    orig = HOOK(Red, 'render_map', hook)
end
