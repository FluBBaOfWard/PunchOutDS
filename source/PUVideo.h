// Punch Out Video Chip emulation

#ifndef PUVIDEO_HEADER
#define PUVIDEO_HEADER

#ifdef __cplusplus
extern "C" {
#endif
	
/** \brief  Game screen height in pixels */
#define GAME_HEIGHT (224)
/** \brief  Game screen width in pixels */
#define GAME_WIDTH  (256)

typedef struct {
	u32 lineState;
	u32 nextLineChange;
	u32 scanline;

	u32 frameIrqFunc;

//puVideoState:

//puVideoRegs:
	u8 irqControl;
	u8 selectedGame;
	u8 revBGfx1;
	u8 revBLayout;

	u8 *gfxRam;
	u8 topMemReload;
	u8 fgrMemReload;
	u8 spr1MemReload;
	u8 spr2MemReload;
	u8 palette1Reload;
	u8 palette2Reload;
	u8 palette3Reload;
	u8 palette4Reload;

	u32 topMemAlloc;
	u32 fgrMemAlloc;
	u32 spr1MemAlloc;
	u32 spr2MemAlloc;
	u32 palette1Alloc;
	u32 palette2Alloc;
	u32 palette3Alloc;
	u32 palette4Alloc;
	
	u32 topGfxRomBase;
	u32 fgrGfxRomBase;
	u32 bigSpr1RomBase;
	u32 bigSpr2RomBase;
	u32 bgrRomSize;
	u32 bgrMask;
	u32 bgrTopGfxDest;
	u32 fgrBotGfxDest;
	u32 bigSpr1GfxDest;
	u32 bigSpr1GfxDest2;
	u32 bigSpr2GfxDest;
	u32 spriteRomBase;
	u32 spriteRomSize;

	u8 topBlockLUT[256*4];			// Actually TOPBLOCKCOUNT*4
	u8 fgrBlockLUT[256*4];			// Actually FGRBLOCKCOUNT*4
	u8 spr1BlockLUT[256*4];			// Actually SPR1BLOCKCOUNT*4
	u8 spr2BlockLUT[256*4];			// Actually SPR2BLOCKCOUNT*4
	u8 palette1LUT[0x20];
	u8 palette2LUT[0x20];
	u8 palette3LUT[0x20];
	u8 palette4LUT[0x20];

} PUVideo;

void puVideoReset(void *periodicIrqFunc(), void *frameIrqFunc(), void *frame2IrqFunc());

/**
 * Saves the state of the PUVideo chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The PUVideo chip to save.
 * @return The size of the state.
 */
int puVideoSaveState(void *destination, const PUVideo *chip);

/**
 * Loads the state of the PUVideo chip from the source.
 * @param  *chip: The PUVideo chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int puVideoLoadState(PUVideo *chip, const void *source);

/**
 * Gets the state size of a AY38910.
 * @return The size of the state.
 */
int puVideoGetStateSize(void);

void convertTiles2BP(void *destination, const void *source, int length);
void doScanline(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // PUVIDEO_HEADER
