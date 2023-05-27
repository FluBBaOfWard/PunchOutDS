
#ifdef __arm__

#include "ARMZ80/ARMZ80mac.h"
#include "PUVideo.i"
#include "RP2A03/RP2A03.i"

	.global ioReset
	.global Z80In
	.global Z80Out
	.global refreshEMUjoypads
	.global soundLatch10R
	.global soundLatch11R

	.global joyCfg
	.global EMUinput
	.global gDipSwitch0
	.global gDipSwitch1
	.global gDipSwitch2
	.global gDipSwitch3
	.global coinCounter0
	.global coinCounter1

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	b rp5c01Reset
	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------
		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	and r0,r4,#0xf0
	mov r3,r4
		ldr r2,joyCfg
		andcs r4,r4,r2
		tstcs r4,r4,lsr#10		;@ L?
		andcs r4,r4,r2,lsr#16
//	adr r1,rlud2lrud
//	ldrb r1,[r1,r0,lsr#4]
	mov r1,r0,lsr#4

	mov r0,#0x40
	tst r3,#0x800				;@ Y
//	orrne r0,r0,#0x01			;@ Button 1
	orrne r0,r0,#0x21			;@ Button 1 + Start button 1 (Arm Wrestling)
	tst r3,#0x400				;@ X
	orrne r0,r0,#0x04			;@ Button 2
	tst r3,#0x01				;@ A
	orrne r0,r0,#0x08			;@ Button 3
	tst r3,#0x02				;@ B
	bicne r0,r0,#0x40			;@ Button 4, active low

	tst r4,#0x4					;@ Select
	orrne r1,r1,#0x80			;@ Coin 1
	tst r4,#0x8					;@ Start
	orrne r1,r1,#0x40			;@ Service Coin
//	orrne r1,r1,#0x20			;@ Coin 2
//	tst r2,#0x20000000			;@ Player2?
//	movne r1,r0
//	movne r0,#0
//	movne r3,r3,lsl#1

	strb r0,joy0State
	strb r1,joy1State
//	strb r3,joy2State
	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
nrPlayers:	.long 0			;@ Number of players in multilink.
joySerial:	.byte 0
joy0State:	.byte 0
joy1State:	.byte 0
joy2State:	.byte 0
rlud2lrud:		.byte 0x00,0x02,0x01,0x03, 0x04,0x06,0x05,0x07, 0x08,0x0a,0x09,0x0b, 0x0c,0x0e,0x0d,0x0f
rlud2lrud180:	.byte 0x00,0x01,0x02,0x03, 0x08,0x09,0x0a,0x0b, 0x04,0x05,0x06,0x07, 0x0c,0x0d,0x0e,0x0f
gDipSwitch0:	.byte 0
gDipSwitch1:	.byte 0x15		;@ Lives, cabinet & demo sound.
gDipSwitch2:	.byte 0
gDipSwitch3:	.byte 0
coinCounter0:	.long 0
coinCounter1:	.long 0

latch0:			.byte 0
latch1:			.byte 0
latch2:			.byte 0
latch3:			.byte 0

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
Input0_R:					;@ Player 1
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy0State
//	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input1_R:					;@ Player 2
;@----------------------------------------------------------------------------
	ldrb r0,joy1State
//	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input2_R:					;@ Coins, Start & Service
;@----------------------------------------------------------------------------
	ldrb r0,joy2State
//	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input3_R:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	blx VLM5030_BSY
	ldmfd sp!,{r3,lr}

	cmp r0,#0
	ldrb r0,gDipSwitch0
	orreq r0,r0,#0x10			;@ VLM5030 busy pin
	orr r0,r0,#0x20
//	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input4_R:
;@----------------------------------------------------------------------------
	ldrb r0,gDipSwitch1
//	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input5_R:
;@----------------------------------------------------------------------------
	ldrb r0,gDipSwitch2
	eor r0,r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
Z80In:						;@ I/O read  (0x00-0x0F)
;@----------------------------------------------------------------------------
	ands r1,addy,#0x0F
	beq Input0_R
	cmp r1,#0x01
	beq Input1_R
	cmp r1,#0x02
	beq Input4_R
	cmp r1,#0x03
	beq Input3_R
	cmp r1,#0x07
	beq protectionRead
;@---------------------------
	b empty_IO_R

;@----------------------------------------------------------------------------
Z80Out:						;@I/O write  (0x00-0x0F)
;@----------------------------------------------------------------------------
	and r1,addy,#0x0F
	ldr pc,[pc,r1,lsl#2]
	nop
;@----------------------------------------------------------------------------
z80OutTbl:
	.long soundLatch00W
	.long soundLatch01W
	.long soundLatch10W
	.long soundLatch11W
	.long vlmData				;@ VLM5030
	.long empty_IO_W
	.long empty_IO_W
	.long protectionWrite
	.long nmiMaskW
	.long empty_IO_W
	.long punchoutLampsW
	.long punchout2A03ResetW
	.long punchoutSpeechResetW	;@ VLM5030
	.long punchoutSpeechStW		;@ VLM5030
	.long punchoutSpeechVcuW	;@ VLM5030
	.long enableNVRAM


;@----------------------------------------------------------------------------
soundLatch00W:
soundLatch01W:
punchoutLampsW:
punchout2A03ResetW:
enableNVRAM:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
soundLatch10W:
;@----------------------------------------------------------------------------
	strb r0,latch2
	bx lr
;@----------------------------------------------------------------------------
soundLatch11W:
;@----------------------------------------------------------------------------
	strb r0,latch3
	bx lr
;@----------------------------------------------------------------------------
soundLatch10R:
;@----------------------------------------------------------------------------
	ldrb r0,latch2
	bx lr
;@----------------------------------------------------------------------------
soundLatch11R:
;@----------------------------------------------------------------------------
	ldrb r0,latch3
	bx lr

;@----------------------------------------------------------------------------
vlmData:					;@ VLM5030
;@----------------------------------------------------------------------------
	mov r1,r0
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	stmfd sp!,{r3,lr}
	blx VLM5030_WRITE8
	ldmfd sp!,{r3,pc}
;@----------------------------------------------------------------------------
punchoutSpeechResetW:		;@ VLM5030
;@----------------------------------------------------------------------------
	and r1,r0,#1
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	stmfd sp!,{r3,lr}
	blx VLM5030_RST
	ldmfd sp!,{r3,pc}
;@----------------------------------------------------------------------------
punchoutSpeechStW:			;@ VLM5030
;@----------------------------------------------------------------------------
	and r1,r0,#1
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	stmfd sp!,{r3,lr}
	blx VLM5030_ST
	ldmfd sp!,{r3,pc}
;@----------------------------------------------------------------------------
punchoutSpeechVcuW:			;@ VLM5030
;@----------------------------------------------------------------------------
	and r1,r0,#1
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	stmfd sp!,{r3,lr}
	blx VLM5030_VCU
	ldmfd sp!,{r3,pc}

;@----------------------------------------------------------------------------
protectionRead:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov addy,addy,lsr#4
	bl rp5c01Read
// Hack, fix me
	loadLastBank r1
	sub r1,z80pc,r1
	ldr r2,=0x0315
	cmp r1,r2
	orreq r0,r0,#0xC0

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
protectionWrite:
;@----------------------------------------------------------------------------
	mov addy,addy,lsr#4
	b rp5c01Write
;@----------------------------------------------------------------------------
watchDogWrite:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
coinWrite:
;@----------------------------------------------------------------------------
	tst r0,#1
	ldrne r2,=coinCounter0
	ldrne r1,[r2]
	addne r1,r1,#1
	strne r1,[r2]
	tst r0,#2
	ldrne r2,=coinCounter1
	ldrne r1,[r2]
	addne r1,r1,#1
	strne r1,[r2]
	bx lr

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
