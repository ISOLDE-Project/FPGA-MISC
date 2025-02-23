#!/usr/bin/env tclsh


# Check if the correct number of arguments is provided
if {$argc != 2} {
    puts "Usage: tclsh export.tcl <input_xdc> <output_csv>"
    exit 1
}
# Get arguments from command line
set xdc_file [lindex $argv 0]
set output_file [lindex $argv 1]

# Open the output file for writing
set f_out [open $output_file w]

# Write the header
puts $f_out "pin_type,pin_number,port_name"

# Mock get_ports function (simulating Vivado behavior)
proc get_ports {port_name} {
    return $port_name
}

# Mock set_property function (stores pin mappings)
proc set_property {args} {
    global f_out
    set param1 [lindex $args 0]  
    set pin_number [lindex $args 1]
    set port_name [lindex $args 2]

    # Store in dictionary
    #dict set pin_mappings $pin_number $port_name
    #if {$param1 == "PACKAGE_PIN" } {
        puts $f_out "$param1,$pin_number,$port_name"
    #}
}

#puts "pin_type,pin_number,port_name"
#source ../master/board/master-zcu102.xdc
source $xdc_file
close  $f_out