# Copyleft 2024 ISOLDE


set __prj_name        sensorSupervisor
set __ip_description  "returns the TUSER side channel"
set __ip_taxonomy     "ISOLDE"

set __top_function execute 

set tcl_dir [file normalize ../tcl]
puts "**** INFO: tcl folder: $tcl_dir"
source [file join $tcl_dir isolde_common.tcl]


proc set_optimizations {} {
    global __top_function

    set_directive_interface -bundle ctrl      -mode s_axilite  ${__top_function} frame_no,
    set_directive_interface                   -mode ap_none    ${__top_function} tuser_in,
    set_directive_interface                   -mode ap_none    ${__top_function} tvalid,
    set_directive_interface                   -mode ap_none    ${__top_function} tready
    set_directive_interface -bundle ctrl      -mode s_axilite  ${__top_function} return
}



# Add design files
set __files {
	src/sensorSupervisor.cpp
}

# Add test bench files
set  __tb_files {
 	src/resizer_tb.cpp
 }