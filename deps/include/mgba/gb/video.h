/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GB_VIDEO_H
#define GB_VIDEO_H

#include "util/common.h"

#include "core/interface.h"
#include "gb/interface.h"
#include "gb/memory.h"

enum {
	GB_VIDEO_HORIZONTAL_PIXELS = 160,
	GB_VIDEO_VERTICAL_PIXELS = 144,
	GB_VIDEO_VBLANK_PIXELS = 10,
	GB_VIDEO_VERTICAL_TOTAL_PIXELS = GB_VIDEO_VERTICAL_PIXELS + GB_VIDEO_VBLANK_PIXELS,

	// TODO: Figure out exact lengths
	GB_VIDEO_MODE_2_LENGTH = 76,
	GB_VIDEO_MODE_3_LENGTH_BASE = 171,
	GB_VIDEO_MODE_0_LENGTH_BASE = 209,

	GB_VIDEO_HORIZONTAL_LENGTH = GB_VIDEO_MODE_0_LENGTH_BASE + GB_VIDEO_MODE_2_LENGTH + GB_VIDEO_MODE_3_LENGTH_BASE,

	GB_VIDEO_MODE_1_LENGTH = GB_VIDEO_HORIZONTAL_LENGTH * GB_VIDEO_VBLANK_PIXELS,
	GB_VIDEO_TOTAL_LENGTH = GB_VIDEO_HORIZONTAL_LENGTH * GB_VIDEO_VERTICAL_TOTAL_PIXELS,

	GB_BASE_MAP = 0x1800,
	GB_SIZE_MAP = 0x0400
};

DECL_BITFIELD(GBObjAttributes, uint8_t);
DECL_BITS(GBObjAttributes, CGBPalette, 0, 3);
DECL_BIT(GBObjAttributes, Bank, 3);
DECL_BIT(GBObjAttributes, Palette, 4);
DECL_BIT(GBObjAttributes, XFlip, 5);
DECL_BIT(GBObjAttributes, YFlip, 6);
DECL_BIT(GBObjAttributes, Priority, 7);

struct GBObj {
	uint8_t y;
	uint8_t x;
	uint8_t tile;
	GBObjAttributes attr;
};

union GBOAM {
	struct GBObj obj[40];
	uint8_t raw[160];
};

enum GBModel;
struct mTileCache;
struct GBVideoRenderer {
	void (*init)(struct GBVideoRenderer* renderer, enum GBModel model);
	void (*deinit)(struct GBVideoRenderer* renderer);

	uint8_t (*writeVideoRegister)(struct GBVideoRenderer* renderer, uint16_t address, uint8_t value);
	void (*writeVRAM)(struct GBVideoRenderer* renderer, uint16_t address);
	void (*writePalette)(struct GBVideoRenderer* renderer, int index, uint16_t value);
	void (*drawRange)(struct GBVideoRenderer* renderer, int startX, int endX, int y, struct GBObj* objOnLine, size_t nObj);
	void (*finishScanline)(struct GBVideoRenderer* renderer, int y);
	void (*finishFrame)(struct GBVideoRenderer* renderer);

	void (*getPixels)(struct GBVideoRenderer* renderer, size_t* stride, const void** pixels);
	void (*putPixels)(struct GBVideoRenderer* renderer, size_t stride, const void* pixels);

	uint8_t* vram;
	union GBOAM* oam;
	struct mTileCache* cache;
};

DECL_BITFIELD(GBRegisterLCDC, uint8_t);
DECL_BIT(GBRegisterLCDC, BgEnable, 0);
DECL_BIT(GBRegisterLCDC, ObjEnable, 1);
DECL_BIT(GBRegisterLCDC, ObjSize, 2);
DECL_BIT(GBRegisterLCDC, TileMap, 3);
DECL_BIT(GBRegisterLCDC, TileData, 4);
DECL_BIT(GBRegisterLCDC, Window, 5);
DECL_BIT(GBRegisterLCDC, WindowTileMap, 6);
DECL_BIT(GBRegisterLCDC, Enable, 7);

DECL_BITFIELD(GBRegisterSTAT, uint8_t);
DECL_BITS(GBRegisterSTAT, Mode, 0, 2);
DECL_BIT(GBRegisterSTAT, LYC, 2);
DECL_BIT(GBRegisterSTAT, HblankIRQ, 3);
DECL_BIT(GBRegisterSTAT, VblankIRQ, 4);
DECL_BIT(GBRegisterSTAT, OAMIRQ, 5);
DECL_BIT(GBRegisterSTAT, LYCIRQ, 6);

struct GBVideo {
	struct GB* p;
	struct GBVideoRenderer* renderer;

	int x;
	int ly;
	GBRegisterSTAT stat;

	int mode;

	int32_t nextEvent;
	int32_t eventDiff;

	int32_t nextMode;
	int32_t dotCounter;

	int32_t nextFrame;

	uint8_t* vram;
	uint8_t* vramBank;
	int vramCurrentBank;

	union GBOAM oam;
	struct GBObj objThisLine[10];
	int objMax;

	int bcpIndex;
	bool bcpIncrement;
	int ocpIndex;
	bool ocpIncrement;

	uint16_t palette[64];

	int32_t frameCounter;
	int frameskip;
	int frameskipCounter;
};

void GBVideoInit(struct GBVideo* video);
void GBVideoReset(struct GBVideo* video);
void GBVideoDeinit(struct GBVideo* video);
void GBVideoAssociateRenderer(struct GBVideo* video, struct GBVideoRenderer* renderer);
int32_t GBVideoProcessEvents(struct GBVideo* video, int32_t cycles);
void GBVideoProcessDots(struct GBVideo* video);

void GBVideoWriteLCDC(struct GBVideo* video, GBRegisterLCDC value);
void GBVideoWriteSTAT(struct GBVideo* video, GBRegisterSTAT value);
void GBVideoWriteLYC(struct GBVideo* video, uint8_t value);
void GBVideoWritePalette(struct GBVideo* video, uint16_t address, uint8_t value);
void GBVideoSwitchBank(struct GBVideo* video, uint8_t value);

struct GBSerializedState;
void GBVideoSerialize(const struct GBVideo* video, struct GBSerializedState* state);
void GBVideoDeserialize(struct GBVideo* video, const struct GBSerializedState* state);

#endif
