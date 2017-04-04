local f = io.open(PATH..'/res/pokered.sym')

local symbols = {}

for line in f:lines() do
    local bank, addr, name = string.match(line, '(%w%w)%:(%w%w%w%w) (.+)')
    if bank and addr and name then
        bank = tonumber(bank, 16)
        addr = tonumber(addr, 16)
        symbols[name] = {bank = bank, addr = addr}
    end
end
f:close()


local wram = {}

wram.wTilesetCollisionPtr = 2
wram.wRepelRemainingSteps = 1
wram.wDoNotWaitForButtonPressAfterDisplayingText = 1
wram.wEnemyMonNick = {string = true, len = 11}
wram.wIsInBattle = 1
wram.wBattleMon = {'struct battle *'}
wram.wEnemyMon = {'struct battle *'}
wram.wWalkBikeSurfState = 1
wram.wMapPalOffset = 1
wram.wCurMap = 1
wram.wCurMapHeight = 1
wram.wCurMapWidth = 1
wram.wCurrentTileBlockMapViewPointer = 2
wram.wYCoord = 1
wram.wXCoord = 1
wram.wWalkCounter = 1
wram.wStepCounter = 1
wram.wPlayerMovingDirection = 1
wram.wPlayerName = {string = true, len=11}

wram.wSimulatedJoypadStatesIndex = 1
wram.H_LOADEDROMBANK = 1
wram.wOverworldMap = 1
wram.wNumSprites = 1
wram.wSpriteSetID = 1

wram.wCurMapHeight = 1
wram.wCurMapWidth = 1

wram.wObtainedBadges = 1

wram.wNumBagItems = 1
wram.wBagItems = {'struct bagitem *', len=20}
wram.wSpriteStateData1 = {'struct spritestatedata1 *', len=16}
wram.wSpriteStateData2 = {'struct spritestatedata2 *', len=16}
wram.wSpriteSet = {'uint8_t *', len=11}

wram.wMissableObjectList = {'struct MissableObject *', len=17}
wram.wMissableObjectFlags = {'uint8_t *', len=32}

wram.wPartyCount = 1
wram.wPartySpecies = {'uint8_t *', len=6}
wram.wPartyMons = {'struct party *', len=6}
wram.wPartyMonOT = {string = true, len=11, arr=true}
wram.wPartyMonNicks = {string = true, len=11, arr=true}

-- metatable voodoo

local function index_string(ptr, info)
    local str = ffi.new('char[?]', info.len)
    for i=0,info.len-1 do
        local c = ptr[i]
        if c == 80 then
            str[i] = 0
            break
        end
        str[i] = c - Red.CharOffset
    end
    return ffi.string(str)
end

local function newindex_string(ptr, info, v)
    assert(#v < info.len)
    local str = ffi.new('char[?]', info.len, v)
    for i=0,info.len-1 do
        local c = str[i] + Red.CharOffset
        ptr[i] = c
    end
    ptr[#v] = 80
end

local mt = {}
mt.__index = function(t, k)
    local sym = symbols[k]
    local ptr = emu.wram + sym.addr

    local info = wram[k]
    if not info then error('doesnt exist') end

    local typ = type(info)
    if typ == 'number' then
        if info == 1 then
            return ptr[0]
        elseif info == 2 then
            return ptr[0] * 0x100 + ptr[1]
        else
            error('not implemented')
        end
    elseif typ == 'table' then
        local typ = type(info[1])
        if typ == 'string' or typ == 'cdata' then
            local ptr = ffi.cast(info[1], ptr)
            if info.len then
                return ptr
            else
                return ptr[0]
            end
        elseif typ == 'nil' then
            if info.string then
                if info.arr then
                    return setmetatable({}, {
                        __index = function(t, k)
                            return index_string(ptr + info.len*k, info)
                        end,
                        __newindex = function(t, k, v)
                            newindex_string(ptr + info.len*k, info, v)
                        end,
                    })
                else
                    return index_string(ptr, info)
                end
            else
                error('wat')
            end
        end
    else
        error('wat')
    end
end

mt.__newindex = function(t, k, v)
    local sym = symbols[k]
    local ptr = emu.wram + sym.addr

    local info = wram[k]
    local typ = type(info)
    if not info then error('doesnt exist') end

    if typ == 'number' then
        if info == 1 then
            ptr[0] = v
        elseif info == 2 then
            local tens = math.floor(v / 0x100)
            ptr[0] = tens
            ptr[1] = v - tens
        else
            error('not implemented')
        end
    elseif typ == 'table' then
        local typ = type(info[1])
        if typ == 'string' or typ == 'cdata' then
            error('setting structs isnt allowed')
        elseif typ == 'nil' then
            if info.string then
                if info.arr then
                    error('cannot set array of strings')
                end
                newindex_string(ptr, info, v)
            else
                error('wat')
            end
        end
    else
        error('wat')
    end
end

-- cdefs


ffi.cdef[[
#pragma pack(1)
struct battle {
    uint8_t Species;

    uint8_t HP_16_0;
    uint8_t HP_16_1;

    uint8_t BoxLevel;
    uint8_t Status;
    uint8_t Type1;
    uint8_t Type2;
    uint8_t CatchRate;
    uint8_t Moves[4];
    uint8_t DVs[2];
    uint8_t Level;

    uint8_t MaxHP_16_0;
    uint8_t MaxHP_16_1;

    uint8_t Attack_16_0;
    uint8_t Attack_16_1;

    uint8_t Defense_16_0;
    uint8_t Defense_16_1;

    uint8_t Speed_16_0;
    uint8_t Speed_16_1;

    uint8_t Special_16_0;
    uint8_t Special_16_1;

    uint8_t PP[4];
};
struct spritestatedata1 {
    uint8_t PictureID;
    uint8_t MovementStatus;
    uint8_t SpriteImageIdx;
    uint8_t YStepVector;
    uint8_t YPixels;
    uint8_t XStepVector;
    uint8_t XPixels;
    uint8_t IntroAnimFrameCounter;
    uint8_t AnimFrameCounter;
    uint8_t FacingDirection;
    uint8_t unknown[6];
};
struct spritestatedata2 {
    uint8_t WalkAnimationCounter;
    uint8_t unknown;
    uint8_t YDisplacement;
    uint8_t XDisplacement;
    uint8_t MapY;
    uint8_t MapX;
    uint8_t MovementByte1;
    uint8_t GrassPriority;
    uint8_t MovementDelay;
    uint8_t unknown2[5];
    uint8_t SpriteImageBaseOffset;
    uint8_t unknown3;
};
struct MissableObject {
    uint8_t id;
    uint8_t index;
};
struct bagitem {
    uint8_t id;
    uint8_t count;
};

struct box {
    uint8_t Species;
    uint8_t HP_16_0;
    uint8_t HP_16_1;
    uint8_t BoxLevel;
    uint8_t Status;
    uint8_t Type1;
    uint8_t Type2;
    uint8_t CatchRate;
    uint8_t Moves[4];

    uint8_t OTID_16_0;
    uint8_t OTID_16_1;

    uint8_t Exp_24_0;
    uint8_t Exp_24_1;
    uint8_t Exp_24_2;

    uint8_t HPExp_16_0;
    uint8_t HPExp_16_1;

    uint8_t AttackExp_16_0;
    uint8_t AttackExp_16_1;

    uint8_t DefenseExp_16_0;
    uint8_t DefenseExp_16_1;

    uint8_t SpeedExp_16_0;
    uint8_t SpeedExp_16_1;

    uint8_t SpecialExp_16_0;
    uint8_t SpecialExp_16_1;

    uint8_t DVs[2];
    uint8_t PP[4];
};
struct party {
    struct box box;
    uint8_t Level;

    uint8_t MaxHP_16_0;
    uint8_t MaxHP_16_1;

    uint8_t Attack_16_0;
    uint8_t Attack_16_1;

    uint8_t Defense_16_0;
    uint8_t Defense_16_1;

    uint8_t Speed_16_0;
    uint8_t Speed_16_1;

    uint8_t Special_16_0;
    uint8_t Special_16_1;
};
]]

local struct_mt = {
    __index = function(t, k)
        if ffi.offsetof(t, k..'_16_0') then
            return t[k..'_16_0'] * 0x100 + t[k..'_16_1']
        elseif ffi.offsetof(t, k..'_24_0') then
            error('not yet implemented')
--          return t[k..'_24_0'] + t[k..'_24_1'] * 0x100 + t[k..'_24_2'] * 0x10000
        else
            error('bad key')
        end
    end,
    __newindex = function(t, k, v)
        if ffi.offsetof(t, k..'_16_0') then
            local high = math.floor(v / 0x100)
            local low = v - high * 0x100
            t[k..'_16_0'] = high
            t[k..'_16_1'] = low
        elseif ffi.offsetof(t, k..'_24_0') then
            error('not yet implemented')
        else
            error('bad key')
        end
    end,
}
ffi.metatype('struct box', struct_mt)
ffi.metatype('struct party', struct_mt)
ffi.metatype('struct battle', struct_mt)

Red.sym = symbols
Red.wram = setmetatable({}, mt)
Red.rom = setmetatable({}, {
    __index = function(t, k)
        local sym = symbols[k]
        return emu:rom(sym.bank, sym.addr)
    end,
    __newindex = function()
        error('not allowed')
    end,
})
