#include <nds.h>

#include "PunchOut.h"
#include "Cart.h"
#include "Gfx.h"
#include "Sound.h"
#include "PUVideo.h"
#include "RP5C01.h"
#include "RP2A03/RP2A03.h"
#include "ARMZ80/ARMZ80.h"
#include "cpu.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, cpu2Ram, sizeof(cpu2Ram));
	size += sizeof(cpu2Ram);
	size += rp5c01SaveState(statePtr+size);
	size += rp2A03SaveState(statePtr+size, &rp2A03_0);
	size += puVideoSaveState(statePtr+size, &puVideo_0);
	size += Z80SaveState(statePtr+size, &Z80OpTable);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(cpu2Ram, statePtr+size, sizeof(cpu2Ram));
	size += sizeof(cpu2Ram);
	size += rp5c01LoadState(statePtr+size);
	size += rp2A03LoadState(&rp2A03_0, statePtr+size);
	size += puVideoLoadState(&puVideo_0, statePtr+size);
	Z80LoadState(&Z80OpTable, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(cpu2Ram);
	size += rp5c01GetStateSize();
	size += rp2A03GetStateSize();
	size += puVideoGetStateSize();
	size += Z80GetStateSize();
	return size;
}

static const ArcadeRom punchoutRoms[50] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chp1-c.8l",    0x2000, 0xa4003adc},
	{"chp1-c.8k",    0x2000, 0x745ecf40},
	{"chp1-c.8j",    0x2000, 0x7a7f870e},
	{"chp1-c.8h",    0x2000, 0x5d8123d7},
	{"chp1-c.8f",    0x4000, 0xc8a55ddb},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chp1-b.4c",    0x2000, 0x49b763bc},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4d",    0x2000, 0x08bc6d67},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0xc075f831},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xc4cc2b5a},
	{FILL0XFF,       0x6000, 0x00000000},

	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chp1-v.2r",    0x4000, 0xbd1d4b2e},
	{"chp1-v.2t",    0x4000, 0xdd9a688a},
	{"chp1-v.2u",    0x2000, 0xda6a3c4b},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.2v",    0x2000, 0x8c734a67},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3r",    0x4000, 0x2e74ad1d},
	{"chp1-v.3t",    0x4000, 0x630ba9fb},
	{"chp1-v.3u",    0x2000, 0x6440321d},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3v",    0x2000, 0xbb7b7198},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.4r",    0x4000, 0x4e5b0fe9},
	{"chp1-v.4t",    0x4000, 0x37ffc940},
	{"chp1-v.4u",    0x2000, 0x1a7521d4},
	{FILL0XFF,       0x6000, 0x00000000},

	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x75be7aae},
	{"chp1-v.6n",    0x2000, 0xdaf74de0},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0x4cb7ea82},
	{"chp1-v.8n",    0x2000, 0x1c0d09aa},
	//{FILL0XFF,       0x4000, 0x00000000},

	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chp1-b-6e_pink.6e",  0x0200, 0xe9ca3ac6},
	{"chp1-b-6f_pink.6f",  0x0200, 0x02be56ab},
	{"chp1-b-7f_pink.7f",  0x0200, 0x11de55f1},
	{"chp1-b-7e_pink.7e",  0x0200, 0xfddaa777},
	{"chp1-b-8e_pink.8e",  0x0200, 0xc3d5d71f},
	{"chp1-b-8f_pink.8f",  0x0200, 0xa3037155},
	// White labeled color proms (indices are reversed)
	//{"chp1-b-6e_white.6e", 0x0200, 0xddac5f0e},
	//{"chp1-b-6f_white.6f", 0x0200, 0x846c6261},
	//{"chp1-b-7f_white.7f", 0x0200, 0x1682dd30},
	//{"chp1-b-7e_white.7e", 0x0200, 0x47adf7a2},
	//{"chp1-b-8e_white.8e", 0x0200, 0xb0fc15a8},
	//{"chp1-b-8f_white.8f", 0x0200, 0x1ffd894a},
	{"chp1-v-2d.2d",       0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chp1-c.6p",    0x4000, 0xea0bbb31},
};

static const ArcadeRom punchoutaRoms[50] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chp1-c.8l",    0x2000, 0xa4003adc},
	{"chp1-c.8k",    0x2000, 0x745ecf40},
	{"chp1-c.8j",    0x2000, 0x7a7f870e},
	{"chp1-c.8h",    0x2000, 0x5d8123d7},
	{"chp1-c.8f",    0x4000, 0xc8a55ddb},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chp1-b.4c",    0x2000, 0xe26dc8b3},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4d",    0x2000, 0xdd1310ca},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0x20fb4829},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xedc34594},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chp1-v.2r",    0x4000, 0xbd1d4b2e},
	{"chp1-v.2t",    0x4000, 0xdd9a688a},
	{"chp1-v.2u",    0x2000, 0xda6a3c4b},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.2v",    0x2000, 0x8c734a67},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3r",    0x4000, 0x2e74ad1d},
	{"chp1-v.3t",    0x4000, 0x630ba9fb},
	{"chp1-v.3u",    0x2000, 0x6440321d},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3v",    0x2000, 0xbb7b7198},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.4r",    0x4000, 0x4e5b0fe9},
	{"chp1-v.4t",    0x4000, 0x37ffc940},
	{"chp1-v.4u",    0x2000, 0x1a7521d4},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x16588f7a},
	{"chp1-v.6n",    0x2000, 0xdc743674},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0xc2db5b4e},
	{"chp1-v.8n",    0x2000, 0xe6af390e},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chp1-b-6e_pink.6e",  0x0200, 0xe9ca3ac6},
	{"chp1-b-6f_pink.6f",  0x0200, 0x02be56ab},
	{"chp1-b-7f_pink.7f",  0x0200, 0x11de55f1},
	{"chp1-b-7e_pink.7e",  0x0200, 0xfddaa777},
	{"chp1-b-8e_pink.8e",  0x0200, 0xc3d5d71f},
	{"chp1-b-8f_pink.8f",  0x0200, 0xa3037155},
	// White labeled color proms (indices are reversed)
	//{"chp1-b-6e_white.6e", 0x0200, 0xddac5f0e},
	//{"chp1-b-6f_white.6f", 0x0200, 0x846c6261},
	//{"chp1-b-7f_white.7f", 0x0200, 0x1682dd30},
	//{"chp1-b-7e_white.7e", 0x0200, 0x47adf7a2},
	//{"chp1-b-8e_white.8e", 0x0200, 0xb0fc15a8},
	//{"chp1-b-8f_white.8f", 0x0200, 0x1ffd894a},
	{"chp1-v-2d.2d",       0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chp1-c.6p",    0x4000, 0xea0bbb31},
};

static const ArcadeRom punchoutjRoms[50] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chp1-c_8l_a.8l", 0x2000, 0x9735eb5a},
	{"chp1-c_8k_a.8k", 0x2000, 0x98baba41},
	{"chp1-c_8j_a.8j", 0x2000, 0x7a7f870e},
	{"chp1-c_8h_a.8h", 0x2000, 0x5d8123d7},
	{"chp1-c_8f_a.8f", 0x4000, 0xea52cda1},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c_4k_a.4k", 0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chp1-b_4c_a.4c", 0x2000, 0xe26dc8b3},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-b_4d_a.4d", 0x2000, 0xdd1310ca},
	{FILL0XFF,         0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b_4a_a.4a", 0x2000, 0x20fb4829},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-b_4b_a.4b", 0x2000, 0xedc34594},
	{FILL0XFF,         0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chp1-v_2r_a.2r", 0x4000, 0xbd1d4b2e},
	{"chp1-v_2t_a.2t", 0x4000, 0xdd9a688a},
	{"chp1-v_2u_a.2u", 0x2000, 0xda6a3c4b},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-v_2v_a.2v", 0x2000, 0x8c734a67},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-v_3r_a.3r", 0x4000, 0x2e74ad1d},
	{"chp1-v_3t_a.3t", 0x4000, 0x630ba9fb},
	{"chp1-v_3u_a.3u", 0x2000, 0x6440321d},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-v_3v_a.3v", 0x2000, 0xbb7b7198},
	{FILL0XFF,         0x2000, 0x00000000},
	{"chp1-v_4r_a.4r", 0x4000, 0x4e5b0fe9},
	{"chp1-v_4t_a.4t", 0x4000, 0x37ffc940},
	{"chp1-v_4u_a.4u", 0x2000, 0x1a7521d4},
	{FILL0XFF,         0x6000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v_6p_a.6p", 0x2000, 0x16588f7a},
	{"chp1-v_6n_a.6n", 0x2000, 0xdc743674},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v_8p_a.8p", 0x2000, 0xc2db5b4e},
	{"chp1-v_8n_a.8n", 0x2000, 0xe6af390e},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chp1-b-6e_pink.6e",  0x0200, 0xe9ca3ac6},
	{"chp1-b-6f_pink.6f",  0x0200, 0x02be56ab},
	{"chp1-b-7f_pink.7f",  0x0200, 0x11de55f1},
	{"chp1-b-7e_pink.7e",  0x0200, 0xfddaa777},
	{"chp1-b-8e_pink.8e",  0x0200, 0xc3d5d71f},
	{"chp1-b-8f_pink.8f",  0x0200, 0xa3037155},
	// White labeled color proms (indices are reversed)
	//{"chp1-b-6e_white.6e", 0x0200, 0xddac5f0e},
	//{"chp1-b-6f_white.6f", 0x0200, 0x846c6261},
	//{"chp1-b-7f_white.7f", 0x0200, 0x1682dd30},
	//{"chp1-b-7e_white.7e", 0x0200, 0x47adf7a2},
	//{"chp1-b-8e_white.8e", 0x0200, 0xb0fc15a8},
	//{"chp1-b-8f_white.8f", 0x0200, 0x1ffd894a},
	{"chp1-v-2d.2d",       0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chp1-c_6p_a.6p",  0x4000, 0x597955ca},
};

static const ArcadeRom punchitaRoms[50] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chp1-c.8l",    0x2000, 0x1d595ce2},
	{"chp1-c.8k",    0x2000, 0xc062fa5c},
	{"chp1-c.8j",    0x2000, 0x48d453ef},
	{"chp1-c.8h",    0x2000, 0x67f5aedc},
	{"chp1-c.8f",    0x4000, 0x761de4f3},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chp1-b.4c",    0x2000, 0x9a9ff1d3},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4d",    0x2000, 0x4c23350f},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0xc075f831},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xc4cc2b5a},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chp1-v.2r",    0x4000, 0xbd1d4b2e},
	{"chp1-v.2t",    0x4000, 0xdd9a688a},
	{"chp1-v.2u",    0x2000, 0xda6a3c4b},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.2v",    0x2000, 0x8c734a67},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3r",    0x4000, 0x2e74ad1d},
	{"chp1-v.3t",    0x4000, 0x630ba9fb},
	{"chp1-v.3u",    0x2000, 0x6440321d},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.3v",    0x2000, 0xbb7b7198},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-v.4r",    0x4000, 0x4e5b0fe9},
	{"chp1-v.4t",    0x4000, 0x37ffc940},
	{"chp1-v.4u",    0x2000, 0x1a7521d4},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x75be7aae},
	{"chp1-v.6n",    0x2000, 0xdaf74de0},
	//{FILL0XFF,     0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0x4cb7ea82},
	{"chp1-v.8n",    0x2000, 0x1c0d09aa},
	//{FILL0XFF,     0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chp1-b-6e_pink.6e",  0x0200, 0xe9ca3ac6},
	{"chp1-b-6f_pink.6f",  0x0200, 0x02be56ab},
	{"chp1-b-7f_pink.7f",  0x0200, 0x11de55f1},
	{"chp1-b-7e_pink.7e",  0x0200, 0xfddaa777},
	{"chp1-b-8e_pink.8e",  0x0200, 0xc3d5d71f},
	{"chp1-b-8f_pink.8f",  0x0200, 0xa3037155},
	// White labeled color proms (indices are reversed)
	//{"chp1-b-6e_white.6e", 0x0200, 0xddac5f0e},
	//{"chp1-b-6f_white.6f", 0x0200, 0x846c6261},
	//{"chp1-b-7f_white.7f", 0x0200, 0x1682dd30},
	//{"chp1-b-7e_white.7e", 0x0200, 0x47adf7a2},
	//{"chp1-b-8e_white.8e", 0x0200, 0xb0fc15a8},
	//{"chp1-b-8f_white.8f", 0x0200, 0x1ffd894a},
	{"chp1-v-2d.2d",       0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chp1-c.6p",    0x4000, 0xea0bbb31},
};

static const ArcadeRom spnchoutRoms[48] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chs1-c.8l",    0x2000, 0x703b9780},
	{"chs1-c.8k",    0x2000, 0xe13719f6},
	{"chs1-c.8j",    0x2000, 0x1fa629e8},
	{"chs1-c.8h",    0x2000, 0x15a6c068},
	{"chs1-c.8f",    0x4000, 0x4ff3cdd9},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chs1-b.4c",    0x2000, 0x9f2ede2d},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-b.4d",    0x2000, 0x143ae5c6},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0xc075f831},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xc4cc2b5a},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chs1-v.2r",    0x4000, 0xff33405d},
	{"chs1-v.2t",    0x4000, 0xf507818b},
	{"chs1-v.2u",    0x4000, 0x0995fc95},
	{"chs1-v.2v",    0x2000, 0xf44d9878},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.3r",    0x4000, 0x09570945},
	{"chs1-v.3t",    0x4000, 0x42c6861c},
	{"chs1-v.3u",    0x4000, 0xbf5d02dd},
	{"chs1-v.3v",    0x2000, 0x5673f4fc},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.4r",    0x4000, 0x8e155758},
	{"chs1-v.4t",    0x4000, 0xb4e43448},
	{"chs1-v.4u",    0x4000, 0x74e0d956},
	{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x75be7aae},
	{"chp1-v.6n",    0x2000, 0xdaf74de0},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0x4cb7ea82},
	{"chp1-v.8n",    0x2000, 0x1c0d09aa},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chs1-b-6e_pink.6e",  0x0200, 0x0ad4d727},
	{"chs1-b-6f_pink.6f",  0x0200, 0x86f5cfdb},
	{"chs1-b-7f_pink.7f",  0x0200, 0x8bd406f8},
	{"chs1-b-7e_pink.7e",  0x0200, 0x4c7e3a67},
	{"chs1-b-8e_pink.8e",  0x0200, 0xec659313},
	{"chs1-b-8f_pink.8f",  0x0200, 0x8b493c09},
	// White labeled color proms (indices are reversed)
	//{"chs1-b-6e_white.6e", 0x0200, 0x8efd867f},
	//{"chs1-b-6f_white.6f", 0x0200, 0x279d6cbc},
	//{"chs1-b-7f_white.7f", 0x0200, 0xcad6b7ad},
	//{"chs1-b-7e_white.7e", 0x0200, 0x9e170f64},
	//{"chs1-b-8e_white.8e", 0x0200, 0x3a2e333b},
	//{"chs1-b-8f_white.8f", 0x0200, 0x1663eed7},
	{"chs1-v.2d",          0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chs1-c.6p",    0x4000, 0xad8b64b8},
};

static const ArcadeRom spnchoutaRoms[48] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chs1-c.8l",    0x2000, 0x703b9780},
	{"chs1-c.8k",    0x2000, 0xe13719f6},
	{"chs1-c.8j",    0x2000, 0x1fa629e8},
	{"chs1-c.8h",    0x2000, 0x15a6c068},
	{"chs1-c.8f",    0x4000, 0x4ff3cdd9},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chs1-b.4c",    0x2000, 0xb017e1e9},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-b.4d",    0x2000, 0xe3de9d18},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0x20fb4829},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xedc34594},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chs1-v.2r",    0x4000, 0xff33405d},
	{"chs1-v.2t",    0x4000, 0xf507818b},
	{"chs1-v.2u",    0x4000, 0x0995fc95},
	{"chs1-v.2v",    0x2000, 0xf44d9878},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.3r",    0x4000, 0x09570945},
	{"chs1-v.3t",    0x4000, 0x42c6861c},
	{"chs1-v.3u",    0x4000, 0xbf5d02dd},
	{"chs1-v.3v",    0x2000, 0x5673f4fc},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.4r",    0x4000, 0x8e155758},
	{"chs1-v.4t",    0x4000, 0xb4e43448},
	{"chs1-v.4u",    0x4000, 0x74e0d956},
	{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x16588f7a},
	{"chp1-v.6n",    0x2000, 0xdc743674},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0xc2db5b4e},
	{"chp1-v.8n",    0x2000, 0xe6af390e},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chs1-b-6e_pink.6e",  0x0200, 0x0ad4d727},
	{"chs1-b-6f_pink.6f",  0x0200, 0x86f5cfdb},
	{"chs1-b-7f_pink.7f",  0x0200, 0x8bd406f8},
	{"chs1-b-7e_pink.7e",  0x0200, 0x4c7e3a67},
	{"chs1-b-8e_pink.8e",  0x0200, 0xec659313},
	{"chs1-b-8f_pink.8f",  0x0200, 0x8b493c09},
	// White labeled color proms (indices are reversed)
	//{"chs1-b-6e_white.6e", 0x0200, 0x8efd867f},
	//{"chs1-b-6f_white.6f", 0x0200, 0x279d6cbc},
	//{"chs1-b-7f_white.7f", 0x0200, 0xcad6b7ad},
	//{"chs1-b-7e_white.7e", 0x0200, 0x9e170f64},
	//{"chs1-b-8e_white.8e", 0x0200, 0x3a2e333b},
	//{"chs1-b-8f_white.8f", 0x0200, 0x1663eed7},
	{"chs1-v.2d",          0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chs1-c.6p",    0x4000, 0xad8b64b8},
};

static const ArcadeRom spnchoutjRoms[48] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chs1c8la.bin", 0x2000, 0xdc2a592b},
	{"chs1c8ka.bin", 0x2000, 0xce687182},
	{"chs1-c.8j",    0x2000, 0x1fa629e8},
	{"chs1-c.8h",    0x2000, 0x15a6c068},
	{"chs1c8fa.bin", 0x4000, 0xf745b5d5},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"b_4c_01a.bin", 0x2000, 0xb017e1e9},
	{FILL0XFF,       0x2000, 0x00000000},
	{"b_4d_01a.bin", 0x2000, 0xe3de9d18},
	{FILL0XFF,       0x2000, 0x00000000},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chp1-b.4a",    0x2000, 0xc075f831},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chp1-b.4b",    0x2000, 0xc4cc2b5a},
	{FILL0XFF,       0x6000, 0x00000000},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chs1-v.2r",    0x4000, 0xff33405d},
	{"chs1-v.2t",    0x4000, 0xf507818b},
	{"chs1-v.2u",    0x4000, 0x0995fc95},
	{"chs1-v.2v",    0x2000, 0xf44d9878},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.3r",    0x4000, 0x09570945},
	{"chs1-v.3t",    0x4000, 0x42c6861c},
	{"chs1-v.3u",    0x4000, 0xbf5d02dd},
	{"chs1-v.3v",    0x2000, 0x5673f4fc},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chs1-v.4r",    0x4000, 0x8e155758},
	{"chs1-v.4t",    0x4000, 0xb4e43448},
	{"chs1-v.4u",    0x4000, 0x74e0d956},
	{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chp1-v.6p",    0x2000, 0x75be7aae},
	{"chp1-v.6n",    0x2000, 0xdaf74de0},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chp1-v.8p",    0x2000, 0x4cb7ea82},
	{"chp1-v.8n",    0x2000, 0x1c0d09aa},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x2100, (int)&promBase}, // See driver notes
	// Pink labeled color proms
	{"chs1-b-6e_pink.6e",  0x0200, 0x0ad4d727},
	{"chs1-b-6f_pink.6f",  0x0200, 0x86f5cfdb},
	{"chs1-b-7f_pink.7f",  0x0200, 0x8bd406f8},
	{"chs1-b-7e_pink.7e",  0x0200, 0x4c7e3a67},
	{"chs1-b-8e_pink.8e",  0x0200, 0xec659313},
	{"chs1-b-8f_pink.8f",  0x0200, 0x8b493c09},
	// White labeled color proms (indices are reversed)
	//{"chs1-b-6e_white.6e", 0x0200, 0x8efd867f},
	//{"chs1-b-6f_white.6f", 0x0200, 0x279d6cbc},
	//{"chs1-b-7f_white.7f", 0x0200, 0xcad6b7ad},
	//{"chs1-b-7e_white.7e", 0x0200, 0x9e170f64},
	//{"chs1-b-8e_white.8e", 0x0200, 0x3a2e333b},
	//{"chs1-b-8f_white.8f", 0x0200, 0x1663eed7},
	{"chs1-v.2d",          0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chs1c6pa.bin", 0x4000, 0xd05fb730},
};

static const ArcadeRom armwrestRoms[43] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code
	{"chv1-c.8l",    0x2000, 0xb09764c1},
	{"chv1-c.8k",    0x2000, 0x0e147ff7},
	{"chv1-c.8j",    0x2000, 0xe7365289},
	{"chv1-c.8h",    0x2000, 0xa2118eec},
	{"chpv-c.8f",    0x4000, 0x664a07c4},
	{ROM_REGION,   0x10000, (int)&soundCpu},   // 64k for the sound CPU
	{"chp1-c.4k",    0x2000, 0xcb6ef376},
	{ROM_REGION,   0x04000, (int)&vromBase0},
	{"chpv-b.2e",    0x4000, 0x8b45f365},
	{"chpv-b.2d",    0x4000, 0xb1a2850c},
	{ROM_REGION,   0x04000, (int)&vromBase1},
	{"chpv-b.2m",    0x4000, 0x19245b37},
	{"chpv-b.2l",    0x4000, 0x46797941},
	{FILL0XFF,       0x2000, 0x00000000},
	{"chpv-b.2k",    0x2000, 0xde189b00},
	{ROM_REGION,   0x30000, (int)&vromBase2},
	{"chv1-v.2r",    0x4000, 0xd86056d9},
	{"chv1-v.2t",    0x4000, 0x5ad77059},
	{FILL0XFF,       0x4000, 0x00000000},
	{"chv1-v.2v",    0x4000, 0xa0fd7338},
	{"chv1-v.3r",    0x4000, 0x690e26fb},
	{"chv1-v.3t",    0x4000, 0xea5d7759},
	{FILL0XFF,       0x4000, 0x00000000},
	{"chv1-v.3v",    0x4000, 0xceb37c05},
	{"chv1-v.4r",    0x4000, 0xe291cba0},
	{"chv1-v.4t",    0x4000, 0xe01f3b59},
	{FILL0XFF,       0x8000, 0x00000000},
	{ROM_REGION,   0x10000, (int)&vromBase3},
	{"chv1-v.6p",    0x2000, 0xd834e142},
	{FILL0XFF,       0x2000, 0x00000000},
	//{FILL0XFF,       0x4000, 0x00000000},
	{"chv1-v.8p",    0x2000, 0xa2f531db},
	{FILL0XFF,       0x2000, 0x00000000},
	//{FILL0XFF,       0x4000, 0x00000000},
	{ROM_REGION,     0x0E00, (int)&promBase},
	{"chpv-b.7b",    0x0200, 0xdf6fdeb3},
	{"chpv-b.7c",    0x0200, 0xb1da5f42},
	{"chpv-b.7d",    0x0200, 0x4ede813e},
	{"chpv-b.4b",    0x0200, 0x9d51416e},
	{"chpv-b.4c",    0x0200, 0xb8a25795},
	{"chpv-b.4d",    0x0200, 0x474fc3b1},
//	{"chv1-b.3c",    0x0100, 0xc3f92ea2},
	{"chpv-v.2d",    0x0100, 0x71dc0d48},
	{ROM_REGION,     0x4000, (int)&vlmBase}, // 16k for the VLM5030 data
	{"chv1-c.6p",    0x4000, 0x31b52896},
};

const ArcadeGame punchoutGames[GAME_COUNT] = {
	AC_GAME("punchout",  "Punch-Out!! (Rev B)", punchoutRoms)
	AC_GAME("punchouta", "Punch-Out!! (Rev A)", punchoutaRoms)
	AC_GAME("punchoutj", "Punch-Out!! (Japan)", punchoutjRoms)
	AC_GAME("punchita",  "Punch-Out!! (Italian bootleg)", punchitaRoms)
	AC_GAME("spnchout",  "Super Punch-Out!! (Rev B)", spnchoutRoms)
	AC_GAME("spnchouta", "Super Punch-Out!! (Rev A)", spnchoutaRoms)
	AC_GAME("spnchoutj", "Super Punch-Out!! (Japan)", spnchoutjRoms)
	AC_GAME("armwrest",  "Arm Wrestling", armwrestRoms)
};
