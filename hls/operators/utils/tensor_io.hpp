#ifndef _TENSOR_IO_SIMULATION_H_
#define _TENSOR_IO_SIMULATION_H_


#include "memoryInterface.h"
#include <cstddef>
#include <cstdint>

#ifndef __SYNTHESIS__
#define pretty_print_float(  addr, shape, io )  pretty_print<float>(stderr, addr, shape, io)

#else
#define pretty_print_float(  addr, shape, io )  

#endif

 template <size_t size> 
 struct PointerType;

 template<>
 struct PointerType<8>{
    typedef uint64_t type;
 };

template<>
 struct PointerType<4>{
    typedef uint32_t type;
 };

 template <typename elem_type> 
  uint32_t convert_pointer(elem_type* p){
    using src_type=typename PointerType<sizeof((void*)p)>::type;
    return reinterpret_cast<src_type>(p);

  }
    
template <typename elem_type> 
inline void set(DataUnion& data, const elem_type value);

template <> 
inline void set(DataUnion& data, const float value){
  data.f32=value;
}

template <> 
inline void set(DataUnion& data, const int32_t value){
  data.i32=value;
}

template <> 
inline void set(DataUnion& data, const uint32_t value){
  data.ui32=value;
}

   
template <typename elem_type> 
inline elem_type get(const DataUnion& data);

template <> 
inline float get(const DataUnion& data){ return data.f32;}

template <> 
inline volatile float get(const DataUnion& data){ return data.f32;}


template <> 
inline int32_t get(const DataUnion& data){ return data.i32;}

template <> 
inline volatile int32_t get(const DataUnion& data){ return data.i32;}

template <> 
inline uint32_t get(const DataUnion& data){ return data.ui32;}


namespace tensor_io{
  

template<typename MemIntfType>
struct _TensorIO {
  using addr_type=typename MemIntfType::addr_type;
  using data_type=typename MemIntfType::data_type;
  static constexpr uint32_t wr_cache_size   = 512;
  DataUnion write_cache[wr_cache_size];
  addr_type wr_addr;
  uint32_t  wr_size;

  _TensorIO(){
    wr_addr=0x0;
    wr_size =0x0;
  }

  void flush_wr_cache(volatile addr_type* mem_phy){
    if(wr_addr== 0x0)
      return;
    for(uint32_t offset=0;offset<wr_size;++offset){
      addr_type addr=(offset*sizeof(data_type)+wr_addr);
      MemIntfType::pushData(mem_phy,addr,write_cache[offset]);
    }
     wr_size =0x0;
  }
  





  template <typename elem_type, typename dim_t> 
  void tensor_write(volatile addr_type* mem_phy, const addr_type address, const dim_t& shape, const dim_t& index,
                    const elem_type value) {
    
    DataUnion data;
    set(data,value);
    addr_type offset = tensor_index_to_offset(shape, index);
    addr_type addr=(offset*sizeof(data_type)+address);
    MemIntfType::pushData(mem_phy,addr,data);
  }

  template <typename elem_type> 
  void cache_tensor_write_next(volatile addr_type* mem_phy, const addr_type address, size_t&offset,
                    const elem_type value) {
    
    DataUnion data;
    set(data,value);
    addr_type addr=(offset*sizeof(data_type)+address);
    uint32_t wr_cache_idx = (addr - wr_addr)/4;
    if(wr_cache_idx<wr_cache_size){
      write_cache[wr_cache_idx]=data;
      wr_size = wr_cache_idx+1;
    }else{
      flush_wr_cache(mem_phy);
      wr_addr = addr;
      write_cache[0]=data;
      wr_size = 1;
      //MemIntfType::pushData(mem_phy,addr,data);
    }
    offset+=1;
  }

template <typename elem_type> 
  void tensor_write_next(volatile addr_type* mem_phy, const addr_type address, size_t&offset,
                    const elem_type value) {
    
    DataUnion data;
    set(data,value);
    addr_type addr=(offset*sizeof(data_type)+address);
    MemIntfType::pushData(mem_phy,addr,data);
    offset+=1;
  }

  template <typename elem_type, typename dim_t> 
  elem_type tensor_read(volatile addr_type*& mem_phy,  const addr_type address,  const dim_t& shape,  dim_t& index) {
    DataUnion data;
    addr_type offset = tensor_index_to_offset(shape, index);
    addr_type addr=(offset*sizeof(data_type)+address);
    MemIntfType::fetchData( mem_phy,addr,data);
    return  get<elem_type>(data);
  }

  template <typename elem_type, uint32_t W,typename dim_t> 
  elem_type tensor_read_with_offset(volatile addr_type*& mem_phy,  const addr_type address, const dim_t& shape,   size_t offset, dim_t& index) {
    DataUnion data;
    offset = offset + index[W-1]*shape[W]+index[W];
    addr_type addr=(offset*sizeof(data_type)+address);
    MemIntfType::fetchData( mem_phy,addr,data);
    return  get<elem_type>(data);
  }

   template <typename elem_type> 
  elem_type tensor_read_next(volatile addr_type*& mem_phy,  const addr_type address, size_t& offset) {
    DataUnion data;
    addr_type addr=(offset*sizeof(data_type)+address);
    MemIntfType::fetchData( mem_phy,addr,data);
    offset+=1;
    return  get<elem_type>(data);
  }
};

} //namespace tensor_io

#endif