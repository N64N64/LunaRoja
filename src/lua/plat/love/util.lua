function ls(dir)
    if string.has_prefix(dir, PATH) then
        dir = string.sub(dir, #PATH + 1, #dir)
    end
    return love.filesystem.getDirectoryItems(dir)
end
