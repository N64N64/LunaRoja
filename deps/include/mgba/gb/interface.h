/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GB_INTERFACE_H
#define GB_INTERFACE_H

#include "util/common.h"

enum GBModel {
	GB_MODEL_AUTODETECT = 0xFF,
	GB_MODEL_DMG = 0x00,
	GB_MODEL_SGB = 0x40,
	GB_MODEL_CGB = 0x80,
	GB_MODEL_AGB = 0xC0
};

enum GBMemoryBankControllerType {
	GB_MBC_AUTODETECT = -1,
	GB_MBC_NONE = 0,
	GB_MBC1 = 1,
	GB_MBC2 = 2,
	GB_MBC3 = 3,
	GB_MBC5 = 5,
	GB_MBC6 = 6,
	GB_MBC7 = 7,
	GB_MMM01 = 0x10,
	GB_HuC1 = 0x11,
	GB_HuC3 = 0x12,
	GB_MBC3_RTC = 0x103,
	GB_MBC5_RUMBLE = 0x105
};

#endif
