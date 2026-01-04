#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Shared/EmuSettings.h"
#include "ARMZ80/ARMZ80.i"
#include "PUVideo.i"

	.global gfxInit
	.global gfxReset
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrame
	.global nmiMaskW
	.global gfxState
//	.global oamBufferReady
	.global gScaling
	.global gTwitch
	.global gFlicker
	.global gGfxMask
	.global vblIrqHandler
	.global yStart
	.global EMUPALBUFF

	.global puVideo_0



	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x200
	bl memset_
	mov r0,#OAM
	mov r2,#0x100
	bl memset_					;@ No stray sprites please
	ldr r0,=OAM_SUB
	mov r2,#0x100
	bl memset_					;@ No stray sprites please

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping

	bl puVideoInit

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@  NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0120,0xfeb6
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset, r0 = selectedGame
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	mov r4,r0
	strb r4,gfxGame

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	mov r1,#REG_BASE
	ldr r0,=0x400A
	cmp r4,#GameArmWrestling
	ldreq r0,=0x000A			;@ Arm Wrestling
	strh r0,[r1,#REG_BG1CNT]

	mov r0,#0x0000
	strh r0,[r1,#REG_BG3PB]
	strh r0,[r1,#REG_BG3PC]

	ldr r0,=0x00FF				;@ start-end
	strh r0,[r1,#REG_WIN0H]
	mov r0,#0x00C0				;@ start-end
	strh r0,[r1,#REG_WIN0V]
	mov r0,#0x0000
	strh r0,[r1,#REG_WINOUT]

	ldr r1,=0x03F003F0
	ldr r0,=BG_GFX+0x800
	mov r2,#0x800/4
	bl memset_
	ldr r0,=BG_GFX+0x1000
	mov r2,#0x2000/4
	bl memset_
	ldr r0,=BG_GFX+0x3000
	mov r2,#0x2000/4
	bl memset_
	ldr r0,=BG_GFX_SUB+0x2000
	mov r2,#0x2000/4
	bl memset_

	mov r1,#0
	ldr r0,=BG_GFX+0x10000
	mov r2,#0x8000/4
	bl memset_

	ldr r0,=cpu01SetIRQ
	mov r1,r4					;@ Selected game
	ldr r2,=EMU_RAM
	ldr puptr,=puVideo_0
	bl puVideoReset

	ldr r0,=vromBase0
	ldr r0,[r0]
	str r0,[puptr,#topGfxRomBase]
	ldr r0,=vromBase1
	ldr r0,[r0]
	str r0,[puptr,#fgrGfxRomBase]
	ldr r0,=vromBase2
	ldr r0,[r0]
	str r0,[puptr,#bigSpr1RomBase]
	ldr r0,=vromBase3
	ldr r0,[r0]
	str r0,[puptr,#bigSpr2RomBase]

	ldr r0,=BG_GFX+0x10000		;@ r0 = NDS BG tileset 4
	str r0,[puptr,#fgrBotGfxDest]
	ldr r0,=BG_GFX+0x18000		;@ r0 = NDS BG tileset 6
	str r0,[puptr,#bigSpr2GfxDest]
	ldr r0,=BG_GFX+0x20000		;@ r0 = NDS BG tileset 8
	str r0,[puptr,#bigSpr1GfxDest]
	ldr r0,=BG_GFX_SUB+0x8000	;@ r0 = NDS SUB BG tileset 2
	str r0,[puptr,#bgrTopGfxDest]
	ldr r0,=BG_GFX_SUB+0x10000	;@ r0 = NDS SUB BG tileset 4
	str r0,[puptr,#bigSpr1GfxDest2]

	cmp r4,#GameArmWrestling
	beq resetAW
	ldr r0,=BG_GFX+0x8000		;@ r0 = NDS BG tileset 2
	ldr r1,[puptr,#fgrGfxRomBase]
	mov r2,#0x8000
	bl convertTiles2BP
	b resetCont
resetAW:
	ldr r0,=BG_GFX+0x8000		;@ r0 = NDS BG tileset 2
	ldr r1,[puptr,#topGfxRomBase]
	mov r2,#0x8000
	bl convertTiles2BP

resetCont:
	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ called by ui.c:  void paletteInit(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	mov r7,#0xF0
	ldr r6,=MAPPED_RGB
	mov r4,#4096				;@ Punch Out 4096 colors
noMap:							;@ Map 0000bbbbggggrrrr  ->  0bbbbbgggggrrrrr
	sub r9,r4,#1
	and r0,r7,r9,lsr#4			;@ Blue ready
	bl gPrefix
	mov r5,r0

	and r0,r7,r9				;@ Green ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	and r0,r7,r9,lsl#4			;@ Red ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	strh r5,[r6],#2
	subs r4,r4,#1
	bne noMap

	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsr#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr puptr,=puVideo_0
	ldr r7,=MAPPED_RGB
	ldr r8,=EMUPALBUFF
	ldr r11,=promBase			;@ Proms
	ldr r11,[r11]
	add r10,r11,#0x600			;@ Bottom screen palette

	ldr r1,=EMU_RAM+0x1FFD		;@ Palette bank (0xDFFD)
	ldrb r1,[r1]
	tst r1,#1					;@ Bit 0 = bottom
	addne r10,r10,#0x100
	tst r1,#2					;@ Bit 1 = top
	addne r11,r11,#0x100

	ldrb r0,gfxGame
	cmp r0,#GameArmWrestling
	beq txPalAW
;@----------------------------------------------------------------------------
	add r2,r10,#0x03
	ldr r6,=palette4LUT
	mov r4,#64
	bl transfer4ColInv

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r10,#0x03
	ldr r6,=palette2LUT
	mov r4,#32
	bl transfer4ColInv

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r10,#0x07
	bl transfer8ColInv

;@----------------------------------------------------------------------------
	ldr r8,=EMUPALBUFF+0x400+8
	add r2,r11,#0x03
	ldr r6,=palette1LUT
	mov r4,#32
	bl transfer4ColInv

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r11,#0x07
	bl transfer8ColInv

	b wholePalette

;@----------------------------------------------------------------------------
txPalAW:
;@----------------------------------------------------------------------------
	add r2,r10,#0x03
	ldr r6,=palette4LUT
	mov r4,#64
	bl transfer4ColInv

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r10,#0x0
	ldr r6,=palette2LUT
	bl transfer4Col

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r10,#0x07
	bl transfer8ColInv

;@----------------------------------------------------------------------------
	ldr r8,=EMUPALBUFF+0x400+8
	add r2,r11,#0x00
	ldr r6,=palette1LUT
	bl transfer4Col

;@----------------------------------------------------------------------------
	add r8,r8,#8
	add r2,r11,#0x07
	bl transfer8ColInv


;@----------------------------------------------------------------------------
;@ Show whole palette in sprite palette mem.
wholePalette:
	mov r2,r10
	ldr r8,=EMUPALBUFF+0x200
	mov r1,#256
nomap6:
	ldrb r3,[r2,#0x400]			;@ Blue
	ldrb r4,[r2,#0x200]			;@ Green
	orr r3,r4,r3,lsl#4
	ldrb r4,[r2],#1				;@ Red
	orr r3,r4,r3,lsl#4

	mov r3,r3,lsl#1
	ldrh r3,[r7,r3]
	strh r3,[r8],#2
	subs r1,r1,#1
	bne nomap6

	ldmfd sp!,{r4-r11,lr}
	bx lr



;@----------------------------------------------------------------------------
transfer4Col:
;@----------------------------------------------------------------------------
	mov r4,#32
	add r6,r6,puptr
noMap41:
	ldrb r0,[r6],#1
	tst r0,#0x80
	addne r2,r2,#4
	bne skipMap4
	add r3,r8,r0,lsl#5
	mov r5,#4
noMap4:
	ldrb r0,[r2,#0x400]			;@ Blue
	ldrb r1,[r2,#0x200]			;@ Green
	orr r0,r1,r0,lsl#4
	ldrb r1,[r2],#1				;@ Red
	orr r0,r1,r0,lsl#4

	mov r0,r0,lsl#1
	ldrh r0,[r7,r0]
	strh r0,[r3],#2
	subs r5,r5,#1
	bne noMap4
skipMap4:
	subs r4,r4,#1
	bne noMap41
	bx lr
;@----------------------------------------------------------------------------
transfer4ColInv:
;@----------------------------------------------------------------------------
	add r6,r6,puptr
noMap41I:
	ldrb r0,[r6],#1
	tst r0,#0x80
	addne r2,r2,#4
	bne skipMap4I
	add r3,r8,r0,lsl#5
	mov r5,#4
noMap4I:
	ldrb r0,[r2,#0x400]			;@ Blue
	ldrb r1,[r2,#0x200]			;@ Green
	orr r0,r1,r0,lsl#4
	ldrb r1,[r2],#-1			;@ Red
	orr r0,r1,r0,lsl#4

	mov r0,r0,lsl#1
	ldrh r0,[r7,r0]
	strh r0,[r3],#2
	subs r5,r5,#1
	bne noMap4I
	add r2,r2,#8
skipMap4I:
	subs r4,r4,#1
	bne noMap41I
	bx lr
;@----------------------------------------------------------------------------
transfer8ColInv:
;@----------------------------------------------------------------------------
	mov r4,#32
	ldr r6,=palette3LUT
	add r6,r6,puptr
noMap81I:
	ldrb r0,[r6],#1
	tst r0,#0x80
	addne r2,r2,#8
	bne skipMap8I
	add r3,r8,r0,lsl#5
	mov r5,#8
noMap8I:
	ldrb r0,[r2,#0x400]			;@ Blue
	ldrb r1,[r2,#0x200]			;@ Green
	orr r0,r1,r0,lsl#4
	ldrb r1,[r2],#-1			;@ Red
	orr r0,r1,r0,lsl#4

	mov r0,r0,lsl#1
	ldrh r0,[r7,r0]
	strh r0,[r3],#2
	subs r5,r5,#1
	bne noMap8I
	add r2,r2,#16
skipMap8I:
	subs r4,r4,#1
	bne noMap81I
	bx lr
;@----------------------------------------------------------------------------
copyExtPalette:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr r12,=VRAM_F_CR
	ldr lr,=VRAM_H_CR
	mov r0,#0x80
	strb r0,[r12]				;@ So we can write to VRAM_F
	strb r0,[lr]				;@ So we can write to VRAM_H

	ldr r0,=VRAM_F				;@ Dst, Palette transfer:
	add r0,r0,#0x2000			;@ Slot 1 for BG3
	ldr r2,=EMUPALBUFF			;@ Src, Palette transfer:
	mov r3,#16
xPalLoop:
	ldmia r2!,{r4-r11}
	stmia r0,{r4-r11}
	add r0,r0,#0x200
	subs r3,r3,#1
	bne xPalLoop

	ldr r0,=VRAM_H				;@ Dst, Palette transfer:
	add r0,r0,#0x6000			;@ Slot 3 for BG3
	add r2,r2,#0x200			;@ Skip sprite palette
	mov r3,#16
x2PalLoop:
	ldmia r2!,{r4-r11}
	stmia r0,{r4-r11}
	add r0,r0,#0x200
	subs r3,r3,#1
	bne x2PalLoop

	mov r0,#0x8C				;@ VRAM enable, MST=4, OFS=1.
	strb r0,[r12]				;@ So we can use VRAM_F
	mov r0,#0x82				;@ VRAM enable, MST=2, OFS=0.
	strb r0,[lr]				;@ So we can use VRAM_H

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	bl calculateFPS

	ldrb r0,gScaling
	tst r0,#SCALED
	moveq r6,#0
	ldrne r6,=0x80000000 + ((GAME_HEIGHT-SCREEN_HEIGHT)*0x10000) / (SCREEN_HEIGHT-1)		;@ NDS 0x2B10 (was 0x2AAB)
	ldrbeq r8,yStart
	movne r8,#0
	add r8,r8,#0x10
	mov r7,r8,lsl#16

	ldr r0,gFlicker
	eors r0,r0,r0,lsl#31
	str r0,gFlicker
	addpl r6,r6,r6,lsl#16

	ldr r11,=scrollBuff
	ldr r10,=scrollBuffSub
	mov r4,r11

	ldr r5,=scrollTemp
	mov r12,#SCREEN_HEIGHT
scrolLoop2:
	add r3,r5,r8,lsl#3
	ldr r1,[r3]
	ldr r2,[r3,#4]
	add r0,r7,#0xFF
	add r1,r1,r7
	add r2,r2,r7
	stmia r4!,{r0-r2}
	str r7,[r10],#4
	adds r6,r6,r6,lsl#16
	addcs r7,r7,#0x10000
	adc r8,r8,#1
	subs r12,r12,#1
	bne scrolLoop2


	mov r8,#REG_BASE
	add r7,r8,#0x1000			;@ REG_BASE_SUB
	strh r8,[r8,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r8,#REG_DMA0SAD
	mov r1,r11					;@ Setup DMA buffer for scrolling:
	ldmia r1!,{r3-r5}			;@ Read
	add r2,r8,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r2,{r3-r5}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0x96600003			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r0,{r1-r3}			;@ DMA0 go

	strh r8,[r8,#REG_DMA1CNT_H]	;@ DMA1 stop

	add r0,r8,#REG_DMA1SAD
	ldr r1,=scrollBuffSub		;@ Setup DMA buffer for scrolling:
	ldmia r1!,{r3}				;@ Read
	add r2,r7,#REG_BG2HOFS		;@ DMA1 always goes here
	stmia r2,{r3}				;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0x96600001			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r0,{r1-r3}			;@ DMA1 go

	add r1,r8,#REG_DMA3SAD
	ldr r2,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r3,#BG_PALETTE			;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#0x200			;@ 512 words (2048 bytes)
	stmia r1,{r2-r4}			;@ DMA3 go
	bl copyExtPalette


	ldr r9,=EMU_RAM+0x1FF0		;@ 0xDFF0
	ldrh r4,[r9]				;@ zoom: 10bit fraction, 1bit integer.	0x07F8=smal, 0x00C0=Big
	ldrh r5,[r9,#2]				;@ x pos: 2bit fraction, 9bit integer.	0x0B48, 0x1070
	ldrh r6,[r9,#4]				;@ y pos: 9bit integer. 				0x03A6, 0x046C

	mov r0,r4,lsr#2
	strh r0,[r8,#REG_BG3PA]		;@ H scaling
	strh r0,[r7,#REG_BG3PA]

	ldrb r0,gScaling
	cmp r0,#0
	moveq r3,#0x10000
	ldrne r3,=0x12B10			;@ was 0x12AAB
	mul r1,r4,r3
	mov r0,r1,lsr#18
	strh r0,[r8,#REG_BG3PD]		;@ V scaling
	strh r0,[r7,#REG_BG3PD]

	mov r2,#60
	mul r2,r4,r2
	mov r0,r5,lsl#6
	add r0,r0,r2,lsr#2
//	ldr r1,gFlicker
//	tst r1,#0x80000000
//	addmi r0,r0,r4,lsr#3
	str r0,[r8,#REG_BG3X]	;@ Opponent horizontal
	str r0,[r7,#REG_BG3X]

	mov r2,#13
	ldrbeq r0,yStart
	addeq r2,r2,r0
	mul r2,r4,r2
	mov r0,r6,lsl#8
	add r0,r0,r2,lsr#2
	str r0,[r8,#REG_BG3Y]	;@ Opponent vertical
	str r0,[r7,#REG_BG3Y]

	ldrb r0,[r9,#7]			;@ bit 0 = show on top, bit 1 = show on bottom
	tst r0,#2
	ldrh r1,[r8]
	biceq r1,r1,#0x800
	orrne r1,r1,#0x800
	strh r1,[r8]

	tst r0,#1
	ldrh r1,[r7]
	biceq r1,r1,#0x800
	orrne r1,r1,#0x800
	strh r1,[r7]

	mov r0,#0x0013
	ldrb r1,gGfxMask
	bic r0,r0,r1
	strh r0,[r8,#REG_WININ]

	blx scanKeys
	ldmfd sp!,{r4-r11,pc}


;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte SCALED
gGfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	ldr puptr,=puVideo_0
;@----------------------------------------------------------------------------
endFrame:					;@ Called just before screen end (~line 224)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r0,=scrollTemp
	bl copyScrollValues

	ldrb r0,gfxGame
	cmp r0,#GameArmWrestling
	beq endFrameAW

endFramePU:
	ldr r0,=BG_GFX_SUB+0x1000
	bl convertTileMapPUVideoTop
	mov r0,#BG_GFX
	bl convertTileMapPUVideoBottom
	ldr r0,=BG_GFX+0x3000
	bl convertTileMapPUVideoBS1
	ldr r0,=BG_GFX_SUB+0x2000
	bl convertTileMapPUVideoBS1
	b endFrameCommon

endFrameAW:
	ldr r0,=BG_GFX_SUB+0x1000
	bl convertTileMapAWVideoTop
	mov r0,#BG_GFX
	bl convertTileMapAWVideoBottom
	ldr r0,=BG_GFX+0x3000
	bl convertTileMapAWVideoBS1
	ldr r0,=BG_GFX_SUB+0x2000
	bl convertTileMapAWVideoBS1
	ldr r0,=BG_GFX+0x800
	bl convertTileMapAWVideoFG

endFrameCommon:
	ldr r0,=BG_GFX+0x1000
	bl convertTileMapPUVideoBS2
	bl paletteTxAll
;@--------------------------
	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	mov r0,#1
	str r0,oamBufferReady

	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------
nmiMaskW:
;@----------------------------------------------------------------------------
	ldr puptr,=puVideo_0
	b puvNmiMaskWrite
;@----------------------------------------------------------------------------
tmpOamBuffer:		.long OAM_BUFFER1
dmaOamBuffer:		.long OAM_BUFFER2

oamBufferReady:		.long 0
;@----------------------------------------------------------------------------

gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0
wTop:
	.long 0,0,0		;@ windowtop  (this label too)   L/R scrolling in unscaled mode

gfxGame:
	.byte 0
	.space 3

	.byte 0
	.byte 0
	.byte 0,0

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
scrollTemp:
	.space 0x400*2
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
DMA0BUFF:
	.space 0x200
scrollBuff:
	.space 0x400*3				;@ Scrollbuffer.
scrollBuffSub:
	.space 0x400*1
MAPPED_RGB:
	.space 0x2000				;@ 12bit * 2
EMUPALBUFF:
	.space 0x400*2				;@ For both main & sub screens
puVideo_0:
	.space puVideoSize

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
