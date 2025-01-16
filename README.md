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
