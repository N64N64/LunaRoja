ffi.cdef[[
struct TableList;
struct Table {
	struct TableList* table;
	size_t tableSize;
	size_t size;
	void (*deinitializer)(void*);
};
struct Configuration {
	struct Table sections;
	struct Table root;
};
struct mCoreConfig {
	struct Configuration configTable;
	struct Configuration defaultsTable;
	struct Configuration overridesTable;
	char* port;
};
struct mCoreOptions {
	char* bios;
	bool skipBios;
	bool useBios;
	int logLevel;
	int frameskip;
	bool rewindEnable;
	int rewindBufferCapacity;
	float fpsTarget;
	size_t audioBuffers;
	unsigned sampleRate;

	int fullscreen;
	int width;
	int height;
	bool lockAspectRatio;
	bool resampleVideo;
	bool suspendScreensaver;
	char* shader;

	char* savegamePath;
	char* savestatePath;
	char* screenshotPath;
	char* patchPath;

	int volume;
	bool mute;

	bool videoSync;
	bool audioSync;
};

struct VDir;
struct mDirectorySet {
	char baseName[128]; // PATH_MAX
	struct VDir* base;
	struct VDir* archive;
	struct VDir* save;
	struct VDir* patch;
	struct VDir* state;
	struct VDir* screenshot;
};

struct mInputMapImpl;
struct mInputMap {
	struct mInputMapImpl* maps;
	size_t numMaps;
	const struct mInputPlatformInfo* info;
};

struct mRTCSource;
struct mCoreSync;
struct mStateExtdata;
struct mDebugger;
struct mCore {
	struct LR35902Core *cpu;
	void* board;
	struct mDebugger* debugger;

	struct mDirectorySet dirs;
	struct mInputMap inputMap;

	struct mCoreConfig config;
	struct mCoreOptions opts;

	bool (*init)(struct mCore*);
	void (*deinit)(struct mCore*);

	int (*platform)(const struct mCore*);

	void (*setSync)(struct mCore*, void*);
	void (*loadConfig)(struct mCore*, const struct mCoreConfig*);

	void (*desiredVideoDimensions)(struct mCore*, unsigned* width, unsigned* height);
	void (*setVideoBuffer)(struct mCore*, void* buffer, size_t stride);

	void (*getPixels)(struct mCore*, const void** buffer, size_t* stride);
	void (*putPixels)(struct mCore*, const void* buffer, size_t stride);

	void* (*getAudioChannel)(struct mCore*, int ch);
	void (*setAudioBufferSize)(struct mCore*, size_t samples);
	size_t (*getAudioBufferSize)(struct mCore*);

	void (*setCoreCallbacks)(struct mCore*, void*);
	void (*setAVStream)(struct mCore*, void*);

	bool (*isROM)(void* vf);
	bool (*loadROM)(struct mCore*, void* vf);
	bool (*loadSave)(struct mCore*, void* vf);
	bool (*loadTemporarySave)(struct mCore*, void* vf);
	void (*unloadROM)(struct mCore*);

	bool (*loadBIOS)(struct mCore*, void* vf, int biosID);
	bool (*selectBIOS)(struct mCore*, int biosID);

	bool (*loadPatch)(struct mCore*, void* vf);

	void (*reset)(struct mCore*);
	void (*runFrame)(struct mCore*);
	void (*runLoop)(struct mCore*);
	void (*step)(struct mCore*);

	size_t (*stateSize)(struct mCore*);
	bool (*loadState)(struct mCore*, const void* state);
	bool (*saveState)(struct mCore*, void* state);

	void (*setKeys)(struct mCore*, uint32_t keys);
	void (*addKeys)(struct mCore*, uint32_t keys);
	void (*clearKeys)(struct mCore*, uint32_t keys);

	int32_t (*frameCounter)(const struct mCore*);
	int32_t (*frameCycles)(const struct mCore*);
	int32_t (*frequency)(const struct mCore*);

	void (*getGameTitle)(const struct mCore*, char* title);
	void (*getGameCode)(const struct mCore*, char* title);

	void (*setRTC)(struct mCore*, void*);
	void (*setRotation)(struct mCore*, void*);
	void (*setRumble)(struct mCore*, void*);

	uint32_t (*busRead8)(struct mCore*, uint32_t address);
	uint32_t (*busRead16)(struct mCore*, uint32_t address);
	uint32_t (*busRead32)(struct mCore*, uint32_t address);

	void (*busWrite8)(struct mCore*, uint32_t address, uint8_t);
	void (*busWrite16)(struct mCore*, uint32_t address, uint16_t);
	void (*busWrite32)(struct mCore*, uint32_t address, uint32_t);

	uint32_t (*rawRead8)(struct mCore*, uint32_t address, int segment);
	uint32_t (*rawRead16)(struct mCore*, uint32_t address, int segment);
	uint32_t (*rawRead32)(struct mCore*, uint32_t address, int segment);

	void (*rawWrite8)(struct mCore*, uint32_t address, int segment, uint8_t);
	void (*rawWrite16)(struct mCore*, uint32_t address, int segment, uint16_t);
	void (*rawWrite32)(struct mCore*, uint32_t address, int segment, uint32_t);
};

struct mCore * mCoreFind(const char *);
void mCoreInitConfig(struct mCore *, void *);
void mCoreConfigLoadDefaults(void *, struct mCoreOptions *);
bool mCoreLoadFile(struct mCore *, const char*);
void mCoreAutoloadSave(struct mCore *);

void _GBCoreReset(struct mCore* core);
bool _GBCoreInit(struct mCore* core);
void _GBCoreDesiredVideoDimensions(struct mCore* core, unsigned* width, unsigned* height);
void _GBCoreSetVideoBuffer(struct mCore* core, void* buffer, size_t stride);
void* VFileOpen(const char* path, int flags);
bool _GBCoreLoadROM(struct mCore* core, void* vf);
void _GBCoreRunFrame(struct mCore* core);

bool _GBCoreLoadSave(struct mCore* core, void* vf);
void _GBCoreAddKeys(struct mCore* core, uint32_t keys);
void _GBCoreClearKeys(struct mCore* core, uint32_t keys);

void GBPatch8(struct LR35902Core* cpu, uint16_t address, int8_t value, int8_t* old, int segment);
uint8_t GBView8(struct LR35902Core* cpu, uint16_t address, int segment);

// core/cpu.h

enum GBAKey {
	GBA_KEY_A = 0,
	GBA_KEY_B = 1,
	GBA_KEY_SELECT = 2,
	GBA_KEY_START = 3,
	GBA_KEY_RIGHT = 4,
	GBA_KEY_LEFT = 5,
	GBA_KEY_UP = 6,
	GBA_KEY_DOWN = 7,
	GBA_KEY_R = 8,
	GBA_KEY_L = 9,
	GBA_KEY_MAX,
	GBA_KEY_NONE = -1
};

enum mCPUComponentType {
	CPU_COMPONENT_DEBUGGER,
	CPU_COMPONENT_CHEAT_DEVICE,
	CPU_COMPONENT_MAX
};

struct mCPUComponent {
	uint32_t id;
	void (*init)(void* cpu, struct mCPUComponent* component);
	void (*deinit)(struct mCPUComponent* component);
};

// interface.h

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

// memory.h


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

typedef uint8_t GBMBC7Field, uint8_t;
//DECL_BIT(GBMBC7Field, SK, 6);
//DECL_BIT(GBMBC7Field, CS, 7);
//DECL_BIT(GBMBC7Field, IO, 1);

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
struct mRTCSource;
struct mRumble;
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
	uint64_t  rtcLastLatch;
	struct mRTCSource* rtc;
	struct mRotationSource* rotation;
	struct mRumble* rumble;
};


// gb.h

// TODO: Prefix GBAIRQ
enum GBIRQ {
	GB_IRQ_VBLANK = 0x0,
	GB_IRQ_LCDSTAT = 0x1,
	GB_IRQ_TIMER = 0x2,
	GB_IRQ_SIO = 0x3,
	GB_IRQ_KEYPAD = 0x4,
};

enum GBIRQVector {
	GB_VECTOR_VBLANK = 0x40,
	GB_VECTOR_LCDSTAT = 0x48,
	GB_VECTOR_TIMER = 0x50,
	GB_VECTOR_SIO = 0x58,
	GB_VECTOR_KEYPAD = 0x60,
};

enum {
	GB_VIDEO_HORIZONTAL_PIXELS = 160,
	GB_VIDEO_VERTICAL_PIXELS = 144,
	GB_VIDEO_VBLANK_PIXELS = 10,
	GB_VIDEO_VERTICAL_TOTAL_PIXELS = GB_VIDEO_VERTICAL_PIXELS + GB_VIDEO_VBLANK_PIXELS,

	// TODO: Figure out exact lengths
	GB_VIDEO_MODE_2_LENGTH = 76,
	GB_VIDEO_MODE_3_LENGTH_BASE = 171,
	GB_VIDEO_MODE_0_LENGTH_BASE = 209,

	GB_VIDEO_HORIZONTAL_LENGTH = GB_VIDEO_MODE_0_LENGTH_BASE + GB_VIDEO_MODE_2_LENGTH + GB_VIDEO_MODE_3_LENGTH_BASE,

	GB_VIDEO_MODE_1_LENGTH = GB_VIDEO_HORIZONTAL_LENGTH * GB_VIDEO_VBLANK_PIXELS,
	GB_VIDEO_TOTAL_LENGTH = GB_VIDEO_HORIZONTAL_LENGTH * GB_VIDEO_VERTICAL_TOTAL_PIXELS,

	GB_BASE_MAP = 0x1800,
	GB_SIZE_MAP = 0x0400
};

typedef uint8_t GBObjAttributes, uint8_t;

struct GBObj {
	uint8_t y;
	uint8_t x;
	uint8_t tile;
	GBObjAttributes attr;
};

union GBOAM {
	struct GBObj obj[40];
	uint8_t raw[160];
};

// video.h

enum GBModel;
struct mTileCache;
struct GBVideoRenderer {
	void (*init)(struct GBVideoRenderer* renderer, enum GBModel model);
	void (*deinit)(struct GBVideoRenderer* renderer);

	uint8_t (*writeVideoRegister)(struct GBVideoRenderer* renderer, uint16_t address, uint8_t value);
	void (*writeVRAM)(struct GBVideoRenderer* renderer, uint16_t address);
	void (*writePalette)(struct GBVideoRenderer* renderer, int index, uint16_t value);
	void (*drawRange)(struct GBVideoRenderer* renderer, int startX, int endX, int y, struct GBObj* objOnLine, size_t nObj);
	void (*finishScanline)(struct GBVideoRenderer* renderer, int y);
	void (*finishFrame)(struct GBVideoRenderer* renderer);

	void (*getPixels)(struct GBVideoRenderer* renderer, size_t* stride, const void** pixels);
	void (*putPixels)(struct GBVideoRenderer* renderer, size_t stride, const void* pixels);

	uint8_t* vram;
	union GBOAM* oam;
	struct mTileCache* cache;
};

typedef uint8_t GBRegisterLCDC;

typedef uint8_t GBRegisterSTAT;

struct GBVideo {
	struct GB* p;
	struct GBVideoRenderer* renderer;

	int x;
	int ly;
	GBRegisterSTAT stat;

	int mode;

	int32_t nextEvent;
	int32_t eventDiff;

	int32_t nextMode;
	int32_t dotCounter;

	int32_t nextFrame;

	uint8_t* vram;
	uint8_t* vramBank;
	int vramCurrentBank;

	union GBOAM oam;
	struct GBObj objThisLine[10];
	int objMax;

	int bcpIndex;
	bool bcpIncrement;
	int ocpIndex;
	bool ocpIncrement;

	uint16_t palette[64];

	int32_t frameCounter;
	int frameskip;
	int frameskipCounter;
};

// timer.h

typedef uint8_t GBRegisterTAC;

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

// audio.h

typedef uint8_t GBAudioRegisterDuty;
typedef uint8_t GBAudioRegisterSweep;
typedef uint8_t GBAudioRegisterControl;
typedef uint8_t GBAudioRegisterSquareSweep;
typedef uint8_t GBAudioRegisterBank;
typedef uint8_t GBAudioRegisterBankVolume;
typedef uint8_t GBAudioRegisterNoiseFeedback;
typedef uint8_t GBAudioRegisterNoiseControl;
typedef uint8_t GBRegisterNR50;
typedef uint8_t GBRegisterNR51;
typedef uint8_t GBAudioEnable;

struct GB;
struct GBAudioEnvelope {
	int length;
	int duty;
	int stepTime;
	int initialVolume;
	int currentVolume;
	bool direction;
	int dead;
	int nextStep;
};

struct GBAudioSquareControl {
	int frequency;
	int length;
	bool stop;
	int hi;
};

struct GBAudioChannel1 {
	int shift;
	int time;
	int sweepStep;
	bool direction;
	bool sweepEnable;
	bool sweepOccurred;
	int realFrequency;

	struct GBAudioEnvelope envelope;
	struct GBAudioSquareControl control;
	int8_t sample;
};

struct GBAudioChannel2 {
	struct GBAudioEnvelope envelope;
	struct GBAudioSquareControl control;
	int8_t sample;
};

struct GBAudioChannel3 {
	bool size;
	bool bank;
	bool enable;

	unsigned length;
	int volume;

	int rate;
	bool stop;

	int window;
	bool readable;
	union {
		uint32_t wavedata32[8];
		uint8_t wavedata8[16];
	};
	int8_t sample;
};

struct GBAudioChannel4 {
	struct GBAudioEnvelope envelope;

	int ratio;
	int frequency;
	bool power;
	bool stop;
	int length;

	uint32_t lfsr;
	int8_t sample;
};

enum GBAudioStyle {
	GB_AUDIO_DMG,
	GB_AUDIO_CGB,
	GB_AUDIO_AGB, // GB in GBA
	GB_AUDIO_GBA, // GBA PSG
};

struct GBAudio {
	struct GB* p;
	struct GBAudioChannel1 ch1;
	struct GBAudioChannel2 ch2;
	struct GBAudioChannel3 ch3;
	struct GBAudioChannel4 ch4;

	void* left;
	void* right;
	int16_t lastLeft;
	int16_t lastRight;
	int clock;
	int32_t clockRate;

	uint8_t volumeRight;
	uint8_t volumeLeft;
	bool ch1Right;
	bool ch2Right;
	bool ch3Right;
	bool ch4Right;
	bool ch1Left;
	bool ch2Left;
	bool ch3Left;
	bool ch4Left;

	bool playingCh1;
	bool playingCh2;
	bool playingCh3;
	bool playingCh4;
	uint8_t* nr52;

	int32_t nextEvent;
	int32_t eventDiff;
	int32_t nextFrame;
	int frame;
	int32_t nextSample;

	int32_t sampleInterval;
	enum GBAudioStyle style;

	int32_t nextCh1;
	int32_t nextCh2;
	int32_t nextCh3;
	int32_t fadeCh3;
	int32_t nextCh4;
	bool enable;

	size_t samples;
	bool forceDisableCh[4];
	int masterVolume;
};

struct GB;
struct GBSIO {
	struct GB* p;

	int32_t nextEvent;
	int32_t period;
	int remainingBits;

	uint8_t pendingSB;
};


struct mCoreSync;
struct mAVStream;
struct LR35902Core;

#pragma pack(push, 1)
union FlagRegister {
	struct {
		unsigned : 4;
		unsigned c : 1;
		unsigned h : 1;
		unsigned n : 1;
		unsigned z : 1;
	};

	uint8_t packed;
};
#pragma pack(pop)

enum LR35902ExecutionState {
	LR35902_CORE_FETCH = 3,
	LR35902_CORE_IDLE_0 = 0,
	LR35902_CORE_IDLE_1 = 1,
	LR35902_CORE_EXECUTE = 2,

	LR35902_CORE_MEMORY_LOAD = 7,
	LR35902_CORE_MEMORY_STORE = 11,
	LR35902_CORE_READ_PC = 15,
	LR35902_CORE_STALL = 19,
	LR35902_CORE_OP2 = 23
};
struct LR35902Memory {
	uint8_t (*cpuLoad8)(struct LR35902Core*, uint16_t address);
	uint8_t (*load8)(struct LR35902Core*, uint16_t address);
	void (*store8)(struct LR35902Core*, uint16_t address, int8_t value);

	uint8_t* activeRegion;
	uint16_t activeMask;
	uint16_t activeRegionEnd;
	void (*setActiveRegion)(struct LR35902Core*, uint16_t address);
};

struct LR35902InterruptHandler {
	void (*reset)(struct LR35902Core* cpu);
	void (*processEvents)(struct LR35902Core* cpu);
	void (*setInterrupts)(struct LR35902Core* cpu, bool enable);
	void (*halt)(struct LR35902Core* cpu);
	void (*stop)(struct LR35902Core* cpu);

	void (*hitIllegal)(struct LR35902Core* cpu);
};

typedef void (*LR35902Instruction)(struct LR35902Core*);

struct LR35902Core {
    // the alignment is messed up somewhere.
    uint16_t af;
    uint16_t bc;
    uint16_t de;
    uint16_t hl;

	uint16_t sp;
	uint16_t pc;

	uint16_t index;

	int32_t cycles;
	int32_t nextEvent;
	enum LR35902ExecutionState executionState;
	bool halted;

	uint8_t bus;
	bool condition;
    void (*instruction)(struct LR35902Core*);

	bool irqPending;
	uint16_t irqVector;

	struct LR35902Memory memory;
	struct LR35902InterruptHandler irqh;

	struct mCPUComponent* master;

	size_t numComponents;
	struct mCPUComponent** components;
};


struct GB {
	struct mCPUComponent d;

	struct LR35902Core* cpu;
	struct GBMemory memory;

	struct GBVideo video;

	struct GBTimer timer;
	struct GBAudio audio;
	struct GBSIO sio;
	enum GBModel model;

	void* sync; //struct mCoreSync* sync;

	uint8_t* keySource;

	void* pristineRom;
	size_t pristineRomSize;
	size_t yankedRomSize;
	uint32_t romCrc32;
	struct VFile* romVf;
	struct VFile* biosVf;
	struct VFile* sramVf;
	struct VFile* sramRealVf;
	uint32_t sramSize;
	int sramDirty;
	int32_t sramDirtAge;
	bool sramMaskWriteback;

	struct mAVStream* stream;

	int32_t eiPending;
	unsigned doubleSpeed;
};

struct GBCartridge {
	uint8_t entry[4];
	uint8_t logo[48];
	union {
		char titleLong[16];
		struct {
			char titleShort[11];
			char maker[4];
			uint8_t cgb;
		};
	};
	char licensee[2];
	uint8_t sgb;
	uint8_t type;
	uint8_t romSize;
	uint8_t ramSize;
	uint8_t region;
	uint8_t oldLicensee;
	uint8_t version;
	uint8_t headerChecksum;
	uint16_t globalChecksum;
	// And ROM data...
};


]]
