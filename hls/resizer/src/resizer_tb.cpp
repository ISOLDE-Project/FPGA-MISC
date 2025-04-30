// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cstdint>
#include <string>
#include <cstdio>
#include <fstream>
#include <iostream>



#include "resizer.h"







  int32_t np_x[1][CHANNELS_I][HEIGHT_I][WIDTH_I];
  int32_t    y[1][CHANNELS_O][HEIGHT_O][WIDTH_O];
  int32_t np_w[1][3][3][3];

  const char* y_bin="../../../../../operators/conv2d/test/y_xsim_int32.bin";
  const char* x_bin="../../../../../operators/conv2d/test/x_int32.bin";
  const char* w_bin="../../../../../operators/conv2d/test/w_int32.bin";
  

int main() {

  int ret =0;

  {
    std::ifstream infile(x_bin, std::ios::binary);
    if (!infile) {
      std::cerr << "Error opening x_bin input file " << std::endl;
      exit(1);
    }
    infile.read(reinterpret_cast<char *>(np_x), sizeof(np_x));
    infile.close();
  }

  {
    std::ifstream infile(w_bin, std::ios::binary);
    if (!infile) {
      std::cerr << "Error opening w_bin input file " << std::endl;
      exit(1);
    }
    infile.read(reinterpret_cast<char *>(np_w), sizeof(np_w));
    infile.close();
  }
  

  
  int32_t* ptr_x =  reinterpret_cast<int32_t*>(np_x);
  int32_t* ptr_w =  reinterpret_cast<int32_t*>(np_w);
  int32_t* ptr_y =
      reinterpret_cast<int32_t*>((y));
  
       execute(ptr_y,
        ptr_x,
        ptr_w
        );

        {
          std::ofstream outfile(y_bin, std::ios::binary);
          if (!outfile) {
            std::cerr << "Error opening outfile file " << std::endl;
            exit(1);
          }
          outfile.write(reinterpret_cast<char *>(y), sizeof(y));
          outfile.close();
        }
  return ret;
}