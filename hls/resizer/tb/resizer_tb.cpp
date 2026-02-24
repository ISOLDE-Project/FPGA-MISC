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
static constexpr int VGA_HEIGHT = 224;
static constexpr int VGA_WIDTH = 224;

static constexpr int FRAME_SIZE_O = 1 * 1 * VGA_HEIGHT * VGA_HEIGHT;

void serialize(const char *fname, uint32_t *buffer, std::streamsize _n);

// int32_t rgb_x[HEIGHT_I][WIDTH_I];
// int32_t y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];
uint32_t y[FRAME_SIZE_O];

const char *y_bin = "conv2d/test/y_cpp_int32.npy";
const char *x_bin = "conv2d/test/x_linux_sim_int32_.npy";
const char *x01_bin = "conv2d/test/x_linux_sim_int32_01.npy";
const char *smoke_test = "conv2d/test/smoke_test_conv2d_i32.py";

void check_frame(stream_vga_t &os, pixel_pkg_t &px_in_q,
                 NumpyModule &numpy_module) {
  typedef dim_t<4> shape_type;
  shape_type shape_y;
  int H = 0, W = 0;
  std::memset(y, 0, sizeof(y));

  axis_read_frame<FRAME_SIZE_O>(os, px_in_q, y, H, W);
  size_t remaining_frames =
      os.size() ? (os.size() - 1) / (FRAME_SIZE_O / 4) : 0;
  std::cerr << "read frame (H,W)= (" << H << "," << W
            << "), remainig frames: " << remaining_frames << " " << os.size()
            << std::endl;

  NumpyArray np_y;
  shape_y.set(1, 1, H, W);
  np_y.set_data((int32_t *)y);
  np_y.set_shape(shape_y);
  numpy_save(y_bin, np_y, numpy_module);
  /*   PythonScriptRunner runner;
    runner(smoke_test); */
}

int main() {

  int ret = 0;

  FILE *trace = stdout;

  typedef dim_t<4> shape_type;
  shape_type shape_x, x_index;
  uint32_t offset_x;

  stream_t input_stream(3 * HEIGHT_I * WIDTH_I + 1);
  stream_vga_t output_stream;

 NumpyModule numpy_module;

  offset_x = 0;
  try {
    // === Stream image into AXI4-Stream ===
    {
      NumpyArray np_x = numpy_load(x_bin, numpy_module);
      shape_x.set(np_x.shape);
      dump(trace, shape_x.data);
      uint32_t *flat_data = np_x.as<uint32_t>();
      matrix_to_axis<pixel_pkg_t, WIDTH_I>(input_stream, flat_data, shape_x[2],
                                           0, true);
      
    }
    // === Stream 2nd image into AXI4-Stream ===
    {
      NumpyArray np_x = numpy_load(x_bin, numpy_module);
      shape_x.set(np_x.shape);
      dump(trace, shape_x.data);
      uint32_t *flat_data = np_x.as<uint32_t>();
      matrix_to_axis<pixel_pkg_t, WIDTH_I>(input_stream, flat_data, shape_x[2],
                                           0, true);
      
    }
    // === Stream 3rd image into AXI4-Stream ===
    {
      NumpyArray np_x = numpy_load(x_bin, numpy_module);
      shape_x.set(np_x.shape);
      dump(trace, shape_x.data);
      uint32_t *flat_data = np_x.as<uint32_t>();
      matrix_to_axis<pixel_pkg_t, WIDTH_I>(input_stream, flat_data, shape_x[2],
                                           0, true);
      
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
  } catch (...) {
    PyErr_Print(); // or PyErr_Fetch(...) for detailed handling
    throw std::runtime_error("Python call failed");
  }

  execute(output_stream, input_stream);

  try {
    pixel_pkg_t px_in_q;
    px_in_q.user = 0;
    std::cerr << "available frames: "
              << (output_stream.size() - 1) / (FRAME_SIZE_O / 4) << " "
              << output_stream.size() << std::endl;
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
    check_frame(output_stream, px_in_q, numpy_module);
  } catch (const std::exception &e) {
    std::cerr << "\nError: " << e.what() << std::endl;
  }

  return ret;
}