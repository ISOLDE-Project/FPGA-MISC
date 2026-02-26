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

#include "axis_helper.hpp"
#include "conv2d/conv2d.hpp"
#include "resizer.h"
#include "utils/tensor_io.hpp"

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
uint32_t conv_o[FRAME_SIZE_O];

const char *y_bin = "conv2d/test/y_cpp_int32.npy";
const char *x_bin = "conv2d/test/x_linux_sim_int32_.npy";
const char *smoke_test = "conv2d/test/unit_test.py";
const char *save_img = "conv2d/test/save_cpp_image.py";

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

void execute(stream_t &stream_i, NumpyModule &numpy_module) {
  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;
  shape_type frame_i_shape;
  shape_type y_index;

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  frame_i_shape.set(1, CHANNELS_I, HEIGHT_I, WIDTH_I);
  int32_t offset_y;

  bool frame_started = false;
  bool endOfFrame = false;
  int row_q = 0, col_q = 0, row_abs = 0;
  int row_out = 0;
  int chunk_cnt = 0;
  pixel_pkg_t px_in_q;
  px_in_q.user = 0;
  int frame_cnt = 0;
  volatile uint32_t *ptr_x = reinterpret_cast<uint32_t *>(y);
  volatile uint32_t *ptr_y = reinterpret_cast<uint32_t *>(conv_o);
  shape_w.set(1, CHANNELS_W, HEIGHT_W, WIDTH_W);
  //
  pads.set(CONV_PADDING, CONV_PADDING, CONV_PADDING, CONV_PADDING);
  strides.set(CONV_STRIDE, CONV_STRIDE, 1, 1);

  while (!endOfFrame) {
    axis_read_lines<HEIGHT_I, WIDTH_I>(stream_i, frame_i_shape, px_in_q, y,
                                       row_abs, row_q, col_q, chunk_cnt,
                                       frame_started, endOfFrame);

    {
      NumpyArray np_y;
      shape_y.set(1, 1, row_q, col_q);
      np_y.set_data((int32_t *)y);
      np_y.set_shape(shape_y);
      numpy_save(y_bin, np_y, numpy_module);
      PythonScriptRunner runner;
      runner(smoke_test);
    }
    if (endOfFrame) {
      row_abs = 0;
      chunk_cnt = 0;
      endOfFrame = px_in_q.keep ? false : true; // check for end of simulation
      if (row_q == 0) {

        std::cerr << "|** nada ** |\n";
        continue;
      }
    }
    shape_x.set(1, 1, row_q, col_q);

    //
    uint32_t Hlast = row_q == frame_i_shape[2] ? 0 : row_q;
    conv2d(io, ptr_y, shape_y, ptr_x, frame_i_shape, pads, strides, Hlast);
    {
      NumpyArray np_y;
      np_y.set_data((int32_t *)ptr_y);
      np_y.set_shape(shape_y);
      PythonScriptRunner runner;
      runner(save_img,frame_cnt,np_y);
    }
    frame_cnt++;
  }
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

  execute(input_stream, numpy_module);
  // try {
  //   pixel_pkg_t px_in_q;
  //   px_in_q.user = 0;

  //   for (int cnt = 0; cnt < FRAME_CNT; ++cnt) {
  //     check_frame(input_stream, px_in_q, numpy_module);
  //   }
  // } catch (const std::exception &e) {
  //   std::cerr << "\nError: " << e.what() << std::endl;
  // }

  return ret;
}