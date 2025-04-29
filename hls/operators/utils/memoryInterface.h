#ifndef __MEMORY_INTERFACE_H__
#define __MEMORY_INTERFACE_H__

#include <cassert>
#include <cstdint>

namespace arch {
typedef int32_t regfile_type;
typedef uint32_t pc_type;
typedef uint32_t uint32_type;
#ifndef __SYNTHESIS__
typedef uint64_t addr_type;
#else
typedef uint32_t addr_type;
#endif
typedef int32_t int32_type;
typedef uint32_t uint7_type;
typedef uint32_t uint3_type;
typedef uint32_t uint5_type;
typedef uint32_t uint4_type;
typedef uint32_t uint1_type;
typedef uint32_t uint8_type;
typedef uint32_t uint12_type;
typedef int32_t int12_type;
typedef uint32_t uint13_type;
typedef int32_t int13_type;
} // namespace arch

union DataUnion {
  float f32;
  uint32_t ui32;
  int32_t i32;
  uint16_t ui16[2];
  uint8_t ui8[4];
};

#ifndef __SYNTHESIS__
struct ArrayMemory {
  typedef uint32_t index_type;
  typedef arch::addr_type addr_type;
  typedef arch::int32_type data_type;

  static inline data_type *addr_to_pointer(const addr_type addr_) {
    return reinterpret_cast<int32_t *>(addr_);
  }

  static void fetchData(volatile addr_type *data, const addr_type addr_,
                        DataUnion &dst) {
    assert(data == nullptr);
    data_type *pData = addr_to_pointer(addr_);
    dst.i32 = *pData;
  }

  static void pushData(volatile addr_type *data, const addr_type addr_,
                       DataUnion &src) {
    assert(data == nullptr);
    data_type *pData = addr_to_pointer(addr_);
    *pData = src.i32;
  }
};
#else
struct BoardMemory {
  typedef uint32_t index_type;
  typedef arch::addr_type addr_type;
  typedef arch::int32_type data_type;

  static inline data_type *addr_to_pointer(const addr_type addr_) {
    return reinterpret_cast<int32_t *>(addr_);
  }

  static void fetchData(volatile addr_type *data, const addr_type addr_,
                        DataUnion &dst) {
    data_type *pData = addr_to_pointer(addr_);
    dst.i32 = *pData;
  }

  static void pushData(volatile addr_type *data, const addr_type addr_,
                       DataUnion &src) {
    data_type *pData = addr_to_pointer(addr_);
    *pData = src.i32;
  }
};
#endif
#endif //__MEMORY_INTERFACE_H__