@echo off
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.3/img2axis-vcu118.zip' -OutFile 'img2axis-vcu118.zip'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.3/isolde_resizer-vcu118.zip' -OutFile 'isolde_resizer-vcu118.zip'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ISOLDE-Project/FPGA-MISC/releases/download/rc0.3/sensorSupervisor-vcu118.zip' -OutFile 'sensorSupervisor-vcu118.zip'"
echo Download complete.
pause
