-- translated from mgba/src/platform/3ds/main.c

local CSND = false
local NDSP = true

local Audio = {}

local AUDIO_SAMPLES = 384
local AUDIO_SAMPLE_BUFFER = AUDIO_SAMPLES * 16
local DSP_BUFFERS = 4
local audioLeft, audioRight

local SOUND_REPEAT = C.SOUND_LOOPMODE_WRAPPER(C.CSND_LOOPMODE_NORMAL)
local SOUND_FORMAT_16BIT = C.SOUND_FORMAT_WRAPPER(C.CSND_ENCODING_PCM16) --> PCM16
local SOUND_ENABLE = bit.lshift(1, 14)
local SOUND_ONE_SHOT = C.SOUND_LOOPMODE_WRAPPER(C.CSND_LOOPMODE_ONESHOT) --> Play the sound once.

local dspBuffer = ffi.new('ndspWaveBuf[?]', DSP_BUFFERS)
local bufferId = 0

local function BIT(n)
    return bit.lshift(1, n)
end

local function NDSP_CHANNELS(n)
    return bit.band(n, 3)
end

local function NDSP_ENCODING(n)
    return bit.lshift(bit.band(n, 3), 2)
end

local NDSP_FORMAT_MONO_PCM8    = bit.bor(NDSP_CHANNELS(1),  NDSP_ENCODING(C.NDSP_ENCODING_PCM8))  --> Buffer contains Mono   PCM8.
local NDSP_FORMAT_MONO_PCM16   = bit.bor(NDSP_CHANNELS(1),  NDSP_ENCODING(C.NDSP_ENCODING_PCM16)) --> Buffer contains Mono   PCM16.
local NDSP_FORMAT_MONO_ADPCM   = bit.bor(NDSP_CHANNELS(1),  NDSP_ENCODING(C.NDSP_ENCODING_ADPCM)) --> Buffer contains Mono   ADPCM.
local NDSP_FORMAT_STEREO_PCM8  = bit.bor(NDSP_CHANNELS(2),  NDSP_ENCODING(C.NDSP_ENCODING_PCM8))  --> Buffer contains Stereo PCM8.
local NDSP_FORMAT_STEREO_PCM16 = bit.bor(NDSP_CHANNELS(2),  NDSP_ENCODING(C.NDSP_ENCODING_PCM16)) --> Buffer contains Stereo PCM16.

local NDSP_FORMAT_PCM8  = NDSP_FORMAT_MONO_PCM8  --> (Alias) Buffer contains Mono PCM8.
local NDSP_FORMAT_PCM16 = NDSP_FORMAT_MONO_PCM16 --> (Alias) Buffer contains Mono PCM16.
local NDSP_FORMAT_ADPCM = NDSP_FORMAT_MONO_ADPCM --> (Alias) Buffer contains Mono ADPCM.

-- Flags
local NDSP_FRONT_BYPASS             = BIT(4) --> Front bypass.
local NDSP_3D_SURROUND_PREPROCESSED = BIT(6) --> (?) Unknown, under research

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

    if NDSP then
        C.memset(audioLeft, 0, AUDIO_SAMPLE_BUFFER * 2 * ffi.sizeof('int16_t'));
    elseif CSND then
        C.memset(audioLeft, 0, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'));
        C.memset(audioRight, 0, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'));
        _csndPlaySound(bit.bor(SOUND_REPEAT, SOUND_FORMAT_16BIT), 32768, 1.0, audioLeft, audioRight, AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'))
        C.csndExecCmds(false)
    end
end

local audioPos = 0
local void = ffi.typeof('void*')
function Audio.setup(emu)
    emu = emu or _G.emu
    emu.stream = ffi.new('struct mAVStream')
    emu.stream.videoDimensionsChanged = nil
    emu.stream.postVideoFrame = nil
    emu.stream.postAudioFrame = nil
    emu.stream.postAudioBuffer = C.aaas_postAudioBuffer
    if NDSP then
        if not(NDSP_ON or C.ndspInit() == 0) then
            error('ndsp doesnt want u')
        end
        C.ndspSetOutputMode(C.NDSP_OUTPUT_STEREO);
        C.ndspSetOutputCount(1);
        C.ndspChnReset(0);
        C.ndspChnSetFormat(0, NDSP_FORMAT_STEREO_PCM16);
        C.ndspChnSetInterp(0, C.NDSP_INTERP_NONE);
        C.ndspChnSetRate(0, 0x8000);
        C.ndspChnWaveBufClear(0);
        audioLeft = ffi.cast('uint8_t *', C.linearMemAlign(AUDIO_SAMPLES * DSP_BUFFERS * 2 * ffi.sizeof('int16_t'), 0x80))
        C.memset(dspBuffer, 0, ffi.sizeof(dspBuffer));
        for i=0,DSP_BUFFERS-1 do
            dspBuffer[i].data_pcm16 = ffi.cast('short  *', audioLeft+AUDIO_SAMPLES*i*2)
            dspBuffer[i].nsamples = AUDIO_SAMPLES;
        end
        SET_POSTAUDIOBUFFER(function (stream, left, right)
            local startId = bufferId
            while dspBuffer[bufferId].status == C.NDSP_WBUF_QUEUED or dspBuffer[bufferId].status == C.NDSP_WBUF_PLAYING do
                bufferId = bit.band(bufferId + 1, DSP_BUFFERS - 1)
                if bufferId == startId then
                    C.blip_clear(left)
                    C.blip_clear(right)
                end
            end
            local tmpBuf = dspBuffer[bufferId].data_pcm16
            C.memset(dspBuffer+bufferId, 0, ffi.sizeof(dspBuffer[bufferId]))
            dspBuffer[bufferId].data_pcm16 = tmpBuf
            dspBuffer[bufferId].nsamples = AUDIO_SAMPLES
            C.blip_read_samples(left, dspBuffer[bufferId].data_pcm16, AUDIO_SAMPLES, true)
            C.blip_read_samples(right, dspBuffer[bufferId].data_pcm16 + 1, AUDIO_SAMPLES, true)
            C.DSP_FlushDataCache(dspBuffer[bufferId].data_pcm16, AUDIO_SAMPLES * 2 * ffi.sizeof('int16_t'))
            C.ndspChnWaveBufAdd(0, dspBuffer+bufferId)
        end)
    elseif CSND then
        audioLeft = ffi.cast('uint8_t *', C.linearMemAlign(AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'), 0x80))
        audioRight = ffi.cast('uint8_t *', C.linearMemAlign(AUDIO_SAMPLE_BUFFER * ffi.sizeof('int16_t'), 0x80))
        SET_POSTAUDIOBUFFER(function (stream, left, right)
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
        end)
    end
    ffi.mgba._GBCoreSetAVStream(emu.core, emu.stream)
    local cookie = ffi.new('aptHookCookie')
    --C.aptHook(cookie, _aptHook, nil) -- callbacks arent supported on 3DS, so this crashes
end

return Audio
