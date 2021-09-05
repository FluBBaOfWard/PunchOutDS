#ifndef RP5C01_HEADER
#define RP5C01_HEADER

#ifdef __cplusplus
extern "C" {
#endif

void rp5c01Reset(void);
int rp5c01SaveState(void *destination);
int rp5c01LoadState(const void *source);
int rp5c01GetStateSize(void);
int rp5c01Read(short address);
void rp5c01Write(short address, unsigned char value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // RP5C01_HEADER
