#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "stb/stb_truetype.h"

static void * openfile(const char *path)
{
    FILE *f = fopen(path, "rb");
    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);

    void *result = malloc(size);
    fread(result, size, 1, f);
    fclose(f);
    return result;
}

stbtt_fontinfo * font_create(const char *path)
{
    void *font = malloc(sizeof(stbtt_fontinfo));
    if(!stbtt_InitFont(font, openfile(path), 0)) {
        free(font);
        return NULL;
    }
    return font;
}

void font_dimensions(stbtt_fontinfo *font, const char *text, int size, int *outwidth, int *outheight)
{
    if(text == NULL) {
        *outwidth = 0;
        *outheight = 0;
        return;
    }
    if(text == NULL) {
        text = "";
    }
    float scale = stbtt_ScaleForPixelHeight(font, size);
    int ascent, descent, lineGap;
    stbtt_GetFontVMetrics(font, &ascent, &descent, &lineGap);

    ascent *= scale;
    descent *= scale;

    int width = 0;
    int height = 0;
    for(int i = 0; i < strlen(text); i++) {
        int ax;
        stbtt_GetCodepointHMetrics(font, text[i], &ax, 0);
        width += ax * scale;

        int kern;
        kern = stbtt_GetCodepointKernAdvance(font, text[i], text[i + 1]);
        width += kern * scale;

        int x1, y1, x2, y2;
        stbtt_GetCodepointBitmapBox(font, text[i], scale, scale, &x1, &y1, &x2, &y2);
        if(y2 > height) {
            height = y2;
        }
    }
    height += ascent;

    *outwidth = width;
    *outheight = height;
}

uint8_t * font_render(stbtt_fontinfo *font, const char *text, int size, int *outwidth, int *outheight)
{
    if(text == NULL) {
        text = "";
    }
    float scale = stbtt_ScaleForPixelHeight(font, size);
    int ascent, descent, lineGap;
    stbtt_GetFontVMetrics(font, &ascent, &descent, &lineGap);

    ascent *= scale;
    descent *= scale;

    int width = 0;
    int height = 0;
    for(int i = 0; i < strlen(text); i++) {
        int ax;
        stbtt_GetCodepointHMetrics(font, text[i], &ax, 0);
        width += ax * scale;

        int kern;
        kern = stbtt_GetCodepointKernAdvance(font, text[i], text[i + 1]);
        width += kern * scale;

        int x1, y1, x2, y2;
        stbtt_GetCodepointBitmapBox(font, text[i], scale, scale, &x1, &y1, &x2, &y2);
        if(y2 > height) {
            height = y2;
        }
    }
    height += ascent;

    uint8_t *pix = malloc(width*height*2); // TODO find the segfault and actually fix it
    if(pix == NULL) {
        // OOM
        return NULL;
    }
    memset(pix, 0, width*height);

    int x = 0;
    for(int i = 0; i < strlen(text); i++) {
        int x1, y1, x2, y2;
        int ax, kern;
        stbtt_GetCodepointBitmapBox(font, text[i], scale, scale, &x1, &y1, &x2, &y2);
        stbtt_GetCodepointHMetrics(font, text[i], &ax, 0);
        kern = stbtt_GetCodepointKernAdvance(font, text[i], text[i + 1]);

        int y = ascent + y1;
        int offset = x + y*width;
        stbtt_MakeCodepointBitmap(font, &pix[offset], x2 - x1, y2 - y1, width, scale, scale, text[i]);

        x += scale*(ax + kern);
    }

    if(outwidth) *outwidth = width;
    if(outheight) *outheight = height;
    return pix;
}
