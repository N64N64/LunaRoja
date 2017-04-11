Mouse = {}

if PLATFORM == 'cmd' then
    function Mouse.Scan() end
else
    require('plat.'..PLATFORM..'.mouse')
end

return Mouse
