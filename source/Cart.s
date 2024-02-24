
#ifdef __arm__

#include "Shared/EmuSettings.h"
#include "ARMZ80/ARMZ80mac.h"
#include "RP2A03/RP2A03.i"
#include "PUVideo.i"

	.global machineInit
	.global loadCart
	.global z80Mapper
	.global SetupM6502Mapping
	.global romNum
	.global emuFlags
//	.global scaling
	.global cartFlags
	.global romStart
	.global mainCpu
	.global soundCpu
	.global vromBase0
	.global vromBase1
	.global vromBase2
	.global vromBase3
	.global promBase
	.global vlmBase

	.global cpu2Ram
	.global NV_RAM
	.global EMU_RAM
	.global ROM_Space



	.syntax unified
	.arm

	.section .rodata
	.align 2

rawRom:
/*
// Punch-Out!! Rev B
// Main cpu
	.incbin "punchout/chp1-c.8l"
	.incbin "punchout/chp1-c.8k"
	.incbin "punchout/chp1-c.8j"
	.incbin "punchout/chp1-c.8h"
	.incbin "punchout/chp1-c.8f"
// Sound cpu
	.incbin "punchout/chp1-c.4k"
// Top tiles
	.incbin "punchout/chp1-b.4c"
	.space 0x2000
	.incbin "punchout/chp1-b.4d"
	.space 0x2000
// Bottom tiles
	.incbin "punchout/chp1-b.4a"
	.space 0x2000
	.incbin "punchout/chp1-b.4b"
	.space 0x6000
// BigSprite 1 tiles
	.incbin "punchout/chp1-v.2r"
	.incbin "punchout/chp1-v.2t"
	.incbin "punchout/chp1-v.2u"
	.space 0x2000
	.incbin "punchout/chp1-v.2v"
	.space 0x2000
	.incbin "punchout/chp1-v.3r"
	.incbin "punchout/chp1-v.3t"
	.incbin "punchout/chp1-v.3u"
	.space 0x2000
	.incbin "punchout/chp1-v.3v"
	.space 0x2000
	.incbin "punchout/chp1-v.4r"
	.incbin "punchout/chp1-v.4t"
	.incbin "punchout/chp1-v.4u"
	.space 0x2000
	.space 0x4000
// BigSprite 2 tiles
	.incbin "punchout/chp1-v.6p"
	.incbin "punchout/chp1-v.6n"
	.incbin "punchout/chp1-v.8p"
	.incbin "punchout/chp1-v.8n"
// Proms
	.incbin "punchout/chp1-b-6e_pink.6e"
	.incbin "punchout/chp1-b-6f_pink.6f"
	.incbin "punchout/chp1-b-7f_pink.7f"
	.incbin "punchout/chp1-b-7e_pink.7e"
	.incbin "punchout/chp1-b-8e_pink.8e"
	.incbin "punchout/chp1-b-8f_pink.8f"

//	.incbin "punchouta/chp1-b-6e_white.6e"
//	.incbin "punchouta/chp1-b-6f_white.6f"
//	.incbin "punchouta/chp1-b-7f_white.7f"
//	.incbin "punchouta/chp1-b-7e_white.7e"
//	.incbin "punchouta/chp1-b-8e_white.8e"
//	.incbin "punchouta/chp1-b-8f_white.8f"
	.incbin "punchouta/chp1-v-2d.2d"
// VLM data
	.incbin "punchout/chp1-c.6p"
*/
/*
// Punch-Out!! Rev A
// Main cpu
	.incbin "punchouta/chp1-c.8l"
	.incbin "punchouta/chp1-c.8k"
	.incbin "punchouta/chp1-c.8j"
	.incbin "punchouta/chp1-c.8h"
	.incbin "punchouta/chp1-c.8f"
// Sound cpu
	.incbin "punchouta/chp1-c.4k"
// Top tiles
	.incbin "punchouta/chp1-b.4c"
	.space 0x2000
	.incbin "punchouta/chp1-b.4d"
	.space 0x2000
// Bottom tiles
	.incbin "punchouta/chp1-b.4a"
	.space 0x2000
	.incbin "punchouta/chp1-b.4b"
	.space 0x6000
// BigSprite 1 tiles
	.incbin "punchouta/chp1-v.2r"
	.incbin "punchouta/chp1-v.2t"
	.incbin "punchouta/chp1-v.2u"
	.space 0x2000
	.incbin "punchouta/chp1-v.2v"
	.space 0x2000
	.incbin "punchouta/chp1-v.3r"
	.incbin "punchouta/chp1-v.3t"
	.incbin "punchouta/chp1-v.3u"
	.space 0x2000
	.incbin "punchouta/chp1-v.3v"
	.space 0x2000
	.incbin "punchouta/chp1-v.4r"
	.incbin "punchouta/chp1-v.4t"
	.incbin "punchouta/chp1-v.4u"
	.space 0x2000
	.space 0x4000
// BigSprite 2 tiles
	.incbin "punchouta/chp1-v.6p"
	.incbin "punchouta/chp1-v.6n"
	.incbin "punchouta/chp1-v.8p"
	.incbin "punchouta/chp1-v.8n"
// Proms
	.incbin "punchouta/chp1-b-6e_pink.6e"
	.incbin "punchouta/chp1-b-6f_pink.6f"
	.incbin "punchouta/chp1-b-7f_pink.7f"
	.incbin "punchouta/chp1-b-7e_pink.7e"
	.incbin "punchouta/chp1-b-8e_pink.8e"
	.incbin "punchouta/chp1-b-8f_pink.8f"

//	.incbin "punchouta/chp1-b-6e_white.6e"
//	.incbin "punchouta/chp1-b-6f_white.6f"
//	.incbin "punchouta/chp1-b-7f_white.7f"
//	.incbin "punchouta/chp1-b-7e_white.7e"
//	.incbin "punchouta/chp1-b-8e_white.8e"
//	.incbin "punchouta/chp1-b-8f_white.8f"
	.incbin "punchouta/chp1-v-2d.2d"
// VLM data
	.incbin "punchouta/chp1-c.6p"
*/
/*
// Super Punch-Out!!
// Main cpu
	.incbin "spunchout/chs1-c.8l"
	.incbin "spunchout/chs1-c.8k"
	.incbin "spunchout/chs1-c.8j"
	.incbin "spunchout/chs1-c.8h"
	.incbin "spunchout/chs1-c.8f"
// Sound cpu
	.incbin "spunchout/chp1-c.4k"
// Top tiles
	.incbin "spunchout/chs1-b.4c"
	.space 0x2000
	.incbin "spunchout/chs1-b.4d"
	.space 0x2000
// Bottom tiles
	.incbin "spunchout/chp1-b.4a"
	.space 0x2000
	.incbin "spunchout/chp1-b.4b"
	.space 0x6000
// BigSprite 1 tiles
	.incbin "spunchout/chs1-v.2r"
	.incbin "spunchout/chs1-v.2t"
	.incbin "spunchout/chs1-v.2u"
	.incbin "spunchout/chs1-v.2v"
	.space 0x2000
	.incbin "spunchout/chs1-v.3r"
	.incbin "spunchout/chs1-v.3t"
	.incbin "spunchout/chs1-v.3u"
	.incbin "spunchout/chs1-v.3v"
	.space 0x2000
	.incbin "spunchout/chs1-v.4r"
	.incbin "spunchout/chs1-v.4t"
	.incbin "spunchout/chs1-v.4u"
	.space 0x4000
// BigSprite 2 tiles
	.incbin "spunchout/chp1-v.6p"
	.incbin "spunchout/chp1-v.6n"
	.incbin "spunchout/chp1-v.8p"
	.incbin "spunchout/chp1-v.8n"
// Proms
	.incbin "spunchout/chs1-b.6e"
	.incbin "spunchout/chs1-b.6f"
	.incbin "spunchout/chs1-b.7f"
	.incbin "spunchout/chs1-b.7e"
	.incbin "spunchout/chs1-b.8e"
	.incbin "spunchout/chs1-b.8f"
	.incbin "spunchout/chs1-v.2d"
// VLM data
	.incbin "spunchout/chs1-c.6p"
*/
/*
// Super Punch-Out!! Rev A
// Main cpu
	.incbin "spnchouta/chs1-c.8l"
	.incbin "spnchouta/chs1-c.8k"
	.incbin "spnchouta/chs1-c.8j"
	.incbin "spnchouta/chs1-c.8h"
	.incbin "spnchouta/chs1-c.8f"
// Sound cpu
	.incbin "spnchouta/chp1-c.4k"
// Top tiles
	.incbin "spnchouta/chs1-b.4c"
	.space 0x2000
	.incbin "spnchouta/chs1-b.4d"
	.space 0x2000
// Bottom tiles
	.incbin "spnchouta/chp1-b.4a"
	.space 0x2000
	.incbin "spnchouta/chp1-b.4b"
	.space 0x6000
// BigSprite 1 tiles
	.incbin "spnchouta/chs1-v.2r"
	.incbin "spnchouta/chs1-v.2t"
	.incbin "spnchouta/chs1-v.2u"
	.incbin "spnchouta/chs1-v.2v"
	.space 0x2000
	.incbin "spnchouta/chs1-v.3r"
	.incbin "spnchouta/chs1-v.3t"
	.incbin "spnchouta/chs1-v.3u"
	.incbin "spnchouta/chs1-v.3v"
	.space 0x2000
	.incbin "spnchouta/chs1-v.4r"
	.incbin "spnchouta/chs1-v.4t"
	.incbin "spnchouta/chs1-v.4u"
	.space 0x4000
// BigSprite 2 tiles
	.incbin "spnchouta/chp1-v.6p"
	.incbin "spnchouta/chp1-v.6n"
	.incbin "spnchouta/chp1-v.8p"
	.incbin "spnchouta/chp1-v.8n"
// Proms
	.incbin "spnchouta/chs1-b-6e_pink.6e"
	.incbin "spnchouta/chs1-b-6f_pink.6f"
	.incbin "spnchouta/chs1-b-7f_pink.7f"
	.incbin "spnchouta/chs1-b-7e_pink.7e"
	.incbin "spnchouta/chs1-b-8e_pink.8e"
	.incbin "spnchouta/chs1-b-8f_pink.8f"

//	.incbin "spnchouta/chs1-b-6e_white.6e"
//	.incbin "spnchouta/chs1-b-6f_white.6f"
//	.incbin "spnchouta/chs1-b-7f_white.7f"
//	.incbin "spnchouta/chs1-b-7e_white.7e"
//	.incbin "spnchouta/chs1-b-8e_white.8e"
//	.incbin "spnchouta/chs1-b-8f_white.8f"
	.incbin "spnchouta/chs1-v.2d"
// VLM data
	.incbin "spnchouta/chs1-c.6p"
*/
/*
// Arm Wrestling
// Main Cpu
	.incbin "armwrest/chv1-c.8l"
	.incbin "armwrest/chv1-c.8k"
	.incbin "armwrest/chv1-c.8j"
	.incbin "armwrest/chv1-c.8h"
	.incbin "armwrest/chpv-c.8f"
// audiocpu
	.incbin "armwrest/chp1-c.4k"
// gfx1
	.incbin "armwrest/chpv-b.2e"
	.incbin "armwrest/chpv-b.2d"
// gfx2
	.incbin "armwrest/chpv-b.2m"
	.incbin "armwrest/chpv-b.2l"
	.space 0x2000
	.incbin "armwrest/chpv-b.2k"
// gfx3
	.incbin "armwrest/chv1-v.2r"
	.incbin "armwrest/chv1-v.2t"
	.space 0x4000
	.incbin "armwrest/chv1-v.2v"
	.incbin "armwrest/chv1-v.3r"
	.incbin "armwrest/chv1-v.3t"
	.space 0x4000
	.incbin "armwrest/chv1-v.3v"
	.incbin "armwrest/chv1-v.4r"
	.incbin "armwrest/chv1-v.4t"
	.space 0x4000
	.space 0x4000
// gfx4
	.incbin "armwrest/chv1-v.6p"
	.space 0x2000
	.incbin "armwrest/chv1-v.8p"
	.space 0x2000
// Proms
	.incbin "armwrest/chpv-b.7b"
	.incbin "armwrest/chpv-b.7c"
	.incbin "armwrest/chpv-b.7d"
	.incbin "armwrest/chpv-b.4b"
	.incbin "armwrest/chpv-b.4c"
	.incbin "armwrest/chpv-b.4d"
	.incbin "armwrest/chv1-b.3c"
	.incbin "armwrest/chpv-v.2d"
// VLM data
	.incbin "armwrest/chv1-c.6p"
*/
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
//	ldr r0,=rawRom
	ldr r0,=ROM_Space

	str r0,romStart				;@ Set rom base
	add r0,r0,#0xC000			;@ 0xC000
	str r0,soundCpu				;@ Sound cpu rom
	add r0,r0,#0x2000			;@ 0x2000
	str r0,vromBase0			;@ Top tile map
	add r0,r0,#0x8000
	str r0,vromBase1			;@ Bottom tile map
	add r0,r0,#0xC000
	str r0,vromBase2			;@ Big sprite 1
	add r0,r0,#0x30000
	str r0,vromBase3			;@ Big sprite 2
	add r0,r0,#0x8000
	str r0,promBase				;@ Colour prom
	add r0,r0,#0xD00
	str r0,vlmBase				;@ VLM data

	bl gfxInit
//	bl ioInit
	bl soundInit
	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

//	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuFlags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
//	mov r0,#GamePunchOutB
//	mov r0,#GamePunchOutA
//	mov r0,#GameArmWrestling
	str r0,romNum
	str r1,emuFlags
	mov r11,r0

//	ldr r3,=rawRom
	ldr r3,=ROM_Space			;@ r3=romBase til end of loadcart so DON'T FUCK IT UP

	ldr r4,=MEMMAPTBL_
	ldr r5,=RDMEMTBL_
	ldr r6,=WRMEMTBL_
	ldr r7,=memZ80R0
	ldr r8,=rom_W
	mov r0,#0
tbloop1:
	add r1,r3,r0,lsl#13
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]
	str r8,[r6,r0,lsl#2]
	add r0,r0,#1
	cmp r0,#0x06
	bne tbloop1

	ldr r7,=empty_R
	ldr r8,=empty_W
tbloop2:
	str r3,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]
	str r8,[r6,r0,lsl#2]
	add r0,r0,#1
	cmp r0,#0x100
	bne tbloop2

	ldr r1,=EMU_RAM
	ldr r7,=memZ80R6
	ldr r8,=ramZ80W
	mov r0,#0xFE				;@ RAM
	str r1,[r4,r0,lsl#2]		;@ MemMap
	str r7,[r5,r0,lsl#2]		;@ RdMem
	str r8,[r6,r0,lsl#2]		;@ WrMem

	add r1,r1,#0x2000
	ldr r7,=memZ80R7
	mov r0,#0xFF				;@ RAM
	str r1,[r4,r0,lsl#2]		;@ MemMap
	str r7,[r5,r0,lsl#2]		;@ RdMem
	str r8,[r6,r0,lsl#2]		;@ WrMem


	mov r0,r11					;@ Rom number
	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	ldr r1,vlmBase
	mov r2,#0x4000				;@ ROM size
	blx VLM5030_set_rom

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
SetupM6502Mapping:			;@ Call with rp2a03ptr initialized
;@----------------------------------------------------------------------------
	mov r0,#0
	ldr r1,=empty_R
	ldr r2,=empty_W

	str r0,[rp2a03ptr,#m6502MemTbl+4]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+4]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+4]	;@ WrMem

	str r0,[rp2a03ptr,#m6502MemTbl+12]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+12]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+12]	;@ WrMem

	str r0,[rp2a03ptr,#m6502MemTbl+16]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+16]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+16]	;@ WrMem

	str r0,[rp2a03ptr,#m6502MemTbl+20]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+20]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+20]	;@ WrMem

	str r0,[rp2a03ptr,#m6502MemTbl+24]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+24]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+24]	;@ WrMem

	ldr r0,=cpu2Ram
	ldr r1,=mem6502R0
	ldr r2,=ram6502W
	str r0,[rp2a03ptr,#m6502MemTbl]		;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl]		;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl]	;@ WrMem

	ldr r0,soundCpu
	sub r0,r0,#0xE000
	ldr r1,=mem6502R7
	ldr r2,=rom_W
	str r0,[rp2a03ptr,#m6502MemTbl+28]	;@ MemMap
	str r1,[rp2a03ptr,#m6502ReadTbl+28]	;@ RdMem
	str r2,[rp2a03ptr,#m6502WriteTbl+28]	;@ WrMem

	bx lr
;@----------------------------------------------------------------------------
z80Mapper:		;@ Rom paging..
;@----------------------------------------------------------------------------
	ands r0,r0,#0xFF			;@ Safety
	bxeq lr
	stmfd sp!,{r3-r8,lr}
	ldr r5,=MEMMAPTBL_
	ldr r2,[r5,r1,lsl#2]!
	ldr r3,[r5,#-1024]			;@ RDMEMTBL_
	ldr r4,[r5,#-2048]			;@ WRMEMTBL_

	mov r5,#0
	cmp r1,#0x88
	movmi r5,#12

	add r6,z80ptr,#z80ReadTbl
	add r7,z80ptr,#z80WriteTbl
	add r8,z80ptr,#z80MemTbl
	b z80MemAps
z80MemApl:
	add r6,r6,#4
	add r7,r7,#4
	add r8,r8,#4
z80MemAp2:
	add r3,r3,r5
	sub r2,r2,#0x2000
z80MemAps:
	movs r0,r0,lsr#1
	bcc z80MemApl				;@ C=0
	strcs r3,[r6],#4			;@ readmem_tbl
	strcs r4,[r7],#4			;@ writemem_tb
	strcs r2,[r8],#4			;@ memmap_tbl
	bne z80MemAp2

;@------------------------------------------
z80Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	reEncodePC

	ldmfd sp!,{r3-r8,lr}
	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romNumber
romInfo:						;@ Keep emuFlags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ emuFlags      (label this so Gui.c can take a peek) see EmuSettings.h for bitfields
//scaling:
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartFlags
	.space 3

romStart:
mainCpu:
	.long 0
soundCpu:
	.long 0
vromBase0:
	.long 0
vromBase1:
	.long 0
vromBase2:
	.long 0
vromBase3:
	.long 0
promBase:
	.long 0
vlmBase:
	.long 0

	.section .bss
WRMEMTBL_:
	.space 256*4
RDMEMTBL_:
	.space 256*4
MEMMAPTBL_:
	.space 256*4
cpu2Ram:
	.space 0x0800
NV_RAM:
EMU_RAM:
	.space 0x4000
ROM_Space:
	.space 0x5ED00

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
