// ghetto symbol table for LuaJIT ffi

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// macros so it's somewhat easy to edit

#define mgba_symbols(export)                    \
    export(romBuffer);                          \
    export(romBufferSize);                      \
    export(mCoreFind);                          \
    export(mCoreInitConfig);                    \
    export(mCoreConfigLoadDefaults);            \
    export(mCoreLoadFile);                      \
    export(mCoreAutoloadSave);                  \
                                                \
    export(_GBCoreInit);                        \
    export(_GBCoreReset);                       \
    export(_GBCoreDesiredVideoDimensions);      \
    export(_GBCoreSetVideoBuffer);              \
    export(_GBCoreRunFrame);                    \
    export(_GBCoreLoadROM);                     \
    export(_GBCoreLoadSave);                    \
    export(_GBCoreAddKeys);                     \
    export(_GBCoreClearKeys);                   \
                                                \
    export(GBPatch8);                           \
    export(GBView8);                            \
                                                \
    export(VFileOpen);                          \

#define my_symbols(export)                      \
    export(FT_Init_FreeType);                   \
    export(FT_Done_FreeType);                   \
    export(FT_Set_Pixel_Sizes);                 \
    export(FT_Load_Char);                       \
    export(FT_New_Face);                        \
    export(FT_New_Memory_Face);                 \
    export(FT_Done_Face);                       \
    export(FT_Set_Transform);                   \
    export(FT_Get_Char_Index);                  \
    export(FT_Get_First_Char);                  \
    export(FT_Get_Next_Char);                   \
    export(FT_Glyph_Get_CBox);                  \
    export(FT_Done_Glyph);                      \
    export(FT_Outline_Translate);               \
    export(FT_Outline_Copy);                    \
    export(FT_Outline_Transform);               \
    export(FT_Outline_Embolden);                \
    export(FT_Outline_Reverse);                 \
    export(FT_Outline_Get_Orientation);         \
                                                \
    export(untargz);                            \
                                                \
    export(mgba_should_print);                  \
    export(MGBA_ACTIVE_ADDR);                   \
                                                \
    export(closedir);                           \
    export(opendir);                            \
    export(readdir);                            \
                                                \
    export(consoleInit);                        \
    export(aptMainLoop);                        \
    export(gspWaitForEvent);                    \
                                                \
    export(osGetTime);                          \
                                                \
    export(hidScanInput);                       \
    export(hidKeysDown);                        \
    export(hidKeysHeld);                        \
    export(hidKeysUp);                          \
    export(hidTouchRead);                       \
    export(hidCircleRead);                      \
                                                \
    export(gfxInitDefault);                     \
    export(gfxGetFramebuffer);                  \
    export(gfxFlushBuffers);                    \
    export(gfxSwapBuffers);                     \
    export(gfxExit);                            \
                                                \
    export(svcCreateMutex);                     \
    export(svcWaitSynchronization);             \
    export(svcReleaseMutex);                    \
    export(svcCloseHandle);                     \
    export(svcOutputDebugString);               \
                                                \
    export(dumbcopy);                           \
    export(fastcopy);                           \
    export(fastcopyaf);                         \
    export(mgbacopy);                           \
    export(rotatecopy);                         \
    export(scalecopy);                          \
    export(makebgr);                            \
    export(draw_set_color);                     \
    export(draw_pixel);                         \
    export(draw_circle);                        \
    export(draw_line);                          \
    export(draw_rect);                          \
    export(minstride_override);                 \
                                                \
    export(lua_initted_gfx);                    \
                                                \
    export(server_start);                       \
    export(server_listen);                      \
    export(client_start);                       \
    export(client_is_connected);                \
    export(recv);                               \
    export(send);                               \
    export(closesocket);                        \
    export(gethostname);                        \
                                                \
    export(stbi_load);                          \
    export(stbi_failure_reason);                \
    export(stbi_image_free);                    \
                                                \
    export(stbi_write_png);                     \
    export(stbi_write_png_to_func);             \
                                                \
    export(__heap_size);                        \
    export(__linear_heap_size);                 \
                                                \
    export(fseek_wrapper);                      \
    export(mallinfo);                           \

#define builtin_symbols(export)                 \
                                                \
    export(printf);                             \
    export(free);                               \
    export(malloc);                             \
    export(realloc);                            \
    export(calloc);                             \
    export(memcpy);                             \
    export(memset);                             \
    export(strcmp);                             \
    export(memcmp);                             \
    export(strncmp);                            \
                                                \
    export(fseek);                              \
    export(rewind);                             \
    export(fopen);                              \
    export(fread);                              \
    export(fclose);                             \
    export(ftell);                              \

// declare the symbols in C
// this creates a lot of warnings when linking but whatever

#define void_bind(symbol) void *symbol
my_symbols(void_bind);
#ifdef USE_MGBA
mgba_symbols(void_bind);
#endif

// declare them in Lua

#define lua_bind(symbol) do {               \
    lua_pushstring(L, #symbol);             \
    lua_pushnumber(L, (uintptr_t)&symbol);  \
    lua_settable(L, -3);                    \
} while(0)

void export_symbols(lua_State *L)
{
    lua_newtable(L);
    my_symbols(lua_bind);
    builtin_symbols(lua_bind);
#ifdef USE_MGBA
    mgba_symbols(lua_bind);
#endif
    lua_setglobal(L, "SYMBOLS");
}
