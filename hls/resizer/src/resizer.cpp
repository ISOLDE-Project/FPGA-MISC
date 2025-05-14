

#include "resizer.h"
#include "axis_helper.hpp"
#include "conv2d/conv2d.hpp"
#include "conv2d/shapes_FullHD.inc"
#include "utils/tensor_io.hpp"

#ifdef LINUX_APP
#include "utils/trace.hpp"
#include <iostream>
void serialize(const char *fname, uint32_t *buffer, std::streamsize _n);
#endif

constexpr int N_KNOB = 15;
constexpr int CHUNK_HEIGHT = (2 * N_KNOB + 3);
constexpr int _HLAST__ = CHUNK_HEIGHT - (FHD_HEIGHT_I % CHUNK_HEIGHT);
/**
 * since stride=0, the last block shall be larger then 2 rows
 */
static_assert(_HLAST__ > 2,
              "_HLAST__ must be greater than 2, please modify N_KNOB");

#define BRAM_C_I FHD_CHANNELS_I
// #define BRAM_H_I FHD_HEIGHT_I
#define BRAM_H_I CHUNK_HEIGHT
#define BRAM_W_I FHD_WIDTH_I

#define BRAM_C_O FHD_CHANNELS_O
// #define BRAM_H_O FHD_HEIGHT_O
#define BRAM_H_O (CHUNK_HEIGHT / 2 + 1)
#define BRAM_W_O FHD_WIDTH_O

/*frame shape*/
#define CHANNELS_I BRAM_C_I
#define HEIGHT_I BRAM_H_I
#define WIDTH_I BRAM_W_I

uint32_t x_bram[1 * BRAM_C_I * BRAM_H_I * BRAM_W_I];
uint32_t y_bram[1 * BRAM_C_O * BRAM_H_O * BRAM_W_O];

void execute(stream_vga_t &stream_o, stream_t &stream_i) {
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
  int row_q = 0, col_q = 0, row_abs = 0;
  int row_out = 0;
  int chunk_cnt = 0;
  pixel_pkg_t px_in_q;
  px_in_q.user = 0;

#ifdef LINUX_APP
  FILE *trace = stdout;
  fprintf(trace, "frame_i_shape=");
  dump(trace, frame_i_shape);
  fprintf(trace, "chunk_height= %d\n", BRAM_H_I);
#endif
  //
  volatile uint32_t *ptr_x = reinterpret_cast<uint32_t *>(x_bram);
  volatile uint32_t *ptr_y = reinterpret_cast<uint32_t *>(y_bram);
  while (!endOfFrame) {

#ifdef LINUX_APP

    std::cerr << chunk_cnt << ": input [" << row_abs << ":";
#endif
    axis_read_lines<BRAM_H_I, BRAM_W_I>(stream_i, frame_i_shape, px_in_q, ptr_x,
                                        row_abs, row_q, col_q, chunk_cnt,
                                        frame_started, endOfFrame);

#ifdef LINUX_APP
    std::cerr << row_abs << "] -> ";
    std::string base = "conv2d/test/x_slice_";
    std::string fname = base + std::to_string(chunk_cnt) + ".bin";
    serialize(fname.c_str(), x_bram, sizeof(x_bram));
#endif

    if (endOfFrame) {
      row_abs = 0;
      chunk_cnt = 0;
      endOfFrame = px_in_q.keep ? false : true; // check for end of simulation
      if (row_q == 0) {
#ifdef LINUX_APP
        std::cerr << "|** nada ** |\n";
#endif
        continue;
      }
    }
    //
    shape_x.set(1, BRAM_C_I, row_q, col_q);
    shape_w.set(1, 3, 3, 3);
    //
    pads.set(0, 0, 0, 0);
    strides.set(2, 2, 1, 1);
    //
    uint32_t Hlast = row_q == frame_i_shape[2] ? 0 : row_q;
    conv2d(io, ptr_y, shape_y, ptr_x, frame_i_shape, pads, strides, Hlast);

#ifdef LINUX_APP
    std::cerr << row_q << " -> ";
    std::cerr << "[" << shape_x[0] << ", " << shape_x[1] << ",";
    std::cerr << " " << shape_x[2] << ", " << shape_x[3] << "]";
    std::cerr << " => ";
    std::cerr << "[" << shape_y[0] << ", " << shape_y[1] << ",";
    std::cerr << " " << shape_y[2] << ", " << shape_y[3] << "]" << "\n";
    {
      std::string base = "conv2d/test/conv_slice_";
      std::string fname = base + std::to_string(chunk_cnt) +
                          std::to_string(shape_y[2]) + "x" +
                          std::to_string(shape_y[3]) + ".bin";
      serialize(fname.c_str(), y_bram,
                shape_y[2] * shape_y[3] * sizeof(y_bram[0]));
    }
#endif

    // === Stream result into AXI4-Stream ===
   
    vga_to_axis<pixel_pkg_t, BRAM_W_O>(stream_o, y_bram, shape_y[2]);
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