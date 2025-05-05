#ifndef INCLUDE_RESIZER_HPP
#define INCLUDE_RESIZER_HPP
#ifndef LINUX_APP

#include <cstdint>
#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"
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

typedef ap_uint<32> pixel_t;
typedef ap_axiu<32, 1, 1, 1> pixel_pkg_t;
typedef hls::stream<pixel_pkg_t> stream_t;
#else
#include "ap_data.hpp"
#include "stream.hpp"
typedef uint32_t pixel_t;
typedef isolde::ap_axiu <pixel_t, bool, bool, bool> pixel_pkg_t;
typedef isolde::stream<pixel_pkg_t> stream_t;
#endif

void execute(stream_t &stream_o, stream_t &stream_i, int &M_o, int &C_o, int &H_o, int &W_o

);

#endif