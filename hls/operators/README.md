# Build using make
This uses CMAKE, and it's just a convenient way to call cmake
```sh
. ./eth.sh
make 
make -C build test-conv2d
```
The output should look like:
```
[100%] Running Python smoke test for conv2d
Output shape: (1, 1, 540, 960)

****************
* Test passed! *
****************

output image: /home/uic52463/hdd1/FPGA-MISC/hls/operators/output.png

make[3]: Leaving directory '/home/uic52463/hdd1/FPGA-MISC/hls/operators/build'
[100%] Built target test-conv2d
```

# Build using CMake
```sh
. ./eth.sh
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE="Debug" ..
make conv2d
 ./bin/conv2d 
```

see also [hls/operators/conv2d/models/conv2d.ipynb](hls/operators/conv2d/models/conv2d.ipynb)