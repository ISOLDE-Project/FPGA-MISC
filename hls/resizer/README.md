# Linux functional simulator 
This uses CMAKE, and it's just a convenient way to call cmake
```sh
. ./eth.sh
make 
make -C build clean test-clean test-generate  test-resizer
```
# HLS synthesis

```sh
. ./vitis_hls.sh
```
In the console:
```
% config
% make 4
```