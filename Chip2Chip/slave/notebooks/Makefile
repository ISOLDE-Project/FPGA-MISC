ROOT_DIR            :=  $(shell git rev-parse --show-toplevel)
REMOTE_HOST         ?=  192.168.100.121
REMOTE_USER         ?=  xilinx
REMOTE_PATH         ?=  /home/xilinx/jupyter_notebooks/s_chip2chip
DEV_BOARD           ?= zcu102
PYNQ_FOLDER         := $(ROOT_DIR)/Chip2Chip/slave/vivado/slave-$(DEV_BOARD)/PYNQ
REMOTE_FILES        := slave-mmio.ipynb

%: 
	@echo password:'xilinx'
	scp $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/$@ .

.PHONY: download clean upload

clean:
	rm -f $(REMOTE_FILES)

download: clean 
	@echo password:'xilinx'
	scp $(addprefix $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/, $(REMOTE_FILES)) .

upload: 
	@echo password:'xilinx'
	scp $(PYNQ_FOLDER)/slave-$(DEV_BOARD).bit  $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/
	scp $(PYNQ_FOLDER)/slave-$(DEV_BOARD).hwh  $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/
