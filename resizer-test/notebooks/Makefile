ROOT_DIR            :=  $(shell git rev-parse --show-toplevel)
REMOTE_HOST         ?=  192.168.100.111
REMOTE_USER         ?=  xilinx
REMOTE_PATH         ?=  /home/xilinx/jupyter_notebooks/isolde
REMOTE_FILES        := output_image-2025-05-23_09-38-32.png isolde.ipynb

%: 
	@echo password:'xilinx'
	scp $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/$@ .

.PHONY: download clean

clean:
	rm -f $(REMOTE_FILES)

download: clean $(REMOTE_FILES)

