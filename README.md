# Lua Red

## Features

* Full-screen overworld
* Bag editor
* Cheats
* Fixed overworld bike sprite
* In-game Lua console

## Planned Features

* Map editor
* Party/box editor
* Sprite/tile editor
* Actually useful Pokedex (like viewing learnsets)

## Supported platforms

* 3DS
* macOS
* Linux

## IRC chat

[#luared](https://kiwiirc.com/client/irc.freenode.net?channel=#luared) on freenode

## Building

### 3DS

1. Be on macOS or Linux
2. Install LuaJIT
3. Install devkitARM and ctrulib
4. Install [aite](http://github.com/rweichler/aite)
5. Run `aite 3ds`

Then, copy `build/luared.3dsx`, `build/luared.smdh`, the `lua` folder, and the `res` folder to the `/3ds/luared` folder on your SD card.

### macOS / Linux

1. Compile [this mGBA edit](https://github.com/N64N64/mgba) and then copy libmgba.so (or libmgba.dylib if you're on macOS) to `deps/lib/love/` in this repo. Create the directories if they don't exist.
2. Install LuaJIT
3. Install [LÖVE](https://love2d.org/) (0.10.2 or newer)
4. Install [aite](http://github.com/rweichler/aite)
5. Run `aite love`

Open the LÖVE executable with the repo directory to run it.
