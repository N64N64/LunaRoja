Console = {}

Console.lineheight = 12
Console.history = {}
Console.backlog = {}

Console.input = UI.Label:new('', Console.lineheight)
Console.input.font = Font.Monospace
Console.input:paint()

Console.mode = {
    keycallback = function(key)
        Console:keycallback(key)
    end,
    rendercallback = function()
        Keyboard:render()
        Console:render()
    end,
}

local button = PLATFORM == '3ds' and 'B' or 'ESC'
local header = UI.Label:new('Lua console! Press '..button..' to return to game', Console.lineheight, {0x86, 0x86, 0xff})
header.font = Font.Monospace
header:paint()

local override = {}
override.help = function(self)
    local msg = UI.Label:new('Type some Lua code. Here\'s an example: 2 + 2', Console.lineheight)
    msg.font = Font.Monospace
    msg.color = header.color
    msg:paint()
    table.insert(self.history, self.input.text)
    table.insert(self.backlog, self.input)
    table.insert(self.backlog, msg)

    return true
end

override.quit = function()
    SHOULD_QUIT = true
end

function Console:keycallback(key)
    if key == '\b' then
        local front = string.sub(self.input.text, 1, math.max(0, self.blinker.pos - 1))
        local back = string.sub(self.input.text, self.blinker.pos + 1, #self.input.text)
        self.input.text = front..back
        self.input:paint()
        self.blinker.pos = self.blinker.pos - 1
        if self.blinker.pos < 0 then
            self.blinker.pos = 0
        end
    elseif key == '\n' then
        if not _G[self.input.text] and override[self.input.text] and override[self.input.text](self) then
            -- skip
        else
            local empty = string.match(self.input.text, '(%s*)') == self.input.text
            local returning = not empty
            local f, err = load('return '..self.input.text) -- first try returning result
            if err then
                returning = string.find(self.input.text, 'return')
                f, err = load(self.input.text)
            end
            local success, result
            if f then
                success, result = pcall(f)
            else
                success = false
                result = err
            end
            if not(empty or self.history[#self.history] == self.input.text) then
                table.insert(self.history, self.input.text)
            end
            table.insert(self.backlog, self.input)
            if not success then
                print(result)
                -- remove that dumb [string "what you just typed']:1: part at the beginning
                if string.has_prefix(result, '[string "') then
                    local add = #'[string ""]:' + 1
                    if #self.input.text < 48 then
                        result = string.sub(result, #self.input.text + add, #result)
                    else
                        result = string.sub(result, 48 + add, #result)
                    end
                    result = string.match(result, '%d+%: (.*)')
                end
            end
            if returning or not(result == nil) then
                local result = UI.Label:new(tostring(result), Console.lineheight)
                result.font = Font.Monospace
                result.color = success and {0x00, 0xff, 0x00} or {0xff, 0x00, 0x00}
                result:paint()
                table.insert(self.backlog, result)
            end
        end
        while (#self.backlog + 2) * Console.lineheight > Screen.top.height do
            table.remove(self.backlog, 1)
        end
        self.input = UI.Label:new('', Console.lineheight)
        self.input.font = Font.Monospace
        self.input:paint()
        self.blinker.pos = 0
        self.history_idx = nil
    else
        local front = string.sub(self.input.text, 1, self.blinker.pos)
        local back = string.sub(self.input.text, self.blinker.pos + 1, #self.input.text)
        self.input.text = front..key..back
        self.input:paint()
        self.blinker.pos = self.blinker.pos + 1
    end
    self.blinker:reset()
end

if PLATFORM == 'love' then
    local dirs = {}
    dirs.up = true; dirs.down = true; dirs.left = true; dirs.right = true
    local orig
    orig = HOOK(love, 'keypressed', function(key)
        orig(key)
        if not(Mode.idx == 'console') then 
            if key == 'escape' then
                Mode:changeto('console')
            end
            return
        end
        if key == 'return' then
            Console:keycallback('\n')
        elseif key == 'backspace' then
            Console:keycallback('\b')
        elseif key == 'escape' then
            Mode:changeto('game')
            love.keyboard.setKeyRepeat(false)
        elseif dirs[key] then
            Console[key](Console)
        end
    end)
    local orig
    orig = HOOK(love, 'textinput', function(key)
        orig(key)
        if not(Mode.idx == 'console') then return end
        Console:keycallback(key)
        love.keyboard.setKeyRepeat(true)
    end)
end

Console.blinker = Object.new(Console)
Console.blinker.interval = 0.6
Console.blinker.time = 0
Console.blinker.on = true
Console.blinker.pos = 0
function Console.blinker:draw(x0, y0)
    self.time = self.time + DT
    while self.time > self.interval do
        self.time = self.time - self.interval
        self.on = not self.on
    end
    if self.on then
        ffi.luared.draw_set_color(0x00, 0xff, 0x00)
        local charwidth = #self.input.text == 0 and 0 or self.input.width/#self.input.text
        local x, y = charwidth*self.pos + x0, (#self.backlog + 1)*Console.lineheight + y0
        Screen.top:line(x, y, x, y + Console.lineheight)
    end
end
function Console.blinker:reset()
    self.on = true
    self.time = 0
end

function Console:down()
    if not self.history_idx then return end

    self.history_idx = self.history_idx + 1
    if self.history_idx > #self.history then
        self.input.text = self.cached_command
        self.cached_command = nil
        self.history_idx = nil
    else
        self.input.text = self.history[self.history_idx]
    end
    self.input:paint()
    self.blinker.pos = #self.input.text
end

function Console:left()
    self.blinker.pos = self.blinker.pos - 1
    if self.blinker.pos < 0 then
        self.blinker.pos = 0
    end
    self.blinker:reset()
end

function Console:right()
    self.blinker.pos = self.blinker.pos + 1
    if self.blinker.pos > #self.input.text then
        self.blinker.pos = #self.input.text
    end
    self.blinker:reset()
end

function Console:up()
    if self.history_idx then
        self.history_idx = self.history_idx - 1
        if self.history_idx < 1 then
            self.history_idx = 1
        end
    elseif #self.history > 0 then
        self.history_idx = #self.history
        self.cached_command = self.input.text
    end
    if self.history_idx then
        self.input.text = self.history[self.history_idx]
        self.blinker.pos = #self.input.text
    end
    self.input:paint()
end

function Console:render()
    if PLATFORM == '3ds' then
        if Button.isdown(Button.b) then
            Mode:changeto('game')
        end
        if Button.isdown(Button.dleft) then
            self:left()
        end
        if Button.isdown(Button.dright) then
            self:right()
        end
        if Button.isdown(Button.dup) then
            self:up()
        end
        if Button.isdown(Button.ddown) then
            self:down()
        end
    end

    local xpad = 3

    header:render(Screen.top, xpad, 0)
    for i,v in ipairs(self.backlog) do
        v:render(Screen.top, xpad, i*Console.lineheight)
    end

    self.input:render(Screen.top, xpad, (#self.backlog + 1)*Console.lineheight)

    self.blinker:draw(xpad, 0)
end

return Console
