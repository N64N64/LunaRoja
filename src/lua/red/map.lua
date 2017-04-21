local super = Object
Red.Map = Object.new(super)


local all = {}
function Red.Map.Clear()
    all = {}
end

function Red.Map:new(map)
    if all[map] then
        return all[map]
    end
    local self = super.new(self)


    self.map = map
    self.wram = {}
    self.wram.header, self.wram.blocks = getmapheader(self.map)
    self.tileset = self.wram.header[0]
    self.blockwidth = self.wram.header[2]
    self.blockheight = self.wram.header[1]
    self.tilewidth = 2*self.blockwidth
    self.tileheight = 2*self.blockheight
    self.width = 16*self.tilewidth
    self.tileheight = 16*self.tileheight

    self.pix = ffi.new('uint8_t *[?]', self.tilewidth*self.tileheight)

    for y=0,self.blockheight-1 do
        for x=0,self.blockwidth-1 do
            local tileno = self.wram.blocks[y*self.blockwidth + x]
            local block = gettilefromrom(self.tileset, tileno)
            local pix = self.pix + 4*y*self.blockwidth + 2*x
            pix[0] = block.nw.pix
            pix[1] = block.ne.pix
            local pix = pix + 2*self.blockwidth
            pix[0] = block.sw.pix
            pix[1] = block.se.pix
        end
    end




    all[map] = self
    return self
end

function Red.Map:draw(scr, x, y)
    ffi.luared.tilecopy(
        scr.pix, scr.width, scr.height, x, y,
        self.pix, self.tilewidth, self.tileheight
    )
end

getmetatable(Red.Map).__call = function(x, ...)
    return Red.Map:new(...)
end

return Red.Map
