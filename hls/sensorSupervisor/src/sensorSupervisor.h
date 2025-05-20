#ifndef INCLUDE_SENSOR_SUPERVISOR_HPP
#define INCLUDE_SENSOR_SUPERVISOR_HPP

#include "ap_int.h"
//typedef ap_uint<32> tuser_t;
typedef ap_uint<32> tuser_t;
typedef ap_uint<32> framecnt_t;

void execute(
    framecnt_t* frame_no,
    tuser_t tuser_in,
    bool    tvalid,
    bool    tready
);




#endif