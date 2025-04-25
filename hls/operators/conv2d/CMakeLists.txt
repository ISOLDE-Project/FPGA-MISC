add_executable(conv2d 
               main.cpp 
               scratchpad_memory.cpp
               )

target_include_directories(conv2d PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})             
target_link_libraries(conv2d PRIVATE py_runtime)
