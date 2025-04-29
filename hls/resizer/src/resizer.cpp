

#include "resizer.h"
#include "conv2d/conv2d.hpp"
#include "utils/tensor_io.hpp"
#include <cstdint>
#include <cstdio>

// void execute(volatile uint32_t w_bram[W_SIZE],
//              hls::stream<trans_pkt> &data_in,
//              hls::stream<trans_pkt> &data_out) {

extern void execute(volatile int32_t y_bram[Y_SIZE],
                    volatile int32_t x_bram[X_SIZE],
                    volatile int32_t w_bram[W_SIZE]
                    // hls::stream<trans_pkt> &data_in,
                    // hls::stream<trans_pkt> &data_out
) {
  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;

  shape_x.set(1, 3, 1080, 1920);

  shape_w.set(1, 3, 3, 3);

  pads.set(1, 1, 1, 1);
  strides.set(2, 2, 1, 1);

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  
  int32_t *ptr_bias = 0;

  conv2d(io, y_bram, shape_y, x_bram, shape_x, w_bram, shape_w, pads, strides,
         ptr_bias);
}