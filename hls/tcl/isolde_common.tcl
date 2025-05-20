# Copyleft 2024 ISOLDE
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

#https://github.com/Xilinx/Embedded-Design-Tutorials/blob/2023.1/docs/Introduction/Versal-EDT/ref_files/EDT_2023.1_PACKAGE/ug1305-embedded-design-tutorial/vmk180/pl/pl_helloworld/scripts/create_project.tcl





source [file join $tcl_dir create_proj.tcl]
source [file join $tcl_dir make_sol.tcl]


#tuple's layout:
#{solution part_name clock}
set configs { \
{"zcu102" "xczu9eg-ffvb1156-2-e" 50} \
{"zcu104" "xczu7ev-ffvc1156-2-e" 15} \
{"vcu118" "xcvu9p-flga2104-2L-e" 15} \
{"vmk180" "xcvm1802-vsva2197-2MP-e-S" 15} \
}


# ########################################################
#set active solution
set config_index 0

# helpers ########################################################
proc listconfigs {configs} {
    set i 0
    foreach j $configs {
        puts "**** INFO: ([lindex $j 0 ],[lindex $j 1 ]) is configuration number $i "
        incr i
    }
}

proc info { } {
    global configs config_index
    
    listconfigs $configs

    if {$config_index < [llength $configs]} {
        puts "**** INFO: active configuration: [lindex $configs $config_index]"
    } else {
        puts "**** ERROR: config_index $config_index is out of range"
        return
    }
}

proc mkdir { base_dir suffix_dir} {
    set target_dir [file normalize [file join $base_dir $suffix_dir]]

    # Create the directory if it doesn't exist
    if {![file exists $target_dir]} {
        file mkdir $target_dir
        puts "**** INFO: Created directory: $target_dir"
    } else {
        puts "**** INFO: Directory already exists: $target_dir"
    }
}


#possible values for hls_exec
# 1   =>  only checks source code, no synthesis
# 2   =>  csynth_design
# 3   =>  csynth_design + cosimulation
# 4   =>  csynth_design + export_design:  RTL synthesis 
# 5   =>  csynth_design + export_design:  RTL synthesis and implementation, including a detailed place and route of the RTL netlist
# >5  =>  nothing...

proc build_solution {__prj_name __sol_name hls_exec } {
    open_project ${__prj_name}
    #set __proj_dir  [get_project -directory]
    open_solution   ${__sol_name}
    puts "step $hls_exec for  ${__prj_name}, active solution: [get_solution -name]"
    set_optimizations 
    if {$hls_exec == 1} {
        # Run Synthesis check only
        csynth_design    -synthesis_check 
        
    } elseif {$hls_exec == 2} {
        # Run Synthesis
        csynth_design

    } elseif {$hls_exec == 3} { 
        # Run Synthesis, RTL Simulation
        csynth_design
        cosim_design 
        
    } elseif {$hls_exec == 4} { 

        set __out_file  [get_solution -directory]/[get_project  -name]-[get_solution -name].zip
        set __ip_name  [get_project  -name] 
        mkdir [get_solution -directory] ../../../../vivado-ip
        csynth_design 
        export_design  -description \"${::__ip_description}\" -display_name ${__ip_name} -flow syn -format ip_catalog -ipname ${__ip_name} -output ${__out_file}  -taxonomy \"${::__ip_taxonomy}\"
        file copy -force ${__out_file} [get_solution -directory]/../../../../vivado-ip	
    } elseif {$hls_exec == 5} { 
                
        set __out_file  [get_solution -directory]/[get_project  -name]-[get_solution -name].zip
        set __ip_name  [get_project  -name] 
        mkdir [get_solution -directory] ../../../../vivado-ip
        csynth_design 
        export_design  -description \"${::__ip_description}\" -display_name ${__ip_name} -flow impl -format ip_catalog -ipname ${__ip_name} -output ${__out_file}  -taxonomy \"${::__ip_taxonomy}\"
        file copy -force ${__out_file} [get_solution -directory]/../../../../vivado-ip	
    } else {

        #we are done 
        mkdir [get_solution -directory] ../../../../vivado-ip
    }
    close_solution
    close_project
}   

proc create_project { __prj_name __files __tb_files __top_function } {
    # Declare $configs as a global variable
    global configs config_index

    puts "*****************************************"
    puts "create_project prj_name=${__prj_name}, top function=${__top_function}"
    puts "*****************************************"
    # Open the project with the given name
    open_project -reset ${__prj_name}

    # Get the project directory
    set __proj_dir [get_project -directory]


    # Define compiler flags
    set __COMPILE_DEFINITIONS_ "-DDTYPE_I32 -DSCALE=256 -DGRAYING -DNO_BIAS"
    set __INCLUDE_DIRECTORIES_ "-I${__proj_dir}/../include -I${__proj_dir}/../../include  -I${__proj_dir}/../../operators"
    set __C__FLAGS " $__INCLUDE_DIRECTORIES_  $__COMPILE_DEFINITIONS_ -std=c++17"
    set __SIM_C__FLAGS " "

    # Add source files with compiler flags
    add_files ${__files} -cflags $__C__FLAGS -csimflags $__C__FLAGS

    # Add testbench files with compiler flags
    add_files ${__tb_files} -tb -cflags $__C__FLAGS -csimflags $__SIM_C__FLAGS

    # Set the top-level function
    set_top ${__top_function}

    # Iterate over configurations

        set __sol_name  [lindex [lindex $configs $config_index] 0 ]
        set _part_name_ [lindex [lindex $configs $config_index] 1 ]
        set _clock_     [lindex [lindex $configs $config_index] 2 ]

        # Open a solution with the given name and flow target
        open_solution -reset -flow_target vivado ${__sol_name}

        # Set the part name
        set_part ${_part_name_}

        # Create a clock with the specified period
        create_clock -period ${_clock_}

        set_optimizations

        # Close the solution
        close_solution
    
    close_project
}

info