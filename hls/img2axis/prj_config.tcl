set __prj_name        img2axis
set __ip_description  "streaming a FullHD picture from memory"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 
set __m_axi_depth [expr 4*1024]

set tcl_dir [file normalize ../tcl]
puts "**** INFO: tcl folder: $tcl_dir"
source [file join $tcl_dir isolde_common.tcl]

proc set_optimizations {} {
    global __top_function
    # Force 32-bit address width for AXI interfaces
    config_interface -m_axi_addr64=0
    # AXIS
    set_directive_interface                   -mode axis      ${__top_function} stream_o
    # m_AXI
    set_directive_interface -bundle data_mem  -mode m_axi     ${__top_function} data_port  -depth ${::__m_axi_depth}
    # s_AXI
    set_directive_interface -bundle cfg_port -mode s_axilite  ${__top_function} frame_no  
    set_directive_interface -bundle cfg_port -mode s_axilite  ${__top_function} end_of_stream
    set_directive_interface -bundle cfg_port -mode s_axilite  ${__top_function} return

}



# Add design files
set __files {
	src/img2axis.cpp
}

# Add test bench files
set  __tb_files {
 	src/img2axis_tb.cpp
 }