## Supported platforms

* Old 3DS / New 3DS
* Mac / Linux / Windows

## IRC chat

[#luared](https://kiwiirc.com/client/irc.freenode.net?channel=#luared) on freenode

## Building

For both platforms, you must supply your own symfile and ROM and place them in the `rom` directory (create it if it does not exist). The symfile must have the same basename as the rom. So, for example, if your ROM was named `example.gb`, your symfile must be named `example.sym`.

### 3DS

Linux / Mac only.

1. Install LuaJIT, devkitARM, ctrulib
2. Run `./compile.lua`

Then, copy `build/luared.3dsx`, `build/luared.smdh`, the `lua` folder, and the `res` folder to the `/3ds/luared` folder on your SD card.

### Mac / Linux / Windows

1. Compile [this mGBA edit](https://github.com/N64N64/mgba) and then copy libmgba.dll or libmgba.so or libmgba.dylib (depending on your OS) to `deps/lib/love/` in this repo. Create the directories if they don't exist.
2. Install LuaJIT, zlib, and [löve2d](https://love2d.org/) (0.10.2 or newer)
3. Windows: Put [this .dll](https://github.com/N64N64/mgba/releases/download/1/freetype6.dll) in `deps\lib\love`
4. Run `./compile.lua` (Windows: `luajit.exe compile.lua`)

Open the LÖVE executable with the repo directory to run it.
