-- translated from mgba/src/platform/3ds/main.c

local CSND = false
local NDSP = true

local Audio = {}

local AUDIO_SAMPLES = 384
local AUDIO_SAMPLE_BUFFER = AUDIO_SAMPLES * 16
local DSP_BUFFERS = 4
local linearData

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

function Audio.gameLoaded(emu)
    emu = emu or _G.emu
    local ratio = C.GBAAudioCalculateRatio(1, 59.8260982880808, 1)
    C.blip_set_rates(C._GBCoreGetAudioChannel(emu.core, 0), C._GBCoreFrequency(emu.core), 32768 * ratio)
    C.blip_set_rates(C._GBCoreGetAudioChannel(emu.core, 1), C._GBCoreFrequency(emu.core), 32768 * ratio)

    ffi.fill(linearData, AUDIO_SAMPLE_BUFFER * 2 * ffi.sizeof('s16'));
end

local audioPos = 0
local void = ffi.typeof('void*')
function Audio.setup(emu)
    if not NDSP_ON then
        error('ndsp doesnt want u')
    end

    emu = emu or _G.emu
    emu.stream = ffi.new('struct mAVStream')
    emu.stream.videoDimensionsChanged = nil
    emu.stream.postVideoFrame = nil
    emu.stream.postAudioFrame = nil
    emu.stream.postAudioBuffer = C.aaas_postAudioBuffer
    ffi.mgba._GBCoreSetAVStream(emu.core, emu.stream)

    C.ndspSetOutputMode(C.NDSP_OUTPUT_STEREO);
    C.ndspSetOutputCount(1);
    C.ndspChnReset(0);
    C.ndspChnSetFormat(0, NDSP_FORMAT_STEREO_PCM16);
    C.ndspChnSetInterp(0, C.NDSP_INTERP_NONE);
    C.ndspChnSetRate(0, 0x8000);
    C.ndspChnWaveBufClear(0);
    linearData = ffi.cast('s16 *', C.linearMemAlign(AUDIO_SAMPLES * DSP_BUFFERS * 2 * ffi.sizeof('s16'), 0x80))
    ffi.fill(dspBuffer, ffi.sizeof(dspBuffer))
    for i=0,DSP_BUFFERS-1 do
        dspBuffer[i].data_pcm16 = linearData+AUDIO_SAMPLES*i
        dspBuffer[i].nsamples = AUDIO_SAMPLES;
    end
    SET_POSTAUDIOBUFFER(function (stream, left, right)
        local success, err = xpcall(function()
            local startId = bufferId
            while dspBuffer[bufferId].status == C.NDSP_WBUF_QUEUED or dspBuffer[bufferId].status == C.NDSP_WBUF_PLAYING do
                bufferId = bit.band(bufferId + 1, DSP_BUFFERS - 1)
                if bufferId == startId then
                    C.blip_clear(left)
                    C.blip_clear(right)
                    return
                end
            end
            local tmpBuf = dspBuffer[bufferId].data_pcm16
            ffi.fill(dspBuffer+bufferId, ffi.sizeof(dspBuffer[bufferId]))
            dspBuffer[bufferId].data_pcm16 = tmpBuf
            dspBuffer[bufferId].nsamples = AUDIO_SAMPLES
            C.blip_read_samples(left, dspBuffer[bufferId].data_pcm16, AUDIO_SAMPLES, true)
            C.blip_read_samples(right, dspBuffer[bufferId].data_pcm16 + 1, AUDIO_SAMPLES, true)
            if RENDER_AUDIO then
                RENDER_AUDIO(dspBuffer[bufferId].data_pcm16, AUDIO_SAMPLES)
            end
            C.DSP_FlushDataCache(dspBuffer[bufferId].data_pcm16, AUDIO_SAMPLES * 2 * ffi.sizeof('s16'))
            C.ndspChnWaveBufAdd(0, dspBuffer+bufferId)
        end, debug.traceback)
        if not success then
            ERROR = err
            SHOULD_QUIT = true
        end
    end)
end

return Audio
