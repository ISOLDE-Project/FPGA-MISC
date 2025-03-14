# FMC connector
[Chip2Chip/doc/README.md](./Chip2Chip/doc/README.md)
# Linux Vivado/Vitis settings
## Cable drivers
```sh
cd /tools/Xilinx/Vivado/2022.1/data/xicom/cable_drivers/lin64/install_script/install_drivers
sudo ./install_drivers
```
Expected result:
```
INFO: Installing cable drivers.
INFO: Script name = ./install_drivers
INFO: HostName = asus-b650-plus
INFO: Current working dir = /tools/Xilinx/Vivado/2022.1/data/xicom/cable_drivers/lin64/install_script/install_drivers
INFO: Kernel version = 6.8.0-52-generic.
INFO: Arch = x86_64.
Successfully installed Digilent Cable Drivers
--File /etc/udev/rules.d/52-xilinx-ftdi-usb.rules does not exist.
--File version of /etc/udev/rules.d/52-xilinx-ftdi-usb.rules = 0000.
--Updating rules file.
--File /etc/udev/rules.d/52-xilinx-pcusb.rules does not exist.
--File version of /etc/udev/rules.d/52-xilinx-pcusb.rules = 0000.
--Updating rules file.

INFO: Digilent Return code = 0
INFO: Xilinx Return code = 0
INFO: Xilinx FTDI Return code = 0
INFO: Return code = 0
INFO: Driver installation successful.

```
## COM ports
```sh
ls -l /dev/ttyUSB*
```
Expected results:
```
crw-rw---- 1 root dialout 188, 1 mar  7 10:03 /dev/ttyUSB1
crw-rw---- 1 root dialout 188, 2 mar  7 10:03 /dev/ttyUSB2
crw-rw---- 1 root dialout 188, 3 mar  7 10:03 /dev/ttyUSB3
```
Make one port accesabble as non-root user:
```sh
sudo chmod 666 /dev/ttyUSB1
```

# How to use tcl scripts 
1. open Vivado
the followings commands, shall be typed in the Vivado Tcl console 
2. Set Tcl working directory
```
cd <local_repo>/<project_name>
```  

3. create Vivado project
```
source ./create_project.tcl
```

*__Note__:* if the Vivado project already exists, the *create_project.tcl* script fails,you have to rename/delete it.    

4. In Vivado,modify the project, generate bitstream, etc.

5. Export the updated project, using the following script in Tcl console:
```  
source ./exportProject.tcl
```   
6. git commit **__only__** the *.tcl scripts and constrains files
## Note   
Project name can be configurated in board/xilinix_<board_name>.cfg
