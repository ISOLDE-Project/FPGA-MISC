
#include "../utils/memoryInterface.h"

#ifdef DTYPE_I32
arch::uint32_type scratchpad_0[3*128*128];
arch::uint32_type scratchpad_1[3*224*224];
arch::uint32_type scratchpad_2[256];
#elif DTYPE_F32
float scratchpad_0[3*128*128];
float scratchpad_1[3*224*224];
float scratchpad_2[256];
#else
#pragma error unsuported data type
#endif


