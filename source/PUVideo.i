;@ ASM header for the Punch Out Video emulator
;@

/** \brief  Game screen height in pixels */
#define GAME_HEIGHT (224)
/** \brief  Game screen width in pixels */
#define GAME_WIDTH  (256)

	.equ GamePunchOutB,			0
	.equ GamePunchOutA,			1
	.equ GamePunchOutJp,		2
	.equ GamePunchOutIt,		3
	.equ GameSuperPunchOutB,	4
	.equ GameSuperPunchOutA,	5
	.equ GameSuperPunchOutJp,	6
	.equ GameArmWrestling,		7

	.equ TOPSRCTILECOUNTBITS,	11
	.equ TOPDSTTILECOUNTBITS,	10
	.equ TOPGROUPTILECOUNTBITS,	4
	.equ TOPBLOCKCOUNT,			(1<<(TOPSRCTILECOUNTBITS - TOPGROUPTILECOUNTBITS))
	.equ TOPTILESIZEBITS,		5

	.equ FGRSRCTILECOUNTBITS,	11
	.equ FGRDSTTILECOUNTBITS,	10
	.equ FGRGROUPTILECOUNTBITS,	4
	.equ FGRBLOCKCOUNT,			(1<<(FGRSRCTILECOUNTBITS - FGRGROUPTILECOUNTBITS))
	.equ FGRTILESIZEBITS,		5

	.equ SPR1SRCTILECOUNTBITS,	13
	.equ SPR1DSTTILECOUNTBITS,	10
	.equ SPR1GROUPTILECOUNTBITS,	4
	.equ SPR1BLOCKCOUNT,		(1<<(SPR1SRCTILECOUNTBITS - SPR1GROUPTILECOUNTBITS))
	.equ SPR1TILESIZEBITS,		5

	.equ SPR2SRCTILECOUNTBITS,	12
	.equ SPR2DSTTILECOUNTBITS,	10
	.equ SPR2GROUPTILECOUNTBITS,	4
	.equ SPR2BLOCKCOUNT,		(1<<(SPR2SRCTILECOUNTBITS - SPR2GROUPTILECOUNTBITS))
	.equ SPR2TILESIZEBITS,		5

						;@ PUVideo.s
	puptr		.req r12
	.struct 0
scanline:		.long 0			;@ These 3 must be first in state.
nextLineChange:	.long 0
lineState:		.long 0

frameIrqFunc:	.long 0

puVideoState:					;@

puVideoRegs:
irqControl:		.byte 0

selectedGame:	.byte 0
revBGfx1:		.byte 0
revBLayout:		.byte 0

gfxRam:			.long 0
gfxReload:
topMemReload:	.byte 0
fgrMemReload:	.byte 0
spr1MemReload:	.byte 0
spr2MemReload:	.byte 0
paletteReload:
palette1Reload:	.byte 0
palette2Reload:	.byte 0
palette3Reload:	.byte 0
palette4Reload:	.byte 0

topMemAlloc:	.long 0
fgrMemAlloc:	.long 0
spr1MemAlloc:	.long 0
spr2MemAlloc:	.long 0
palette1Alloc:	.long 0
palette2Alloc:	.long 0
palette3Alloc:	.long 0
palette4Alloc:	.long 0

topGfxRomBase:	.long 0
fgrGfxRomBase:	.long 0
bigSpr1RomBase:	.long 0
bigSpr2RomBase:	.long 0
bgrRomSize:		.long 0
bgrMask:		.long 0
bgrTopGfxDest:	.long 0
fgrBotGfxDest:	.long 0
bigSpr1GfxDest:	.long 0
bigSpr1GfxDest2:	.long 0
bigSpr2GfxDest:	.long 0
spriteRomBase:	.long 0
spriteRomSize:	.long 0

topBlockLUT:	.space TOPBLOCKCOUNT*4
fgrBlockLUT:	.space FGRBLOCKCOUNT*4
spr1BlockLUT:	.space SPR1BLOCKCOUNT*4
spr2BlockLUT:	.space SPR2BLOCKCOUNT*4
palette1LUT:	.space 0x20
palette2LUT:	.space 0x20
palette3LUT:	.space 0x20
palette4LUT:	.space 0x40

puVideoSize:

;@----------------------------------------------------------------------------

