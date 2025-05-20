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
#include "shapes/FullHD.inc"

/*
 * Full HD input

#define FHD_CHANNELS_I  3
#define FHD_HEIGHT_I    1080
#define FHD_WIDTH_I     1920
 */



// int32_t rgb_x[HEIGHT_I][WIDTH_I];
// int32_t y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];

static constexpr int Y_ELEMS = (FHD_HEIGHT_I * FHD_WIDTH_I)+1;

uint32_t y[Y_ELEMS ];

const char *y_bin = "conv2d/test/y_cpp_int32.npy";
const char *x_bin = "conv2d/test/x_linux_sim_int32.npy";
const char *x01_bin = "conv2d/test/x_linux_sim_int32_01.npy";
const char *smoke_test = "conv2d/test/smoke_test_rgb.py";

void check_frame(stream_t &os, pixel_pkg_t &px_in_q,
                 NumpyModule &numpy_module) {

  std::memset(y, 0, sizeof(y));
int H=0,W=0;
typedef dim_t<4> shape_type;
shape_type shape_y;
  axis_read_frame<Y_ELEMS>(os, px_in_q, y, H, W);
  size_t remaining_frames =
      os.size() ? (os.size() - 1) / (FHD_HEIGHT_I * FHD_WIDTH_I) : 0;
  std::cerr << "read frame (H,W)= (" << H << "," << W
            << "), remainig frames: " << remaining_frames << " " << os.size()
            <<" frame cnt: "<< (px_in_q.user>>1)
            << std::endl;

  NumpyArray np_y;
  shape_y.set(1, 1, H, W);
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
  uint32_t frame_no;

  stream_t output_stream(3 * 1920 * 1080 + 1);

  NumpyModule numpy_module;

  frame_no = 0;
  // === Stream image into AXI4-Stream ===
  {
    NumpyArray np_x = numpy_load(x_bin, numpy_module);
    shape_x.set(np_x.shape);
    dump(trace, shape_x.data);
   uint32_t *data_port = np_x.as<uint32_t>();
    execute(output_stream, data_port, frame_no++);
  }
  // === Stream 2nd image into AXI4-Stream ===
  {
    NumpyArray np_x = numpy_load(x_bin, numpy_module);
    shape_x.set(np_x.shape);
    dump(trace, shape_x.data);
    uint32_t *data_port = np_x.as<uint32_t>();
    execute(output_stream, data_port, frame_no++);
  }
  // === Stream 3rd image into AXI4-Stream ===
  {
    NumpyArray np_x = numpy_load(x_bin, numpy_module);
    shape_x.set(np_x.shape);
    dump(trace, shape_x.data);
    uint32_t *data_port = np_x.as<uint32_t>();
    execute(output_stream, data_port, frame_no++, true);
  }

  try {
    pixel_pkg_t px_in_q;
    px_in_q.user = 0;
    std::cerr << "available frames: "
              << (output_stream.size() - 1) / (FHD_HEIGHT_I * FHD_WIDTH_I) << " "
              << output_stream.size() << std::endl;
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
  } catch (const std::exception &e) {
    std::cerr << "\nError: " << e.what() << std::endl;
  }

  return ret;
}