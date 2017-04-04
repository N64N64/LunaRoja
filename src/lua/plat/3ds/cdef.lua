function FFI_DLSYM(name)
    return SYMBOLS[name]
end

ffi.mgba = ffi.C
ffi.luared = ffi.C

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

int server_getconnection(int port);
int _listenfd;
int closesocket(int fd);
int gethostname(const char *, size_t);
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
