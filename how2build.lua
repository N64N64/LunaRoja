local mgba = true

local info
if fs.isfile('deps/lib/info.lua') then
    info = dofile('deps/lib/info.lua')
else
    info = {}
end

local function checkfile(path, url)
    if info[path] == url then return end

    print(GREEN('downloading pre-built '..path..'...'))
    local success = os.execute("curl -L -f '"..url.."' -o "..path) == 0
    if not success then
        error('could not download '..path..' (maybe curl isnt installed?)')
    end
    info[path] = url
end

local function downloadlibs(libs)
    for _,v in ipairs(libs) do
        checkfile(unpack(v))
    end

    -- update info.lua

    local f = io.open('deps/lib/info.lua', 'w')
    f:write('return {\n')
    for k,v in pairs(info) do
        f:write('    ["'..k..'"] = "'..v..'",\n')
    end
    f:write('}\n')
    f:close()
end

function default()
    print(GREEN('There are two supported platforms. Try running one of these commands:'))
    print('aite 3ds')
    print('aite love')
end

_G['3ds'] = function()
    fs.mkdir('deps/lib/3ds')
    downloadlibs{
        {'deps/lib/3ds/libluajit.a', 'https://github.com/N64N64/mgba/releases/download/1/libluajit.a'},
        {'deps/lib/3ds/libfreetype.a', 'https://github.com/N64N64/mgba/releases/download/1/libfreetype.a'},
        {'deps/lib/3ds/libmgba.a', 'https://github.com/N64N64/mgba/releases/download/1/libmgba.a'},
        {'deps/lib/3ds/libpng16.a', 'https://github.com/N64N64/mgba/releases/download/1/libpng16.a'},
        {'deps/lib/3ds/libzlibstatic.a', 'https://github.com/N64N64/mgba/releases/download/1/libzlibstatic.a'},
    }

    local b = builder('3ds')
    b.compiler = 'gcc'
    b.src = table.merge(
        fs.find('src/c/common', '*.c'),
        fs.find('deps/c/common', '*.c'),
        fs.find('src/c/3ds', '*.c')
    )
    b.build_dir = 'build/3ds'
    b.output = 'build/3ds/luared.elf'
    b.include_dirs = {
        'src/c',
        'src/c/3ds',
        'src/c/common',
        'deps/include',
        'deps/include/mgba',
    }
    b.library_dirs = {
        'deps/lib/3ds',
    }
    b.libraries = {
        'luajit',
        'freetype',
        'zlibstatic',
        'png16',
    }
    if mgba then
        table.insert(b.libraries, 'mgba')
        b.defines = {
            'USE_MGBA',
        }
    end
    b.cflags = '-Wno-misleading-indentation'
    b.ldflags = '-Wl,--whole-archive,--allow-multiple-definition'
    local objs = b:compile()
    b:link(objs)
    folder()
end

function love()
    local b = builder()
    b.compiler = 'gcc'
    b.src = table.merge(
        fs.find('src/c/common', '*.c'),
        fs.find('deps/c/common', '*.c')
    )
    b.build_dir = 'build/love'
    b.output = 'build/love/luared.'..builder.dylib_ext
    b.include_dirs = {
        'src/c',
        'src/c/common',
        'deps/include',
        'deps/include/mgba',
    }
    b.library_dirs = {
        'deps/lib/love',
    }
    b.libraries = {
        'z',
    }
    b.defines = {
        '_GNU_SOURCE',
    }
    if mgba then
        table.insert(b.defines, 'USE_MGBA')
    end
    b.sflags = '-std=c99'
    b:link(b:compile())
end

function zip()
    os.pexecute('rm -rf luared')
    fs.mkdir('luared')
    os.pexecute('cp -r src/lua luared/')
    os.pexecute('cp -r res luared/')
    os.pexecute('cp build/3ds/luared.3dsx luared/')
    os.pexecute('cp build/3ds/luared.smdh luared/')
    fs.mkdir('luared/rom')
    os.pexecute('zip -r luared.zip luared')
end

function ftp(...)
    local ip = '10.0.0.111:5000'

    local did = false
    for i,v in ipairs{...} do
        did = true
        if v == 'bin' then
            os.pexecute('curl -T build/luared.3dsx ftp://'..ip..'/3ds/luared/luared.3dsx')
        elseif string.sub(v, #v - 3, #v) == '.lua' and fs.isfile('src/lua/'..v) then
            os.pexecute('curl -T src/lua/'..v..' ftp://'..ip..'/3ds/luared/lua/'..v)
        elseif fs.isfile(v) then
            os.pexecute('curl -T '..v..' ftp://'..ip..'/3ds/luared/'..v)
        else
            error('wat')
        end
    end
 
    if did then return end

    for _,file in pairs(fs.find('src/lua', '*.lua')) do
        os.pexecute('curl -T '..file..' ftp://'..ip..'/3ds/luared/'..file)
    end

end

function sd(name)
    local dir = '/Volumes/'..(name or 'N3DS-J')
    --os.pexecute('cp build/luared.3dsx "'..dir..'/3ds/luared/"')
    os.pexecute('cp -r src/lua/* "'..dir..'/3ds/luared/"')
    local cmd = ('diskutil eject "'..dir..'"')
    os.pexecute(cmd..' || '..cmd)
end

function folder()
    -- 3dsx
    os.pexecute('smdhtool --create "Lua Red" "" "" 3ds_stuff/icon.png build/3ds/luared.smdh')
    os.pexecute('3dsxtool build/3ds/luared.elf build/3ds/luared.3dsx --smdh=build/3ds/luared.smdh')
    -- cia, this doesn't work for some reason
    --[[
    os.pexecute('bannertool makebanner -i 3ds_stuff/cia/banner.png -a 3ds_stuff/cia/sound.wav -o build/banner.bin')
    os.pexecute('cp build/luared.elf build/cia_luared.elf')
    os.pexecute('arm-none-eabi-strip build/cia_luared.elf')
    os.pexecute('makerom -f cia -o build/luared.cia -rsf 3ds_stuff/cia/dummy.rsf -target t -exefslogo -elf build/cia_luared.elf -icon build/luared.smdh -banner build/banner.bin')
    ]]
end

function clean()
    os.pexecute('rm -rf build')
end

function run(plat)
    plat = plat or '3ds'
    if plat == '3ds' then
        os.execute('citra build/3ds/luared.3dsx')
    elseif plat == 'love' then
        os.execute('love .')
    end
end
