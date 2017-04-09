Keyboard = {}
Keyboard.color = {0xb2, 0xb2, 0xb2}
Keyboard.background_color = {0x00, 0x00, 0x00}
Keyboard.callbacks = {}

Keyboard.normal = {}
Keyboard.shift = {}

Keyboard.normal.layout = {
    '\'       \b',
    '0+/*()-=9',
    '12345678p',
    'qwertyuio',
    'asdfghjkl',
    ',zxcvbnm.',
    '\t_     :\n',
}
Keyboard.normal.bitmaps = {}

Keyboard.shift.layout = {
    '"       \b',
    '~;[]{}_+|',
    '!@#$%^&*P',
    'QWERTYUIO',
    'ASDFGHJKL',
    '<ZXCVBNM>',
    '\t\\     ?\n',
}
Keyboard.shift.bitmaps = {}

local caps_label


local function setup(layout, bitmaps)
    for k,str in pairs(layout) do
        bitmaps[k] = {}
        local t = {}
        for i=1,#str do
            t[i] = string.sub(str, i, i)
            local key
            if t[i] == '\b' then
                key = UI.Label:new('<-', 15)
            elseif t[i] == '\t' then
                key = UI.Label:new('CAPS', 10)
                caps_label = key
            elseif t[i] == '\n' then
                key = UI.Label:new('enter', 8)
            else
                key = UI.Label:new(t[i], 20)
            end
            key.color = Keyboard.color
            key.background_color = Keyboard.background_color
            key:paint()
            bitmaps[k][i] = key
        end
        layout[k] = t
    end
end
setup(Keyboard.normal.layout, Keyboard.normal.bitmaps)
setup(Keyboard.shift.layout, Keyboard.shift.bitmaps)

function Keyboard:new()
end

local inshift = false
local function getlayout()
    if inshift then
        return Keyboard.shift.layout, Keyboard.shift.bitmaps
    else
        return Keyboard.normal.layout, Keyboard.normal.bitmaps
    end
end

local touchx, touchy, keyx, keyy
local function kdown(ci, ri)
    return keyx == ci and keyx == touchx and keyy == ri and keyy == touchy
end
function Keyboard:render()
    Keyboard:update()

    local layout, bitmaps = getlayout()

    local scr = Screen.bottom
    local numrows = #layout
    local rowheight = scr.height/numrows
    local numcols = #layout[1]
    local colwidth = scr.width/numcols

    ffi.luared.draw_set_color(unpack(self.color))

    for ri, row in ipairs(layout) do
        local y = scr.height * (ri-1)/numrows
        for ci, col in ipairs(row) do
            local x = scr.width * (ci-1)/numcols

            local label = bitmaps[ri][ci]
            local isdown = kdown(ci, ri)
            if isdown then
                scr:rect(x, y, colwidth, rowheight)
                if not(label.color == self.background_color) then
                    label.color = self.background_color
                    label.background_color = self.color
                    label:paint()
                end
                ffi.luared.draw_set_color(unpack(self.background_color))
            elseif not(label.color == self.color) then
                label.color = self.color
                label.background_color = self.background_color
                label:paint()
            end
            label:render(Screen.bottom, x + (colwidth - label.width)/2 + math.floor(math.random()*2), y + (rowheight - label.height)/2 + math.floor(math.random()*2))
            if isdown then
                ffi.luared.draw_set_color(unpack(self.color))
            end
        end
    end
end

local wastouching = false

local function getkeypos(layout, bitmaps)

    local numrows = #layout
    local rowheight = Screen.bottom.height/numrows
    local numcols = #layout[1]
    local colwidth = Screen.bottom.width/numcols

    local x = math.ceil(Mouse.x/colwidth)
    local y = math.ceil(Mouse.y/rowheight)

    return x, y
end

function Keyboard:callcallbacks(key)
    if key == '\t' then
        inshift = not inshift
        if inshift then
            caps_label.text = 'caps'
        else
            caps_label.text = 'CAPS'
        end
        caps_label:paint()
        return
    end
    for _,f in pairs(self.callbacks) do
        f(key)
    end
end

function Keyboard:update()
    local layout, bitmaps = getlayout()

    if Mouse.isheld and not wastouching then
        keyx, keyy = getkeypos(layout, bitmaps)
        touchx, touchy = keyx, keyy
    elseif Mouse.isheld then
        touchx, touchy = getkeypos(layout, bitmaps)
    elseif not Mouse.isheld and wastouching then
        if keyx == touchx and keyy == touchy then
            local char = layout[touchy][touchx]
            if char then
                self:callcallbacks(char)
            end
        end
        keyx, keyy, touchx, touchy = nil, nil, nil, nil
    end

    wastouching = Mouse.isheld
end


return Keyboard
