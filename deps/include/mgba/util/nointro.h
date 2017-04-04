/* Copyright (c) 2013-2015 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef NOINTRO_H
#define NOINTRO_H

#include "util/common.h"

struct NoIntroGame {
	const char* name;
	const char* romName;
	const char* description;
	size_t size;
	uint32_t crc32;
	uint8_t md5[16];
	uint8_t sha1[20];
	bool verified;
};

struct NoIntroDB;
struct VFile;

struct NoIntroDB* NoIntroDBLoad(struct VFile* vf);
void NoIntroDBDestroy(struct NoIntroDB* db);
bool NoIntroDBLookupGameByCRC(const struct NoIntroDB* db, uint32_t crc32, struct NoIntroGame* game);

#endif
