BUILD_DIR   := build

all: build/Makefile

$(BUILD_DIR):
	mkdir -p $@

build/Makefile:$(BUILD_DIR)
	cd $(BUILD_DIR) && \
	cmake -DCMAKE_BUILD_TYPE="Debug" ..

cosim:
	vitis_hls -f run_cosim.tcl
	cd ../operators && python conv2d/test/smoke_test_xsim.py

check:
	cd ../operators && python conv2d/test/smoke_test_xsim.py

clean:		
	rm -fr $(BUILD_DIR)
	rm -fr isolde_resizer/
	cd ../operators && rm -f conv2d/test/output_xsim.png