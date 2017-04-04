Red = {}
Red.Tilesize = 8

local function init()
    init = function() end

    require 'red.symbols'
    require 'red.dialogue'
    require 'red.start_menu.render'
    require 'red.start_menu.bag'
    require 'red.start_menu.party'
    require 'red.render'
    require 'red.cheats'
    require 'red.string'
    require 'red.pic'
    require 'red.dex'

    Toggler.OnUpdate.red = function()
        Red:reset()
    end
end

function Red:overworld()
    if cheats.repel then
        self.wram.wRepelRemainingSteps = 2
    end
    if not(cheats.bike == nil) then
        self.wram.wWalkBikeSurfState = cheats.bike and 1 or 0
    end
    if cheats.all_badges then
        self.wram.wObtainedBadges = 0xff
    end
    self.wram.wMapPalOffset = 0 -- override flash
end

function Red:battle()
    self.wram.wEnemyMonNick = 'lololo'
    local friend = self.wram.wBattleMon
    local enemy = self.wram.wEnemyMon

    friend.Type2 = math.ceil(math.random() * 6)
    if cheats.always_win then
        enemy.HP = 0
    end

    friend.Moves[3] = math.ceil(math.random() * 60)
    friend.PP[3] = 14
end

function Red:run()
    if self.wram.wIsInBattle == 0 then
        self:overworld()
    else
        self:battle()
    end
end

function Red:reset()
    init()

    emu:resetrom()
    self:patch_cheats()
end

return Red
