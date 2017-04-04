/* Copyright (c) 2013-2014 Jeffrey Pfau
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef CLI_DEBUGGER_H
#define CLI_DEBUGGER_H

#include "util/common.h"

#include "debugger.h"

#ifdef USE_CLI_DEBUGGER
#include <histedit.h>

struct CLIDebugger;

struct CLIDebugVector {
	struct CLIDebugVector* next;
	enum CLIDVType {
		CLIDV_ERROR_TYPE,
		CLIDV_INT_TYPE,
		CLIDV_CHAR_TYPE,
	} type;
	union {
		char* charValue;
		struct {
			int32_t intValue;
			int segmentValue;
		};
	};
};

typedef void (*CLIDebuggerCommand)(struct CLIDebugger*, struct CLIDebugVector*);
typedef struct CLIDebugVector* (*CLIDVParser)(struct CLIDebugger* debugger, const char* string, size_t length);

struct CLIDebuggerCommandSummary {
	const char* name;
	CLIDebuggerCommand command;
	CLIDVParser parser;
	const char* summary;
};

struct CLIDebuggerSystem {
	struct CLIDebugger* p;

	void (*init)(struct CLIDebuggerSystem*);
	void (*deinit)(struct CLIDebuggerSystem*);
	bool (*custom)(struct CLIDebuggerSystem*);

	void (*disassemble)(struct CLIDebuggerSystem*, struct CLIDebugVector* dv);
	uint32_t (*lookupIdentifier)(struct CLIDebuggerSystem*, const char* name, struct CLIDebugVector* dv);
	uint32_t (*lookupPlatformIdentifier)(struct CLIDebuggerSystem*, const char* name, struct CLIDebugVector* dv);
	void (*printStatus)(struct CLIDebuggerSystem*);

	struct CLIDebuggerCommandSummary* commands;
	const char* name;
	struct CLIDebuggerCommandSummary* platformCommands;
	const char* platformName;
};

struct CLIDebugger {
	struct mDebugger d;

	struct CLIDebuggerSystem* system;

	EditLine* elstate;
	History* histate;
};

struct CLIDebugVector* CLIDVParse(struct CLIDebugger* debugger, const char* string, size_t length);
struct CLIDebugVector* CLIDVStringParse(struct CLIDebugger* debugger, const char* string, size_t length);

void CLIDebuggerCreate(struct CLIDebugger*);
void CLIDebuggerAttachSystem(struct CLIDebugger*, struct CLIDebuggerSystem*);
#endif

#endif
