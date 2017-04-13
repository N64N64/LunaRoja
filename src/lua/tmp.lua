local last_client_count
local function getpos()
    local update = {}
    update[1] = encode(sendposstr() or 'false')
    local should_send = not(last_client_count == #server.clients and update[1] == 'false')
    for i,client in ipairs(server.clients) do
        update[i + 1] = 'false'

        if client.backlog then
            client.pos = client.pos or {}
            local s = client.backlog[#client.backlog]
            local f = setfenv(load('return '..s), Env.Empty())
            if f then
                client.pos = f()
                client.pos.id = client.id
                update[i + 1] = encode(client.pos)
                should_send = true
            end
            client.backlog = nil
        end
    end
    if should_send then
        server:send('{'..table.concat(update, ',')..'}\n')
    end
    last_client_count = #server.clients
end

local lastx, lasty, lastmap, lastdir, lastanim, lastwalk, diffx, diffy
function sendposstr()
    if not Red.wram then return end
    if  lastx == Red.wram.wXCoord
        and lasty == Red.wram.wYCoord
        and lastmap == Red.wram.wCurMap
        and lastdir == Red.wram.wSpriteStateData1[0].FacingDirection
        and lastanim == Red.wram.wSpriteStateData1[0].AnimFrameCounter
        and diffx == Red.diffx
        and diffy == Red.diffy
    then return end

    lastx = Red.wram.wXCoord
    lasty = Red.wram.wYCoord
    lastmap = Red.wram.wCurMap
    lastdir = Red.wram.wSpriteStateData1[0].FacingDirection
    lastanim = Red.wram.wSpriteStateData1[0].AnimFrameCounter
    lastwalk = Red.wram.wWalkCounter
    diffx = Red.diffx or 0
    diffy = Red.diffy or 0
    return '{x='..lastx..', y='..lasty..', map='..lastmap..', dir='..lastdir..', anim='..lastanim..', diffx = '..diffx..', diffy = '..diffy..'}'
end

local orig, peers
local function hook(...)
    orig(...)
    local _, map, mapx, mapy, xplayer, yplayer = ...
    for _,peer in ipairs(peers) do
        if peer.pos and peer.pos.map == map and (not client or not(client.id == peer.pos.id)) then
            C.draw_set_color(0xff, 0x00, 0x00)
            local x = peer.pos.x*16
            local y = peer.pos.y*16
            local bmap = getspritefromrom(Red.wram.wSpriteStateData1[0].PictureID)
            Red:render_sprite(bmap, x + peer.pos.diffx, y + peer.pos.diffy, xplayer, yplayer, peer.pos.dir, peer.pos.anim)
        end
    end
end

function startserver()
    if orig then error('already running') end
    print('starting server')
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
        if Red then
            if is_connected then
                local str = sendposstr()
                if str then
                    client:send(encode(str)..'\n')
                end
            end
        end
        if not is_connected then
            peers = {}
            UPDATE_CALLBACKS.client = nil
            client = nil
            return
        end

        if not client.id and client.backlog and #client.backlog > 0 then
            client.id = client.backlog[1]
            if #client.backlog == 1 then
                client.backlog = nil
            else
                table.remove(client.backlog, 1)
            end
        end

        if client.backlog then
            local s = client.backlog[#client.backlog]
            print(s)
            local f = setfenv(load('return '..s), Env.Empty())
            for i,peer in ipairs(f()) do
                if peer == false then
                    peers[i] = peers[i] or {}
                else
                    peers[i] = {pos = peer}
                end
            end
            client.backlog = nil
        end
    end

    orig = HOOK(Red, 'render_map', hook)
end
