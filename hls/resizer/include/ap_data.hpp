#pragma once
#include <cstdint>

namespace isolde
{
    template <typename data_t, typename user_t, typename id_t, typename dst_t>
    struct ap_axiu
    {
        data_t data;       // Main data (e.g. 32 bits for RGB packed)
        uint8_t keep; // Byte-valid signal (one bit per byte)
        uint8_t strb; // Strobe signal (usually same as keep)
        user_t user;  // User-defined sideband signal
        bool last;    // Indicates end of frame or line
        id_t id;      // Transaction ID (optional for stream routing)
        dst_t dest;   // Destination routing (optional)
    };
}