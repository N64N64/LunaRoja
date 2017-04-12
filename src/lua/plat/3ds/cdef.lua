function FFI_DLSYM(name)
    return SYMBOLS[name]
end

ffi.mgba = ffi.C
ffi.luared = ffi.C
ffi.freetype = ffi.C

SEEK_END = 2
SEEK_SET = 0

GFX_TOP = 0
GFX_BOTTOM = 1
GFX_LEFT = 0
GFX_RIGHT = 1
GSPGPU_EVENT_VBlank0 = 2

O_CREAT = 0x0200
O_RDWR = 2

ffi.cdef[[

// mgba

uint32_t* romBuffer;
size_t romBufferSize;

// ctru

void gfxInitDefault();
void gfxFlushBuffers();
void gfxSwapBuffers();
void gfxExit();
uint8_t *gfxGetFramebuffer(int, int, uint16_t *, uint16_t *);

void* consoleInit(int screen, void *console);
bool aptMainLoop();
void gspWaitForEvent(int id, bool nextEvent);

typedef struct
{
	uint16_t px;
	uint16_t py;
} touchPosition;

uint64_t osGetTime();

void hidTouchRead(touchPosition* pos);
void hidScanInput();
uint32_t hidKeysDown();
uint32_t hidKeysHeld();
uint32_t hidKeysUp();

int svcOutputDebugString(const char* str, int length);

extern uint32_t __heap_size;
extern uint32_t __linear_heap_size;

// my stuff

void aaas_postAudioBuffer(struct mAVStream*, blip_t* left, blip_t* right);
bool lua_initted_gfx;
bool lua_exited_gfx;

// mallinfo

struct mallinfo {
	int arena;     /* Non-mmapped space allocated (bytes) */
	int ordblks;   /* Number of free chunks */
	int smblks;    /* Number of free fastbin blocks */
	int hblks;     /* Number of mmapped regions */
	int hblkhd;    /* Space allocated in mmapped regions (bytes) */
	int usmblks;   /* Maximum total allocated space (bytes) */
	int fsmblks;   /* Space in freed fastbin blocks (bytes) */
	int uordblks;  /* Total allocated space (bytes) */
	int fordblks;  /* Total free space (bytes) */
	int keepcost;  /* Top-most, releasable space (bytes) */
};
struct mallinfo mallinfo(void);

// directory

typedef unsigned int ino_t;
struct dirent {
    ino_t d_ino;
    unsigned char d_type;
    char d_name[768+1]; // NAME_MAX=768
};

typedef void DIR;

int closedir(DIR *dirp);
DIR *opendir(const char *dirname);
struct dirent *readdir(DIR *dirp);

]]




ffi.cdef[[
/// APT hook types.
typedef enum {
	APTHOOK_ONSUSPEND = 0, ///< App suspended.
	APTHOOK_ONRESTORE,     ///< App restored.
	APTHOOK_ONSLEEP,       ///< App sleeping.
	APTHOOK_ONWAKEUP,      ///< App waking up.
	APTHOOK_ONEXIT,        ///< App exiting.

	APTHOOK_COUNT,         ///< Number of APT hook types.
} APT_HookType;


typedef uint32_t u32;
typedef int32_t s32;

typedef uint16_t u16;
typedef int16_t s16;

typedef uint8_t u8;
typedef int8_t s8;

typedef u32 Result;
typedef struct tag_aptHookCookie {
	struct tag_aptHookCookie* next; ///< Next cookie.
} aptHookCookie;
typedef void (*aptHookFn)(APT_HookType hook, void* param);

/// CSND encodings.
enum
{
	CSND_ENCODING_PCM8 = 0, ///< PCM8
	CSND_ENCODING_PCM16,    ///< PCM16
	CSND_ENCODING_ADPCM,    ///< IMA-ADPCM
	CSND_ENCODING_PSG,      ///< PSG (Similar to DS?)
};

/// CSND loop modes.
enum
{
	CSND_LOOPMODE_MANUAL = 0, ///< Manual loop.
	CSND_LOOPMODE_NORMAL,     ///< Normal loop.
	CSND_LOOPMODE_ONESHOT,    ///< Do not loop.
	CSND_LOOPMODE_NORELOAD,   ///< Don't reload.
};

u32 SOUND_CHANNEL_WRAPPER(u32 n);
u32 SOUND_FORMAT_WRAPPER(u32 n);
u32 SOUND_LOOPMODE_WRAPPER(u32 n);

void aptHook(aptHookCookie* cookie, aptHookFn callback, void* param);
void* linearMemAlign(size_t size, size_t alignment);
Result GSPGPU_FlushDataCache(const void* adr, u32 size);
void CSND_SetChnRegs(u32 flags, u32 physaddr0, u32 physaddr1, u32 totalbytesize, u32 chnVolumes, u32 capVolumes);
uint32_t CSND_TIMER_WRAPPER(uint32_t n);
uint32_t CSND_VOL_WRAPPER(float vol, float pan);
void CSND_SetPlayState(u32 channel, u32 value);
u32 osConvertVirtToPhys(const void* vaddr);
Result csndExecCmds(bool waitDone);
Result csndIsPlaying(u32 channel, u8* status);
Result csndInit(void);
void csndExit();
]]


ffi.cdef[[
///@name Data types
///@{
/// Supported sample encodings.
enum
{
	NDSP_ENCODING_PCM8 = 0, ///< PCM8
	NDSP_ENCODING_PCM16,    ///< PCM16
	NDSP_ENCODING_ADPCM,    ///< DSPADPCM (GameCube format)
};
/// Interpolation types.
typedef enum
{
	NDSP_INTERP_POLYPHASE = 0, ///< Polyphase interpolation
	NDSP_INTERP_LINEAR    = 1, ///< Linear interpolation
	NDSP_INTERP_NONE      = 2, ///< No interpolation
} ndspInterpType;
]]

ffi.cdef[[
///@name Data types
///@{
/// Sound output modes.
typedef enum
{
	NDSP_OUTPUT_MONO     = 0, ///< Mono sound
	NDSP_OUTPUT_STEREO   = 1, ///< Stereo sound
	NDSP_OUTPUT_SURROUND = 2, ///< 3D Surround sound
} ndspOutputMode;

// Clipping modes.
typedef enum
{
	NDSP_CLIP_NORMAL = 0, ///< "Normal" clipping mode (?)
	NDSP_CLIP_SOFT   = 1, ///< "Soft" clipping mode (?)
} ndspClippingMode;

// Surround speaker positions.
typedef enum
{
	NDSP_SPKPOS_SQUARE = 0, ///<?
	NDSP_SPKPOS_WIDE   = 1, ///<?
	NDSP_SPKPOS_NUM    = 2, ///<?
} ndspSpeakerPos;

/// ADPCM data.
typedef struct
{
	u16 index;    ///< Current predictor index
	s16 history0; ///< Last outputted PCM16 sample.
	s16 history1; ///< Second to last outputted PCM16 sample.
} ndspAdpcmData;

/// Wave buffer type.
typedef struct tag_ndspWaveBuf ndspWaveBuf;

/// Wave buffer status.
enum
{
	NDSP_WBUF_FREE    = 0, ///< The wave buffer is not queued.
	NDSP_WBUF_QUEUED  = 1, ///< The wave buffer is queued and has not been played yet.
	NDSP_WBUF_PLAYING = 2, ///< The wave buffer is playing right now.
	NDSP_WBUF_DONE    = 3, ///< The wave buffer has finished being played.
};

/// Wave buffer struct.
struct tag_ndspWaveBuf
{
	union
	{
		s8*         data_pcm8;  ///< Pointer to PCM8 sample data.
		s16*        data_pcm16; ///< Pointer to PCM16 sample data.
		u8*         data_adpcm; ///< Pointer to DSPADPCM sample data.
		const void* data_vaddr; ///< Data virtual address.
	};
	u32 nsamples;              ///< Total number of samples (PCM8=bytes, PCM16=halfwords, DSPADPCM=nibbles without frame headers)
	ndspAdpcmData* adpcm_data; ///< ADPCM data.

	u32  offset;  ///< Buffer offset. Only used for capture.
	bool looping; ///< Whether to loop the buffer.
	u8   status;  ///< Queuing/playback status.

	u16 sequence_id;   ///< Sequence ID. Assigned automatically by ndspChnWaveBufAdd.
	ndspWaveBuf* next; ///< Next buffer to play. Used internally, do not modify.
};

Result ndspInit(void);
void ndspSetOutputMode(ndspOutputMode mode);
void ndspSetOutputCount(int count);
void ndspChnReset(int id);
void ndspChnSetFormat(int id, u16 format);
void ndspChnSetInterp(int id, ndspInterpType type);
void ndspChnSetRate(int id, float rate);
void ndspChnWaveBufClear(int id);
Result DSP_FlushDataCache(const void* address, u32 size);
void ndspChnWaveBufAdd(int id, ndspWaveBuf* buf);
]]
