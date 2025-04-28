
BUILD_DIR   := build

all: build/Makefile

$(BUILD_DIR):
	mkdir -p $@

build/Makefile:$(BUILD_DIR)
	cd $(BUILD_DIR) && \
	cmake -DCMAKE_BUILD_TYPE="Debug" ..

conv2d: $(BUILD_DIR)
	cd $(BUILD_DIR) && \
	cmake -DCMAKE_BUILD_TYPE="Debug" .. && \
	make $@

.PHONY: clean	

clean:
	rm -fr ./$(BUILD_DIR)

