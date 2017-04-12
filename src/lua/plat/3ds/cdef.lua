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
typedef uint8_t u8;
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
