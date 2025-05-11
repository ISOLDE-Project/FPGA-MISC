


source prj_config.tcl
source ../tcl/isolde_common.tcl
source make_sol.tcl

proc config {} {
    global configs config_index __prj_name __files __tb_files __top_function

    listconfigs $configs

    if {$config_index < [llength $configs]} {
        puts "**** INFO: active configuration: [lindex $configs $config_index]"
    } else {
        puts "**** ERROR: config_index $config_index is out of range"
        return
    }

    # Erase previous versions
    file delete -force -- "./${__prj_name}"

    # Create a project
    create_project ${__prj_name} ${__files} ${__tb_files} ${__top_function}
}
