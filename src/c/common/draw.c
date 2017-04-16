#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

static uint8_t _color[3];

bool lovecopy(uint8_t *out, uint8_t *in, int size)
{
    for(int i = 0; i < size; i++) {
        out[i*4 + 0] = in[i*3 + 0];
        out[i*4 + 1] = in[i*3 + 1];
        out[i*4 + 2] = in[i*3 + 2];
        out[i*4 + 3] = 0xff;
    }
    return true;
}

void lastcopy(uint8_t *out, uint8_t *in, int w, int h)
{
    for(int y = 0; y < h; y++) {
        for(int x = 0; x < w; x++) {
            uint8_t *i = &in[3*(w*y + x)];
            uint8_t *o = &out[3*(h*(x+1) - (y+1))];
#ifdef _3DS
            o[0] = i[2];
            o[1] = i[1];
            o[2] = i[0];
#else
            o[0] = i[0];
            o[1] = i[1];
            o[2] = i[2];
#endif
        }
    }
}

#define CHECK(i, s) do{\
    if(i < 0 || i >= s) {\
        return false;\
    }\
} while(0)

bool dumbcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, int stride)
{
    for(int y = 0; y < inh; y++) {
        int outidx = (outy + y)*outw + outx;
        int inidx = y*inw;

        //printf("%d %d %d %d %d %d\n", outx, outy, y, outw, outh, inw);
        CHECK(outidx + inw, outw*outh);
        CHECK(inidx + inw, outw*outh);

        //printf("yee %d %d\n", outidx, inidx);
        memcpy(out + outidx*stride, in + inidx*stride, inw*stride);
    }
    return true;
}

bool dumbcopyaf(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, uint8_t invis, bool flip)
{
    for(int y = 0; y < inh; y++) {
        int outidx = (outy + y)*outw + outx;
        int inidx = y*inw;

        CHECK(outidx + inw, outw*outh);
        CHECK(inidx + inw, outw*outh);

        for(int x = 0; x < inw; x++) {
            int ix = flip ? inw-x-1 : x;
            uint8_t *i = &in[3*(y*inw + ix)];
            uint8_t *o = &out[3*((outy+y)*outw + outx+x)];
            if(i[0] == invis && i[1] == invis && i[2] == invis) {
                // pass
            } else {
                o[0] = i[0];
                o[1] = i[1];
                o[2] = i[2];
            }
        }
    }
    return true;
}

bool alphacopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh)
{
    for(int y = 0; y < inh; y++) {
        int outidx = (outy + y)*outw + outx;
        int inidx = y*inw;

        CHECK(outidx + inw, outw*outh);
        CHECK(inidx + inw, outw*outh);

        for(int x = 0; x < inw; x++) {
            uint8_t *i = &in[4*(y*inw + x)];
            uint8_t *o = &out[3*((outy+y)*outw + outx+x)];
            uint8_t a = i[3];
            o[0] = (o[0]*(0xff-a) + i[0]*a) / 0xff;
            o[1] = (o[1]*(0xff-a) + i[1]*a) / 0xff;
            o[2] = (o[2]*(0xff-a) + i[2]*a) / 0xff;
        }
    }
    return true;
}

bool purealphacopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh)
{
    for(int y = 0; y < inh; y++) {
        int outidx = (outy + y)*outw + outx;
        int inidx = y*inw;

        CHECK(outidx + inw, outw*outh);
        CHECK(inidx + inw, outw*outh);

        for(int x = 0; x < inw; x++) {
            uint8_t a = in[y*inw + x];
            uint8_t *i = _color;
            uint8_t *o = &out[3*((outy+y)*outw + outx+x)];
            o[0] = (o[0]*(0xff-a) + i[0]*a) / 0xff;
            o[1] = (o[1]*(0xff-a) + i[1]*a) / 0xff;
            o[2] = (o[2]*(0xff-a) + i[2]*a) / 0xff;
        }
    }
    return true;
}

bool scalecopy(uint8_t *out, uint8_t *in, int width, int height, float scale)
{
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            int ii = y*width + x;
            for(int yy = 0; yy < scale; yy++) {
                for(int xx = 0; xx < scale; xx++) {
                    int oi = ((yy+scale*y)*width*scale + xx+scale*x);
                    out[oi*3 + 0] = in[ii*3 + 0];
                    out[oi*3 + 1] = in[ii*3 + 1];
                    out[oi*3 + 2] = in[ii*3 + 2];
                }
            }
        }
    }
    return true;
}

// mGBA outputs 4 bytes per pixel on
// desktop and 2 bytes per pixel on
// 3DS. no clue why
#ifdef _3DS
#define WTF 2
#else
#define WTF 4
#endif

bool mgbacopy(uint8_t *out, int outw, int outh, int outx, int outy,
              uint8_t *in,  int inw,  int inh,  int  inx, int  iny)
{
    for(int y = 0; y < inh; y++) {
        for(int x = 0; x < inw; x++) {
            int outi = 3*((y + outy)*outw - (x + outx));
            int ini = WTF*((y + iny)*inw + x + inx);
            int v = in[ini + 1]; // need to get the 2nd pixel because
                                 // the first pixel is wrong
                                 // on the 3DS for some reason???
            out[outi + 0] = v;
            out[outi + 1] = v;
            out[outi + 2] = v;
        }
    }
    return true;
}

void draw_set_color(uint8_t r, uint8_t g, uint8_t b)
{
    _color[0] = r;
    _color[1] = g;
    _color[2] = b;
}

bool draw_pixel(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy)
{
    int x = (int)(fx + 0.5);
    int y = (int)(fy + 0.5);
    if(x < 0 || x >= fbwidth || y < 0 || y > fbheight) {
        return false;
    }

    int s = 3*(fbwidth*y + x);
    for(int i = 0; i < 3; i++) {
        fb[s + i] = _color[i];
    }
    return true;
}

void draw_rect(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy, float fwidth, float fheight)
{
    int px = (int)(fx + 0.5);
    int py = (int)(fy + 0.5);
    int width = (int)(fwidth + 0.5);
    int height = (int)(fheight + 0.5);

    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *o = &fb[3*(fbwidth*py + px)];
            o[0] = _color[0];
            o[1] = _color[1];
            o[2] = _color[2];
        }
    }
}

void draw_line(uint8_t *fb, int fbwidth, int fbheight, float x1, float y1, float x2, float y2)
{
    float distx = x2 - x1;
    float disty = y2 - y1;
    float steps = fabs(distx) > fabs(disty) ? distx : disty;
    steps = fabs(steps);

    float dx = distx / steps;
    float dy = disty / steps;

    float x = x1;
    float y = y1;
    for(int i = 0; i < steps; i++) {
        draw_pixel(fb, fbwidth, fbheight, x, y);
        x += dx;
        y += dy;
    }
    draw_pixel(fb, fbwidth, fbheight, x2, y2);
}

void draw_circle(uint8_t *fb, int fbwidth, int fbheight, float x0, float y0, float radius, bool should_outline)
{
    if(should_outline) {
        float x = radius;
        float y = 0;
        float err = 0;
        while (x >= y) {
            draw_pixel(fb, fbwidth, fbheight, x0 + x, y0 + y);
            draw_pixel(fb, fbwidth, fbheight, x0 + y, y0 + x);
            draw_pixel(fb, fbwidth, fbheight, x0 - y, y0 + x);
            draw_pixel(fb, fbwidth, fbheight, x0 - x, y0 + y);
            draw_pixel(fb, fbwidth, fbheight, x0 - x, y0 - y);
            draw_pixel(fb, fbwidth, fbheight, x0 - y, y0 - x);
            draw_pixel(fb, fbwidth, fbheight, x0 + y, y0 - x);
            draw_pixel(fb, fbwidth, fbheight, x0 + x, y0 - y);
            if (err <= 0) {
                y += 1;
                err += 2*y + 1;
            }
            if (err > 0) {
                x -= 1;
                err -= 2*x + 1;
            }
        }
    } else { // fill
        for(int y = -radius; y <= radius; y++) {
            for(int x = -radius; x <= radius; x++) {
                if(x*x + y*y <= radius*radius) {
                    draw_pixel(fb, fbwidth, fbheight, x0 + x, y0 + y);
                }
            }
        }
    }
}
