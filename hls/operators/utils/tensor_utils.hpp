#pragma once

#include <assert.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>

// #include <iostream>
//  input
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

typedef int32_t index_t;

template <uint32_t N> struct dim_t {
  static uint32_t constexpr rank = N;
  uint32_t data[N];
  uint32_t &operator[](int i) { return data[i]; }
  uint32_t operator[](int i) const { return data[i]; }
  operator uint32_t *() { return data; }

  dim_t() { memset((void *)data, 0, N); }

  template <typename... A> void set(const A... vals) {
    // lambda expressions
    // https://en.cppreference.com/w/cpp/language/lambda
    uint32_t i = 0;
    auto f = [&](uint32_t val) {
      if (i < rank)
        data[i++] = val;
    };
    // unary right fold over comma
    // https://www.scs.stanford.edu/~dm/blog/param-pack.html#comma-fold
    (f(vals), ...);
  }

  template <typename... A> [[deprecated]] dim_t(const A... vals) {
    // lambda expressions
    // https://en.cppreference.com/w/cpp/language/lambda
    uint32_t i = 0;
    auto f = [&](uint32_t val) {
      if (i < rank)
        data[i++] = val;
    };
    // unary right fold over comma
    // https://www.scs.stanford.edu/~dm/blog/param-pack.html#comma-fold
    (f(vals), ...);
  }

  // void operator=( const dim_t &other) const{
  //  assert(false);
  //  assert(false && "maybe function template param deduction force left hand
  //  side type operator to const??");
  // }

  bool operator==(const dim_t &other) {
    bool result = true;
    for (uint32_t i = 0; i < rank; ++i)
      if (data[i] != other.data[i]) {
        result = false;
        break;
      }
    return result;
  }
};

template <typename tensor> uint32_t rank(tensor &) { return tensor::rank; }
template <typename tensor> const uint32_t rank() { return tensor::rank; }

// Check the tensor shape is valid and return the tensor size in elements
template <typename dim_t> size_t tensor_size(dim_t shape) {
  size_t size = 1;
  for (int32_t i = 0; i < rank(shape); i++) {
    // REQUIRE(1 <= shape[i] && shape[i] <= maximum<size_t> / size);
    size *= shape[i];
  }
  return size;
}

template <typename dim_t> size_t tensor_size_safe(dim_t shape) {
  size_t size = 1;
  for (int32_t i = 0; i < rank(shape); i++) {
    // REQUIRE(1 <= shape[i] && shape[i] <= maximum<size_t> / size);
    if (shape[i] >= 1)
      size *= shape[i];
  }
  return size;
}

template <typename dim_t>
size_t tensor_index_to_offset(dim_t shape, dim_t index) {
  size_t size = tensor_size(shape); // check tensor shape is valid
  size_t offset = 0;
  for (int32_t i = 0; i < rank(shape); i++) {
    // REQUIRE(index[i] >= 0 && index[i] < shape[i]);
    offset = offset * shape[i] + index[i];
  }
  return offset;
}

// Convert an element offset to tensor index co-ordinates
template <typename dim_t>
dim_t tensor_offset_to_index(dim_t shape, size_t offset) {
  size_t size = tensor_size(shape); // check tensor shape is valid
  // REQUIRE(offset < size);
  dim_t index; // index has rank(shape) indicies
  for (int32_t i = rank(shape) - 1; i >= 0; i--) {
    index[i] = offset % shape[i];
    offset /= shape[i];
  }
  return index;
}

/**
*** Broadcast Helper
* The index argument should be a valid location within out_shape.
* The function returns the location within in_shape that contributes
* to the output based on broadcasting rules.
**/

template <typename dim_t>
void apply_broadcast(dim_t &index, const dim_t &out_shape,
                     const dim_t &in_shape) {
  using index_t = int32_t;
  // ERROR_IF(rank(out_shape) != rank(in_shape));
  // ERROR_IF(rank(out_shape) != rank(index));
  for (index_t i = 0; i < rank(out_shape); ++i) {
    if (out_shape[i] != in_shape[i]) {
      assert(in_shape[i] == 1);
      index[i] = 0;
    }
  }
}

template <typename dim_t> void max(dim_t &out, const dim_t &a, const dim_t &b) {
  // ERROR_IF(rank(out_shape) != rank(in_shape));
  // ERROR_IF(rank(out_shape) != rank(index));
  using index_t = int32_t;
  for (index_t i = 0; i < rank(a); ++i) {
    if (a[i] < b[i]) {
      out[i] = b[i];
    } else {
      out[i] = a[i];
    }
  }
}

struct TensorIO {

  /*
    template <typename elem_type, typename dim_t>
    void tensor_write(elem_type *address, const dim_t& shape, const dim_t&
    index, const elem_type value) { size_t offset =
    tensor_index_to_offset(shape, index); address[offset] = value;
    }
  */
  template <typename elem_type, typename dim_t>
  void tensor_write(volatile elem_type *address, const dim_t &shape,
                    const dim_t &index, const elem_type value) {
    size_t offset = tensor_index_to_offset(shape, index);
    address[offset] = value;
  }

  template <typename ret_type, typename elem_type, typename dim_t>
  ret_type tensor_read(elem_type *address, const dim_t &shape,
                       const dim_t &index) {
    size_t offset = tensor_index_to_offset(shape, index);
    elem_type result = address[offset];
    return static_cast<ret_type>(result);
  }

  template <uint32_t W, uint32_t H,typename ret_type, typename elem_type, typename dim_t>
  ret_type tensor_read_with_offset(elem_type *address, const dim_t &shape, size_t offset,
                       const dim_t &index) {
    offset = offset + index[H]*shape[W]+index[W];
    elem_type result = address[offset];
    return static_cast<ret_type>(result);
  }
};

template <typename elem_type, typename dim_t>
elem_type tensor_read(elem_type *address, dim_t shape, dim_t index) {
  size_t offset = tensor_index_to_offset(shape, index);
  elem_type result;
  result = address[offset];
  return result;
}
