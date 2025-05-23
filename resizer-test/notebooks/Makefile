ROOT_DIR            :=  $(shell git rev-parse --show-toplevel)
REMOTE_HOST         ?=  192.168.100.111
REMOTE_USER         ?=  xilinx
REMOTE_PATH         ?=  /home/xilinx/jupyter_notebooks/isolde
REMOTE_FILES        := image-output.png isolde.ipynb

%: 
	@echo password:'xilinx'
	scp $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/$@ .

.PHONY: download clean

clean:
	rm -f $(REMOTE_FILES)

download: clean 
	@echo password:'xilinx'
	scp $(addprefix $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/, $(REMOTE_FILES)) .

