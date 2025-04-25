
BUILD_DIR   := build

$(BUILD_DIR):
	mkdir -p $@

conv2d: $(BUILD_DIR)
	cd $(BUILD_DIR) && \
	cmake -DCMAKE_BUILD_TYPE="Debug" .. && \
	make $@

.PHONY: clean	

clean:
	rm -fr ./$(BUILD_DIR)

