

#include "resizer.h"
#include "conv2d/conv2d.hpp"
#include "utils/tensor_io.hpp"
#include "conv2d/shapes_FullHD.inc"
#include "axis_helper.hpp"
#include "shapes.inc"

#ifdef LINUX_APP
#include <iostream>
#endif

#define BRAM_C_I FHD_CHANNELS_I
#define BRAM_H_I 50 // FHD_HEIGHT_I
#define BRAM_W_I FHD_WIDTH_I

#define BRAM_C_O FHD_CHANNELS_O
#define BRAM_H_O 50 // FHD_HEIGHT_O
#define BRAM_W_O FHD_WIDTH_O

uint32_t x_bram[1 * BRAM_C_I * BRAM_H_I * BRAM_W_I];
uint32_t y_bram[1 * BRAM_C_O * BRAM_H_O * BRAM_W_O];

void execute(stream_t &stream_o, stream_t &stream_i, int &M_o, int &C_o, int &H_o, int &W_o)
{
  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;
  shape_type frame_i_shape;
  shape_type y_index;

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  int32_t *ptr_bias = 0;
  frame_i_shape.set(1, CHANNELS_I, HEIGHT_I, WIDTH_I);
  int32_t offset_y;

  bool frame_started = false;
  bool endOfFrame = false;
  int row_q = 0, col_q = 0;
  pixel_pkg_t px_in_q;
  px_in_q.user = 0;

  //
  volatile uint32_t *ptr_x = reinterpret_cast<uint32_t *>(x_bram);
  volatile uint32_t *ptr_y = reinterpret_cast<uint32_t *>(y_bram);
  while (true)
  {
    row_q = 0, col_q = 0;
    axis_read_lines<BRAM_H_I, BRAM_W_I>(
        stream_i, frame_i_shape, px_in_q, ptr_x, row_q, col_q, frame_started, endOfFrame);

#ifdef LINUX_APP
    std::cerr << "frame_started: " << frame_started << "\n";
    std::cerr << "endOfFrame: " << endOfFrame << "\n";
    std::cerr << "row_q: " << row_q << "\n";
    std::cerr << "col_q: " << col_q << "\n";
#endif
    if (endOfFrame)
      break;
  
  //
  shape_x.set(1, BRAM_C_I, row_q, col_q);
  shape_w.set(1, 3, 3, 3);
  //
  pads.set(1, 1, 1, 1);
  strides.set(2, 2, 1, 1);
  //
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x, pads, strides);
    
  M_o = shape_y[0];
  C_o = shape_y[1];
  H_o = shape_y[2];
  W_o = shape_y[3];

  int y_h = shape_y[2];
  int y_w = shape_y[3];
  
    
#ifdef LINUX_APP
  std::cerr << "y_h: " << y_h << "\n";
  std::cerr << "y_w: " << y_w << "\n";
#endif
  
  // === Stream result into AXI4-Stream ===
  offset_y = 0;
  for (int i = 0; i < y_h; ++i)
  {
    y_index.set(0, 0, i, 0);
    offset_y = tensor_index_to_offset(shape_y, y_index);
    for (int j = 0; j < y_w; ++j)
    {
      pixel_pkg_t px;
      px.data = y_bram[offset_y++];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == y_w - 1) ? 1 : 0;     // End of each line
      px.user = (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      stream_o.write(px);
    }
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