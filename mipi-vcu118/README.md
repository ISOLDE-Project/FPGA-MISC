After project is created using `create_project.tcl` script, the width from tdata (vdma_0) will be 32 bits not 24. Delete vdma_0 and add new vdma, after that 
reconnect to demosaic and validate. Check if the width from vdma is the same with tdata from demosaic.
