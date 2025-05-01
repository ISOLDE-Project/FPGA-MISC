

#include "resizer.h"
#include "conv2d/conv2d.hpp"
#include "utils/tensor_io.hpp"

#define BRAM_C_I 3
#define BRAM_H_I 100
#define BRAM_W_I 125

#define BRAM_C_O 1
#define BRAM_H_O 50
#define BRAM_W_O 63

int32_t x_bram[1][BRAM_C_I][BRAM_H_I][BRAM_W_I];
int32_t y_bram[1][BRAM_C_O][BRAM_H_O][BRAM_W_O];

void execute(stream_t &stream_o, stream_t &stream_i
  ,int& M_o
  ,int& C_o
  ,int& H_o
  ,int& W_o
)
{
  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  int32_t *ptr_bias = 0;

  // === Read one frame ===
  bool frame_started = false;
  int row = 0, col = 0;
  int row_q = 0, col_q = 0;
  pixel_pkg_t px_in_q;
  px_in_q.user = 0;
  while (true)
  {
    // #pragma HLS PIPELINE II=1

    pixel_pkg_t px_in = px_in_q.user ? px_in_q : stream_i.read();

    // Detect start of frame
    if (px_in.user == 1 && !frame_started)
    {
      frame_started = true;
      px_in_q.user = 0;
      px_in.user = 0;
      row = 0;
      col = 0;
    }

    if (frame_started)
    {

      if (px_in.user == 1)
      {
        row_q = row ;
        px_in_q = px_in;
        frame_started = false;
        // prepare for a next frame
        row = 0;
        col = 0;
        break; // // End of frame
      }
      // === Unpack RGB from 0x00RRGGBB ===
      pixel_t pixel_val = px_in.data;
      uint8_t red = (pixel_val >> 16) & 0xFF;
      uint8_t green = (pixel_val >> 8) & 0xFF;
      uint8_t blue = (pixel_val) & 0xFF;

      // === Store into x_bram ===
      if (row < BRAM_H_I && col < BRAM_W_I)
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
        col_q = col;
        col = 0;
      }
    }
  }
  //
  volatile int32_t *ptr_x = reinterpret_cast<int32_t *>(x_bram);
  volatile int32_t *ptr_y = reinterpret_cast<int32_t *>(y_bram);
  //
  shape_x.set(1, BRAM_C_I, row_q, col_q);
  shape_w.set(1, 3, 3, 3);
  //
  pads.set(1, 1, 1, 1);
  strides.set(2, 2, 1, 1);
  //
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x, pads, strides,
         ptr_bias);

          M_o =shape_y[0];
          C_o=shape_y[1];
         H_o=shape_y[2];
         W_o=shape_y[3];

  int y_h = shape_y[2];
  int y_w = shape_y[3];

  // === Stream result into AXI4-Stream ===
  for (int i = 0; i < y_h; ++i)
  {
    for (int j = 0; j < y_w; ++j)
    {
      pixel_pkg_t px;
      px.data = y_bram[0][0][i][j];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == y_w - 1) ? 1 : 0;     // End of each line
      px.user = (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      stream_o.write(px);
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
  stream_o.write(px);
}