# Lua Red

## Supported platforms

* New 3DS
* macOS / Linux / Windows

## IRC chat

[#luared](https://kiwiirc.com/client/irc.freenode.net?channel=#luared) on freenode

## Building

For both platforms, you must supply your own symfile and ROM and place them in the `rom` directory (create it if it does not exist). The symfile must have the same basename as the rom. So, for example, if your ROM was named `example.gb`, your symfile must be named `example.sym`.

### New 3DS

1. Be on macOS or Linux
2. Install LuaJIT
3. Install devkitARM and ctrulib
4. Install [aite](http://github.com/rweichler/aite)
5. Run `aite 3ds`

Then, copy `build/luared.3dsx`, `build/luared.smdh`, the `lua` folder, and the `res` folder to the `/3ds/luared` folder on your SD card.

### macOS / Linux / Windows

1. Compile [this mGBA edit](https://github.com/N64N64/mgba) and then copy libmgba.dll or libmgba.so or libmgba.dylib (depending on your OS) to `deps/lib/love/` in this repo. Create the directories if they don't exist.
2. Install LuaJIT
3. Install zlib
4. Windows: Put [this .dll](https://github.com/N64N64/mgba/releases/download/1/freetype6.dll) in `deps\lib\love`
5. Install [LÖVE](https://love2d.org/) (0.10.2 or newer)
6. Install [aite](http://github.com/rweichler/aite)
7. Run `aite love`

Open the LÖVE executable with the repo directory to run it.
