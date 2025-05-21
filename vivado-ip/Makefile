all: download

download:
	wget  https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.2/aiml_stub-vcu118.zip
	wget  https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.2/isolde_resizer-vcu118.zip

unzip:
	 unzip aiml_stub-vcu118.zip         
	 unzip isolde_resizer-vcu118.zip	  

clean:
	rm -fr isolde_resizer-*
	rm -fr aiml_stub-*
	rm -fr img2axis-*
	rm -fr sensorSupervisor-*