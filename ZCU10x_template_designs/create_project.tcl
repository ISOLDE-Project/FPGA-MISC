################################################################
# configure board
source ./board/xilinx_zcu104.cfg
################################################################


################################################################
# load block design
source  $project-bd.tcl
################################################################

if { ![info exists ::project] } {
  puts "project name is not defined"
  exit(0)
}



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

# Set project properties
set obj [current_project]
set_property -name "board_part"         -value ${_board_part_}        -objects $obj
set_property -name "platform.board_id"  -value ${_platform_board_id_} -objects $obj

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
# Create block design
cr_bd_$::_xil_proj_name_ ""
################################################################


################################################################
# make (top-module)wrapper

# Step 1: Retrieve all block design files in the project
set bd_files [get_files -filter {FILE_TYPE == "Block Designs"}]

# Check if any block designs are available
if {[llength $bd_files] == 0} {
    puts "ERROR: No block designs found in the project."
    exit 1
}
# Step 2: Open the first block design found
set bd_file [lindex $bd_files 0]
puts "INFO: Opening block design: $bd_file"
catch {open_bd_design $bd_file} result
if {[string match "*ERROR*" $result]} {
    puts "ERROR: Unable to open block design: $bd_file"
    puts $result
    exit 1
}
# Step 3: Generate the HDL wrapper for the block design
puts "INFO: Generating HDL wrapper for the block design."
catch {make_wrapper -files $bd_file -top} result
if {[string match "*ERROR*" $result]} {
    puts "ERROR: Failed to generate HDL wrapper."
    puts $result
    exit 1
} else {
    puts "INFO: $result"
    set wrapper_file_path $result
}
# Step 4: Add the wrapper file to the project
puts "INFO: Adding HDL wrapper to the project."
add_files -norecurse ${wrapper_file_path}

################################################################