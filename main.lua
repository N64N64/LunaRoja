#!/usr/bin/env luajit

if love then
    dofile(love.filesystem.getSource()..'/src/lua/plat/love/init.lua')
else
    ROMPATH = arg[1]
    if ROMPATH == nil then
        local f = io.open('src/lua/config/cmd_rom.lua')
        if f then
            f:close()
            ROMPATH = dofile('src/lua/config/cmd_rom.lua')
        else
            print('Usage: '..arg[0]..' rom.gb')
            return
        end
    end
    local function runcmd(cmd)
        local f = io.popen(cmd, 'r')
        local s =f:read('*a')
        f:close()
        return s
    end
    local function string_split(self, sep)
        local fields = {}
        string.gsub(self, '([^'..sep..']+)', function(c) table.insert(fields, c) end)
        return fields
    end
    local function get_folder_from_path(path)
        local components = string_split(path, '/')
        components[#components] = nil
        local prefix = string.sub(path,1,1) == '/' and '/' or './'
        return prefix..table.concat(components, '/')
    end
    local function where_is_main_dot_lua()
        local path = arg[0]
        local symlink = runcmd('readlink "'..path..'"')
        if #symlink == 0 then
            return get_folder_from_path(path)
        elseif not (string.sub(symlink, 1, 3) == '../') then
            return get_folder_from_path(symlink)
        end
        -- get absolute path
        return get_folder_from_path(get_folder_from_path(get_folder_from_path(path))..'/'..string.sub(symlink, 4, #symlink))
    end

    PATH = where_is_main_dot_lua()

    dofile(PATH..'/src/lua/plat/cmd/init.lua')
end
