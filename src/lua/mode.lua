Mode = {}
Mode.idx = 1

function Mode:update()
    --[[
    if Button.isdown(Button.r) then
        self:change(1)
    elseif Button.isdown(Button.l) then
        self:change(-1)
    end
    ]]
end

function Mode:change(offset)
    offset = offset or 1
    local idx = self.idx + offset
    if idx < 1 then
        idx = #self
    elseif idx > #self then
        idx = 1
    end
    return self:changeto(idx)
end
function Mode:changeto(idx)
    if not idx then
        Keyboard.callbacks.mode = nil
        rendercallbacks.mode = nil
        return
    end

    self.idx = idx

    local info = self[self.idx]
    if not info then
        error('invalid index')
    end

    Keyboard.callbacks.mode = info.keycallback or function() end
    rendercallbacks.mode = info.rendercallback or function() end
end

return Mode
