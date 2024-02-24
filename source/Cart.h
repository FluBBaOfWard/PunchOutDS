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
extern u8 *mainCpu;
extern u8 *soundCpu;
extern u8 *vromBase0;
extern u8 *vromBase1;
extern u8 *vromBase2;
extern u8 *vromBase3;
extern u8 *promBase;
extern u8 *vlmBase;

void machineInit(void);
void loadCart(int, int);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
