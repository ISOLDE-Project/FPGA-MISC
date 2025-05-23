

#include "img2axis.h"
#include "axis_helper.hpp"
#include "conv2d/conv2d.hpp"
#include "shapes/FullHD.inc"
#include "utils/tensor_io.hpp"

#ifdef LINUX_APP
#include "utils/trace.hpp"
#include <iostream>
void serialize(const char *fname, uint32_t *buffer, std::streamsize _n);
#endif

/**
#define FHD_HEIGHT_I    1080
#define FHD_WIDTH_I     1920
*/

void execute(stream_t &stream_o, volatile uint32_t *data_port,
             uint32_t frame_cnt, bool end_of_stream ) {

  uint32_t frame_no;
  for(frame_no=0;frame_no<frame_cnt;++frame_no)
    matrix_to_axis<pixel_pkg_t, FHD_WIDTH_I>(stream_o, data_port, FHD_HEIGHT_I,
                                            frame_no, true);

  if (end_of_stream) { // just to signal the end of streaming
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
}