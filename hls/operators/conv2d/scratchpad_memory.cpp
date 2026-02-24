
#include "scratchpad_memory.h"
//#include "shapes_FullHD.inc"
#include "shapes.inc"


/*
* local storage for kernel
*/
#ifdef GRAYING
scratchpad_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W] = { 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10 };
#else
scratchpad_t scratchpad_0 [CHANNELS_W*HEIGHT_W*WIDTH_W];
#endif

/*
* local storage for a tensor slice 
*/
scratchpad_t scratchpad_1[CHANNELS_W*HEIGHT_W*WIDTH_I];

/*
* local storage for bias
*/
#ifndef NO_BIAS
scratchpad_t scratchpad_2 [WIDTH_O];
#endif


