# Copyleft 2024 ISOLDE

#possible values for hls_exec
# 1   =>  only checks source code, no synthesis
# 2   =>  csynth_design
# 3   =>  csynth_design + cosimulation
# 4   =>  csynth_design + export_design:  RTL synthesis 
# 5   =>  csynth_design + export_design:  RTL synthesis and implementation, including a detailed place and route of the RTL netlist
# >5  =>  nothing...

proc make {hls_exec} {
    global  configs config_index __prj_name
    if {$hls_exec eq "help"} {
        puts "Usage: make <hls_exec>"
        puts "Possible values for hls_exec:"
        puts "  1   =>  only checks source code, no synthesis"
        puts "  2   =>  csynth_design"
        puts "  3   =>  csynth_design + cosimulation"
        puts "  4   =>  csynth_design + export_design: RTL synthesis"
        puts "  5   =>  csynth_design + export_design: RTL synthesis and implementation, including a detailed place and route of the RTL netlist"
        puts " >5   =>  nothing..."
        return
    }
    
    puts "**** INFO: active configuration:  [lindex $configs $config_index]"

    build_solution $__prj_name [lindex [lindex $configs $config_index] 0 ] $hls_exec
}
