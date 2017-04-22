local Paint = {}
function lol(i)
    Paint.set_bitmap(Red.tiles[0x00][i])
end

local function scalecopy(bmap, scale)
end

function Paint.set_bitmap(bmap)
    if bmap.channels ~= 3 then
        error('unsupported bmap')
    end
    self.bitmap = bmap
    self.canvas = Bitmap:new(bmap.pix, bmap.width, bmap.height, bmap.channels)
    local scale = math.floor(math.min(Screen.bottom.height/bmap.height, Screen.bottom.width/bmap.width))
    self.canvas:scale(scale)
end

function Paint.render()
    if not self.bitmap then return end

    self.canvas:draw(Screen.bottom, 0, 0)
end

Paint.mode = {
    rendercallback = Paint.render,
}
return Paint
