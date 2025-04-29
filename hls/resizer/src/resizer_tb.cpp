// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cstdint>
#include <string>
#include <cstdio>
#include <fstream>
#include <iostream>



#include "resizer.h"


int32_t y[1][1][540][960];

#define CHANNELS 3
#define HEIGHT 1080
#define WIDTH 1920

  int32_t np_x[1][CHANNELS][HEIGHT][WIDTH];

int main() {

  int ret =0;

  std::ifstream infile("conv2d/test/x_int32.bin", std::ios::binary);
  if (!infile) {
    std::cerr << "Error opening input file " << std::endl;
    exit(1);
  }
  infile.read(reinterpret_cast<char *>(np_x), sizeof(np_x));
  infile.close();


  

  
  int32_t* ptr_x =  reinterpret_cast<int32_t*>(np_x);
  int32_t* ptr_w =  reinterpret_cast<int32_t*>(0);
  int32_t* ptr_y =
      reinterpret_cast<int32_t*>((y));
  
       execute(ptr_y,
        ptr_x,
        ptr_w
        );

  return ret;
}