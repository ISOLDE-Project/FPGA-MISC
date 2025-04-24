


#include <cstdio>
#include "conv2d.hpp"
#include "../utils/tensor_io.hpp"
#include "../utils/memoryInterface.h"
#include "../utils/trace.hpp"




  float input[1][1][5][5] = // (1, 1, 5, 5) input tensor
      {{{
          {0.0, 1.0, 2.0, 3.0, 4.0},
          {5.0, 6.0, 7.0, 8.0, 9.0},
          {10.0, 11.0, 12.0, 13.0, 14.0},
          {15.0, 16.0, 17.0, 18.0, 19.0},
          {20.0, 21.0, 22.0, 23.0, 24.0},
      }}};

  float weights[1][1][3][3] = // # (1, 1, 3, 3) tensor for convolution weights
      {{{
          {1.0, 1.0, 1.0},
          {1.0, 1.0, 1.0},
          {1.0, 1.0, 1.0},
      }}};

   float y[1][1][3][3]; 


int main(){
    typedef dim_t<4> shape_type;

    shape_type shape_y,shape_x,shape_w, pads,strides;
    shape_x.set(1, 1, 5, 5);
    shape_w.set(1, 1, 3, 3);
    pads.set(1, 1, 1, 1);
    strides.set(2,2,1,1);

    typedef tensor_io::_TensorIO<ArrayMemory > io_type;
    io_type io;


    arch::addr_type ptr_x = reinterpret_cast<arch::addr_type>((input));
    arch::addr_type ptr_w = reinterpret_cast<arch::addr_type>(reinterpret_cast<const void*>(weights));
    arch::addr_type ptr_y = reinterpret_cast<arch::addr_type>(reinterpret_cast<const void*>(y));
    arch::addr_type ptr_bias =0;

    //for compatibility with hls
    io_type::addr_type* mem_phy = 0;

        conv2d<float,float,float>(io,mem_phy,ptr_y, shape_y, ptr_x,shape_x,
            ptr_w, shape_w, pads,strides,ptr_bias); 
        io.flush_wr_cache(mem_phy);

    FILE* trace=stdout;

    py_pretty_print<float>(trace, "x",ptr_x, shape_x,io,mem_phy);

    py_pretty_print<float>(trace, "w",ptr_w, shape_w,io,mem_phy);

    py_pretty_print<float>(trace, "y",ptr_y, shape_y,io,mem_phy);

    
    return 0;
}
