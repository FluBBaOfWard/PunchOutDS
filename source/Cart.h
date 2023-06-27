#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 romNum;
extern u32 emuFlags;
extern u8 cartFlags;

extern u8 NV_RAM[0x400];
extern u8 EMU_RAM[0x4000];
extern u8 cpu2Ram[0x800];
extern u8 ROM_Space[0x5ED00];

void machineInit(void);
void loadCart(int, int);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
