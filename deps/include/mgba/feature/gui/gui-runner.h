/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GUI_RUNNER_H
#define GUI_RUNNER_H

#include "util/common.h"

#include "core/config.h"
#include "feature/gui/remap.h"
#include "gba/hardware.h"
#include "util/circle-buffer.h"
#include "util/gui.h"

enum mGUIInput {
	mGUI_INPUT_INCREASE_BRIGHTNESS = GUI_INPUT_USER_START,
	mGUI_INPUT_DECREASE_BRIGHTNESS,
	mGUI_INPUT_SCREEN_MODE,
	mGUI_INPUT_SCREENSHOT,
	mGUI_INPUT_FAST_FORWARD,
};

struct mGUIBackground {
	struct GUIBackground d;
	struct mGUIRunner* p;

	color_t* screenshot;
	int screenshotId;
};

struct mCore;
struct mGUIRunnerLux {
	struct GBALuminanceSource d;
	int luxLevel;
};

struct mGUIRunner {
	struct mCore* core;
	struct GUIParams params;

	struct mGUIBackground background;
	struct mGUIRunnerLux luminanceSource;

	struct mInputMap guiKeys;
	struct mCoreConfig config;
	struct GUIMenuItem* configExtra;
	size_t nConfigExtra;

	struct GUIInputKeys* keySources;

	const char* port;
	float fps;
	int64_t lastFpsCheck;
	int32_t totalDelta;
	struct CircleBuffer fpsBuffer;

	void (*setup)(struct mGUIRunner*);
	void (*teardown)(struct mGUIRunner*);
	void (*gameLoaded)(struct mGUIRunner*);
	void (*gameUnloaded)(struct mGUIRunner*);
	void (*prepareForFrame)(struct mGUIRunner*);
	void (*drawFrame)(struct mGUIRunner*, bool faded);
	void (*drawScreenshot)(struct mGUIRunner*, const color_t* pixels, unsigned width, unsigned height, bool faded);
	void (*paused)(struct mGUIRunner*);
	void (*unpaused)(struct mGUIRunner*);
	void (*incrementScreenMode)(struct mGUIRunner*);
	void (*setFrameLimiter)(struct mGUIRunner*, bool limit);
	uint16_t (*pollGameInput)(struct mGUIRunner*);
};

void mGUIInit(struct mGUIRunner*, const char* port);
void mGUIDeinit(struct mGUIRunner*);
void mGUIRun(struct mGUIRunner*, const char* path);
void mGUIRunloop(struct mGUIRunner*);

#endif
