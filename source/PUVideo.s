// Punch Out Video Chip emulation

#ifdef __arm__

#include "PUVideo.i"

	.global puVideoInit
	.global puVideoReset
	.global puVideoSaveState
	.global puVideoLoadState
	.global puVideoGetStateSize
	.global convertTiles2BP
	.global addBackgroundTiles
	.global doScanline
	.global copyScrollValues
	.global convertTileMapPUVideoTop
	.global convertTileMapAWVideoTop
	.global convertTileMapPUVideoBottom
	.global convertTileMapAWVideoBottom
	.global convertTileMapAWVideoFG
	.global convertTileMapPUVideoBS1
	.global convertTileMapAWVideoBS1
	.global convertTileMapPUVideoBS2
	.global puvNmiMaskWrite


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
puVideoInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r3,=CHR_DECODE			;@ 0x400
	ldr lr,=CHR_DECODE_INV+0x400

	mov r2,#0xffffff00			;@ Build chr decode tbl
ppi0:
	mov r0,#0
	tst r2,#0x01
	orrne r0,r0,#0x10000000
	tst r2,#0x02
	orrne r0,r0,#0x01000000
	tst r2,#0x04
	orrne r0,r0,#0x00100000
	tst r2,#0x08
	orrne r0,r0,#0x00010000
	tst r2,#0x10
	orrne r0,r0,#0x00001000
	tst r2,#0x20
	orrne r0,r0,#0x00000100
	tst r2,#0x40
	orrne r0,r0,#0x00000010
	tst r2,#0x80
	orrne r0,r0,#0x00000001
	str r0,[r3],#4
	str r0,[lr,#-4]!
	adds r2,r2,#1
	bne ppi0

	mov r2,#0xffffff00			;@ Build chr decode tbl, inverted.
	ldr r3,=BGR_DECODE+0x800	;@ 0x400*2
ppi1:
	mov r0,#0
	mov r1,#0
	tst r2,#0x01
	orrne r1,r1,#0x01000000
	tst r2,#0x02
	orrne r1,r1,#0x00010000
	tst r2,#0x04
	orrne r1,r1,#0x00000100
	tst r2,#0x08
	orrne r1,r1,#0x00000001
	tst r2,#0x10
	orrne r0,r0,#0x01000000
	tst r2,#0x20
	orrne r0,r0,#0x00010000
	tst r2,#0x40
	orrne r0,r0,#0x00000100
	tst r2,#0x80
	orrne r0,r0,#0x00000001
	strd r0,r1,[r3,#-8]!
	adds r2,r2,#1
	bne ppi1

	ldmfd sp!,{r3,lr}
	bx lr
;@----------------------------------------------------------------------------
puVideoReset:		;@ r0=NMI(frameIrqFunc), r1=game, r2=ram
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r2,lr}

	mov r0,puptr
	ldr r1,=puVideoSize/4
	bl memclr_					;@ Clear VDP state

	ldr r2,=PUVLineStateTable
	ldr r1,[r2],#4
	mov r0,#0
	stmia puptr,{r0-r2}			;@ Reset scanline, nextLineChange & lineState

	mov r0,#1
	strb r0,[puptr,#topMemReload]
	strb r0,[puptr,#fgrMemReload]
	strb r0,[puptr,#spr1MemReload]
	strb r0,[puptr,#spr2MemReload]
	strb r0,[puptr,#palette1Reload]
	strb r0,[puptr,#palette2Reload]
	strb r0,[puptr,#palette3Reload]
	strb r0,[puptr,#palette4Reload]
	bl checkTopTileReload
	bl checkFgrTileReload
	bl checkSpr1TileReload
	bl checkSpr2TileReload
	bl checkPalette1Reload
	bl checkPalette2Reload
	bl checkPalette3Reload
	bl checkPalette4Reload

	ldmfd sp!,{r0,r1,r2}
	strb r1,[puptr,#selectedGame]
	cmp r1,#GamePunchOutB
	cmpne r1,#GamePunchOutIt
	cmpne r1,#GameSuperPunchOutB
	cmpne r1,#GameSuperPunchOutJp
	mov r3,#0
	moveq r3,#1
	strb r3,[puptr,#revBLayout]
	cmpeq r1,#GameSuperPunchOutJp
	moveq r3,#0
	strb r3,[puptr,#revBGfx1]

	cmp r0,#0
	adreq r0,dummyIrqFunc
	str r0,[puptr,#frameIrqFunc]

	str r2,[puptr,#gfxRam]

	ldmfd sp!,{lr}
dummyIrqFunc:
	bx lr
;@----------------------------------------------------------------------------
puVideoSaveState:			;@ In r0=destination, r1=puptr. Out r0=state size.
	.type   puVideoSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r1					;@ Store puptr (r1)
	mov r4,r0					;@ Store destination

	ldr r1,[r5,#gfxRam]
	mov r2,#0x4000
	bl memcpy

	add r0,r4,#0x4000
	add r1,r5,#puVideoRegs
	mov r2,#0x04
	bl memcpy

	ldmfd sp!,{r4,r5,lr}
	ldr r0,=0x4004
	bx lr
;@----------------------------------------------------------------------------
puVideoLoadState:			;@ In r0=puptr, r1=source. Out r0=state size.
	.type   puVideoLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r0					;@ Store puptr (r0)
	mov r4,r1					;@ Store source

	ldr r0,[r5,#gfxRam]
	mov r2,#0x4000
	bl memcpy

	add r0,r5,#puVideoRegs
	add r1,r4,#0x4000
	mov r2,#0x04
	bl memcpy

	mov r0,#-1
	str r0,[r5,#gfxReload]
	mov puptr,r5				;@ Restore puptr (r12)
	bl endFrame

	ldmfd sp!,{r4,r5,lr}
;@----------------------------------------------------------------------------
puVideoGetStateSize:		;@ Out r0=state size.
	.type   puVideoGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=0x4004
	bx lr

;@----------------------------------------------------------------------------
convertTiles2BP:			;@ r0 = destination, r1 = source, r2 = length.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	ldrb r3,[puptr,#revBLayout]
	cmp r3,#0
	ldreq lr,=CHR_DECODE
	ldrne lr,=CHR_DECODE_INV
cvt2BPStart:
	ldr r6,=0x44444444
	mov r5,#0x4000
cvt2BPLoop:
	ldrb r3,[r1,r5]				;@ Read bitplane 1
	ldr r4,[lr,r3,lsl#2]
	ldrb r3,[r1],#1				;@ Read bitplane 0
	ldr r3,[lr,r3,lsl#2]
	orr r4,r3,r4,lsl#1
	orr r4,r6,r4
	str r4,[r0],#4

	subs r2,r2,#4
	bne cvt2BPLoop

	ldmfd sp!,{r4-r6,lr}
	bx lr
;@----------------------------------------------------------------------------
addBackgroundTiles:			;@ r0 = dest.
;@----------------------------------------------------------------------------
	ldr r1,=0x10101010
	mov r3,#0
bgChrLoop2:
	mov r2,#16
bgChrLoop1:
	str r3,[r0],#4
	subs r2,r2,#1
	bne bgChrLoop1
	adds r3,r3,r1
	bcc bgChrLoop2
	bx lr
;@----------------------------------------------------------------------------
PUVLineStateTable:
	.long 0, newFrame			;@ puvZeroLine
	.long 223, endFrame			;@ puvLastScanline
	.long 224, checkFrameIRQ	;@ frameIRQ on
	.long 225, clearFrameIRQ	;@ frameIRQ off
	.long 264, frameEndHook		;@ totalScanlines
;@----------------------------------------------------------------------------
redoScanline:
;@----------------------------------------------------------------------------
	ldr r2,[puptr,#lineState]
	ldmia r2!,{r0,r1}
	stmib puptr,{r1,r2}			;@ Write nextLineChange & lineState
	stmfd sp!,{lr}
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
doScanline:
;@----------------------------------------------------------------------------
	ldmia puptr,{r0,r1}			;@ Read scanLine & nextLineChange
	cmp r0,r1
	bpl redoScanline
	add r0,r0,#1
	str r0,[puptr,#scanline]

	mov r0,#0
	bx lr

;@----------------------------------------------------------------------------
newFrame:					;@ Called before line 0
;@----------------------------------------------------------------------------
//	mov r0,#0
//	str r0,[puptr,#scanline]	;@ Reset scanline count
//	strb r0,lineState			;@ Reset line state
	bx lr

;@----------------------------------------------------------------------------
checkFrameIRQ:
;@----------------------------------------------------------------------------
	ldrb r0,[puptr,#irqControl]
	ands r0,r0,#1				;@ IRQ enabled?
	ldrne pc,[puptr,#frameIrqFunc]
	bx lr
;@----------------------------------------------------------------------------
clearFrameIRQ:
;@----------------------------------------------------------------------------
	mov r0,#0
	ldr pc,[puptr,#frameIrqFunc]
;@----------------------------------------------------------------------------
frameEndHook:
	ldr r2,=PUVLineStateTable
	ldr r1,[r2],#4
	mov r0,#0
	stmia puptr,{r0-r2}			;@ Reset scanline, nextLineChange & lineState

	mov r0,#1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
puvNmiMaskWrite:		;@
;@----------------------------------------------------------------------------
	strb r0,[puptr,#irqControl]
	ands r0,r0,#1
	ldreq r1,[puptr,#frameIrqFunc]
	bxeq r1
	bx lr
;@----------------------------------------------------------------------------
copyScrollValues:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7}

	ldr r7,[puptr,#gfxRam]
//	add r1,r7,#0x1800			;@ Top BG scroll ram (0xD800)? 0xC7 for PU, 0xC8 for AW.
	add r1,r7,#0x3000			;@ BG scroll ram (0xF000)
	add r7,r7,#0x2000
	ldrh r5,[r7,#-8]			;@ Big Sprite 2 X-position
	ldrh r7,[r7,#-6]			;@ Big Sprite 2 Y-position
	add r5,r5,#57				;@ Big Sprite 2 X-offset
	sub r7,r7,#3				;@ Big Sprite 2 Y-offset
	mov r7,r7,lsl#23
	orr r5,r5,r7,asr#7
	mov r6,#0x3E
	mov r3,#0
	ldrb r2,[puptr,#selectedGame]
	cmp r2,#GameArmWrestling
	beq awScrlLoop
cpyScrlLoop:
	and r2,r6,r3,lsr#2
	ldrh r4,[r1,r2]
	add r4,r4,#60				;@ BG-offset, between 58 - 62, 60 if compared to top screen on https://www.youtube.com/watch?v=cNB0S5mdMnc
	str r4,[r0],#4
	str r5,[r0],#4
	add r3,r3,#1
	cmp r3,#0x100
	bne cpyScrlLoop

	ldmfd sp!,{r4-r7}
	bx lr

awScrlLoop:
	mov r4,#0
	str r4,[r0],#4
	str r5,[r0],#4
	add r3,r3,#1
	cmp r3,#0x100
	bne awScrlLoop

	ldmfd sp!,{r4-r7}
	bx lr
;@----------------------------------------------------------------------------
checkTopTileReload:
;@----------------------------------------------------------------------------
	ldr r9,=topBlockLUT
	add r9,r9,puptr
	ldrb r0,[puptr,#topMemReload]
	cmp r0,#0
	bxeq lr
	mov r0,#1<<(TOPDSTTILECOUNTBITS-TOPGROUPTILECOUNTBITS)
	str r0,[puptr,#topMemAlloc]
	mov r0,#0
	strb r0,[puptr,#topMemReload]	;@ Clear bg mem reload.
	mov r0,r9					;@ r0=destination
	mov r1,#1<<(32-TOPGROUPTILECOUNTBITS)		;@ r1=value
	mov r2,#TOPBLOCKCOUNT		;@ Tile entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkFgrTileReload:
;@----------------------------------------------------------------------------
	ldr r9,=fgrBlockLUT
	add r9,r9,puptr
	ldrb r0,[puptr,#fgrMemReload]
	cmp r0,#0
	bxeq lr
	mov r0,#1<<(FGRDSTTILECOUNTBITS-FGRGROUPTILECOUNTBITS)
	str r0,[puptr,#fgrMemAlloc]
	mov r0,#0
	strb r0,[puptr,#fgrMemReload]	;@ Clear bg mem reload.
	mov r0,r9					;@ r0=destination
	mov r1,#1<<(32-FGRGROUPTILECOUNTBITS)		;@ r1=value
	mov r2,#FGRBLOCKCOUNT		;@ Tile entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkSpr1TileReload:
;@----------------------------------------------------------------------------
	ldr r9,=spr1BlockLUT
	add r9,r9,puptr
	ldrb r0,[puptr,#spr1MemReload]
	cmp r0,#0
	bxeq lr
	mov r0,#1<<(SPR1DSTTILECOUNTBITS-SPR1GROUPTILECOUNTBITS)
	str r0,[puptr,#spr1MemAlloc]
	mov r0,#0
	strb r0,[puptr,#spr1MemReload]	;@ Clear bg mem reload.
	mov r0,r9					;@ r0=destination
	mov r1,#1<<(32-SPR1GROUPTILECOUNTBITS)		;@ r1=value
	mov r2,#SPR1BLOCKCOUNT		;@ Tile entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkSpr2TileReload:
;@----------------------------------------------------------------------------
	ldr r9,=spr2BlockLUT
	add r9,r9,puptr
	ldrb r0,[puptr,#spr2MemReload]
	cmp r0,#0
	bxeq lr
	mov r0,#1<<(SPR2DSTTILECOUNTBITS-SPR2GROUPTILECOUNTBITS)
	str r0,[puptr,#spr2MemAlloc]
	mov r0,#0
	strb r0,[puptr,#spr2MemReload]	;@ Clear bg mem reload.
	mov r0,r9					;@ r0=destination
	mov r1,#1<<(32-SPR2GROUPTILECOUNTBITS)		;@ r1=value
	mov r2,#SPR2BLOCKCOUNT		;@ 512 tile entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkPalette1Reload:
;@----------------------------------------------------------------------------
	ldrb r0,[puptr,#palette1Reload]
	cmp r0,#0
	bxeq lr
	mov r0,#16
	str r0,[puptr,#palette1Alloc]
	mov r0,#0
	strb r0,[puptr,#palette1Reload]	;@ Clear bg mem reload.

	ldr r0,=palette1LUT
	add r0,r0,puptr				;@ r0=destination
	ldr r1,=0x80808080			;@ r1=value
	mov r2,#32/4				;@ 32 palette entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkPalette2Reload:
;@----------------------------------------------------------------------------
	ldrb r0,[puptr,#palette2Reload]
	cmp r0,#0
	bxeq lr
	mov r0,#16
	str r0,[puptr,#palette2Alloc]
	mov r0,#0
	strb r0,[puptr,#palette2Reload]	;@ Clear bg mem reload.

	ldr r0,=palette2LUT
	add r0,r0,puptr				;@ r0=destination
	ldr r1,=0x80808080			;@ r1=value
	mov r2,#32/4				;@ 32 palette entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkPalette3Reload:
;@----------------------------------------------------------------------------
	ldrb r0,[puptr,#palette3Reload]
	cmp r0,#0
	bxeq lr
	mov r0,#16
	str r0,[puptr,#palette3Alloc]
	mov r0,#0
	strb r0,[puptr,#palette3Reload]	;@ Clear bg mem reload.

	ldr r0,=palette3LUT
	add r0,r0,puptr				;@ r0=destination
	ldr r1,=0x80808080			;@ r1=value
	mov r2,#32/4				;@ 32 palette entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
checkPalette4Reload:
;@----------------------------------------------------------------------------
	ldrb r0,[puptr,#palette4Reload]
	cmp r0,#0
	bxeq lr
	mov r0,#16
	str r0,[puptr,#palette4Alloc]
	mov r0,#0
	strb r0,[puptr,#palette4Reload]	;@ Clear bg mem reload.

	ldr r0,=palette4LUT
	add r0,r0,puptr				;@ r0=destination
	ldr r1,=0x80808080			;@ r1=value
	mov r2,#64/4				;@ 64 palette entries
	b memset_					;@ Prepare lut
;@----------------------------------------------------------------------------
convertTileMapPUVideoTop:	;@ r0 = destination, Background
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	add r6,r0,#0x80				;@ Destination
	bl checkTopTileReload
	bl checkPalette1Reload

	ldrb r0,[puptr,#revBGfx1]
	cmp r0,#0
	ldreq r8,=getTopTilesFromCache
	ldrne r8,=getTopTilesFromCacheRevB
	ldreq r10,=CHR_DECODE
	ldrne r10,=CHR_DECODE_INV
	mov r11,#28					;@ Row count
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x1880
	bl bglo1

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapAWVideoTop:	;@ r0 = destination, Background
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	add r6,r0,#0x80				;@ Destination
	bl checkTopTileReload
	bl checkPalette1Reload

	ldr r10,=CHR_DECODE
	mov r11,#28					;@ Row count
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x3880
	bl bgAWTop

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapPUVideoBottom:	;@ r0 = destination, Background
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	add r6,r0,#0x80				;@ Destination
	bl checkPalette2Reload

	ldrb r0,[puptr,#revBLayout]
	cmp r0,#0
	moveq r8,#0x0000
	movne r8,#0x0300			;@ Rev B
	mov r11,#28					;@ Row count
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x3100
	bl bglo2

	mov r11,#28					;@ Row count
	sub r4,r4,#0x1000-0x240
	add r6,r6,#0x100			;@ Skip 2 bottom & 2 top rows
	bl bglo2

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapAWVideoBottom:	;@ r0 = destination, Background
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	add r6,r0,#0x80				;@ Destination
	bl checkPalette2Reload

	ldr r10,=CHR_DECODE
	mov r11,#28					;@ Row count
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x3080
	bl bgAWBot

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapAWVideoFG:	;@ r0 = destination, Foreground
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	add r6,r0,#0x80				;@ Destination
	bl checkFgrTileReload
	bl checkPalette2Reload

	ldr r10,=CHR_DECODE_INV
	mov r11,#28					;@ Row count
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x1880
	bl fgAWBot

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapPUVideoBS1:	;@ r0 = destination, Opponent
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	mov r6,r0					;@ Destination
	bl checkSpr1TileReload
	bl checkPalette3Reload

	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x2000
	ldrb r0,[r4,#-10]			;@ dff6 x-flip
	tst r0,#1
	adr lr,endBS1LO
	beq bs1PUlo
	bne bs1PUxlo
endBS1LO:
	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapAWVideoBS1:	;@ r0 = destination, Opponent
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	mov r6,r0					;@ Destination
	bl checkSpr1TileReload
	bl checkPalette3Reload

	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x2000
	ldrb r0,[r4,#-10]			;@ dff6 x-flip
	tst r0,#1
	adr lr,endBS1LO
	beq bs1AWlo
	bne bs1AWxlo

	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
convertTileMapPUVideoBS2:	;@ r0 = destination, Player
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	mov r6,r0					;@ Destination
	bl checkSpr2TileReload
	bl checkPalette4Reload

	ldrb r0,[puptr,#revBLayout]
	cmp r0,#0
	ldreq r8,=getSpr2TilesFromCache
	ldrne r8,=getSpr2TilesFromCacheRevB
	ldreq r10,=CHR_DECODE
	ldrne r10,=CHR_DECODE_INV
	ldr r4,[puptr,#gfxRam]
	add r4,r4,#0x2800
	ldrb r0,[r4,#-0x804]		;@ dffc x-flip
	tst r0,#1
	adr lr,endBS2LO
	beq bs2lo
	bne bs2xlo
endBS2LO:
	ldmfd sp!,{r3-r11,pc}
;@----------------------------------------------------------------------------
bglo1:
	stmfd sp!,{lr}

bgTrLoop1:
	ldrh r0,[r4],#2				;@ Read from Punch Out Tilemap RAM,  xccccctttttttttt
	mov r5,r0,ror#10			;@ Separate tile & color bits
	mov r0,r5,lsr#22

	blx r8
	and r7,r5,#0x20
	orr r7,r0,r7,lsl#5			;@ Add x-flip
	mov r0,r5
	bl getPaletteFromCache1
	orr r0,r7,r0,lsl#12			;@ Add color

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x03E
	bne bgTrLoop1
	subs r11,r11,#1
	bne bgTrLoop1

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bgAWTop:
	stmfd sp!,{lr}

bgAWTrLoop1:
	ldrh r0,[r4],#2				;@ Read from Arm Wrestling Tilemap RAM,  xccccctttttttttt
	mov r5,r0,ror#10			;@ Separate tile & color bits
	mov r0,r5,lsr#22
	tst r5,#0x20
	orrne r0,r0,#0x0400			;@ Add x-flip as bit 11

	bl getTopTilesFromCache
	mov r7,r0
	mov r0,r5
	bl getPaletteFromCache1
	orr r0,r7,r0,lsl#12			;@ Add color

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x03E
	bne bgAWTrLoop1
	subs r11,r11,#1
	bne bgAWTrLoop1

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bglo2:
	stmfd sp!,{lr}

bgTrLoop2:
	ldrh r0,[r4],#2				;@ Read from Punch Out Tilemap RAM,  xccccctttttttttt
	mov r0,r0,ror#10			;@ separate tile & color bits
	mov r5,r0,lsr#22

	ands r1,r5,r8				;@ Rev B address wrangling
	cmpne r1,r8
	eorne r5,r5,r8

	tst r0,#0x20
	orrne r5,r5,#0x0400			;@ Add x-flip
	bl getPaletteFromCache2
	orr r0,r5,r0,lsl#12			;@ Add color

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x03E
	bne bgTrLoop2
	add r4,r4,#0x40
	subs r11,r11,#1
	bne bgTrLoop2

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bgAWBot:
	stmfd sp!,{lr}

bgAWTrLoop2:
	ldrh r0,[r4],#2				;@ Read from Punch Out Tilemap RAM,  xccccctttttttttt
	mov r0,r0,ror#10			;@ Separate tile & color bits
	mov r5,r0,lsr#22
	tst r0,#0x20
	orrne r5,r5,#0x0400			;@ Add x-flip
	bl getPaletteFromCache2
	orr r0,r5,r0,lsl#12			;@ Add color

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x03E
	bne bgAWTrLoop2
	subs r11,r11,#1
	bne bgAWTrLoop2

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
fgAWBot:
	stmfd sp!,{lr}

fgAWTrLoop2:
	ldrh r0,[r4],#2				;@ Read from Arm Wrestling Tilemap RAM,  xccccttttttttttt
	mov r5,r0,ror#11			;@ Separate tile & color bits
	mov r0,r5,lsr#21
	bl getFgrTilesFromCache
	and r7,r5,#0x10
	orr r7,r0,r7,lsl#6			;@ Add x-flip
	mov r0,r5
	bl getPaletteFromCache3
	orr r0,r7,r0,lsl#12			;@ Add color

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x03E
	bne fgAWTrLoop2
	subs r11,r11,#1
	bne fgAWTrLoop2

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs1PUlo:
	stmfd sp!,{lr}

bs1TLoop:
	ldr r0,[r4],#4				;@ Read from Punch Out tilemap RAM, x00ccccc00000000000ttttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#13			;@ Separate tile & attribute bits
	mov r0,r5,lsr#19

	bl getTilesFromCache8
	and r7,r5,#0x40000
	orr r7,r0,r7,lsr#8			;@ Add x-flip

	mov r0,r5,lsr#11
	bl getPaletteFromCache3
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs1TLoop
	add r6,r6,#0x60
	tst r6,#0xFC0
	bne bs1TLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs1PUxlo:
	stmfd sp!,{lr}
	add r4,r4,#0x40
bs1XTLoop:
	ldr r0,[r4,#-4]!			;@ Read from Punch Out tilemap RAM, x0cccccc000000000000tttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#13			;@ Separate tile & attribute bits
	mov r0,r5,lsr#19

	bl getTilesFromCache8
	mov r7,r0
	tst r5,#0x40000
	orreq r7,r7,#0x0400			;@ Add x-flip
	mov r0,r5,lsr#11
	bl getPaletteFromCache3
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs1XTLoop
	add r4,r4,#0x80
	add r6,r6,#0x60
	tst r6,#0xFC0
	bne bs1XTLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs1AWlo:
	stmfd sp!,{lr}

	mov r11,#2
bs1AWTLoop:
	ldr r0,[r4],#4				;@ Read from Punch Out tilemap RAM, x00ccccc00000000000ttttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#13			;@ Separate tile & attribute bits
	mov r0,r5,lsr#19

	bl getTilesFromCache8
	and r7,r5,#0x40000
	orr r7,r0,r7,lsr#8			;@ Add x-flip
	mov r0,r5,lsr#11
	bl getPaletteFromCache3
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs1AWTLoop
	add r6,r6,#0x60
	tst r6,#0x780
	bne bs1AWTLoop
	sub r6,r6,#0x800-0x20
	subs r11,r11,#1
	bne bs1AWTLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs1AWxlo:
	stmfd sp!,{lr}

	mov r11,#2
	add r6,r6,#0x20
	add r4,r4,#0x40
bs1AWXTLoop:
	ldr r0,[r4,#-4]!			;@ Read from Punch Out tilemap RAM, x0cccccc000000000000tttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#13			;@ Separate tile & attribute bits
	mov r0,r5,lsr#19

	bl getTilesFromCache8
	mov r7,r0
	tst r5,#0x40000
	orreq r7,r7,#0x0400			;@ Add x-flip
	mov r0,r5,lsr#11
	bl getPaletteFromCache3
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs1AWXTLoop
	add r4,r4,#0x80
	add r6,r6,#0x60
	tst r6,#0x780
	bne bs1AWXTLoop
	sub r6,r6,#0x800+0x20
	subs r11,r11,#1
	bne bs1AWXTLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs2lo:
	stmfd sp!,{lr}

bs2TLoop:
	ldr r0,[r4],#4				;@ Read from Punch Out tilemap RAM, x0cccccc000000000000tttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#12			;@ Separate tile & attribute bits
	mov r0,r5,lsr#20

	blx r8
	and r7,r5,#0x80000
	orr r7,r0,r7,lsr#9			;@ Add x-flip
	mov r0,r5,lsr#12
	bl getPaletteFromCache4
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs2TLoop
	add r6,r6,#0x20
	tst r6,#0x7C0
	bne bs2TLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bs2xlo:
	stmfd sp!,{lr}
	add r4,r4,#0x40
bs2XTLoop:
	ldr r0,[r4,#-4]!			;@ Read from Punch Out tilemap RAM, x0cccccc000000000000tttttttttttt -> cccc0xtttttttttt
	mov r5,r0,ror#12			;@ Separate tile & attribute bits
	mov r0,r5,lsr#20

	blx r8
	mov r7,r0
	tst r5,#0x80000
	orreq r7,r7,#0x0400			;@ Add x-flip
	mov r0,r5,lsr#12
	bl getPaletteFromCache4
	orr r0,r7,r0,lsl#12

	strh r0,[r6],#2				;@ Write to NDS Tilemap RAM
	tst r6,#0x01E
	bne bs2XTLoop
	add r4,r4,#0x80
	add r6,r6,#0x20
	tst r6,#0x7C0
	bne bs2XTLoop

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
palette1CacheFull:
	strb r0,[puptr,#palette1Reload]
	bx lr
;@----------------------------------------------------------------------------
getPaletteFromCache1:		;@ Takes palette# in r0, returns new palette# in r0
;@----------------------------------------------------------------------------
	and r2,r0,#0x1F
	ldr r1,=palette1LUT
	add r1,r1,puptr
	ldrb r0,[r1,r2]				;@ Check cache, uncached = 0x80
	tst r0,#0x80
	bxeq lr						;@ Allready cached
allocP1:
	ldr r0,[puptr,#palette1Alloc]
	subs r0,r0,#1
	bmi palette1CacheFull
	str r0,[puptr,#palette1Alloc]
	strb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
palette2CacheFull:
	strb r0,[puptr,#palette2Reload]
	bx lr
;@----------------------------------------------------------------------------
getPaletteFromCache2:		;@ Takes palette# in r0, returns new palette# in r0
;@----------------------------------------------------------------------------
	and r2,r0,#0x1F
	ldr r1,=palette2LUT
	add r1,r1,puptr
	ldrb r0,[r1,r2]				;@ Check cache, uncached = 0x80
	tst r0,#0x80
	bxeq lr						;@ Allready cached
allocP2:
	ldr r0,[puptr,#palette2Alloc]
	subs r0,r0,#1
	bmi palette2CacheFull
	str r0,[puptr,#palette2Alloc]
	strb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
palette3CacheFull:
	strb r0,[puptr,#palette3Reload]
	bx lr
;@----------------------------------------------------------------------------
getPaletteFromCache3:		;@ Takes palette# in r0, returns new palette# in r0
;@----------------------------------------------------------------------------
	and r2,r0,#0x1F
	ldr r1,=palette3LUT
	add r1,r1,puptr
	ldrb r0,[r1,r2]				;@ Check cache, uncached = 0x80
	tst r0,#0x80
	bxeq lr						;@ Allready cached
allocP3:
	ldr r0,[puptr,#palette3Alloc]
	subs r0,r0,#1
	bmi palette3CacheFull
	str r0,[puptr,#palette3Alloc]
	strb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
palette4CacheFull:
	strb r0,[puptr,#palette4Reload]
	bx lr
;@----------------------------------------------------------------------------
getPaletteFromCache4:		;@ Takes palette# in r0, returns new palette# in r0
;@----------------------------------------------------------------------------
	and r2,r0,#0x3F
	ldr r1,=palette4LUT
	add r1,r1,puptr
	ldrb r0,[r1,r2]				;@ Check cache, uncached = 0x80
	tst r0,#0x80
	bxeq lr						;@ Allready cached
allocP4:
	ldr r0,[puptr,#palette4Alloc]
	subs r0,r0,#1
	bmi palette4CacheFull
	str r0,[puptr,#palette4Alloc]
	strb r0,[r1,r2]
	bx lr


;@----------------------------------------------------------------------------
topTileCacheFull:
	strb r2,[puptr,#topMemReload]
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
getTopTilesFromCacheRevB:	;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	ands r1,r0,0x300			;@ Rev B layout
	cmpne r1,#0x300
	eorne r0,r0,0x300
;@----------------------------------------------------------------------------
getTopTilesFromCache:		;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r1,r0,lsr#TOPGROUPTILECOUNTBITS		;@ Mask tile number
	and r0,r0,#(1<<TOPGROUPTILECOUNTBITS)-1
	ldr r2,[r9,r1,lsl#2]		;@ Check cache, uncached = 0x40000000
	orrs r0,r0,r2,lsl#TOPGROUPTILECOUNTBITS
	bxcc lr						;@ Allready cached
allocTop:
	ldr r2,[puptr,#topMemAlloc]
	subs r2,r2,#1
	bmi topTileCacheFull
	str r2,[puptr,#topMemAlloc]

	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#TOPGROUPTILECOUNTBITS
	stmfd sp!,{r0,r3-r5,lr}
;@----------------------------------------------------------------------------
doTop:
	ldr r0,[puptr,#topGfxRomBase]
	add r1,r0,r1,lsl#TOPGROUPTILECOUNTBITS + 3
	ldr r0,[puptr,#bgrTopGfxDest]
	add r0,r0,r2,lsl#TOPGROUPTILECOUNTBITS + TOPTILESIZEBITS

	mov r4,#0x4000
	ldr r5,=0x44444444
bgTopLoop:
	ldrb r2,[r1,r4]				;@ Read bitplane 1
	ldr r3,[r10,r2,lsl#2]
	ldrb r2,[r1],#1				;@ Read bitplane 0
	ldr r2,[r10,r2,lsl#2]
	orr r3,r2,r3,lsl#1
	orr r3,r5,r3
	str r3,[r0],#4

	movs r2,r0,lsl#32-(TOPGROUPTILECOUNTBITS + TOPTILESIZEBITS)
	bne bgTopLoop

	ldmfd sp!,{r0,r3-r5,pc}
;@----------------------------------------------------------------------------
fgrTileCacheFull:
	strb r2,[puptr,#fgrMemReload]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
getFgrTilesFromCache:		;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r1,r0,lsr#FGRGROUPTILECOUNTBITS		;@ Mask tile number
	and r0,r0,#(1<<FGRGROUPTILECOUNTBITS)-1
	ldr r2,[r9,r1,lsl#2]		;@ Check cache, uncached = 0x40000000
	orrs r0,r0,r2,lsl#FGRGROUPTILECOUNTBITS
	bxcc lr						;@ Allready cached
allocFgr:
	ldr r2,[puptr,#fgrMemAlloc]
	subs r2,r2,#1
	bmi fgrTileCacheFull
	str r2,[puptr,#fgrMemAlloc]

	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#FGRGROUPTILECOUNTBITS
	stmfd sp!,{r0,r3-r4,lr}
;@----------------------------------------------------------------------------
doFgr:
	ldr r0,[puptr,#fgrGfxRomBase]
	add r1,r0,r1,lsl#FGRGROUPTILECOUNTBITS + 3
	ldr r0,[puptr,#fgrBotGfxDest]
	add r0,r0,r2,lsl#FGRGROUPTILECOUNTBITS + FGRTILESIZEBITS

	mov r4,#0x4000
fgrLoop:
	ldrb r2,[r1,r4,lsl#1]		;@ Read bitplane 2
	ldr r3,[r10,r2,lsl#2]
	orr r3,r3,r3,lsl#1
	ldrb r2,[r1,r4]				;@ Read bitplane 1
	ldr r2,[r10,r2,lsl#2]
	orr r3,r3,r2,lsl#1
	orr r3,r2,r3,lsl#1
	ldrb r2,[r1],#1				;@ Read bitplane 0
	ldr r2,[r10,r2,lsl#2]
	orr r3,r3,r2,lsl#2
	orr r3,r2,r3,lsl#1
	str r3,[r0],#4

	movs r2,r0,lsl#32-(FGRGROUPTILECOUNTBITS + FGRTILESIZEBITS)
	bne fgrLoop

	ldmfd sp!,{r0,r3-r4,pc}
;@----------------------------------------------------------------------------
spr2TileCacheFull:
	strb r2,[puptr,#spr2MemReload]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
getSpr2TilesFromCacheRevB:	;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	ands r1,r0,0x300
	cmpne r1,#0x300
	eorne r0,r0,0x300
;@----------------------------------------------------------------------------
getSpr2TilesFromCache:		;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r1,r0,lsr#SPR2GROUPTILECOUNTBITS		;@ Mask tile number
	and r0,r0,#(1<<SPR2GROUPTILECOUNTBITS)-1
	ldr r2,[r9,r1,lsl#2]		;@ Check cache, uncached = 0x40000000
	orrs r0,r0,r2,lsl#SPR2GROUPTILECOUNTBITS
	bxcc lr						;@ Allready cached
alloc4:
	ldr r2,[puptr,#spr2MemAlloc]
	subs r2,r2,#1
	bmi spr2TileCacheFull
	str r2,[puptr,#spr2MemAlloc]

	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#SPR2GROUPTILECOUNTBITS
	stmfd sp!,{r0,r3-r4,lr}
;@----------------------------------------------------------------------------
do4:
	ldr r0,[puptr,#bigSpr2RomBase]
	add r1,r0,r1,lsl#SPR2GROUPTILECOUNTBITS + 3
	ldr r0,[puptr,#bigSpr2GfxDest]
	add r0,r0,r2,lsl#SPR2GROUPTILECOUNTBITS + SPR2TILESIZEBITS

	mov r4,#0x4000
bg4Loop:
	ldrb r2,[r1,r4]				;@ Read bitplane 1
	ldr r3,[r10,r2,lsl#2]
	ldrb r2,[r1],#1				;@ Read bitplane 0
	ldr r2,[r10,r2,lsl#2]
	orr r3,r2,r3,lsl#1
	str r3,[r0],#4

	movs r2,r0,lsl#32-(SPR2GROUPTILECOUNTBITS + SPR2TILESIZEBITS)
	bne bg4Loop

	ldmfd sp!,{r0,r3-r4,pc}
;@----------------------------------------------------------------------------
spr1TileCacheFull:
	strb r2,[puptr,#spr1MemReload]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
getTilesFromCache8:			;@ Takes tile# in r0, returns new tile# in r0
;@----------------------------------------------------------------------------
	mov r1,r0,lsr#SPR1GROUPTILECOUNTBITS		;@ Mask tile number
	and r0,r0,#(1<<SPR1GROUPTILECOUNTBITS)-1
	ldr r2,[r9,r1,lsl#2]		;@ Check cache, uncached = 0x40000000
	orrs r0,r0,r2,lsl#SPR1GROUPTILECOUNTBITS
	bxcc lr						;@ Allready cached
alloc8:
	ldr r2,[puptr,#spr1MemAlloc]
	subs r2,r2,#1
	bmi spr1TileCacheFull
	str r2,[puptr,#spr1MemAlloc]

	str r2,[r9,r1,lsl#2]
	orr r0,r0,r2,lsl#SPR1GROUPTILECOUNTBITS
	stmfd sp!,{r0,r3-r8,lr}
;@----------------------------------------------------------------------------
do8:
	ldr r0,[puptr,#bigSpr1RomBase]
	add r1,r0,r1,lsl#SPR1GROUPTILECOUNTBITS + 3
	ldr r0,[puptr,#bigSpr1GfxDest]
	ldr r3,[puptr,#bigSpr1GfxDest2]
	add r3,r3,r2,lsl#SPR1GROUPTILECOUNTBITS + SPR1TILESIZEBITS + 1
	add r0,r0,r2,lsl#SPR1GROUPTILECOUNTBITS + SPR1TILESIZEBITS + 1

	mov r2,#0x10000
	ldr lr,=BGR_DECODE
bg8Loop:
	ldrb r4,[r1,r2,lsl#1]		;@ Read bitplane 2
	add r8,lr,r4,lsl#3
	ldrd r6,[r8]
	orr r6,r6,r6,lsl#1
	orr r7,r7,r7,lsl#1
	ldrb r4,[r1,r2]				;@ Read bitplane 1
	add r8,lr,r4,lsl#3
	ldrd r4,[r8]
	orr r6,r6,r4,lsl#1
	orr r7,r7,r5,lsl#1
	orr r6,r4,r6,lsl#1
	orr r7,r5,r7,lsl#1
	ldrb r4,[r1],#1				;@ Read bitplane 0
	add r8,lr,r4,lsl#3
	ldrd r4,[r8]
	orr r6,r6,r4,lsl#2
	orr r7,r7,r5,lsl#2
	orr r6,r4,r6,lsl#1
	orr r7,r5,r7,lsl#1
	strd r6,[r0],#8
	strd r6,[r3],#8

	movs r4,r0,lsl#32-(SPR1GROUPTILECOUNTBITS + SPR1TILESIZEBITS + 1)
	bne bg8Loop

	ldmfd sp!,{r0,r3-r8,pc}
;@----------------------------------------------------------------------------

	.section .bss
CHR_DECODE:
	.space 0x400
CHR_DECODE_INV:
	.space 0x400
BGR_DECODE:
	.space 0x400*2

	.end
#endif // #ifdef __arm__
