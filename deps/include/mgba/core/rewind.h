/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef M_CORE_REWIND_H
#define M_CORE_REWIND_H

#include "util/common.h"

#include "util/vector.h"

DECLARE_VECTOR(mCoreRewindPatches, struct PatchFast);

struct VFile;
struct mCoreRewindContext {
	struct mCoreRewindPatches patchMemory;
	size_t current;
	size_t size;
	struct VFile* previousState;
	struct VFile* currentState;
};

void mCoreRewindContextInit(struct mCoreRewindContext*, size_t entries);
void mCoreRewindContextDeinit(struct mCoreRewindContext*);

struct mCore;
void mCoreRewindAppend(struct mCoreRewindContext*, struct mCore*);
bool mCoreRewindRestore(struct mCoreRewindContext*, struct mCore*);

#endif
