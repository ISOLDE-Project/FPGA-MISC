#ifndef INCLUDE_RESIZER_HPP
#define INCLUDE_RESIZER_HPP
#include "axis/axis_helper.hpp"
#include <cstdint>

#define CHANNELS_I  3
#define HEIGHT_I    100
#define WIDTH_I     125
#
#define CHANNELS_O  1
#define HEIGHT_O    50
#define WIDTH_O     63

#define W_SIZE 1 * 3 * 3 * 3 // 1x3x3x3 -> flattened size
#define X_SIZE 1 * CHANNELS_I * HEIGHT_I * WIDTH_I
#define Y_SIZE 1 * CHANNELS_O * HEIGHT_O * WIDTH_O



/**
template <int D, int U, int TI, int TD>
struct ap_axiu {
    ap_uint<D>   data;  // Main data (e.g. 32 bits for RGB packed)
    ap_uint<D/8> keep;  // Byte-valid signal (one bit per byte)
    ap_uint<D/8> strb;  // Strobe signal (usually same as keep)
    ap_uint<U>   user;  // User-defined sideband signal
    ap_uint<1>   last;  // Indicates end of frame or line
    ap_uint<TI>  id;    // Transaction ID (optional for stream routing)
    ap_uint<TD>  dest;  // Destination routing (optional)
};
 */

typedef ap_uint< 32 >              pixel_t;
typedef ap_axiu< 32,1,1,1 >        pixel_pkg_t;
typedef hls::stream< pixel_pkg_t > stream_t;

void execute(       stream_t& stream_o,
                    stream_t& stream_i,
                    volatile int32_t w_bram[W_SIZE]
);

#endif