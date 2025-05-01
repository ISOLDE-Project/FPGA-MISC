add_executable(conv2d 
               main.cpp 
               scratchpad_memory.cpp
               )

target_compile_definitions(conv2d PRIVATE DTYPE_F32)
add_include_directories (conv2d )
target_link_libraries(conv2d PRIVATE py_runtime)

add_executable(conv2d_i32 
               main_i32.cpp 
               scratchpad_memory.cpp
               )

target_compile_definitions(conv2d_i32 PRIVATE DTYPE_I32 SCALE=256)
add_include_directories (conv2d_i32 )
target_link_libraries(conv2d_i32 PRIVATE py_runtime)

#
add_executable(resizer 
               main_i32.cpp 
               scratchpad_memory.cpp
               )

target_compile_definitions(resizer PRIVATE DTYPE_I32 SCALE=256 CONST_WEIGTHS NO_BIAS)
add_include_directories (resizer )
target_link_libraries(resizer PRIVATE py_runtime)

# Add a "test-conv2d" target that runs the Python smoke test
add_custom_target(test-conv2d
    COMMAND $<TARGET_FILE:conv2d>
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test/smoke_test_conv2d.py
    DEPENDS conv2d
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python smoke test for conv2d"
)



add_custom_target(test-conv2d_i32
    COMMAND $<TARGET_FILE:conv2d_i32>
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test/smoke_test_conv2d_i32.py
    DEPENDS conv2d_i32
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python smoke test for conv2d_i32"
)

add_custom_target(test-resizer
    COMMAND $<TARGET_FILE:resizer>
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test/smoke_test_conv2d_i32.py
    DEPENDS resizer
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python smoke test for resizer"
)

add_custom_target(test-generate
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test/generate.py
    COMMAND cp conv2d/*.inc ../resizer/src/
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python to generate test data"
)

add_custom_target(test-clean
    COMMAND rm -f conv2d/test/*.npy
    COMMAND rm -f conv2d/test/*.bin
    COMMAND rm -f conv2d/test/../*.inc
    COMMAND rm -f conv2d/test/output*.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running Python to generate test data"
)