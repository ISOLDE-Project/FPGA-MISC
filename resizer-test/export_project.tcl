

################################################################
# configure board
source ./board/xilinx.cfg
################################################################


namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   #return 1
}
cd  $script_folder 

set proj_dir  [ get_property DIRECTORY [current_project] ]
set proj_name [ get_property NAME [current_project] ]
set orig_proj_dir "[file normalize "$proj_dir"]"

# Get the list of block designs in the current project
set bd_files [get_files -filter {FILE_TYPE == "Block Designs"}]

# Open the first block design, if any
if {[llength $bd_files] > 0} {
    open_bd_design [lindex $bd_files 0]
} else {
    puts "No block designs found in the current project."
    return 1
}
puts [ format "%s -- %s" $proj_dir $proj_name ]

write_project_tcl -target_proj_dir "$orig_proj_dir" -force $script_folder/$proj_name-export.tcl
puts [ format "%s -- done" $script_folder/$proj_name-export.tcl ]

#
set filename  $script_folder/$proj_name-properties.txt
set info [report_property -return_string  [current_project] ]
set fp [open $filename "w+"] 
puts $fp $info
close $fp

# List of block design names you explicitly created
set my_bds {"bd_resizer" "bd_top"}

# Loop through each block design
foreach bd_file $bd_files {
    open_bd_design $bd_file
    set bd_name [get_property NAME [current_bd_design]]
    # Check if bd_name is in your list
    if {[lsearch -exact $my_bds $bd_name] >= 0} {
        puts "Processing block design: $bd_name"

        # Write the BD Tcl
        set bd_tcl_file $script_folder/${bd_name}-$_platform_board_id_-bd.tcl
        write_bd_tcl -no_ip_version -force -no_project_wrapper -include_layout -bd_name $bd_name $bd_tcl_file
        puts "[format "%s -- done" $bd_tcl_file]"

        # Export layouts
        set pdf_file $script_folder/${bd_name}-layout.pdf
        write_bd_layout -force -format pdf -orientation portrait $pdf_file

        set svg_file $script_folder/${bd_name}-layout.svg
        write_bd_layout -force -format svg -orientation portrait $svg_file
        } else {
        puts "Skipping $bd_name (not in explicit BD list)"
    }
}



puts "All block designs exported successfully."