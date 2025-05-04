


#include "utils/tensor_io.hpp"
#include "utils/trace.hpp"
#include "py_rt/py_rt.h"
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

  pads.set(0, 0, 0, 0);
  strides.set(2, 2, 1, 1);

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  float* ptr_x = (np_x.as<float>());
  float* ptr_w = (np_w.as<float>());
  float* ptr_y =
      reinterpret_cast<float*>((y));
  float* ptr_bias = 0;

  
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x,
                                    ptr_w, shape_w, pads, strides, ptr_bias);
  

  FILE *trace = stdout;
  py_pretty_print<float>(trace, "w", ptr_w, shape_w, io);

  NumpyArray np_y;
  np_y.set_data((float*)y);
  np_y.set_shape(shape_y);
  numpy_save("conv2d/test/y_cpp.npy",np_y, numpy_module);

  return 0;
}
