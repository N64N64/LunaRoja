#!/usr/bin/env luajit

if love then
    dofile(love.filesystem.getSource()..'/src/lua/plat/love/init.lua')
else
    if arg[1] == nil then
        print('Usage: '..arg[0]..' rom.gb')
        return
    end
    local function string_split(self, sep)
        local fields = {}
        string.gsub(self, '([^'..sep..']+)', function(c) table.insert(fields, c) end)
        return fields
    end
    local function get_folder_from_path(path)
        local components = string_split(path, '/')
        components[#components] = nil
        local prefix = string.sub(path,1,1) == '/' and '/' or ''
        return prefix..table.concat(components, '/')
    end

    dofile(get_folder_from_path(arg[0])..'/src/lua/plat/cmd/init.lua')
end
