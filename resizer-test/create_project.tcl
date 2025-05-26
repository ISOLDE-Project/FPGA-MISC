################################################################
# configure board
source ./board/xilinx.cfg
################################################################




set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  puts ""
  catch { "CRITICAL WARNING: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado"}
}

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}

# Set the reference directory for source file relative paths (by default the value is script directory path)
variable origin_dir
set origin_dir [_tcl::get_script_folder]




# Set the directory path for the original project from where this script was exported
#set orig_proj_dir "[file normalize "$origin_dir/resizer"]"

# Create project
set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    create_project $project  ./vivado/$project  -part $part  -force
} else {
    puts "Error: ./vivado/$project not an empty folder"
    return 1
}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "board_part"         -value ${_board_part_}        -objects $obj
set_property -name "platform.board_id"  -value ${_platform_board_id_} -objects $obj


# Set IP repository paths
set obj [get_filesets sources_1]
if { $obj != {} } {
   set_property "ip_repo_paths" "[file normalize "$proj_dir/../../../vivado-ip"]" $obj

   # Rebuild user ip_repo's index before adding any source files
   update_ip_catalog -rebuild
}
# Set the directory path for the new project

# source generated/sources.tcl
# set_property top snitch_cluster_wrapper [current_fileset]
# update_compile_order -fileset sources_1
# if {[regexp -nocase {.*board_part.*} [list_property [current_project]]]} {
#   set_property board_part $board [current_project]
# } else {
#   set_property board $board [current_project]
# }

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize ${origin_dir}/board/${project}.xdc]"
add_files -norecurse -fileset constrs_1 [list $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj


################################################################
# load block designs
################################################################

proc load_bd {proj_name tcl_file} {
    set ::_xil_proj_name_ $proj_name
    source $tcl_file
    eval cr_bd_$proj_name {""}
}

################################################################
# load block design
################################################################
load_bd "bd_resizer"  "demo_resizer-$_platform_board_id_-bd.tcl"

################################################################
# load block design
################################################################
load_bd "bd_top"      "top-$_platform_board_id_-bd.tcl"