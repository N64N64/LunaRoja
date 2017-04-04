function ls(dir)
    if string.has_prefix(dir, './') then
        dir = string.sub(dir, 3, #dir)
    end
    return love.filesystem.getDirectoryItems(dir)
end
