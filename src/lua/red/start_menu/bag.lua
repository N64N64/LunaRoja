-- forward decl
local get_item_name, show_bag_hax, show_item_hax

function get_item_name(item)
    if config.show_item_hex or not ((item.id >= 0x01 and item.id <= 0x53) or (item.id >= 0xc4 and item.id <= 0xfa)) then
        return string.format('0x%.2x', item.id)
    end

    local str = ''

    if item.id < 0xc4 then
        str = Red.GetString(Red.rom.ItemNames, item.id - 1)
    else -- TM/HM
        local id
        if item.id < 0xc9 then
            local i = item.id - 0xc4
            str = 'HM '..(i + 1)
            id = Red.rom.HiddenMachines[i]
        else
            local i = item.id - 0xc9
            str = 'TM '..(i + 1)
            id = Red.rom.TechnicalMachines[i]
        end
        str = str..' ('..Red.Dex.Move[id].name..')'
    end

    return str
end

function show_item_hax(item)
    return function()
        local picker = UI.Picker:new()
        picker.header = 'ITEM HAX'
        picker.maxitems = 8
        local function update()
            picker.items = {
                'Kind:  '..get_item_name(item.info),
                'Count: '..item.info.count,
            }
            picker:paint()
        end
        update()

        function picker.oncancel()
            Button.KeysDown = 0
            show_bag_hax(item.idx)
        end

        RENDER_CALLBACKS.itemmenu = function()
            if Button.isdown(Button.right) then
                if picker.idx == 1 then
                    item.info.id = item.info.id + 1
                    if not config.show_item_hex then
                        if item.info.id == 0x54 then
                            -- skip to TM 01
                            item.info.id = 0xc4
                        elseif item.info.id == 0xfb then
                            -- skip to MASTER BALL
                            item.info.id = 0x01
                        end
                    end
                else
                    item.info.count = item.info.count + 1
                end
                update()
            end
            if Button.isdown(Button.left) then
                if picker.idx == 1 then
                    item.info.id = item.info.id - 1
                    if not config.show_item_hex then
                        if item.info.id == 0xc3 then
                            -- skip to MAX ELIXER
                            item.info.id = 0x53
                        elseif item.info.id == 0x00 then
                            -- skip to TM 50
                            item.info.id = 0xfa
                        end
                    end
                else
                    item.info.count = item.info.count - 1
                end
                update()
            end
            picker:update()
            picker:draw(Screen.top, (Screen.top.width - picker.width)/2, (Screen.top.height - picker.height)/2)
        end
    end
end

local function get_bag_item(i)
    local item = {info = Red.wram.wBagItems[i]}
    item.idx = i + 2
    item.title = item.info.count..'x '..get_item_name(item.info)
    item.onselect = show_item_hax(item)
    return item
end

function show_bag_hax(idx)
    local picker = UI.Picker:new()

    picker.header = 'BAG HAX'
    picker.idx = idx
    picker.items = {}
    picker.maxitems = 8
    picker.items[1] = {
        color = {0x22, 0x68, 0xaa},
        title = 'Craft new item',
        onselect = function()
            local i = Red.wram.wNumBagItems
            Red.wram.wNumBagItems = i + 1
            local item = get_bag_item(i)
            do
                -- pad the end
                local nextitem = get_bag_item(i + 1)
                nextitem.info.id = item.info.id
                nextitem.info.count = item.info.count
            end
            item.info.id = 1
            item.info.count = 1
            table.insert(picker.items, item)
            picker:paint()
            item.onselect()
        end,
    }
    for i=0,Red.wram.wNumBagItems-1 do
        local item = get_bag_item(i)
        table.insert(picker.items, item)
    end
    picker:paint()
    function picker.oncancel()
        RENDER_CALLBACKS.itemmenu = nil
        emu.halt = false
    end

    RENDER_CALLBACKS.itemmenu = function()
        picker:update()
        picker:draw(Screen.top, (Screen.top.width - picker.width)/2, (Screen.top.height - picker.height)/2)
    end
end

local bag_open = false

emu:hook(Red.sym.RedisplayStartMenu, function()
    bag_open = false
end)

emu:hook(Red.sym.StartMenu_Item, function()
    if bag_open then return end
    bag_open = true

    Button.KeysDown = 0
    show_bag_hax(1)

    emu.halt = true
    return true
end)
