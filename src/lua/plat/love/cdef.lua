local ext
if ffi.os == 'Windows' then
    ext = 'dll'
elseif ffi.os == 'Linux' then
    ext = 'so'
elseif ffi.os == 'OSX' then
    ext = 'dylib'
else
    error('Unknown platform')
end
ffi.mgba = ffi.load('deps/lib/love/libmgba.'..ext, true)
ffi.luared = ffi.load('build/love/luared.'..ext, true)

O_CREAT = 0x0200
O_RDWR = 2
