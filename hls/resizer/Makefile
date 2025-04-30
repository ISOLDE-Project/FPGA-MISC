all:
	vitis_hls -f run_cosim.tcl
	cd ../operators && python conv2d/test/smoke_test_xsim.py

check:
	cd ../operators && python conv2d/test/smoke_test_xsim.py

clean:		
	rm -fr isolde_resizer/
	cd ../operators && rm -f conv2d/test/output_xsim.png