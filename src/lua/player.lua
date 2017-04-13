local super = Object
Player = Object.new(super)

Player.nick = 'MingeBag'

Player.Attrs = {'id', 'nick', 'x', 'y', 'map', 'dir', 'anim', 'diffx', 'diffy'}
Player.Peers = {}

function Player:new()
    local self = super.new(self)
    return self
end

function Player:update()
    if not Red.wram then return end
    if  self.x == Red.wram.wXCoord
        and self.y == Red.wram.wYCoord
        and self.map == Red.wram.wCurMap
        and self.dir == Red.wram.wSpriteStateData1[0].FacingDirection
        and self.anim == Red.wram.wSpriteStateData1[0].AnimFrameCounter
        and self.diffx == Red.diffx
        and self.diffy == Red.diffy
    then return end

    self.x = Red.wram.wXCoord
    self.y = Red.wram.wYCoord
    self.map = Red.wram.wCurMap
    self.dir = Red.wram.wSpriteStateData1[0].FacingDirection
    self.anim = Red.wram.wSpriteStateData1[0].AnimFrameCounter
    self.diffx = Red.diffx or 0
    self.diffy = Red.diffy or 0
    return true
end

function Player:encode()
    local t = {__class = 'Player'}
    populate(t, self, Player.Attrs)
    return encode(t)
end

function Player.Decode(t)
    local self = Player.Peers[t.id]
    if not self then
        self = Player:new()
        Player.Peers[t.id] = self
    end
    populate(self, t, Player.Attrs)
end

return Player
