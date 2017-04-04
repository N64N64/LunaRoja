/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GB_MEMORY_H
#define GB_MEMORY_H

#include "util/common.h"

#include "core/log.h"
#include "gb/interface.h"
#include "lr35902/lr35902.h"

#include <time.h>

mLOG_DECLARE_CATEGORY(GB_MBC);
mLOG_DECLARE_CATEGORY(GB_MEM);

struct GB;

enum {
	GB_BASE_CART_BANK0 = 0x0000,
	GB_BASE_CART_BANK1 = 0x4000,
	GB_BASE_VRAM = 0x8000,
	GB_BASE_EXTERNAL_RAM = 0xA000,
	GB_BASE_WORKING_RAM_BANK0 = 0xC000,
	GB_BASE_WORKING_RAM_BANK1 = 0xD000,
	GB_BASE_OAM = 0xFE00,
	GB_BASE_UNUSABLE = 0xFEA0,
	GB_BASE_IO = 0xFF00,
	GB_BASE_HRAM = 0xFF80,
	GB_BASE_IE = 0xFFFF
};

enum {
	GB_REGION_CART_BANK0 = 0x0,
	GB_REGION_CART_BANK1 = 0x4,
	GB_REGION_VRAM = 0x8,
	GB_REGION_EXTERNAL_RAM = 0xA,
	GB_REGION_WORKING_RAM_BANK0 = 0xC,
	GB_REGION_WORKING_RAM_BANK1 = 0xD,
	GB_REGION_WORKING_RAM_BANK1_MIRROR = 0xE,
	GB_REGION_OTHER = 0xF,
};

enum {
	GB_SIZE_CART_BANK0 = 0x4000,
	GB_SIZE_CART_MAX = 0x800000,
	GB_SIZE_VRAM = 0x4000,
	GB_SIZE_VRAM_BANK0 = 0x2000,
	GB_SIZE_EXTERNAL_RAM = 0x2000,
	GB_SIZE_WORKING_RAM = 0x8000,
	GB_SIZE_WORKING_RAM_BANK0 = 0x1000,
	GB_SIZE_OAM = 0xA0,
	GB_SIZE_IO = 0x80,
	GB_SIZE_HRAM = 0x7F,
};

enum {
	GB_SRAM_DIRT_NEW = 1,
	GB_SRAM_DIRT_SEEN = 2
};

struct GBMemory;
typedef void (*GBMemoryBankController)(struct GB*, uint16_t address, uint8_t value);

DECL_BITFIELD(GBMBC7Field, uint8_t);
DECL_BIT(GBMBC7Field, SK, 6);
DECL_BIT(GBMBC7Field, CS, 7);
DECL_BIT(GBMBC7Field, IO, 1);

enum GBMBC7MachineState {
	GBMBC7_STATE_NULL = -1,
	GBMBC7_STATE_IDLE = 0,
	GBMBC7_STATE_READ_COMMAND = 1,
	GBMBC7_STATE_READ_ADDRESS = 2,
	GBMBC7_STATE_COMMAND_0 = 3,
	GBMBC7_STATE_COMMAND_SR_WRITE = 4,
	GBMBC7_STATE_COMMAND_SR_READ = 5,
	GBMBC7_STATE_COMMAND_SR_FILL = 6,
	GBMBC7_STATE_READ = 7,
	GBMBC7_STATE_WRITE = 8,
};

struct GBMBC1State {
	int mode;
};

struct GBMBC7State {
	enum GBMBC7MachineState state;
	uint32_t sr;
	uint8_t address;
	bool writable;
	int srBits;
	int command;
	GBMBC7Field field;
};

union GBMBCState {
	struct GBMBC1State mbc1;
	struct GBMBC7State mbc7;
};

struct mRotationSource;
struct GBMemory {
	uint8_t* rom;
	uint8_t* romBase;
	uint8_t* romBank;
	enum GBMemoryBankControllerType mbcType;
	GBMemoryBankController mbc;
	union GBMBCState mbcState;
	int currentBank;

	uint8_t* wram;
	uint8_t* wramBank;
	int wramCurrentBank;

	bool sramAccess;
	uint8_t* sram;
	uint8_t* sramBank;
	int sramCurrentBank;

	uint8_t io[GB_SIZE_IO];
	bool ime;
	uint8_t ie;

	uint8_t hram[GB_SIZE_HRAM];

	int32_t dmaNext;
	uint16_t dmaSource;
	uint16_t dmaDest;
	int dmaRemaining;

	int32_t hdmaNext;
	uint16_t hdmaSource;
	uint16_t hdmaDest;
	int hdmaRemaining;
	bool isHdma;

	size_t romSize;

	bool rtcAccess;
	int activeRtcReg;
	bool rtcLatched;
	uint8_t rtcRegs[5];
	time_t rtcLastLatch;
	struct mRTCSource* rtc;
	struct mRotationSource* rotation;
	struct mRumble* rumble;
};

void GBMemoryInit(struct GB* gb);
void GBMemoryDeinit(struct GB* gb);

void GBMemoryReset(struct GB* gb);
void GBMemorySwitchWramBank(struct GBMemory* memory, int bank);

uint8_t GBLoad8(struct LR35902Core* cpu, uint16_t address);
void GBStore8(struct LR35902Core* cpu, uint16_t address, int8_t value);

uint8_t GBView8(struct LR35902Core* cpu, uint16_t address, int segment);

int32_t GBMemoryProcessEvents(struct GB* gb, int32_t cycles);
void GBMemoryDMA(struct GB* gb, uint16_t base);
void GBMemoryWriteHDMA5(struct GB* gb, uint8_t value);

uint8_t GBDMALoad8(struct LR35902Core* cpu, uint16_t address);
void GBDMAStore8(struct LR35902Core* cpu, uint16_t address, int8_t value);

void GBPatch8(struct LR35902Core* cpu, uint16_t address, int8_t value, int8_t* old, int segment);

struct GBSerializedState;
void GBMemorySerialize(const struct GB* gb, struct GBSerializedState* state);
void GBMemoryDeserialize(struct GB* gb, const struct GBSerializedState* state);

#endif
