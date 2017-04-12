#ifdef USE_MGBA
#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>
#include <stdbool.h>

static lua_State *L = NULL;

bool aaas_call_callback(int callback)
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, callback);
    lua_pcall(L, 0, 1, 0);
    if(lua_isboolean(L, -1) && lua_toboolean(L, -1)) {
        return true;
    } else {
        return false;
    }
}

void aaas_add_pc_hook(int bank, int pc, int callback);
int l_aaas_add_pc_hook(lua_State *l)
{
    L = l;
    if(!lua_isnumber(L, 1) || !lua_isnumber(L, 2) || !lua_isfunction(L, 3)) {
        return luaL_error(L, "invalid arguments");
    }
    lua_pushvalue(L, 3);
    aaas_add_pc_hook(lua_tonumber(L, 1), lua_tonumber(L, 2), luaL_ref(L, LUA_REGISTRYINDEX));
    return 0;
}

static int postAudioBufferFunc = -1;
void aaas_postAudioBuffer(void *arg1, void *arg2, void *arg3)
{
    if(postAudioBufferFunc == -1) {
        return;
    }
    lua_rawgeti(L, LUA_REGISTRYINDEX, postAudioBufferFunc);
    lua_pushlightuserdata(L, arg1);
    lua_pushlightuserdata(L, arg2);
    lua_pushlightuserdata(L, arg3);
    lua_pcall(L, 3, 0, 0);
}

int l_aaas_set_postAudioBuffer(lua_State *L)
{
    if(!lua_isfunction(L, 1)) {
        return luaL_error(L, "expected function");
    }
    lua_pushvalue(L, 1);
    postAudioBufferFunc = luaL_ref(L, LUA_REGISTRYINDEX);
    return 0;
}

#endif
