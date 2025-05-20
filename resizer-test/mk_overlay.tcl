
proc mk_overlay {} {
    # Get project info
    set proj_dir  [ get_property DIRECTORY [current_project] ]
    set proj_name [ get_property NAME [current_project] ]
    set top_module [ get_property top [current_fileset] ]

    # Get the first block design name
    set bds [get_bd_designs]
    if {[llength $bds] == 0} {
        puts "ERROR: No block design found!"
        return
    }
    set bd_name [lindex $bds 0]

    # Create the PYNQ output folder
    set pynq_dir "${proj_dir}/PYNQ"
    file mkdir $pynq_dir

    # Copy and rename bitstream
    set bitstream_path "${proj_dir}/${proj_name}.runs/impl_1/${top_module}.bit"
    if {![file exists $bitstream_path]} {
        puts "ERROR: Bitstream file not found: $bitstream_path"
        return
    }
    file copy -force $bitstream_path "${pynq_dir}/${proj_name}.bit"

    # Copy HWH file (from block design handoff)
    set hwh_path "${proj_dir}/${proj_name}.gen/sources_1/bd/${bd_name}/hw_handoff/${bd_name}.hwh"
    if {![file exists $hwh_path]} {
        puts "ERROR: HWH file not found: $hwh_path"
        return
    }
    file copy -force $hwh_path "${pynq_dir}/${proj_name}.hwh"

    puts "Overlay files copied to: $pynq_dir"
}

mk_overlay

