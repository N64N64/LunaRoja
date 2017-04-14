local super = Object
Ogg = Object.new(super)

-- this doesnt work

-- int stb_vorbis_decode_memory(const uint8 *mem, int len, int *channels, int *sample_rate, short **output);

function Ogg:new(path)
    if created[path] then
        return created[path]
    end
    local self = super.new(self)

    local int = ffi.new('int[2]')
    local output = ffi.new('short *[1]')

    local bin = io.readbin(path)
    self.len = C.stb_vorbis_decode_memory(bin, ffi.sizeof(bin), int+0, int+1, output)
    if self.len <= 0 then
        error('couldnt open file: '..self.len)
    end

    self.channels = int[0]
    self.sample_rate = int[1]
    self.data = output[0]

    return SETGC(self, function()
        C.free(output[0])
    end)
end

function Ogg:play()
    if PLAYING_SOUND then
        error('already playing')
    end
    PLAYING_SOUND = true
    UPDATE_CALLBACKS.ogg = function()
        local startId = bufferId
        while dspBuffer[bufferId].status == C.NDSP_WBUF_QUEUED or dspBuffer[bufferId].status == C.NDSP_WBUF_PLAYING do
            bufferId = bit.band(bufferId + 1, DSP_BUFFERS - 1)
            if bufferId == startId then
                return
            end
        end
        local tmpBuf = dspBuffer[bufferId].data_pcm16
        ffi.fill(dspBuffer+bufferId, ffi.sizeof(dspBuffer[bufferId]))
        dspBuffer[bufferId].data_pcm16 = tmpBuf
        dspBuffer[bufferId].nsamples = AUDIO_SAMPLES

        local len = math.min(self.len, AUDIO_SAMPLES * 2 * ffi.sizeof('s16'))
        ffi.copy(tmpBuf, self.data, len)
        C.DSP_FlushDataCache(tmpBuf, len)
        C.ndspChnWaveBufAdd(0, dspBuffer+bufferId)

        self.len = self.len - len
        self.data = self.data + len

        if self.len == 0 then
            PLAYING_SOUND = false
            UPDATE_CALLBACKS.ogg = nil
        end
    end
end


return Ogg
