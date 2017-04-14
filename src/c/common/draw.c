#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

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

#define CHECK(i, s) do{\
    if(i < 0 || i >= s) {\
        return false;\
    }\
} while(0)

bool fastcopyaf(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, uint8_t invis, bool flip)
{
    int startx = 0;
    int endx = inh;

    if(outx < 0) {
        startx = -outx;
    }
    if(outx + endx > outh) {
        endx = outh - outx - 1;
    }

    int outadd = 0;
    int inadd = 0;
    int inlen = inw;
#if 0
    if(outy < 0) {
        inadd = outy;
        outadd = outy;
        inlen += inadd;
    }
#endif
    if(outy < 0) {
        inlen += outy;
    }
    if(outy + inw > outw) {
        int diff = outy + inw - outw;
        inadd += diff;
        outadd += diff;
        inlen -= diff;
    }

    if(inlen <= 0) {
        return true;
    }

    for(int x = startx; x < endx; x++) {
        int outidx = (x + outx + 1)*outw - outy - inw + outadd;
        int inidx;
        if(flip) {
            inidx = endx - 1 - x + startx;
        } else {
            inidx = x;
        }
        inidx = inidx*inw + inadd;
        for(int i = 0; i < inlen; i++) {
            CHECK(i + inidx, inw*inh);
            uint8_t b = in[(i + inidx)*3 + 0];
            uint8_t g = in[(i + inidx)*3 + 1];
            uint8_t r = in[(i + inidx)*3 + 2];
            if(b == invis && g == invis && r == invis) {
                continue;
            }
            CHECK(i + outidx, outw*outh);
            out[(i + outidx)*3 + 0] = b;
            out[(i + outidx)*3 + 1] = g;
            out[(i + outidx)*3 + 2] = r;
        }
    }
    return true;
}

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

bool fastcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, int stride)
{
    int startx = 0;
    int endx = inh;

    if(outx < 0) {
        startx = -outx;
    }
    if(outx + endx > outh) {
        endx = outh - outx - 1;
    }

    int outadd = 0;
    int inadd = 0;
    int inlen = inw;
#if 0
    if(outy < 0) {
        inadd = outy;
        outadd = outy;
        inlen += inadd;
    }
#endif
    if(outy < 0) {
        inlen += outy;
    }
    if(outy + inw > outw) {
        int diff = outy + inw - outw;
        inadd += diff;
        outadd += diff;
        inlen -= diff;
    }

    if(inlen <= 0) {
        return true;
    }

    for(int x = startx; x < endx; x++) {
        int outidx = (x + outx + 1)*outw - outy - inw + outadd;
        int inidx  = x*inw + inadd;

        CHECK(outidx, outw*outh);
        CHECK(inidx, inw*inh);
        CHECK(outidx + inlen - 1, outw*outh);
        CHECK(inidx + inlen - 1, inw*inh);

        memcpy(out + outidx*stride, in + inidx*stride, inlen*stride);
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
            int outi = 3*((x + outx + 1)*outw - (y + outy + 1));
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

int minstride_override = 0;
static uint8_t _color[3];
bool rotatecopy(uint8_t *out, int outw, int outh, int outstride, int outx, int outy,
                uint8_t *in,  int inw,  int inh,  int instride,  int inx,  int iny)
{
    if(instride == 3) {
        for(int y = 0; y < inh; y++) {
            if(y + outy < 0 || y + outy >= outw) {
                continue;
            }
            for(int x = 0; x < inw; x++) {
                if(x + outx < 0 || x + outx >= outh) {
                    continue;
                }
                int outi = 3*((x + outx + 1)*outw - (y + outy + 1));
                int ini  = 3*((y + iny)*inw + x + inx);
                CHECK(outi, 9*outw*outh);
                CHECK(ini, 9*inw*inh);
                out[outi + 0] = in[ini + 0];
                out[outi + 1] = in[ini + 1];
                out[outi + 2] = in[ini + 2];
            }
        }
    } else if(instride == 1) {
        for(int y = 0; y < inh; y++) {
            for(int x = 0; x < inw; x++) {
                if(x + outx < 0 || y + outy < 0 || x + outx >= outh || y + outy >= outw) {
                    continue;
                }
                int outi = 3*((x + outx + 1)*outw - (y + outy + 1));
                int ini  = instride*((y + iny)*inw + x + inx);
                unsigned int alpha = in[ini];
                CHECK(outi, 9*outw*outh);
                CHECK(ini, instride*instride*inw*inh);
                out[outi + 0] = (out[outi + 0]*(0xff - alpha) + _color[0] * alpha) / 0xff;
                out[outi + 1] = (out[outi + 1]*(0xff - alpha) + _color[1] * alpha) / 0xff;
                out[outi + 2] = (out[outi + 2]*(0xff - alpha) + _color[2] * alpha) / 0xff;
            }
        }
    } else /*if(instride == 4)*/ {
        for(int y = 0; y < inh; y++) {
            for(int x = 0; x < inw; x++) {
                if(x + outx < 0 || y + outy < 0 || x + outx >= outh || y + outy >= outw) {
                    continue;
                }
                int outi = 3*((x + outx + 1)*outw - (y + outy + 1));
                int ini  = instride*((y + iny)*inw + x + inx);
                uint8_t alpha = in[ini + 3];
                CHECK(outi, 9*outw*outh);
                CHECK(ini, instride*instride*inw*inh);
                out[outi + 0] = (out[outi + 0]*(0xff - alpha) + in[ini + 0] * alpha) / 0xff;
                out[outi + 1] = (out[outi + 1]*(0xff - alpha) + in[ini + 1] * alpha) / 0xff;
                out[outi + 2] = (out[outi + 2]*(0xff - alpha) + in[ini + 2] * alpha) / 0xff;
            }
        }
    }
    return true;
}

void makebgr(uint8_t *pix, int width, int height, int channels)
{
    for(int i = 0; i < width*height; i++) {
        uint8_t r = pix[i*channels + 0];
        uint8_t g = pix[i*channels + 1];
        uint8_t b = pix[i*channels + 2];

        pix[i*channels + 0] = b;
        pix[i*channels + 1] = g;
        pix[i*channels + 2] = r;
    }
}

void draw_set_color(uint8_t r, uint8_t g, uint8_t b)
{
#ifdef _3DS
    _color[0] = b;
    _color[1] = g;
    _color[2] = r;
#else
    _color[0] = r;
    _color[1] = g;
    _color[2] = b;
#endif
}

bool draw_pixel(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy)
{
    int x = (int)(fx + 0.5);
    int y = (int)(fy + 0.5);
    if(x < 0 || x >= fbwidth || y < 0 || y > fbheight) {
        return false;
    }

    int s = 3*(fbheight*(x + 1) - (y + 1));
    for(int i = 0; i < 3; i++) {
        fb[s + i] = _color[i];
    }
    return true;
}

void draw_rect(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy, float fwidth, float fheight)
{
    if(fx + fwidth > fbwidth) {
        fwidth = fbwidth - fx;
    }
    if(fy + fheight > fbheight) {
        fheight = fbheight - fy;
    }
    if(fx < 0) {
        fwidth += fx;
        fx = 0;
    }
    if(fy < 0) {
        fheight += fy;
        fy = 0;
    }

    int px = (int)(fx + 1);
    int py = (int)(fy + 1);
    int width = (int)fwidth;
    int height = (int)fheight;

    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            int s = 3*(fbheight*(x + px) - (y + py));
            for(int i = 0; i < 3; i++) {
                fb[s + i] = _color[i];
            }
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
