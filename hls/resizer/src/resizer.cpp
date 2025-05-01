

#include "resizer.h"
#include "conv2d/conv2d.hpp"
#include "utils/tensor_io.hpp"
#include <cstdint>
#include <cstdio>

#include "shapes.inc"

int32_t x_bram[1][CHANNELS_I][HEIGHT_I][WIDTH_I];
int32_t y_bram[1][CHANNELS_O][HEIGHT_O][WIDTH_O];

void execute(stream_t &stream_o,
             stream_t &stream_i

)
{
  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;

  shape_x.set(1, CHANNELS_I, HEIGHT_I, WIDTH_I);

  shape_w.set(1, 3, 3, 3);

  pads.set(1, 1, 1, 1);
  strides.set(2, 2, 1, 1);

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  int32_t *ptr_bias = 0;

  // === Read one frame ===
  bool frame_started = false;
  int row = 0, col = 0;
  while (true)
  {
    // #pragma HLS PIPELINE II=1

    pixel_pkg_t px_in = stream_i.read();

    // Detect start of frame
    if (px_in.user == 1 && !frame_started)
    {
      frame_started = true;
      row = 0;
      col = 0;
    }

    if (frame_started)
    {
      // === Unpack RGB from 0x00RRGGBB ===
      pixel_t pixel_val = px_in.data;
      uint8_t red = (pixel_val >> 16) & 0xFF;
      uint8_t green = (pixel_val >> 8) & 0xFF;
      uint8_t blue = (pixel_val) & 0xFF;

      // === Store into x_bram ===
      if (row < HEIGHT_I && col < WIDTH_I)
      {
        x_bram[0][0][row][col] = red;
        x_bram[0][1][row][col] = green;
        x_bram[0][2][row][col] = blue;
      }
      // === Update coordinates ===
      col++;
      if (px_in.last == 1)
      {
        row++;
        col = 0;
        if (row == HEIGHT_I)
        {
          frame_started = false;
          break; // End of frame
        }
      }
    }
  }

  volatile int32_t *ptr_x = reinterpret_cast<int32_t *>(x_bram);
  volatile int32_t *ptr_y = reinterpret_cast<int32_t *>(y_bram);
  //
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x,  pads, strides,
         ptr_bias);

  // === Stream result into AXI4-Stream ===
  for (int i = 0; i < HEIGHT_O; ++i)
  {
    for (int j = 0; j < WIDTH_O; ++j)
    {
      pixel_pkg_t px;
      px.data = y_bram[0][0][i][j];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == WIDTH_I - 1) ? 1 : 0; // End of each line
      px.user = (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      stream_o << px;
    }
  }
}