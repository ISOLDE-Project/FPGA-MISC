set __prj_name        sensorSupervisor
set __ip_description  "IR sensor supervisor"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 
set __m_axi_depth [expr 4*1024]

proc set_optimizations {} {
    global __top_function
    global __m_axi_depth
    set_directive_interface -mode ap_ctrl_none ${__top_function}
    set_directive_interface -bundle status  -mode m_axi      ${__top_function} status  -depth ${::__m_axi_depth}
    set_directive_interface -bundle cfg     -mode s_axilite  ${__top_function} cfg_port  

}



# Add design files
## core files list
set __files {
	src/sensorSupervisor.cpp
}

# Add test bench files
set  __tb_files {
 	src/sensorSupervisor_tb.cpp
 }