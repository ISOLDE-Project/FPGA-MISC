// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cstdint>
#include <string>
#include <cstdio>
#include <fstream>
#include <iostream>

#include "resizer.h"

#include"shapes.inc"

int32_t rgb_x[HEIGHT_I][WIDTH_I];
int32_t y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];


const char *y_bin = "../../../../../operators/conv2d/test/y_xsim_int32.bin";
const char *x_bin = "../../../../../operators/conv2d/test/x_xsim_int32.bin";


int main()
{

  int ret = 0;

  stream_t input_stream;
  stream_t output_stream;
  {
    std::ifstream infile(x_bin, std::ios::binary);
    if (!infile)
    {
      std::cerr << "Error opening x_bin input file " << std::endl;
      exit(1);
    }
    infile.read(reinterpret_cast<char *>(rgb_x), sizeof(rgb_x));
    infile.close();
  }


  // === Stream image into AXI4-Stream ===
  for (int i = 0; i < HEIGHT_I; ++i)
  {
    for (int j = 0; j < WIDTH_I; ++j)
    {
      pixel_pkg_t px;
      px.data = rgb_x[i][j];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == WIDTH_I - 1) ? 1 : 0; // End of each line
      px.user = (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      input_stream << px;
    }
  }


  execute(output_stream,
          input_stream);
  //

  for (int i = 0; i < HEIGHT_O; ++i)
  {
    for (int j = 0; j < WIDTH_O; ++j)
    {
      pixel_pkg_t px_out = output_stream.read();
      pixel_t pixel_val = px_out.data;
      y[0][0][i][j] = pixel_val.to_uint();
    }
  }
  //
  {
    std::ofstream outfile(y_bin, std::ios::binary);
    if (!outfile)
    {
      std::cerr << "Error opening outfile file " << std::endl;
      exit(1);
    }
    outfile.write(reinterpret_cast<char *>(y), sizeof(y));
    outfile.close();
  }

  return ret;
}