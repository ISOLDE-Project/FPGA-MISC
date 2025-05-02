
#include "scratchpad_memory.h"
#include "shapes_FullHD.inc"


/*
* local storage for kernel
*/
#ifdef GRAYING
scratchpad_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W] = { 8, 8, 8, 8, 8, 8, 8, 8, 8, 16, 16, 16, 16, 16, 16, 16, 16, 16, 3, 3, 3, 3, 3, 3, 3, 3, 3 };
#else
scratchpad_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W];
#endif

/*
* local storage for a tensor slice 
*/
scratchpad_t scratchpad_1[CHANNELS_W*HEIGHT_W*FHD_WIDTH_I];

/*
* local storage for bias
*/
#ifndef NO_BIAS
scratchpad_t scratchpad_2 [FHD_WIDTH_O];
#endif


