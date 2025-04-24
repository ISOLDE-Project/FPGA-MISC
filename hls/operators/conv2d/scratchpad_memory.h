#pragma once

#include <cstddef>
extern float scratchpad_0[3*128*128];
extern float scratchpad_1[3*7*224];
extern float scratchpad_2[256];

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])