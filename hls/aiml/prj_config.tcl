set __prj_name        aiml_stub
set __ip_description  "Stubbing the AI/ML harDware Accelerator"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 
set __m_axi_depth [expr 4*1024]

proc set_optimizations {} {
    global __top_function
	# Set any optimization directives

	set_directive_interface -mode m_axi     ${__top_function}  data_port  -depth ${::__m_axi_depth}
	set_directive_interface -mode s_axilite ${__top_function}  cfg_port1       
	set_directive_interface -mode s_axilite ${__top_function}  cfg_port2
	set_directive_interface -mode s_axilite ${__top_function}  return       -bundle control
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