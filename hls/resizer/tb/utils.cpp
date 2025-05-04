

#include <cstdint>
#include <string>
#include <cstdio>
#include <fstream>
#include <iostream>

void serialize(const char *fname, uint32_t* buffer, std::streamsize _n){

    {
        std::ofstream outfile(fname, std::ios::binary);
        if (!outfile)
        {
          std::cerr << "Error opening outfile file " << std::endl;
          exit(1);
        }
        outfile.write(reinterpret_cast<char *>(buffer), _n);
        outfile.close();
      }
}