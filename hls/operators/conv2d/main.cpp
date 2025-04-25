

#include "../utils/memoryInterface.h"
#include "../utils/tensor_io.hpp"
#include "../utils/trace.hpp"
#include "../py_rt/py_rt.h"
#include "conv2d.hpp"
#include <cstdio>





float y[1][1][540][960];



int main() {


  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;

  NumpyModule numpy_module;

  NumpyArray np_x = numpy_load("conv2d/test/x.npy", numpy_module);
  shape_x.set(np_x.shape);

  NumpyArray np_w = numpy_load("conv2d/test/w.npy", numpy_module);
  shape_w.set(np_w.shape);

  pads.set(1, 1, 1, 1);
  strides.set(2, 2, 1, 1);

  typedef tensor_io::_TensorIO<ArrayMemory> io_type;
  io_type io;

  
  
  arch::addr_type ptr_x = reinterpret_cast<arch::addr_type>(np_x.as<float>());
  arch::addr_type ptr_w = reinterpret_cast<arch::addr_type>(np_w.as<float>());
  arch::addr_type ptr_y =
      reinterpret_cast<arch::addr_type>(reinterpret_cast<const void *>(y));
  arch::addr_type ptr_bias = 0;

  // for compatibility with HLS
  io_type::addr_type *mem_phy = 0;

  conv2d<float, float, float>(io, mem_phy, ptr_y, shape_y, ptr_x, shape_x,
                              ptr_w, shape_w, pads, strides, ptr_bias);
  io.flush_wr_cache(mem_phy);

//   FILE *trace = stdout;

//   py_pretty_print<float>(trace, "x", ptr_x, shape_x, io, mem_phy);

//   py_pretty_print<float>(trace, "w", ptr_w, shape_w, io, mem_phy);

//   py_pretty_print<float>(trace, "y", ptr_y, shape_y, io, mem_phy);

  NumpyArray np_y;
  np_y.set_data((float*)y);
  np_y.set_shape(shape_y);
  numpy_save("conv2d/test/y_cpp.npy",np_y, numpy_module);

  return 0;
}
