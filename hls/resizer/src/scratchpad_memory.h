#pragma once

#include <cstddef>


#ifdef DTYPE_I32
extern uint32_t scratchpad_0[3*128*128];
extern uint32_t scratchpad_1[3*7*224];
extern uint32_t scratchpad_2[256];
#elif DTYPE_F32
extern float scratchpad_0[3*128*128];
extern float scratchpad_1[3*7*224];
extern float scratchpad_2[256];
#else
#pragma error unsuported data type
#endif

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])