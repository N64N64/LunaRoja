require 'plat.3ds.util'
require 'preinit'
math.randomseed(tonumber(C.osGetTime()))
require 'init'

local lasttime
function CALCULATE_DT(DT)
    local curtime = tonumber(C.osGetTime())/1000
    if not lasttime then
        lasttime = curtime
    else
        DT = curtime - lasttime
        lasttime = curtime
    end
    return DT
end

while C.aptMainLoop() do
    if MAIN_LOOP() then
        break
    end
end
