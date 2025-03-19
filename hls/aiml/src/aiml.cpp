

#include <cstdint>

void execute(uint32_t cfg_port1,  uint32_t* cfg_port1_echo, 
             volatile uint32_t *data_port) {

  uint32_t cmd;
  uint32_t out_val;
  // while (1) {
  cmd = cfg_port1;
  out_val = 0x40 + cmd;
  *cfg_port1_echo = out_val;
  // switch (cmd) {
  // case 0xABADCAFE: {
  //   param2 = *cfg_port2;
  //   *data_port = 0xABEE;
  // }

  // default:
  data_port[0] = out_val;
  data_port[1] = 0xABEE;
  // }
  // }
}