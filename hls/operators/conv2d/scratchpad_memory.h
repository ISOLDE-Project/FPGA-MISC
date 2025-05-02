#pragma once

#include <cstdint>


#ifdef DTYPE_I32
typedef uint32_t scratchpad_t;
#elif DTYPE_F32
typedef float scratchpad_t;
#else
#pragma error unsuported data type
#endif


#ifdef GRAYING
typedef uint32_t weight_t;              
#endif


extern scratchpad_t scratchpad_0[];
extern scratchpad_t scratchpad_1[];
extern scratchpad_t scratchpad_2[];

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])

