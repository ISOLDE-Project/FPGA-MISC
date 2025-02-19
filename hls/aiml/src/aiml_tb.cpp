// Copyleft 2024 ISOLDE
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cstdint>
#include <string>

#include "CLI11.hpp"


int main(int argc, char** argv)
{
int ret = 0;

  std::string binaryFile;
  std::string outputFile;
  std::string strcycles("0");
  std::string straddress("0x0");
  CLI::App app{"aiml test bench"};
  app.add_option("-f,--file", binaryFile, "Specifies the RISC-V program binary file (elf)")->required(); 
  app.add_option("-o,--output", outputFile, "Specifies the output file (standard output of the running program)");
  app.add_option("-c,--stop-at-cycle", strcycles, "Stops after specified number of cycles");
  app.add_option("-a,--stop-at-addr", straddress, "Stops at specified address");
  CLI11_PARSE(app, argc, argv);
  
    // 

  uint32_t cycles=0;
  uint32_t stopAtCycle=std::stoi(strcycles, 0);
  uint32_t stopAtAddr=std::stoi(straddress, 0,16);
  return ret;
}