ROOT_DIR            :=  $(shell git rev-parse --show-toplevel)

clean:
	rm -fr vivado/

zcu%:
	cd ./board && cp -v xilinx_$@.cfg xilinx.cfg

update-ip:	
	cp -v ${ROOT_DIR}/hls/resizer/isolde_resizer/zcu104/isolde_resizer-zcu104.zip 	${ROOT_DIR}/vivado-ip
	cd ${ROOT_DIR}/vivado-ip && rm -fr isolde_resizer-zcu104
	cd ${ROOT_DIR}/vivado-ip && unzip isolde_resizer-zcu104.zip     -d isolde_resizer-zcu104
