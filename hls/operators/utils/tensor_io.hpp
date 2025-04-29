#ifndef _TENSOR_IO_SIMULATION_H_
#define _TENSOR_IO_SIMULATION_H_


#include <cstddef>
#include <cstdint>

#ifndef __SYNTHESIS__
#define pretty_print_float(addr, shape, io)                                    \
  pretty_print<float>(stderr, addr, shape, io)

#else
#define pretty_print_float(addr, shape, io)

#endif


namespace tensor_io {

struct _TensorIO {

  _TensorIO() {
  }


  template <typename elem_type, typename dim_t>
  void tensor_write(volatile elem_type* address,
                    const dim_t &shape, const dim_t &index,
                    const elem_type value) {

    auto idx = tensor_index_to_offset(shape, index);
    address[idx]=value;
  }


  template <typename elem_type>
  void tensor_write_next(volatile  elem_type* address,
                         size_t &offset, const elem_type value) {

    
    
    address[offset]=value;
    offset += 1;
  }

  template <typename elem_type, typename dim_t>
  elem_type tensor_read(volatile elem_type *address, const dim_t &shape,
                        dim_t &index) {

    auto offset = tensor_index_to_offset(shape, index);

    return address[offset];
  }

  template <typename elem_type, uint32_t W, typename dim_t>
  elem_type tensor_read_with_offset(volatile elem_type* address, const dim_t &shape,
                                    size_t offset, dim_t &index) {
    
    offset = offset + index[W - 1] * shape[W] + index[W];
    
    return address[offset];
    
  }

  template <typename elem_type>
  elem_type tensor_read_next(volatile elem_type *address, size_t &offset) {
    elem_type result = address[offset];
    offset += 1;
    return result;
  }
};

} // namespace tensor_io

#endif