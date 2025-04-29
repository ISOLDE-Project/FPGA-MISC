
#ifndef INCLUDE_AXIS_HELPER_HPP
#define INCLUDE_AXIS_HELPER_HPP


#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"






#define DWIDTH 8
typedef ap_axiu<DWIDTH, 0, 0, 0> trans_pkt;
typedef ap_uint<DWIDTH>  axi_udata_type;
typedef ap_int<DWIDTH>  axi_data_type;


typedef hls::stream<trans_pkt> axis_type;



template<int  N, typename table_type >
bool readAXIS(axis_type& stream, table_type dst){
#pragma HLS inline
	trans_pkt in;
	int i=0;

	in.last=false;

	READ_AXIS_F:for(i=0; i<N; ++i){
		if(!in.last){
			stream>>in;
			dst[i]=in.data;
		}else
			dst[i]=0xcf; //padding up to N data
	}
	return in.last;
}


template<int  N,typename table_type>
bool readAXIS(axis_type& stream, table_type dst1,table_type dst2){
#pragma HLS inline
	trans_pkt in;
	int i=0;
	//if(stream.empty()){
		in.last=false;
	//}
	READ_AXIS_L:for(i=0; i<N; ++i){
		if(!in.last){
			stream>>in;
			dst1[i]=in.data;
			dst2[i]=in.data;
		}else{
			 //padding up to N data
			dst1[i]=0xcf;
			dst2[i]=0xcf;
		}
	}
	return in.last;
}

template<int N ,typename table_type>
void writeAXIS(table_type msg,  axis_type& stream, bool last=true){
#pragma HLS inline
  int i=0;
	WRITE_AXIS:for (i = 0; i < N-1; i++){
	  trans_pkt out;
	  out.last = false;
	  out.keep = -1;
      out.data=msg[i];
      stream<<out;
  }
//last element
  trans_pkt out;
  out.last = last;
  out.keep = -1;
  out.data=msg[i];
  stream<<out;
}


#endif

