#pragma once

#include <cstddef>
#include "../utils/memoryInterface.h"

#ifdef DTYPE_I32
extern arch::uint32_type scratchpad_0[3*128*128];
extern arch::uint32_type scratchpad_1[3*7*224];
extern arch::uint32_type scratchpad_2[256];
#elif DTYPE_F32
extern float scratchpad_0[3*128*128];
extern float scratchpad_1[3*7*224];
extern float scratchpad_2[256];
#else
#pragma error unsuported data type
#endif

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])