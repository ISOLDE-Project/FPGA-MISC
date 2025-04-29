#ifndef INCLUDE_RESIZER_HPP
#define INCLUDE_RESIZER_HPP
#include "axis/axis_helper.hpp"
#include <cstdint>

#define W_SIZE 1 * 3 * 3 * 3 // 1x3x3x3 -> flattened size
#define X_SIZE 1 * 3 * 1080 * 1920
#define Y_SIZE 1 * 1 * 540 * 960
extern void execute(volatile int32_t y_bram[Y_SIZE],
                    volatile int32_t x_bram[X_SIZE],
                    volatile int32_t w_bram[W_SIZE]
                    // hls::stream<trans_pkt> &data_in,
                    // hls::stream<trans_pkt> &data_out
);

#endif