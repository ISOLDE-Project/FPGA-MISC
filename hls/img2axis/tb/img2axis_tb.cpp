// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "py_rt/py_rt.h"
#include "utils/tensor_utils.hpp"
#include "utils/trace.hpp"
#include <cstdint>
#include <cstdio>

#include <iostream>

#include "img2axis.h"

#include "axis_helper.hpp"
#include "shapes/shapes.inc"





// int32_t rgb_x[HEIGHT_I][WIDTH_I];
// int32_t y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];

static constexpr int FRAME_SIZE_O = 1 * 1 * HEIGHT_I * WIDTH_I;

uint32_t y[FRAME_SIZE_O ];

const char *y_bin = "conv2d/test/y_cpp_int32.npy";
const char *x_bin = "conv2d/test/x_linux_sim_int32_.npy";
const char *x01_bin = "conv2d/test/x_linux_sim_int32_01.npy";
const char *smoke_test = "conv2d/test/unit_test.py";


void check_frame(stream_t &os, pixel_pkg_t &px_in_q,
                 NumpyModule &numpy_module) {
  typedef dim_t<4> shape_type;
  shape_type shape_y;
  int H = 0, W = 0;
  std::memset(y, 0, sizeof(y));

  shape_type frame_i_shape;
  // pixel_pkg_t px_in_q;

  int row_abs = 0;
  int row_q = 0;
  int col_q = 0;
  int chunk_cnt = 0;
  bool frame_started = 0;
  bool endOfFrame = 0;

  frame_i_shape.set(1, CHANNELS_I, HEIGHT_I, WIDTH_I);

  axis_read_lines<HEIGHT_I, WIDTH_I>(os, frame_i_shape, px_in_q, y, row_abs,
                                     row_q, col_q, chunk_cnt, frame_started,
                                     endOfFrame);

  NumpyArray np_y;
  shape_y.set(1, 1, row_q, col_q);
  np_y.set_data((int32_t *)y);
  np_y.set_shape(shape_y);
  numpy_save(y_bin, np_y, numpy_module);
  PythonScriptRunner runner;
  runner(smoke_test);
}
int main() {

  int ret = 0;

  FILE *trace = stdout;

  typedef dim_t<4> shape_type;
  shape_type shape_x, x_index;
  static constexpr uint32_t frame_cnt =4;

  stream_t output_stream(frame_cnt * 1920 * 1080 + 1);

  NumpyModule numpy_module;



  // === Stream 3 images on AXI4-Stream ===
  {
    NumpyArray np_x = numpy_load(x_bin, numpy_module);
    shape_x.set(np_x.shape);
    dump(trace, shape_x.data);
    uint32_t *data_port = np_x.as<uint32_t>();
    execute(output_stream, data_port, frame_cnt, true);
  }

  try {
    pixel_pkg_t px_in_q;
    px_in_q.user = 0;
    std::cerr << "available frames: "
              << (output_stream.size() - 1) / (HEIGHT_I * WIDTH_I) << " "
              << output_stream.size() << std::endl;
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
  } catch (const std::exception &e) {
    std::cerr << "\nError: " << e.what() << std::endl;
  }

  return ret;
}