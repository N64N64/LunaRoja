/* Copyright (c) 2013-2016 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef GB_TIMER_H
#define GB_TIMER_H

#include "util/common.h"

DECL_BITFIELD(GBRegisterTAC, uint8_t);
DECL_BITS(GBRegisterTAC, Clock, 0, 2);
DECL_BIT(GBRegisterTAC, Run, 2);

enum {
	GB_DMG_DIV_PERIOD = 16
};

struct GB;
struct GBTimer {
	struct GB* p;

	int32_t nextEvent;
	int32_t eventDiff;

	uint32_t internalDiv;
	int32_t nextDiv;
	uint32_t timaPeriod;
	bool irqPending;
};

void GBTimerReset(struct GBTimer*);
int32_t GBTimerProcessEvents(struct GBTimer*, int32_t cycles);
void GBTimerDivReset(struct GBTimer*);
uint8_t GBTimerUpdateTAC(struct GBTimer*, GBRegisterTAC tac);

struct GBSerializedState;
void GBTimerSerialize(const struct GBTimer* timer, struct GBSerializedState* state);
void GBTimerDeserialize(struct GBTimer* timer, const struct GBSerializedState* state);

#endif
