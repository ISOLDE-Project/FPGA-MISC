// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "py_rt/py_rt.h"
#include "utils/tensor_utils.hpp"
#include "utils/trace.hpp"
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>

#include "resizer.h"

#include "axis_helper.hpp"
#include "shapes.inc"

/*
 * Full HD input
 */

static constexpr int VGA_CHANNELS = 1;
// ResNet-18 input shape
// static constexpr int VGA_HEIGHT = 224;
// static constexpr int VGA_WIDTH = 224;

static constexpr int FRAME_SIZE_O = 1 * 1 * HEIGHT_I * WIDTH_I;

static constexpr int FRAME_CNT = 7;

void serialize(const char *fname, uint32_t *buffer, std::streamsize _n);

uint32_t y[FRAME_SIZE_O];

const char *y_bin = "conv2d/test/y_cpp_int32.npy";
const char *x_bin = "conv2d/test/x_linux_sim_int32_.npy";
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
  shape_type shape_x, shape_x_01, x_index;
  uint32_t offset_x;

  stream_t input_stream(3 * HEIGHT_I * WIDTH_I + 1);
  stream_vga_t output_stream;

  NumpyModule numpy_module;

  offset_x = 0;
  try {
    NumpyArray np_x = numpy_load(x_bin, numpy_module);
    shape_x.set(np_x.shape);
    dump(trace, shape_x.data);
    uint32_t *flat_data = np_x.as<uint32_t>();
    // === Stream image into AXI4-Stream ===
    for (int cnt = 0; cnt < FRAME_CNT; ++cnt) {

      matrix_to_axis<pixel_pkg_t, WIDTH_I>(input_stream, flat_data, shape_x[2],
                                           0, true);
    }
  } catch (...) {
    PyErr_Print(); // or PyErr_Fetch(...) for detailed handling
    throw std::runtime_error("Python call failed");
  }

  // === just to signal the end of streaming
  pixel_pkg_t px;
  px.data = 0xAABBCC;
  px.keep = 0; // All bytes invalid
  px.strb = 0x1;
  px.id = 0;
  px.dest = 0;
  px.last = 0;
  px.user = 1; // Start of frame only
  input_stream.write(px);

  try {
    pixel_pkg_t px_in_q;
    px_in_q.user = 0;

    for (int cnt = 0; cnt < FRAME_CNT; ++cnt) {
      check_frame(input_stream, px_in_q, numpy_module);
    }
  } catch (const std::exception &e) {
    std::cerr << "\nError: " << e.what() << std::endl;
  }

  return ret;
}