// ghetto symbol table for LuaJIT ffi

#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <malloc.h>
#include <dirent.h>
#include <string.h>

#ifdef USE_MGBA
#include <mgba/core/core.h>
#include <mgba/gb/memory.h>
#include <mgba/util/vfs.h>
#endif

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#include "stb/stb_image.h"
#include "stb/stb_image_write.h"

#include <3ds.h>

#include "export_freetype.h"

// zip.c
bool untargz(const char *filename, const char *outfolder);
// main.c
bool lua_initted_gfx;

// font.c
void * font_create(const char *path);
void font_dimensions(void *font, const char *text, int size, int *outwidth, int *outheight);
uint8_t * font_render(void *font, const char *text, int size, int *outwidth, int *outheight);

// draw.c
bool fastcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int  inh);
bool dumbcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, int stride);
bool fastcopyaf(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int  inh, uint8_t invis);
bool mgbacopy(uint8_t *out, int outw, int outh, int outx, int outy,
              uint8_t *in,  int inw,  int inh,  int  inx, int  iny);
int minstride_override;
bool rotatecopy(uint8_t *out, int outw, int outh, int outstride, int outx, int outy,
                uint8_t *in,  int inw,  int inh,  int instride,  int inx,  int iny);
bool scalecopy(uint8_t *out, uint8_t *in, int width, int height, float scale);
void makebgr(uint8_t *pix, int width, int height, int channels);
void draw_set_color(uint8_t r, uint8_t g, uint8_t b);
bool draw_pixel(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy);
void draw_circle(uint8_t *fb, int fbwidth, int fbheight, float x0, float y0, float radius, bool should_outline);
void draw_line(uint8_t *fb, int fbwidth, int fbheight, float x1, float y1, float x2, float y2);
void draw_rect(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy, float fwidth, float fheight);

// net.c
int client_start(const char *ip, const char *port);
bool client_is_connected(int fd);
int server_start(int port);
int server_listen(int listenfd);

// wrappers.c
int fseek_wrapper(FILE *f, long offset, int whence);


// mgba
#ifdef USE_MGBA
uint32_t* romBuffer;
size_t romBufferSize;
void _GBCoreReset(struct mCore* core);
bool _GBCoreInit(struct mCore* core);
void _GBCoreDesiredVideoDimensions(struct mCore* core, unsigned* width, unsigned* height);
void _GBCoreSetVideoBuffer(struct mCore* core, color_t* buffer, size_t stride);
bool _GBCoreLoadROM(struct mCore* core, struct VFile* vf);
void _GBCoreRunFrame(struct mCore* core);
void _GBCoreRunFrame(struct mCore* core);
bool _GBCoreLoadSave(struct mCore* core, struct VFile* vf);
void _GBCoreAddKeys(struct mCore* core, uint32_t keys);
void _GBCoreClearKeys(struct mCore* core, uint32_t keys);

bool allocateRomBuffer(void);
#endif

// libctru
extern uint32_t __heap_size;
extern uint32_t __linear_heap_size;


#define export(symbol) do {                 \
    lua_pushstring(L, #symbol);             \
    lua_pushnumber(L, (uintptr_t)&symbol);  \
    lua_settable(L, -3);                    \
} while(0)

extern bool mgba_should_print;
extern uint16_t MGBA_ACTIVE_ADDR;
void export_symbols(lua_State *L)
{
    lua_newtable(L);

    // TODO
    export(FT_Init_FreeType);
    export(FT_Done_FreeType);
    export(FT_Set_Pixel_Sizes);
    export(FT_Load_Char);
    export(FT_New_Face);
    export(FT_New_Memory_Face);
    export(FT_Done_Face);
    export(FT_Set_Transform);
    export(FT_Get_Char_Index);
    export(FT_Get_First_Char);
    export(FT_Get_Next_Char);
    export(FT_Glyph_Get_CBox);
    export(FT_Done_Glyph);
    export(FT_Outline_Translate);
    export(FT_Outline_Copy);
    export(FT_Outline_Transform);
    export(FT_Outline_Embolden);
    export(FT_Outline_Reverse);
    export(FT_Outline_Get_Orientation);

    export(untargz);

    export(mgba_should_print);
    export(MGBA_ACTIVE_ADDR);

    export(closedir);
    export(opendir);
    export(readdir);

    export(consoleInit);
    export(aptMainLoop);
    export(gspWaitForEvent);

    export(osGetTime);

    export(hidScanInput);
    export(hidKeysDown);
    export(hidKeysHeld);
    export(hidKeysUp);
    export(hidTouchRead);
    export(hidCircleRead);

    export(gfxInitDefault);
    export(gfxGetFramebuffer);
    export(gfxFlushBuffers);
    export(gfxSwapBuffers);
    export(gfxExit);

    export(printf);
    export(free);
    export(malloc);
    export(realloc);
    export(calloc);
    export(memcpy);
    export(memset);
    export(strcmp);
    export(memcmp);
    export(strncmp);

    export(fseek_wrapper); // TODO
    export(fseek);
    export(rewind);
    export(fopen);
    export(fread);
    export(fclose);
    export(ftell);

#ifdef USE_MGBA
    export(romBuffer);
    export(romBufferSize);
    export(mCoreFind);
    export(mCoreInitConfig);
    export(mCoreConfigLoadDefaults);
    export(mCoreLoadFile);
    export(mCoreAutoloadSave);

    export(_GBCoreInit);
    export(_GBCoreReset);
    export(_GBCoreDesiredVideoDimensions);
    export(_GBCoreSetVideoBuffer);
    export(_GBCoreRunFrame);
    export(_GBCoreLoadROM);
    export(_GBCoreLoadSave);
    export(_GBCoreAddKeys);
    export(_GBCoreClearKeys);

    export(GBPatch8);
    export(GBView8);

    export(VFileOpen);
#endif

    export(svcCreateMutex);
    export(svcWaitSynchronization);
    export(svcReleaseMutex);
    export(svcCloseHandle);
    export(svcOutputDebugString);

    // my stuff

    export(dumbcopy);
    export(fastcopy);
    export(fastcopyaf);
    export(mgbacopy);
    export(rotatecopy);
    export(scalecopy);
    export(makebgr);
    export(draw_set_color);
    export(draw_pixel);
    export(draw_circle);
    export(draw_line);
    export(draw_rect);
    export(minstride_override);

    export(lua_initted_gfx);

    export(server_start);
    export(server_listen);
    export(client_start);
    export(client_is_connected);

    export(recv);
    export(send);
    export(closesocket);
    export(gethostname);

    export(stbi_load);
    export(stbi_failure_reason);
    export(stbi_image_free);

    export(stbi_write_png);
    export(stbi_write_png_to_func);

    export(__heap_size);
    export(__linear_heap_size);

    export(mallinfo);


    lua_setglobal(L, "SYMBOLS");
}
