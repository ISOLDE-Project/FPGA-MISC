

#include "sensorSupervisor.h"

void execute(
    framecnt_t* frame_no,
    tuser_t tuser_in,
    bool    tvalid,
    bool    tready
){
    if (tvalid && tready) {
        *frame_no = tuser_in;

}
}