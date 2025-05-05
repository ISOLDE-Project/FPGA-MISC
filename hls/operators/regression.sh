. ./eth.sh
make 
make -C build clean test-clean test-generate test-conv2d test-conv2d_i32 test-resizer
