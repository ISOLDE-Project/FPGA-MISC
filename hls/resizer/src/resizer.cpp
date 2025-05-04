

#include "resizer.h"
#include "conv2d/conv2d.hpp"
#include "utils/tensor_io.hpp"
#include "conv2d/shapes_FullHD.inc"
#include "axis_helper.hpp"


#ifdef LINUX_APP
#include <iostream>
#include "utils/trace.hpp"
void serialize(const char *fname, uint32_t* buffer, std::streamsize _n);
#endif

#define N_KNOB 50
#define CHUNK_HEIGHT (2 * N_KNOB + 3)

#define BRAM_C_I FHD_CHANNELS_I
//#define BRAM_H_I FHD_HEIGHT_I
#define BRAM_H_I CHUNK_HEIGHT
#define BRAM_W_I FHD_WIDTH_I

#define BRAM_C_O FHD_CHANNELS_O
#define BRAM_H_O FHD_HEIGHT_O
#define BRAM_W_O FHD_WIDTH_O

/*frame shape*/
#define CHANNELS_I BRAM_C_I
#define HEIGHT_I BRAM_H_I
#define WIDTH_I BRAM_W_I


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
  int row_q = 0, col_q = 0,row_abs=0;;
  int chunk_cnt = 0;
  pixel_pkg_t px_in_q;
  px_in_q.user = 0;

  H_o = 0;
  W_o = 0;

  #ifdef LINUX_APP
  FILE *trace = stdout;
  fprintf(trace,"frame_i_shape=");
  dump(trace,frame_i_shape);
  fprintf(trace,"chunk_height= %d\n",BRAM_H_I);
  #endif
  //
  volatile uint32_t *ptr_x = reinterpret_cast<uint32_t *>(x_bram);
  volatile uint32_t *ptr_y = reinterpret_cast<uint32_t *>(y_bram);
  while (!endOfFrame)
  {
    

    #ifdef LINUX_APP

    std::cerr << "input [" << row_abs << ":";
#endif
    axis_read_lines<BRAM_H_I, BRAM_W_I>(
        stream_i, frame_i_shape, px_in_q, ptr_x, row_abs,row_q, col_q, chunk_cnt, frame_started, endOfFrame);

#ifdef LINUX_APP
    std::cerr << row_abs << "] -> ";
    std::string base = "conv2d/test/x_slice_";
    std::string fname = base + std::to_string(chunk_cnt) + ".bin";
    serialize(fname.c_str(), x_bram, sizeof(x_bram));
#endif


    if (endOfFrame){
      row_abs=0;
      endOfFrame= px_in_q.keep?false:true; //check for end of simulation
      if(row_q == 0){
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
    uint32_t Hlast = row_q == frame_i_shape[2] ? 0: row_q;
    conv2d(io, ptr_y, shape_y, ptr_x, frame_i_shape, pads, strides,Hlast);

    M_o = shape_y[0];
    C_o = shape_y[1];
    H_o += shape_y[2];
    W_o = shape_y[3];

#ifdef LINUX_APP
    std::cerr << row_q <<" -> ";
    std::cerr << "[" << shape_x[0]<<", "<<shape_x[1]<<",";
    std::cerr << " " << shape_x[2]<<", "<<shape_x[3]<<"]";
    std::cerr <<" => ";
    std::cerr << "[" << shape_y[0]<<", "<<shape_y[1]<<",";
    std::cerr << " " << shape_y[2]<<", "<<shape_y[3]<<"]" << "\n";
{
    std::string base = "conv2d/test/conv_slice_";
    std::string fname = base + std::to_string(chunk_cnt) + std::to_string(shape_y[2])+"x"+ std::to_string(shape_y[3])+".bin";
    serialize(fname.c_str(), y_bram, shape_y[2]*shape_y[3]*sizeof(y_bram[0]));   
}
#endif

    // === Stream result into AXI4-Stream ===
    offset_y = 0;
    for (int i = 0; i < shape_y[2]; ++i)
    {
      y_index.set(0, 0, i, 0);
      offset_y = tensor_index_to_offset(shape_y, y_index);
      for (int j = 0; j < shape_y[3]; ++j)
      {
        pixel_pkg_t px;
        px.data = y_bram[offset_y++];
        px.keep = -1; // All bytes valid
        px.strb = -1;
        px.id = 0;
        px.dest = 0;
        px.last = (j == shape_y[3] - 1) ? 1 : 0;     // End of each line
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