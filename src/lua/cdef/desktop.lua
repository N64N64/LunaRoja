local ext
if ffi.os == 'Windows' then
    ext = 'dll'
elseif ffi.os == 'OSX' then
    ext = 'dylib'
else -- default to something like Linux or BSD
    ext = 'so'
end
ffi.mgba = ffi.load(PATH..'/deps/lib/love/libmgba.'..ext, true)
ffi.luared = ffi.load(PATH..'/build/love/luared.'..ext, true)
if ffi.os == 'Windows' then
    ffi.freetype = ffi.load(PATH..'/deps/lib/love/freetype6.dll')
elseif PLATFORM == 'love' then
    ffi.freetype = C
else
    ffi.freetype = ffi.load'freetype'
end

if ffi.os == 'Linux' then
    O_CREAT = 0x40
elseif ffi.os == 'Windows' then
    O_CREAT = 0x100
elseif ffi.os == 'OSX' or ffi.os == 'BSD' then
    O_CREAT = 0x0200
else
    error('unknown platform')
end

O_RDWR = 2
SEEK_END = 2
SEEK_SET = 0
