add_executable(conv2d 
               main.cpp 
               scratchpad_memory.cpp
               )

target_include_directories(conv2d PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})             
target_link_libraries(conv2d PRIVATE py_runtime)

# Add a "test-conv2d" target that runs the Python smoke test
add_custom_target(test-conv2d
    COMMAND $<TARGET_FILE:conv2d>
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test/smoke_test_conv2d.py
    DEPENDS conv2d
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python smoke test for conv2d"
)