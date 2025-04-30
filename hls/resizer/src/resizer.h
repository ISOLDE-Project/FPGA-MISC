#ifndef INCLUDE_RESIZER_HPP
#define INCLUDE_RESIZER_HPP
#include "axis/axis_helper.hpp"
#include <cstdint>

#define CHANNELS_I  3
#define HEIGHT_I    100
#define WIDTH_I     125
#
#define CHANNELS_O  1
#define HEIGHT_O    50
#define WIDTH_O     63

#define W_SIZE 1 * 3 * 3 * 3 // 1x3x3x3 -> flattened size
#define X_SIZE 1 * CHANNELS_I * HEIGHT_I * WIDTH_I
#define Y_SIZE 1 * CHANNELS_O * HEIGHT_O * WIDTH_O

extern void execute(volatile int32_t y_bram[Y_SIZE],
                    volatile int32_t x_bram[X_SIZE],
                    volatile int32_t w_bram[W_SIZE]
                    // hls::stream<trans_pkt> &data_in,
                    // hls::stream<trans_pkt> &data_out
);

#endif