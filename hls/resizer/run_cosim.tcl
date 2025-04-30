
source prj_config.tcl
source ../tcl/isolde_common.tcl

puts "**** INFO: active configuration:  [lindex $configs $config_index]"

open_project ${__prj_name}
    
open_solution   [lindex [lindex $configs $config_index] 0 ]

csynth_design
cosim_design 

close_project

exit