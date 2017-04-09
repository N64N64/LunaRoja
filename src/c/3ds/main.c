#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#include <3ds.h>
#include <3ds/srv.h>
#include <3ds/gfx.h>
#include <3ds/sdmc.h>
#include <3ds/services/apt.h>
#include <3ds/services/fs.h>
#include <3ds/services/hid.h>

#include <sys/socket.h>

#define SOCU_ALIGN      0x1000
#define SOCU_BUFFERSIZE 0x100000

bool lua_initted_gfx = false;

#ifdef USE_MGBA
uint32_t* romBuffer;
size_t romBufferSize;
int l_aaas_add_pc_hook(lua_State *l);
#endif
void export_symbols(lua_State *L);

int main(int argc, char **argv)
{
    //FSUSER_OpenArchive(&sdmcArchive, ARCHIVE_SDMC, fsMakePath(PATH_EMPTY, ""));

    u32 *SOCU_buffer = (u32*)memalign(SOCU_ALIGN, SOCU_BUFFERSIZE);
    if(socInit(SOCU_buffer, SOCU_BUFFERSIZE) != 0) {
        return 1;
    }

    srvInit();
    aptInit();
    hidInit();

    fsInit();
    sdmcInit();
#ifdef USE_MGBA
    // 2 MB should be enough
    romBufferSize = 2 * 1024 * 1024;
    romBuffer = malloc(romBufferSize);
#endif

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
#ifdef USE_MGBA
    lua_pushcfunction(L, l_aaas_add_pc_hook);
    lua_setglobal(L, "PC_HOOK");
#endif
    export_symbols(L);

    bool success = luaL_dofile(L, "/3ds/luared/lua/plat/3ds/init.lua") == 0;
    if(!success) {
        // file errored
    }

    if(lua_isboolean(L, -1) && lua_toboolean(L, -1) == true) {
        // successfully exited, don't do anything
    } else {
        const char *msg = lua_tostring(L, -1);
        lua_close(L);
        L = NULL;
        if(!lua_initted_gfx) {
            gfxInitDefault();
        }
        consoleInit(GFX_TOP, NULL);
        printf("\x1b[00;00HLua died :( Press start to exit\n\n");
        printf("%s\n", msg);
        while(aptMainLoop()) {
            hidScanInput();
            u32 kDown = hidKeysDown();
            if (kDown & KEY_START) break;

            gfxFlushBuffers();
            gfxSwapBuffers();
            gspWaitForVBlank();
        }
    }
    gfxExit();
    socExit();
    srvExit();
    aptExit();
    hidExit();
    fsExit();
    sdmcExit();
    return 0;
}

extern char* fake_heap_start;
extern char* fake_heap_end;
extern u32 __ctru_linear_heap;
extern u32 __ctru_heap;
extern u32 __ctru_heap_size;
extern u32 __ctru_linear_heap_size;
static u32 __custom_heap_size = 0x03600000 * 4 / 4;
static u32 __custom_linear_heap_size = 0x01400000;

void __system_allocateHeaps() {
    u32 tmp=0;

    __ctru_heap_size = __custom_heap_size;
    __ctru_linear_heap_size = __custom_linear_heap_size;

    // Allocate the application heap
    __ctru_heap = 0x08000000;
    svcControlMemory(&tmp, __ctru_heap, 0x0, __ctru_heap_size, MEMOP_ALLOC, MEMPERM_READ | MEMPERM_WRITE);

#if 0
    Handle handle;
    svcDuplicateHandle(&handle, CUR_PROCESS_HANDLE);
    svcControlProcessMemory(handle, tmp, 0x0, __ctru_heap_size, MEMOP_PROT, MEMPERM_READ | MEMPERM_WRITE | MEMPERM_EXECUTE);
#endif

    // Allocate the linear heap
    svcControlMemory(&__ctru_linear_heap, 0x0, 0x0, __ctru_linear_heap_size, MEMOP_ALLOC_LINEAR, MEMPERM_READ | MEMPERM_WRITE);
    // Set up newlib heap
    fake_heap_start = (char*)__ctru_heap;
    fake_heap_end = fake_heap_start + __ctru_heap_size;
}
