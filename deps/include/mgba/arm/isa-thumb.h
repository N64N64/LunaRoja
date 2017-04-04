/* Copyright (c) 2013-2014 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef ISA_THUMB_H
#define ISA_THUMB_H

#include "util/common.h"

struct ARMCore;

typedef void (*ThumbInstruction)(struct ARMCore*, uint16_t opcode);
extern const ThumbInstruction _thumbTable[0x400];

#endif
