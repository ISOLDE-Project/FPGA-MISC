

#include "py_rt/py_rt.h"
#include "utils/tensor_io.hpp"
#include "utils/trace.hpp"
#include "conv2d/conv2d.hpp"
#include <cstdint>
#include <cstdio>

int32_t y[1][1][540][960];

int main() {

  typedef dim_t<4> shape_type;
  shape_type shape_y, shape_x, shape_w, pads, strides;

  NumpyModule numpy_module;

  NumpyArray np_x = numpy_load("conv2d/test/x_int32.npy", numpy_module);
  shape_x.set(np_x.shape);

  NumpyArray np_w = numpy_load("conv2d/test/w_int32.npy", numpy_module);
  shape_w.set(np_w.shape);

  pads.set(0, 0, 0, 0);
  strides.set(2, 2, 1, 1);

  typedef tensor_io::_TensorIO io_type;
  io_type io;

  int32_t* ptr_x = (np_x.as<int32_t>());
  int32_t* ptr_w = (np_w.as<int32_t>());
  int32_t* ptr_y =
      reinterpret_cast<int32_t*>((y));
  int32_t* ptr_bias = 0;

  #ifdef GRAYING
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x,
                                     pads, strides);
  #else
  conv2d(io, ptr_y, shape_y, ptr_x, shape_x,
    ptr_w, shape_w, pads, strides, ptr_bias);
  #endif

  FILE *trace = stdout;
  py_pretty_print<int32_t>(trace, "w", ptr_w, shape_w, io);

  NumpyArray np_y;
  np_y.set_data((int32_t *)y);
  np_y.set_shape(shape_y);
  numpy_save("conv2d/test/y_cpp_int32.npy", np_y, numpy_module);

  return 0;
}
