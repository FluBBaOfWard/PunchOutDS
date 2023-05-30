
#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMZ80/ARMZ80.i"
#include "RP2A03/RP2A03.i"
#include "PUVideo.i"

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global cpu01SetIRQ

	.global rp2A03_0


	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]

	ldr r2,=yStart
	ldrb r1,[r2]
	tst r0,#0x200				;@ L?
	subsne r1,#1
	movmi r1,#0
	tst r0,#0x100				;@ R?
	addne r1,#1
	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
	strb r1,[r2]

	bl refreshEMUjoypads		;@ Z=1 if communication ok

;@----------------------------------------------------------------------------
puFrameLoop:
;@----------------------------------------------------------------------------
	ldr rp2a03ptr,=rp2A03_0
	ldr r0,rp2A03CyclesPerScanline
	bl rp2A03RestoreAndRunXCycles
	add r0,rp2a03ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}				;@ Save M6502 state
;@--------------------------------------
	ldr z80ptr,=Z80OpTable
	ldr r0,z80CyclesPerScanline
	bl Z80RestoreAndRunXCycles
	add r0,z80ptr,#z80Regs
	stmia r0,{z80f-z80pc,z80sp}				;@ Save Z80 state
;@--------------------------------------
	ldr puptr,=puVideo_0
	bl doScanline
	cmp r0,#0
	beq puFrameLoop
;@----------------------------------------------------------------------------

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
cpu01SetIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,z80ptr,lr}
	ldr z80ptr,=Z80OpTable
	bl Z80SetNMIPin
	ldmfd sp!,{r0}
	ldr rp2a03ptr,=rp2A03_0
	bl rp2A03SetNMIPin
	ldmfd sp!,{z80ptr,pc}
;@----------------------------------------------------------------------------
z80CyclesPerScanline:	.long 0
rp2A03CyclesPerScanline:	.long 0
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type   stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
;@----------------------------------------------------------------------------
puStepLoop:
;@----------------------------------------------------------------------------
	ldr rp2a03ptr,=rp2A03_0
	ldr r0,rp2A03CyclesPerScanline
	bl rp2A03RestoreAndRunXCycles
	add r0,rp2a03ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}				;@ Save M6502 state
;@--------------------------------------
	ldr z80ptr,=Z80OpTable
	ldr r0,z80CyclesPerScanline
	bl Z80RestoreAndRunXCycles
	add r0,z80ptr,#z80Regs
	stmia r0,{z80f-z80pc,z80sp}				;@ Save Z80 state
;@--------------------------------------
	ldr puptr,=puVideo_0
	bl doScanline
	cmp r0,#0
	beq puStepLoop
;@----------------------------------------------------------------------------
	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
cpuInit:
	stmfd sp!,{rp2a03ptr,lr}
	ldr rp2a03ptr,=rp2A03_0
	mov r0,rp2a03ptr
	bl rp2A03Init
	bl SetupM6502Mapping
	ldr r0,=soundLatch10R
	str r0,[rp2a03ptr,#rp2A03IORead0]
	ldr r0,=soundLatch11R
	str r0,[rp2a03ptr,#rp2A03IORead1]
	ldmfd sp!,{rp2a03ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 4.0MHz / 60Hz		;Punch Out Z80.
	ldr r0,=253
	str r0,z80CyclesPerScanline
;@--------------------------------------
	ldr z80ptr,=Z80OpTable

	adr r4,cpuMapData
	bl mapZ80Memory

	mov r0,z80ptr
	mov r1,#0
	bl Z80Reset


;@---Speed - 1.76MHz / 60Hz		;Punch Out RP2A03.
	ldr r0,=341
	str r0,rp2A03CyclesPerScanline
;@--------------------------------------
	ldr r0,=rp2A03_0
	bl rp2A03Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
cpuMapData:
;@	.byte 0x07,0x06,0x05,0x04,0xFD,0xF8,0xFE,0xFF			;@ Double Dribble CPU0
;@	.byte 0x0B,0x0A,0x09,0x08,0xFB,0xFB,0xF9,0xF8			;@ Double Dribble CPU1
;@	.byte 0x0F,0x0E,0x0D,0x0C,0xFB,0xFB,0xFB,0xFA			;@ Double Dribble CPU2
;@	.byte 0x09,0x08,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Jackal CPU0
;@	.byte 0x0D,0x0C,0x0B,0x0A,0xF8,0xFD,0xFA,0xFB			;@ Jackal CPU1
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Iron Horse
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Finalizer
;@	.byte 0x03,0x02,0x01,0x00,0xF9,0xF9,0xFF,0xFE			;@ Jail Break
;@	.byte 0xFF,0xFE,0x05,0x04,0x03,0x02,0x01,0x00			;@ Green Beret
	.byte 0xFF,0xFE,0x05,0x04,0x03,0x02,0x01,0x00			;@ Punch-Out!! Z80
;@----------------------------------------------------------------------------
mapZ80Memory:
	stmfd sp!,{lr}
	mov r5,#0x80
z80DataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl z80Mapper
	movs r5,r5,lsr#1
	bne z80DataLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits			;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits		;@ For the GBA
#else
	.section .text
#endif
;@----------------------------------------------------------------------------
rp2A03_0:
	.space rp2A03Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
