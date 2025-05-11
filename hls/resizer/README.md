# Linux functional simulator 
This uses CMAKE, and it's just a convenient way to call cmake
```sh
. ./eth.sh
make 
make -C build clean test-clean test-generate  test-resizer
```
# HLS synthesis
## Linux  
```sh
. ./vitis_hls.sh
```
## Windows  
In a Vivado Tcl shell
```
vitis_hls create_proj.tcl -i
```

In the console:
```
% config
% make 4
```
# Windows
