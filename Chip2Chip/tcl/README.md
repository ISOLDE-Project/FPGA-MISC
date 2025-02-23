# ISOLDE

```sh
. ./env.sh
```
it will activate the environment for using the scripts
## Generate chip-2-chip slave constrains file
```sh
tclsh xcd_to_csv.tcl ../master/board/master-zcu102.xdc master-zcu102.csv
python mirror_master.py master-zcu102.csv slave-zcu102.csv
python csv_to_xdc.py slave-zcu102.csv ../slave/board/slave-zcu102.xdc
```

## Export current environment
```sh
pip3 list --format=freeze | grep -v "@" > python-requirements.txt
```
## Update the current environment
```sh
pip3 install -U -r python-requirements.txt
```