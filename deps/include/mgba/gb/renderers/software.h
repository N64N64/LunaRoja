/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GB_RENDERER_SOFTWARE_H
#define GB_RENDERER_SOFTWARE_H

#include "util/common.h"

#include "core/core.h"
#include "gb/gb.h"
#include "gb/video.h"

struct GBVideoSoftwareRenderer {
	struct GBVideoRenderer d;

	color_t* outputBuffer;
	int outputBufferStride;

	uint8_t row[GB_VIDEO_HORIZONTAL_PIXELS + 8];

	color_t palette[128];

	uint32_t* temporaryBuffer;

	uint8_t scy;
	uint8_t scx;
	uint8_t wy;
	uint8_t wx;
	uint8_t currentWy;

	GBRegisterLCDC lcdc;
	enum GBModel model;
};

void GBVideoSoftwareRendererCreate(struct GBVideoSoftwareRenderer*);

#endif
