
#ifdef __arm__

#include "ARMZ80/ARMZ80.i"

#define RAM_SIZE 0x40

	.global rp5c01Reset
	.global rp5c01SaveState
	.global rp5c01LoadState
	.global rp5c01GetStateSize
	.global rp5c01Read
	.global rp5c01Write


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
rp5c01Reset:
	.type rp5c01Reset STT_FUNC
;@----------------------------------------------------------------------------
	adr r0,ram
	mov r1,#0x40/4
	b memclr_

;@----------------------------------------------------------------------------
rp5c01SaveState:			;@ In r0=where to save. Out r0=state size.
	.type rp5c01SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	adr r1,ram
	mov r2,#RAM_SIZE
	bl memcpy
	mov r0,#RAM_SIZE
	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
rp5c01LoadState:			;@ In r0=where to load. Out r0=state size.
	.type rp5c01LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r1,r0
	adr r0,ram
	mov r2,#RAM_SIZE
	bl memcpy
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
rp5c01GetStateSize:
	.type rp5c01GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#RAM_SIZE
	bx lr
;@----------------------------------------------------------------------------
rp5c01Read:
	.type rp5c01Read STT_FUNC
;@----------------------------------------------------------------------------
	and addy,addy,#0x0F
	adr r1,ram
	ldrb r2,[r1,#0x0D]
	and r2,r2,#0x03
	cmp addy,#0xD
	addmi addy,addy,r2,lsl#4
	ldrb r0,[r1,addy]
	tst r2,#0x02
	bxne lr
	adr r1,regMask
	ldrb r1,[r1,addy]
	and r0,r0,r1
	bx lr
;@----------------------------------------------------------------------------
regMask:
	.byte 0xFF, 0x07, 0xFF, 0x07, 0xFF, 0x03, 0x07, 0xFF, 0x03, 0xFF, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xFF, 0x07, 0xFF, 0x03, 0x07, 0xFF, 0x03, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00
;@----------------------------------------------------------------------------
rp5c01Write:
	.type rp5c01Write STT_FUNC
;@----------------------------------------------------------------------------
	and addy,addy,#0x0F
	and r0,r0,#0x0F
	adr r1,ram
	ldrb r2,[r1,#0x0D]
	and r2,r2,#0x03
	cmp addy,#0xD
	addmi r1,r1,r2,lsl#4
	strb r0,[r1,addy]

	bx lr
;@----------------------------------------------------------------------------
ram:
	.space RAM_SIZE

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
