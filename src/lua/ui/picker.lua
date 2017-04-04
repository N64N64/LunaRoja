local super = require 'ui.view'
UI.Picker = Object.new(super)

function UI.Picker:new()
    local self = super.new(self)

    self.idx = 1
    self.padding = 10

    self.arrow = UI.Label:new('>  ')
    self.arrow.color = {0x00, 0x00, 0x00}
    self.arrow.background_color = {0xff, 0xff, 0xff}
    self.arrow:paint()

    return self
end

function UI.Picker:onselect(idx)
    local item = self.items[idx]
    if type(item) == 'table' then
        item:onselect()
    end
end
function UI.Picker:oncancel()
end

function UI.Picker:updateoffset()
    while self.idx > self.offset + self.maxitems do
        self.offset = self.offset + 1
    end

    while self.offset >= self.idx do
        self.offset = self.offset - 1
    end
end

function UI.Picker:update()
    if Button.isdown(Button.down) then
        self.idx = self.idx + 1
        if self.idx > #self.items then
            self.idx = 1
        end
        self:paint()
    end
    if Button.isdown(Button.up) then
        self.idx = self.idx - 1
        if self.idx < 1 then
            self.idx = #self.items
        end
        self:paint()
    end
    if Button.isdown(Button.a) then
        self:onselect(self.idx)
    end
    if Button.isdown(Button.b) then
        self:oncancel()
    end
end

function UI.Picker:paint()
    self.labels = {}

    local width = 0
    local height = 0

    if self.header then
        local label = UI.Label:new(self.header)
        label.color = {0xaa, 0x00, 0x00}
        label.background_color = {0xff, 0xff, 0xff}
        label:paint()

        self.labels.header = label

        width = math.max(width, label.width)
        height = height + label.fontsize*2
    end

    local first, last
    if self.maxitems and #self.items > self.maxitems then
        self.offset = self.offset or 0
        self:updateoffset()

        first = self.offset + 1
        last = self.offset + self.maxitems
    else
        self.offset = nil
        first = 1
        last = #self.items
    end

    for i,v in ipairs(self.items) do
        local s = v
        local is_table = type(v) == 'table'
        if is_table then
            s = v.title
        end

        local label = UI.Label:new(s)
        if is_table and v.color then
            label.color = v.color
        else
            label.color = {0x00, 0x00, 0x00}
        end
        label.background_color = {0xff, 0xff, 0xff}
        label:paint()

        width = math.max(width, label.width + self.arrow.width)

        -- only insert label if within the bounds
        -- i dont simply loop from first to last because
        -- i need the width calculation
        if i >= first and i <= last then
            table.insert(self.labels, label)
            height = height + label.fontsize
        end
    end

    local pad = self.padding or 0

    self.width = width + pad*2
    self.height = height + pad*2
end

local SCROLLBAR_WIDTH = 10
function UI.Picker:draw(scr, x, y)
    local width, height = self.width, self.height
    local pad = self.padding or 0

    if self.offset then
        width = width + pad + SCROLLBAR_WIDTH
    end

    C.draw_set_color(0x00, 0x00, 0x00)
    scr:line(x - 1, y - 1, x + width + 1, y - 1)
    scr:line(x + width + 1, y - 1, x + width + 1, y + height + 1)
    scr:line(x + width + 1, y + height + 1, x - 1, y + height + 1)
    scr:line(x - 1, y + height + 1, x - 1, y - 1)

    C.draw_set_color(0xff, 0xff, 0xff)
    scr:rect(x, y, width, height)

    local contenty = y
    if self.labels.header then
        self.labels.header:draw(scr, x + (width - self.labels.header.width)/2, y + pad)
        contenty = contenty + self.labels.header.fontsize*2
    end

    for i,label in ipairs(self.labels) do
        local x = x + pad
        local y = contenty + pad + (i-1)*label.fontsize
        if i == self.idx - (self.offset or 0) then
            self.arrow:draw(scr, x, y)
        end
        label:draw(scr, x + self.arrow.width, y)
    end


    if self.offset then
        C.draw_set_color(0xcc, 0xcc, 0xcc)
        local height = height - (contenty - y) - pad*2
        local x = x + width - pad - SCROLLBAR_WIDTH
        local y = contenty + pad

        local dy = self.offset * height / #self.items
        y = y + dy
        height = height * self.maxitems / #self.items

        scr:rect(x, y, SCROLLBAR_WIDTH, height)
    end
end

return UI.Picker
