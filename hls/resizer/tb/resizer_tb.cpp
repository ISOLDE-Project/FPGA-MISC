// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "py_rt/py_rt.h"
#include <cstdint>
#include <string>
#include <cstdio>
#include <fstream>
#include <iostream>
#include "utils/tensor_utils.hpp"
#include "utils/trace.hpp"

#include "resizer.h"

#include "shapes.inc"
#include "axis_helper.hpp"

void serialize(const char *fname, uint32_t* buffer, std::streamsize _n);

// int32_t rgb_x[HEIGHT_I][WIDTH_I];
// int32_t y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];
uint32_t y[1 * CHANNELS_O * HEIGHT_O * WIDTH_O];

const char *y_bin = "conv2d/test/y_xsim_int32.bin";
const char *x_bin = "conv2d/test/x_linux_sim_int32.npy";

int main()
{

  int ret = 0;

  FILE *trace = stdout;

  typedef dim_t<4> shape_type;
  shape_type shape_x, x_index;
  uint32_t offset_x;

  shape_type shape_y, y_index;
  uint32_t offset_y;

  stream_t input_stream;
  stream_t output_stream;

  NumpyModule numpy_module;

  NumpyArray np_x = numpy_load(x_bin, numpy_module);
  shape_x.set(np_x.shape);
  dump(trace, shape_x.data);

  uint32_t *flat_data = np_x.as<uint32_t>();
  offset_x = 0;
  // === Stream image into AXI4-Stream ===
  for (int i = 0; i < HEIGHT_I; ++i)
  {
    x_index.set(0, 0, i, 0);
    offset_x = tensor_index_to_offset(shape_x, x_index);
    for (int j = 0; j < WIDTH_I; ++j)
    {
      pixel_pkg_t px;
      px.data = flat_data[offset_x++];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == WIDTH_I - 1) ? 1 : 0; // End of each line
      px.user = (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      input_stream.write(px);
    }
  }
  // just to signal the end of streaming
  pixel_pkg_t px;
  px.data = 0xAABBCC;
  px.keep = 0; // All bytes invalid
  px.strb = 0x1;
  px.id = 0;
  px.dest = 0;
  px.last = 0;
  px.user = 1; // Start of frame only
  input_stream.write(px);

  int M, C, H, W;
  execute(output_stream,
          input_stream, M, C, H, W);
  //
  std::cerr << "(M,C,H,W)= (" << M << "," << C << "," << H << "," << W << ")" << std::endl;

  shape_y.set(M,C,H,W);
  for (int i = 0; i < H; ++i)
  {
    y_index.set(0, 0, i, 0);
    offset_y = tensor_index_to_offset(shape_y, y_index);
    for (int j = 0; j < W; ++j)
    {
      pixel_pkg_t px = output_stream.read();
      
      y[offset_y++] = px.data;
      
    }
  }

   serialize(y_bin, y, sizeof(y));
  //
  // {
  //   std::ofstream outfile(y_bin, std::ios::binary);
  //   if (!outfile)
  //   {
  //     std::cerr << "Error opening outfile file " << std::endl;
  //     exit(1);
  //   }
  //   outfile.write(reinterpret_cast<char *>(y), sizeof(y));
  //   outfile.close();
  // }

  return ret;
}