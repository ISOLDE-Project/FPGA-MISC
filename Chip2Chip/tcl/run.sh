. ./env.sh
tclsh xcd_to_csv.tcl ../master/board/master-zcu102.xdc master-zcu102.csv
python mirror_master.py master-zcu102.csv slave-zcu102.csv
python csv_to_xdc.py slave-zcu102.csv ../slave/board/slave-zcu102.xdc
###
tclsh xcd_to_csv.tcl ../master/board/master-zcu104.xdc master-zcu104.csv
python mirror_master.py master-zcu104.csv slave-zcu104.csv
python csv_to_xdc.py slave-zcu104.csv ../slave/board/slave-zcu104.xdc
