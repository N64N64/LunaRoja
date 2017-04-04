/* Copyright (c) 2013-2014 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef DEBUGGER_H
#define DEBUGGER_H

#include "util/common.h"

#include "arm/arm.h"
#include "core/log.h"
#include "util/vector.h"

mLOG_DECLARE_CATEGORY(DEBUGGER);

extern const uint32_t DEBUGGER_ID;

enum mDebuggerType {
	DEBUGGER_NONE = 0,
#ifdef USE_CLI_DEBUGGER
	DEBUGGER_CLI,
#endif
#ifdef USE_GDB_STUB
	DEBUGGER_GDB,
#endif
	DEBUGGER_MAX
};

enum mDebuggerState {
	DEBUGGER_PAUSED,
	DEBUGGER_RUNNING,
	DEBUGGER_CUSTOM,
	DEBUGGER_SHUTDOWN
};

enum mWatchpointType {
	WATCHPOINT_WRITE = 1,
	WATCHPOINT_READ = 2,
	WATCHPOINT_RW = WATCHPOINT_WRITE | WATCHPOINT_READ
};

enum mBreakpointType {
	BREAKPOINT_HARDWARE,
	BREAKPOINT_SOFTWARE
};

enum mDebuggerEntryReason {
	DEBUGGER_ENTER_MANUAL,
	DEBUGGER_ENTER_ATTACHED,
	DEBUGGER_ENTER_BREAKPOINT,
	DEBUGGER_ENTER_WATCHPOINT,
	DEBUGGER_ENTER_ILLEGAL_OP
};

struct mDebugWatchpoint {
	uint32_t address;
	enum mWatchpointType type;
};

extern const char* ERROR_MISSING_ARGS;
extern const char* ERROR_OVERFLOW;

struct mDebuggerEntryInfo {
	uint32_t address;
	union {
		struct {
			uint32_t oldValue;
			uint32_t newValue;
			enum mWatchpointType watchType;
			enum mWatchpointType accessType;
		};

		struct {
			uint32_t opcode;
			enum mBreakpointType breakType;
		};
	};
};

struct mDebugger;
struct mDebuggerPlatform {
	struct mDebugger* p;

	void (*init)(void* cpu, struct mDebuggerPlatform*);
	void (*deinit)(struct mDebuggerPlatform*);
	void (*entered)(struct mDebuggerPlatform*, enum mDebuggerEntryReason, struct mDebuggerEntryInfo*);

	bool (*hasBreakpoints)(struct mDebuggerPlatform*);
	void (*setBreakpoint)(struct mDebuggerPlatform*, uint32_t address);
	void (*clearBreakpoint)(struct mDebuggerPlatform*, uint32_t address);
	void (*setWatchpoint)(struct mDebuggerPlatform*, uint32_t address, enum mWatchpointType type);
	void (*clearWatchpoint)(struct mDebuggerPlatform*, uint32_t address);
	void (*checkBreakpoints)(struct mDebuggerPlatform*);
};

struct mDebugger {
	struct mCPUComponent d;
	struct mDebuggerPlatform* platform;
	enum mDebuggerState state;
	struct mCore* core;

	void (*init)(struct mDebugger*);
	void (*deinit)(struct mDebugger*);

	void (*paused)(struct mDebugger*);
	void (*entered)(struct mDebugger*, enum mDebuggerEntryReason, struct mDebuggerEntryInfo*);
	void (*custom)(struct mDebugger*);
};

struct mDebugger* mDebuggerCreate(enum mDebuggerType type, struct mCore*);
void mDebuggerAttach(struct mDebugger*, struct mCore*);
void mDebuggerRun(struct mDebugger*);
void mDebuggerEnter(struct mDebugger*, enum mDebuggerEntryReason, struct mDebuggerEntryInfo*);


#endif
