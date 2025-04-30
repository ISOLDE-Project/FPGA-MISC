#include <cstdint>
#ifdef DTYPE_I32
uint32_t scratchpad_0[3*128*128];
uint32_t scratchpad_1[3*224*224];
uint32_t scratchpad_2[256];
#elif DTYPE_F32
float scratchpad_0[3*128*128];
float scratchpad_1[3*224*224];
float scratchpad_2[256];
#else
#pragma error unsuported data type
#endif


