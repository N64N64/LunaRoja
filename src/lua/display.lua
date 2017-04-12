local current
function DISPLAY(t)
    if not t then return current end
    current = t
    Keyboard.callbacks.display = current.key or function() end
end

return DISPLAY
