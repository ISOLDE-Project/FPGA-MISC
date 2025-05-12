all: download

download:
	wget  https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.2/aiml_stub-vcu118.zip
	wget  https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.2/isolde_resizer-vcu118.zip

unzip:
	 unzip aiml_stub-vcu118.zip           -d aiml_stub-vcu118
	 unzip isolde_resizer-vcu118.zip	  -d isolde_resizer-vcu118	

clean:
	rm -fr isolde_resizer-*
	rm -fr aiml_stub-*