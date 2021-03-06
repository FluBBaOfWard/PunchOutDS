#ifndef SOUND_HEADER
#define SOUND_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include <maxmod9.h>
#include "N2A03/N2A03.h"

extern N2A03 n2A03_0;
void soundInit(void);
void soundSetFrequency(void);
void setMuteSoundGUI(void);
mm_word VblSound2(mm_word length, mm_addr dest, mm_stream_formats format);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SOUND_HEADER
