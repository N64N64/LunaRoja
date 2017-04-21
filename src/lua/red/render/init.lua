SPRITE_INVIS_COLOR = 0x01

require 'red.render.dialogue'
require 'red.render.custom_sprites'
require 'red.render.map'
require 'red.render.battle'
require 'red.render.bpp'
require 'red.render.sprite'

-- this code is disgusting, needs refactor

Red.Camera = {}
Red.Camera.x = Screen.top.width/2 - 8
Red.Camera.y = Screen.top.height/2 - 8

local lastwalkcount
local sevencount = 0
function get_player_coords()
    local self = Red

    local walkcount = self.wram.wWalkCounter
    if walkcount == 7 then
        -- wWalkCounter is 7 three times when biking
        -- and 2 times while walking
        sevencount = sevencount + 1
    end
    if walkcount == 0 then
        walkcount = 8
        lastwalkcount = 8
        sevencount = 0
    elseif walkcount == lastwalkcount then
        -- get dat sexy 60fps
        if not(sevencount == 3) or walkcount == 7 then -- walking (or still in 7s)
            walkcount = walkcount - 0.5
        else -- biking
            walkcount = walkcount - 1
        end
    else
        lastwalkcount = walkcount
    end
    local speed = (8 - walkcount)*2

    local dir = self.wram.wPlayerMovingDirection
    local diffx, diffy = 0, 0
    if dir == 8 then -- up
        diffy = -speed
    elseif dir == 4 then -- down
        diffy = speed
    elseif dir == 2 then -- left
        diffx = -speed
    elseif dir == 1 then -- right
        diffx = speed
    end

    Red.diffx = diffx
    Red.diffy = diffy

    return math.floor(self.wram.wXCoord * 16 + diffx), math.floor(self.wram.wYCoord * 16 + diffy)
end

function randomizerainbow()
    local function r()
        return math.floor(math.random()*0x100)
    end

    Rainbow = {
        {r(), r(), r()},
        {r(), r(), r()},
        {r(), r(), r()},
        {r(), r(), r()},
    }
end
ROOT.colors = {}
ROOT.colors.randomize = function()
    randomizerainbow()
    Red.tiles = {}
    Red.blocks = {}
    if Red then
        Red.sprites = {}
    end
    collectgarbage()
end

local rainbows
local f = io.open(LUAPATH..'/config/rainbows')
if f then
    f:close()
    rainbows = require 'config.rainbows'
else
    rainbows = require 'default_config.rainbows'
end

local current_rainbow
ROOT.colors.cycle = function(first)
    if not current_rainbow or current_rainbow >= #rainbows then
        current_rainbow = 0
    end
    current_rainbow = current_rainbow + 1

    Rainbow = rainbows[current_rainbow]
    if not first then
        Red.tiles = {}
        Red.blocks = {}
        Red.sprites = {}
    end
end
ROOT.colors.cycle(true)

ROOT.colors.save = function()
    rainbows[#rainbows + 1] = Rainbow
    local f = io.open(LUAPATH..'/config/rainbows.lua', 'w')
    f:write('return '..serialize(rainbows))
    f:close()
end

if Toggler then
    Toggler:reload()
end

local function init(self)
    init = function() end -- make sure this is only run the first frame

    self.sprites = {}
end

function Red:render()
    init(self)

    if self.wram.wIsInBattle == 0 then
        local xplayer, yplayer = get_player_coords()
        local wx = 16*Red.wram.wXCoord
        local wy = 16*Red.wram.wYCoord
        local xx = wx - xplayer
        local yy = wy - yplayer
        if xx < 0 then
            xx = 16+xx
        end
        if yy < 0 then
            yy = 16+yy
        end
        if config.render_map then
            --self:render_map(Screen.top, self.wram.wCurMap, math.floor(self.wram.wXCoord/2), math.floor(self.wram.wYCoord/2), xplayer, yplayer, true)
            self:drawmap(Screen.top, self.wram.wCurMap, xplayer, yplayer)
            self:render_sprites(xplayer, yplayer)
        end
        RENDER_DIALOGUE()
    else
        self:render_battlesprites()

        -- temporary: just draw the emulator on top screen
        emu:render()
    end

    if config.render_mgba_top then
        emu:render()
    end

    SHITTY_DIALOGUE_PRINTER()
end
