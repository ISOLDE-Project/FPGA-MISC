#pragma once

#include <cstddef>
#include "../utils/memoryInterface.h"

extern arch::uint32_type scratchpad_0[3*128*128];
extern arch::uint32_type scratchpad_1[3*7*224];
extern arch::uint32_type scratchpad_2[256];

#define MEM_SIZE(array)  sizeof(array)/sizeof(array[0])