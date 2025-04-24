#ifndef TRACE_UTILITIES
#define TRACE_UTILITIES


#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>



#ifndef __MEMORY_INTERFACE_H__

union DataUnion{
  float f32;
  uint32_t ui32;
  int32_t i32;
  uint16_t ui16[2];
  uint8_t ui8[4];
};
#endif

inline void dump( FILE* trace,  const int32_t* ptr,  uint32_t size=4){
    fprintf(trace,"[ %d ",ptr[0]);     
    for(int i=1;i<size;++i){
         fprintf(trace,", %d",ptr[i]);     
    }
    fprintf(trace," ]\n ");     
}


inline void dump( FILE* trace,  const uint32_t* ptr,  uint32_t size=4){
    fprintf(trace,"[ %u ",ptr[0]);     
    for(int i=1;i<size;++i){
         fprintf(trace,", %u",ptr[i]);     
    }
    fprintf(trace," ]\n ");     
}


inline void dump( FILE* trace,  float* ptr,  uint32_t size=4){ 
    fprintf(trace,"[ %f ",ptr[0]);     
    for(int i=1;i<size;++i){
         fprintf(trace,", %f",ptr[i]);     
    }
    fprintf(trace," ]\n ");     

}

namespace{


  template <typename elem_type>
  const char* pretty_print_format();

  template<>
  inline const char* pretty_print_format<float>() {return "\t\t\t\t%f\n";}

  template<>
  inline const char* pretty_print_format<int32_t>() {return "\t\t\t\t%d\n";}

  template<>
  inline const char* pretty_print_format<uint32_t>() {return "\t\t\t\t%u\n";}

  template <typename elem_type> 
  inline const char*get_npType();

  template<>
  inline const char* get_npType<float>() {return " np.float32" ;}

  template<>
  inline const char* get_npType<int32_t>() {return " np.int32 ";}

  template<>
  inline const char* get_npType<uint32_t>() {return " np.uint32 ";}

  template <typename elem_type>
  const char* py_print_format(uint32_t i, uint32_t max);

  template <>
  inline const char* py_print_format<float>(uint32_t i, uint32_t max){
    bool last =(i==max-1);
    if(last)
        return "%f";
    return "%f, ";
  }

  template <>
  inline const char* py_print_format<int32_t>(uint32_t i, uint32_t max){
    bool last =(i==max-1);
    if(last)
        return "%d";
    return "%d, ";
  }
  template <>
  inline const char* py_print_format<uint32_t>(uint32_t i, uint32_t max){
    bool last =(i==max-1);
    if(last)
        return "%u";
    return "%u, ";
  }

//
  template <typename elem_type>
  const char* c_print_format(uint32_t i, uint32_t max);

  template <>
  inline const char* c_print_format<uint32_t>(uint32_t i, uint32_t max){
    bool last =(i==max-1);
    if(last)
        return "0x%X";
    return "0x%X, ";
  }

}



template<typename elem_type, typename shape_type, typename io_type>
void py_pretty_print(FILE* trace ,std::string name, const typename io_type::addr_type ptr_w,const shape_type& shape_w, io_type& io,volatile typename io_type::addr_type* mem){
  using index_t = int32_t;
    fprintf(trace,"%s = np.array([\n", name.c_str());
    for (index_t m=0;m<shape_w[0];++m){
        fprintf(trace,"\t[\n");
        for (index_t c=0;c<shape_w[1];++c){         
                fprintf(trace,"\t\t[\n");
                for (index_t h=0;h<shape_w[2];++h){
                    fprintf(trace,"\t\t\t[  ");
                    for (index_t w=0;w<shape_w[3];++w){
                        shape_type index;
                        index.set(m,c,h,w);
                        //addr = ptr_w+offset;
                        //core.im->fetchData(addr,value);
                        elem_type elem;
                        elem = io.template tensor_read<elem_type>(mem,ptr_w, shape_w, index);
                        fprintf(trace,py_print_format<elem_type>(w,shape_w[3]),elem);
                        //offset+=sizeof(pType);
                    }
                    bool last = (h == shape_w[2]-1);
                    if(last)
                        fprintf(trace,"  ]\n");
                    else
                        fprintf(trace,"  ],\n");
                }
                //fprintf(trace,"\t\t]\n");
                bool last = (c == shape_w[1]-1);
                if(last)
                    fprintf(trace,"\t\t]\n");
                else
                    fprintf(trace,"\t\t],\n");
        }
        //fprintf(trace,"\t]\n");
        bool last = (m == shape_w[0]-1);
        if(last)
            fprintf(trace,"\t]\n");
        else
            fprintf(trace,"\t],\n");

    }
    fprintf(trace,"],dtype=%s)\n",get_npType<elem_type>());
}

#endif