


source prj_config.tcl
source ../tcl/isolde_common.tcl


#erase previous versions
file delete -force -- ./${__prj_name}
# Create a project
create_project ${__prj_name} ${__files} ${__tb_files} ${__top_function} 

listconfigs $configs
puts "**** INFO: active configuration:  [lindex $configs $config_index]"

# build_solution $__prj_name [lindex [lindex $configs $config_index] 1 ] 2



#exit