Toggler = {}

local FONTSIZE = 16

local intptr = ffi.new('int[2]')
function Toggler:render()
    self:init()
    if not self.labels then
        self:reload()
    end

    self:update()

    if not(#self.levels == 0) then
        self.back_button:render(Screen.bottom, 0, 0)
    end

    for _,label in ipairs(self.labels) do
        if label.y + FONTSIZE > Screen.bottom.height then
            break
        end
        label:render(Screen.bottom, 0, 0)
    end
end

function Toggler:init()
    self.init = function() end

    self.tree = ROOT
    self.levels = {}

    self.back_button = UI.Label:new()
    self.back_button.x = 160
    self.back_button.y = 0
    self.back_button.text = '<--- Back'
    self.back_button.color = {0x88, 0x88, 0x88}
    self.back_button:paint()
end

function Toggler:gettypecolor(label)
    if label == self.back_button then
        return {0x88, 0x88, 0x88}
    end

    local v = self.current_node[label.text]
    local type = type(v)
    if type == 'function' then
        return {0x00, 0xff, 0xff}
    elseif type == 'table' then
        return v.color or {0xff, 0x00, 0xff}
    elseif v == true then
        return {0x00, 0xff, 0x00}
    else--if v == false then
        return {0xff, 0x00, 0x00}
    end
end

function Toggler:reload()
    self.labels = {}
    local t = self.tree
    for i,v in ipairs(self.levels) do
        t = t[v]
    end
    self.current_node = t
    self.labels[0] = self.back_button

    local yoff = 0
    if not(#self.levels == 0) then
        yoff = 1
    end
    local i = 0
    for k,v in pairs(t) do
        i = i + 1
        local label = UI.Label:new()
        label.x = 160
        label.y = (yoff + i - 1)*FONTSIZE
        label.text = k
        label.fontsize = FONTSIZE
        label.color = self:gettypecolor(label)
        label:paint()

        self.labels[i] = label
    end
end

local wastouching = false
function Toggler:update()
    if Mouse.isheld then
        local bitmapcount = #self.labels
        if not(#self.levels == 0) then
            bitmapcount = bitmapcount + 1
        end

        if Mouse.x >= 160 and Mouse.y < FONTSIZE * bitmapcount then
            local idx = math.ceil(Mouse.y / FONTSIZE)
            if not(#self.levels == 0) then
                idx = idx - 1
            end
            if self.highlighted then
                self.highlighted.color = self:gettypecolor(self.highlighted)
                self.highlighted:paint()
            end
            self.highlighted = self.labels[idx]
            if self.highlighted then
                self.highlighted.color = {0xff, 0xff, 0xff}
                self.highlighted:paint()
            end
        end
    elseif wastouching then
        local k = self.highlighted
        local v = k and self.current_node[k.text]
        if type(v) == 'table' and v.onselect then
            v:onselect()
            self:reload()
        elseif type(v) == 'function' then
            v()
        elseif type(v) == 'boolean' then
            self.current_node[k.text] = not v
        end
        if k then
            k.color = self:gettypecolor(k)
        end
        if type(v) == 'table' and not v.onselect then
            self.levels[#self.levels + 1] = k.text
            self:reload()
        elseif k == self.back_button then
            -- back button
            self.levels[#self.levels] = nil
            k:paint()
            self:reload()
        elseif k then
            k:paint()
        end
        self.highlighted = nil
        for _,f in pairs(Toggler.OnUpdate) do
            f()
        end
    end
    wastouching = Mouse.isheld
end

Toggler.OnUpdate = {}

return Toggler
