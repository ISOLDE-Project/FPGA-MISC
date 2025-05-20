set __prj_name        aiml_stub
set __ip_description  "Stubbing the AI/ML harDware Accelerator"
set __ip_taxonomy     "ISOLDE"



set __top_function execute 
set __m_axi_depth [expr 4*1024]

set tcl_dir [file normalize ../tcl]
puts "**** INFO: tcl folder: $tcl_dir"
source [file join $tcl_dir isolde_common.tcl]

proc set_optimizations {} {
    global __top_function
    global __m_axi_depthc
    # Force 32-bit address width for AXI interfaces
    config_interface -m_axi_addr64=0
    # m_AXI
    set_directive_interface -bundle data_mem  -mode m_axi      ${__top_function} data_port  -depth ${::__m_axi_depth}
    # s_AXI
    set_directive_interface -bundle cfg_port1 -mode s_axilite  ${__top_function} cfg_port1  
    set_directive_interface -bundle cfg_port1 -mode s_axilite  ${__top_function} cfg_port1_echo
    set_directive_interface -bundle cfg_port1 -mode s_axilite  ${__top_function} return
}



# Add design files
## core files list
set __files {
	src/aiml.cpp
}

# Add test bench files
set  __tb_files {
 	src/aiml_tb.cpp
 }