set __prj_name        aiml_stub
set __ip_description  "Stubbing the AI/ML harDware Accelerator"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 
set __m_axi_depth [expr 4*1024]

proc set_optimizations {} {
    global __top_function
    global __m_axi_depth
    set_directive_interface -mode ap_ctrl_none ${__top_function}
    set_directive_interface -bundle data_mem  -mode m_axi      ${__top_function} data_port  -depth ${::__m_axi_depth}

    set_directive_interface -bundle cfg_port1 -mode s_axilite  ${__top_function} cfg_port1  
    set_directive_interface -bundle cfg_port2 -mode s_axilite  ${__top_function} cfg_port2  
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