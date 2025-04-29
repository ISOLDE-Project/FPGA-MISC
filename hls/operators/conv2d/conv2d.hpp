#ifndef CONV2D_OP_HEADER
#define CONV2D_OP_HEADER

#include <cstddef>
#include <cstdint>
#include <cstdio>

#include "utils/tensor_utils.hpp"
#include "scratchpad_memory.h"

template <typename io_t, typename addr_type, typename dim_t, typename tensor_io>
void kernel_2_vector(tensor_io &io,
                     volatile typename tensor_io::addr_type *mem_phy,
                     addr_type src, const dim_t shape, dim_t &index,
                     volatile io_t *v) {
  using index_t = int32_t;
  using tensor_index = dim_t;

  tensor_index x_idx;
  size_t offset_y = 0;
  size_t offset_x = 0;
  io_t val;
  index_t max_idx = shape[1] * shape[2] * shape[3];
  x_idx.set(index[0], 0, 0, 0);
  // fprintf(stderr,"cpy_idx");dump(stderr,x_idx);
  offset_x = tensor_index_to_offset(shape, x_idx);
  for (index_t idx = 0; idx < max_idx; ++idx) {
    val = io.template tensor_read_next<io_t>(mem_phy, src, offset_x);
    v[offset_y] = val;
    offset_y += 1;
  }
#ifdef _DEBUG_OPERATORS_CONV2D
  static int kernel_2_vector_cnt = 0;
  fprintf(stderr, "kernel_2_vector_cnt=%d\n", ++kernel_2_vector_cnt);
#endif
}

template <typename io_t, typename addr_type, typename dim_t, typename tensor_io>
void slice_tensor_2_vector(tensor_io &io,
                           volatile typename tensor_io::addr_type *mem_phy,
                           addr_type src, const dim_t shape, int32_t y_start,
                           dim_t &size, volatile io_t *v) {
  using index_t = int32_t;
  using tensor_index = dim_t;

  static int32_t old_y_start = -1;
#ifdef _DEBUG_OPERATORS_CONV2D
  static int slice_tensor_2_vector_cnt = 0;
// fprintf(stderr,"y_start=%d,
// offset_y=%ld\n",y_start,offset_y);dump(stderr,idx);fprintf(stderr,"\n");dump(stderr,size);fprintf(stderr,"\n");dump(stderr,shape);
#endif
  if (old_y_start == y_start) {
#ifdef _DEBUG_OPERATORS_CONV2D
    fprintf(stderr, "y_start=%d,slice_tensor_2_vector_cnt=%d, cached\n",
            y_start, slice_tensor_2_vector_cnt);
#endif
    return;
  }
#ifdef _DEBUG_OPERATORS_CONV2D
  fprintf(stderr, "y_start=%d,slice_tensor_2_vector_cnt=%d\n", y_start,
          ++slice_tensor_2_vector_cnt);
#endif
  old_y_start = y_start;
  size_t offset_y = 0;
  size_t offset_x;
  io_t val;
  index_t max_x_y = size[2] * size[3];
  tensor_index idx;
  // fprintf(stderr,"cpy_idx");dump(stderr,x_idx);
  for (index_t c = 0; c < size[1]; ++c) {
    idx.set(0, c, y_start, 0);
    offset_x = tensor_index_to_offset(shape, idx);
    for (index_t idx = 0; idx < max_x_y; ++idx) {
      val = io.template tensor_read_next<io_t>(mem_phy, src, offset_x);
      v[offset_y] = val;
      offset_y += 1;
    }
  }
}

template <typename out_t, typename in_t, typename weight_t, typename addr_type,
          typename dim_t, typename tensor_io>
void conv2d(tensor_io &io, volatile typename tensor_io::addr_type *mem_phy,
            addr_type output, dim_t &output_shape, addr_type input,
            const dim_t input_shape, addr_type weight, const dim_t weight_shape,
            const dim_t pads, const dim_t strides_dilations, addr_type bias) {
  using index_t = int32_t;
  using tensor_index = dim_t;
  // calculate output size
  // input
  enum { IN = 0, IC = 1, IH = 2, IW = 3 };

  // weights
  enum { M = 0, KC = 1, KH = 2, KW = 3 };

  // output
  enum {
    ON = 0,
    OC = 1,
    OH = 2,
    OW = 3
  }; // output batch size, output channels, output height, output width

  // strides_dilation
  enum { strides_y = 0, strides_x = 1, dilation_y = 2, dilation_x = 3 };

  // pads
  enum { pad_top, pad_bottom, pad_left, pad_right };
  // initialise bias_shape
  dim_t bias_shape;
  bias_shape.set(1, 1, 1, weight_shape[M]);

  // compute output shape
  output_shape[ON] = input_shape[IN]; // batch size
  output_shape[OC] = weight_shape[M]; // output channels
  output_shape[OH] =
      (input_shape[IH] - weight_shape[KH] + pads[pad_top] + pads[pad_bottom]) /
          strides_dilations[strides_y] +
      1; // output H
  output_shape[OW] =
      (input_shape[IW] - weight_shape[KW] + pads[pad_left] + pads[pad_right]) /
          strides_dilations[strides_x] +
      1; // output W

  tensor_index x_idx, x_slice_size;
  tensor_index k_cpy;
  tensor_index y_cpy;
  size_t offset_b;
  size_t offset_y = 0, offset_w;
  size_t k_size = weight_shape[KW] * weight_shape[KH];
  size_t shuffle_ky;
  size_t shuffle_ic;
  // x_slice_size.set(0,weight_shape[KC],weight_shape[KH],input_shape[IW]);
  x_slice_size.set(1, input_shape[KC], weight_shape[KH], input_shape[IW]);
  size_t x_k_size = x_slice_size[IH] * x_slice_size[IW];

  k_cpy.set(0, 0, 0, 0);
  // kernel_2_vector(io,mem_phy,input,input_shape,k_cpy,scratchpad_1);

  if (bias) {
    kernel_2_vector(io, mem_phy, bias, bias_shape, k_cpy, scratchpad_2);
  }

  for (index_t n = 0; n < output_shape[ON]; ++n)
    for (index_t oc = 0; oc < output_shape[OC]; ++oc) {
      // load kernel in scratchpad memory
      k_cpy.set(oc, 0, 0, 0);
      kernel_2_vector(io, mem_phy, weight, weight_shape, k_cpy, scratchpad_0);
      for (index_t oy = 0; oy < output_shape[OH]; ++oy) {
        index_t iy = oy * strides_dilations[strides_y] - pads[pad_top];
        for (index_t ky = 0; ky < weight_shape[KH]; ++ky) {
          index_t y = iy + ky * strides_dilations[dilation_y];
          if (0 > y || y >= input_shape[IH])
            continue;
          slice_tensor_2_vector(io, mem_phy, input, input_shape, y,
                                x_slice_size, scratchpad_1);
          y_cpy.set(0, 0, y, 0);
          break;
        }

        for (index_t ox = 0; ox < output_shape[OW]; ++ox) {
          out_t acc = 0;
          index_t iy = oy * strides_dilations[strides_y] - pads[pad_top];
          index_t ix = ox * strides_dilations[strides_x] - pads[pad_left];
          shuffle_ic = 0;
          for (index_t ic = 0; ic < weight_shape[KC]; ++ic) {
            x_idx.set(n, ic, 0, 0);
            size_t base_x = tensor_index_to_offset(input_shape, x_idx);
            for (index_t ky = 0; ky < weight_shape[KH]; ++ky) {
              index_t y = iy + ky * strides_dilations[dilation_y];
              if (0 > y || y >= input_shape[IH])
                continue;
              shuffle_ky = ky * weight_shape[KW];
              for (index_t kx = 0; kx < weight_shape[KW]; ++kx) {
                index_t x = ix + kx * strides_dilations[dilation_x];
                if (0 > x || x >= input_shape[IW])
                  continue;
#if 0
                x_idx.set(n, ic, y, x);
                in_t in_value = io.template tensor_read_with_offset<in_t, 3>(
                    mem_phy, input, input_shape, base_x, x_idx);
#else
                size_t offset_x = ic * x_slice_size[IW] * x_slice_size[IH] +
                                  (y - y_cpy[2]) * x_slice_size[IW] + x;
                in_t in_value = scratchpad_1[offset_x];
#endif
                offset_w = shuffle_ic + shuffle_ky + kx;
                weight_t w_value = scratchpad_0[offset_w];
                acc += in_value * w_value;
              }
            }
            shuffle_ic += k_size;
          }
          if (bias) {
            // offset_b = oc;
            // dim_t offset_b = {0, 0, 0, oc};
            out_t val = scratchpad_2[oc];
            //  io.template tensor_read_next<out_t>(mem_phy, bias, offset_b);
            acc += val;
          }
#ifdef SCALE
          acc /= SCALE;
#endif
          io.cache_tensor_write_next(mem_phy, output, offset_y, acc );
        }
      } // oy
    }   // oc
}

#endif