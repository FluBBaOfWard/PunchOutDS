
#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMZ80/ARMZ80.i"
#include "ARM6502/m6502.i"
#include "PUVideo.i"

	.global cpuReset
	.global run
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global cpu01SetIRQ



	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:		;@ Return after 1 frame
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
	ldr m6502optbl,=m6502OpTable
	ldr r0,m6502CyclesPerScanline
	b m6502RestoreAndRunXCycles
puM6502End:
	add r0,m6502optbl,#m6502Regs
	stmia r0,{m6502nz-m6502pc,m6502zpage}	;@ Save M6502 state
;@--------------------------------------
	ldr z80optbl,=Z80OpTable
	ldr r0,z80CyclesPerScanline
	b Z80RestoreAndRunXCycles
puZ80End:
	add r0,z80optbl,#z80Regs
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
	stmfd sp!,{r0,z80optbl,lr}
	ldr z80optbl,=Z80OpTable
	bl Z80SetNMIPin
	ldmfd sp!,{r0}
	ldr m6502optbl,=m6502OpTable
	bl m6502SetNMIPin
	ldmfd sp!,{z80optbl,pc}
;@----------------------------------------------------------------------------
z80CyclesPerScanline:	.long 0
m6502CyclesPerScanline:	.long 0
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 4.0MHz / 60Hz		;Punch Out Z80.
	ldr r0,=253
	str r0,z80CyclesPerScanline
;@--------------------------------------
	ldr z80optbl,=Z80OpTable

	adr r4,cpuMapData
	bl mapZ80Memory

	adr r0,puZ80End
	str r0,[z80optbl,#z80NextTimeout]
	str r0,[z80optbl,#z80NextTimeout_]

	mov r0,#0
	bl Z80Reset


;@---Speed - 1.76MHz / 60Hz		;Punch Out 6502.
	ldr r0,=113
	str r0,m6502CyclesPerScanline
;@--------------------------------------
	ldr m6502optbl,=m6502OpTable

	adr r4,cpuMapData+8
	bl mapM6502Memory

	adr r0,puM6502End
	str r0,[m6502optbl,#m6502NextTimeout]
	str r0,[m6502optbl,#m6502NextTimeout_]

	mov r0,#0
	bl m6502Reset

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
	.byte 0x06,0xFB,0xFB,0xF0,0xFB,0xFC,0xFB,0xFD			;@ Punch-Out!! M6502
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
mapM6502Memory:
	stmfd sp!,{lr}
	mov r5,#0x80
m6502DataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl m6502Mapper
	movs r5,r5,lsr#1
	bne m6502DataLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
