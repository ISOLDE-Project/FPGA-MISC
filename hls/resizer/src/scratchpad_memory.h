#pragma once

#include <cstddef>


#ifdef DTYPE_I32
#ifdef CONST_WEIGTHS
extern uint32_t scratchpad_0 [];
typedef uint32_t weight_t;              
extern uint32_t scratchpad_1[];
#else
extern uint32_t scratchpad_0[];
extern uint32_t scratchpad_1[];
extern uint32_t scratchpad_2[];
#endif
#elif DTYPE_F32
extern float scratchpad_0[];
extern float scratchpad_1[];
extern float scratchpad_2[];
#else
#pragma error unsuported data type
#endif

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])

