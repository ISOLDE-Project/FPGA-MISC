set __prj_name        isolde_resizer
set __ip_description  "downsampling the input stream"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 


proc set_optimizations {} {
    global __top_function
#pragma HLS INTERFACE bram port=w_bram
 set_directive_interface  -mode ap_memory   ${__top_function} y_bram
 set_directive_interface  -mode ap_memory   ${__top_function} x_bram
 set_directive_interface  -mode ap_memory   ${__top_function} w_bram
}



# Add design files
set __files {
	src/resizer.cpp
    src/scratchpad_memory.cpp
}

# Add test bench files
set  __tb_files {
 	src/resizer_tb.cpp
 }