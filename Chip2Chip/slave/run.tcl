
set num_cores [exec nproc]
set num_cores_half [expr {$num_cores / 2}]

launch_runs impl_1 -to_step write_bitstream -jobs $num_cores_half
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
   error "ERROR: impl_1 failed"
}