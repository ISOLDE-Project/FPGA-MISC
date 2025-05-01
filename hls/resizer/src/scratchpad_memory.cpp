#include <cstdint>
#include "shapes.inc"
#ifdef DTYPE_I32
#ifdef CONST_WEIGTHS
uint32_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W] = { 8, 8, 8, 8, 8, 8, 8, 8, 8, 16, 16, 16, 16, 16, 16, 16, 16, 16, 3, 3, 3, 3, 3, 3, 3, 3, 3 };
uint32_t scratchpad_1[CHANNELS_I*HEIGHT_W*WIDTH_I];
#else
uint32_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W];
uint32_t scratchpad_1 [CHANNELS_I*HEIGHT_W*WIDTH_I];
uint32_t scratchpad_2 [WIDTH_O];
#endif
#elif DTYPE_F32
float scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W];
float scratchpad_1 [CHANNELS_I*HEIGHT_W*WIDTH_I];
float scratchpad_2 [WIDTH_O];
#else
#pragma error unsuported data type
#endif


