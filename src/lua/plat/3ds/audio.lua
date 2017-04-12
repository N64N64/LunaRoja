-- translated from mgba/src/platform/3ds/main.c

local Audio = {}

local AUDIO_SAMPLES = 384
local AUDIO_SAMPLE_BUFFER = AUDIO_SAMPLES * 16
local DSP_BUFFERS = 4
local audioLeft, audioRight

local SOUND_REPEAT = C.SOUND_LOOPMODE_WRAPPER(C.CSND_LOOPMODE_NORMAL)
local SOUND_FORMAT_16BIT = C.SOUND_FORMAT_WRAPPER(C.CSND_ENCODING_PCM16) --> PCM16
local SOUND_ENABLE = bit.lshift(1, 14)
local SOUND_ONE_SHOT = C.SOUND_LOOPMODE_WRAPPER(C.CSND_LOOPMODE_ONESHOT) --> Play the sound once.

local function _aptHook(hook, user)
    if hook == C.APTHOOK_ONSLEEP then
        C.CSND_SetPlayState(8, 0)
        C.CSND_SetPlayState(9, 0)
        C.csndExecCmds(false)
    elseif hook == C.APTHOOK_ONEXIT then
        C.CSND_SetPlayState(8, 0)
        C.CSND_SetPlayState(9, 0)
        C.csndExecCmds(false)
    end
end

local function _csndPlaySound(flags, sampleRate, vol, left, right, size)
    local loopMode = bit.band(bit.lshift(flags, 10), 3)
    if loopMode == 0 then
        flags = bit.bor(flags, SOUND_ONE_SHOT)
    end

    local pleft = C.osConvertVirtToPhys(left)
    local pright = C.osConvertVirtToPhys(right)

    local timer = C.CSND_TIMER_WRAPPER(sampleRate)
    if timer < 0x0042 then
        timer = 0x0042
    elseif timer > 0xFFFF then
        timer = 0xFFFF
    end
    flags = bit.band(flags, bit.bnot(0xFFFF001F))
    flags = bit.bor(flags, SOUND_ENABLE, bit.lshift(timer, 16))

    local volumes = C.CSND_VOL_WRAPPER(vol, -1)
    C.CSND_SetChnRegs(bit.bor(flags, C.SOUND_CHANNEL_WRAPPER(8)), pleft, pleft, size, volumes, volumes)
    volumes = C.CSND_VOL_WRAPPER(vol, 1)
    C.CSND_SetChnRegs(bit.bor(flags, C.SOUND_CHANNEL_WRAPPER(9)), pright, pright, size, volumes, volumes)
end

-- mGBA callbacks?

function Audio.gameUnloaded(emu)
    emu = emu or _G.emu
    C.CSND_SetPlayState(8, 0)
    C.CSND_SetPlayState(9, 0)
    C.csndExecCmds(false)
end

function Audio.gameLoaded(emu)
    emu = emu or _G.emu
    local ratio = C.GBAAudioCalculateRatio(1, 59.8260982880808, 1)
    C.blip_set_rates(C._GBCoreGetAudioChannel(emu.core, 0), C._GBCoreFrequency(emu.core), 32768 * ratio)
    C.blip_set_rates(C._GBCoreGetAudioChannel(emu.core, 1), C._GBCoreFrequency(emu.core), 32768 * ratio)

    C.memset(audioLeft, 0, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'));
    C.memset(audioRight, 0, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'));
    _csndPlaySound(bit.bor(SOUND_REPEAT, SOUND_FORMAT_16BIT), 32768, 1.0, audioLeft, audioRight, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'))
    C.csndExecCmds(false)
end

local audioPos = 0
local void = ffi.typeof('void*')
function Audio.setup(emu)
    if not(C.csndInit() == 0) then
        error('couldnt load csnd')
    end
    audioLeft = ffi.cast('uint8_t *', C.linearMemAlign(AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'), 0x80))
    audioRight = ffi.cast('uint8_t *', C.linearMemAlign(AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'), 0x80))
    emu = emu or _G.emu
    emu.stream = ffi.new('struct mAVStream')
    emu.stream.videoDimensionsChanged = nil
    emu.stream.postVideoFrame = nil
    emu.stream.postAudioFrame = nil
    emu.stream.postAudioBuffer = function(stream, left, right)
        ffi.mgba.blip_read_samples(left, void(audioLeft+audioPos), AUDIO_SAMPLES, false)
        C.blip_read_samples(right, void(audioRight+audioPos), AUDIO_SAMPLES, false)
        C.GSPGPU_FlushDataCache(audioLeft+audioPos, AUDIO_SAMPLES * ffi.sizeof('int16_t'))
        C.GSPGPU_FlushDataCache(audioRight+audioPos, AUDIO_SAMPLES * ffi.sizeof('int16_t'))
        audioPos = (audioPos + AUDIO_SAMPLES) % AUDIO_SAMPLE_BUFFER
        if audioPos == AUDIO_SAMPLES * 3 then
            local playing = ffi.new('u8[1]')
            C.csndIsPlaying(0x8, playing)
            if playing[0] == 0 then
                C.CSND_SetPlayState(0x8, 1)
                C.CSND_SetPlayState(0x9, 1)
                C.csndExecCmds(false)
            end
        end
    end
    ffi.mgba._GBCoreSetAVStream(emu.core, emu.stream)
    local cookie = ffi.new('aptHookCookie')
    C.aptHook(cookie, _aptHook, nil) -- callbacks arent supported on 3DS, so this crashes
end

return Audio
