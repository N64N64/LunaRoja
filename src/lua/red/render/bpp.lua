local switcharoo = {
    0,
    2,
    3,
}

local invis_color = {SPRITE_INVIS_COLOR, SPRITE_INVIS_COLOR, SPRITE_INVIS_COLOR}

local step -- forward decl

function BPP(getbpp, width, height, ...)
    local is_sprite, make_ff_invis_anyway, transpose, raw
    for _,v in ipairs{...} do
        if v == 'is_sprite' then
            is_sprite = true
        elseif v == 'make_ff_invis_anyway' then
            make_ff_invis_anyway = true
        elseif v == 'transpose' then
            transpose = true
        elseif v == 'raw' then
            raw = true
        end
    end

    if not(type(getbpp) == 'function') then
        local ptr = getbpp
        getbpp = function(i)
            return ptr + i*16
        end
    end

    local pix = ffi.new('uint8_t[?]', width*height*3)

    for i=0,(width/Red.Tilesize)*(height/Red.Tilesize)-1 do
        step(pix, getbpp(i), i, width/Red.Tilesize, is_sprite, make_ff_invis_anyway, transpose)
    end

    if raw then return pix end

    local bmap = Bitmap:new{
        pix = pix,
        width = width,
        height = height,
        channels = 3,
    }
    bmap:prerotate()
    bmap:makebgr()
    return bmap
end

function step(pix, bpp, i, width, is_sprite, make_ff_invis_anyway, transpose)
    local yy = Red.Tilesize*math.floor(i/width)
    local xx = Red.Tilesize*math.floor(i%width)
    if transpose then
        local tmp = xx
        xx = yy
        yy = tmp
    end
    for y=0,Red.Tilesize-1 do
        local low = bpp[2*y + 0]
        local high = bpp[2*y + 1]
        for x=0,Red.Tilesize-1 do
            local val = bit.band(1, bit.rshift(low, 7-x))
            val = val + 2*bit.band(1, bit.rshift(high, 7-x))
            val = 3 - val
            --val = math.floor(val*0xff/3)
            if is_sprite then
                val = switcharoo[val + 1]
            elseif make_ff_invis_anyway and val == 3 then
                val = nil
            end
            local idx = (yy+y)*width*8 + x + xx
            local color = val and Rainbow[val+1] or invis_color
            pix[idx*3 + 0] = color[0+1]
            pix[idx*3 + 1] = color[1+1]
            pix[idx*3 + 2] = color[2+1]
        end
    end
end
