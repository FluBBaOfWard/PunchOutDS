
#ifdef __arm__

#include "N2A03/RP2A03.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global rp2A03_0R
	.global rp2A03_0W
	.global rp2A03_0
	.global setMuteSoundGUI
	.global setMuteSoundGame

	.extern pauseEmulation


;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr rp2a03ptr,=rp2A03_0
//	bl rp2A03Init				;@ sound

	ldmfd sp!,{lr}
//	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr rp2a03ptr,=rp2A03_0
	ldr r0,=m6502SetIRQPin
	bl rp2A03Reset				;@ sound

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
setMuteSoundGame:			;@ For System E ?
;@----------------------------------------------------------------------------
	strb r0,muteSoundGame
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer, r2=formats?
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,lr}

	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	ldr rp2a03ptr,=rp2A03_0
	bl rp2A03Mixer

	ldmfd sp,{r0}
	ldr r1,pcmPtr0
	mov r2,r0,lsr#3
	ldr r0,=vlm5030Chip
	ldr r0,[r0]
	blx vlm5030_update_callback

	ldmfd sp,{r0,r1}
	ldr r2,pcmPtr0
mixLoop02:
	ldrsh r3,[r2],#2
	mov r3,r3,lsl#15

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4

	subs r0,r0,#1
	ldrshpl r12,[r1]
	add r12,r3,r12,lsl#13
	mov r12,r12,lsr#16
	orr r12,r12,r12,lsl#16
	strpl r12,[r1],#4
	bgt mixLoop02

	ldmfd sp!,{r0,r1,lr}
	bx lr

silenceMix:
	ldmfd sp!,{r0,r1}
	mov r12,r0
	mov r2,#0
silenceLoop:
	str r2,[r1],#4
	subs r12,r12,#1
	bhi silenceLoop

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
rp2A03_0R:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	mov r1,r12
	ldr rp2a03ptr,=rp2A03_0
	bl rp2A03Read
	ldmfd sp!,{r3,lr}
	bx lr
;@----------------------------------------------------------------------------
rp2A03_0W:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	mov r1,r12
	ldr rp2a03ptr,=rp2A03_0
	bl rp2A03Write
	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------
pcmPtr0:	.long wavBuffer
pcmPtr1:	.long wavBuffer+0x800

muteSound:
muteSoundGUI:
	.byte 0
muteSoundGame:
	.byte 0
	.space 2

	.section .bss
rp2A03_0:
	.space rp2a03Size
freqTbl:
	.space 1024*2
wavBuffer:
	.space 0x8000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
