
source prj_config.tcl
source ../tcl/isolde_common.tcl


#possible values for hls_exec
# 1   =>  only checks source code, no synthesis
# 2   =>  csynth_design
# 3   =>  csynth_design + cosimulation
# 4   =>  csynth_design + export_design:  RTL synthesis 
# 5   =>  csynth_design + export_design:  RTL synthesis and implementation, including a detailed place and route of the RTL netlist
# >5  =>  nothing...

proc make {hls_exec} {
    global  configs config_index __prj_name
    #set hls_exec [lindex $args 0]  
    
    puts "**** INFO: active configuration:  [lindex $configs $config_index]"

    build_solution $__prj_name [lindex [lindex $configs $config_index] 0 ] $hls_exec
}
