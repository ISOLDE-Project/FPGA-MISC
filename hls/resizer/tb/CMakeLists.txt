#
add_library(py_runtime
            ../../operators/py_rt/numpy_rt.cpp
         )

target_include_directories(py_runtime PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})
target_link_libraries(py_runtime PRIVATE ${Python3_LIBRARIES})   
#

add_executable(resizer 
               ../src/resizer.cpp
               resizer_tb.cpp
               utils.cpp
               ../../operators/conv2d/scratchpad_memory.cpp
               )


target_compile_definitions(resizer PRIVATE LINUX_APP DTYPE_I32 SCALE=256 GRAYING NO_BIAS)
add_include_directories (resizer )
target_link_libraries(resizer PRIVATE py_runtime)

add_executable(utest
               ../src/resizer.cpp
               unit_test.cpp
               utils.cpp
               ../../operators/conv2d/scratchpad_memory.cpp
               )
target_compile_definitions(utest PRIVATE LINUX_APP DTYPE_I32 SCALE=256 GRAYING NO_BIAS)
add_include_directories (utest )
target_link_libraries(utest PRIVATE py_runtime)

# Add a "test-conv2d" target that runs the Python smoke test
add_custom_target(test-resizer
    COMMAND $<TARGET_FILE:resizer>
    #COMMAND ${Python3_EXECUTABLE} conv2d/test/smoke_test_conv2d_i32.py
    DEPENDS resizer
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python smoke test for resizer"
)

add_custom_target(test-unit
    COMMAND $<TARGET_FILE:utest>
    #COMMAND ${Python3_EXECUTABLE} conv2d/test/smoke_test_conv2d_i32.py
    DEPENDS utest
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running unit test"
)

add_custom_target(test-generate
    COMMAND ${Python3_EXECUTABLE} conv2d/test/generate_v2.py
    COMMAND cp conv2d/shapes.inc ../resizer/src/
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python to generate test data"
)

add_custom_target(test-clean
    COMMAND rm -f conv2d/test/*.npy
    COMMAND rm -f conv2d/test/*.bin
    COMMAND rm -f conv2d/shapes.inc
    COMMAND rm -f conv2d/test/output_downsampled.jpg
    COMMAND rm -f conv2d/test/output_downsampled_q.jpg
    COMMAND rm -f conv2d/test/output_q_.jpg
    COMMAND rm -f conv2d/test/output_q__01.jpg
    COMMAND rm -f ../resizer/src/shapes.inc
    COMMAND rm -f conv2d/test/output*.png
    COMMAND rm -f conv2d/test/conv_o_*.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Deletes the generated files"
)

add_custom_target(dumps-clean
    COMMAND rm -f conv2d/test/output*.png
    COMMAND rm -f conv2d/test/conv_o_*.png
    COMMAND rm -f conv2d/test/resizer_o_*.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Deletes the generated files"
)

add_custom_target(test-compare
    COMMAND ${Python3_EXECUTABLE} conv2d/test/compare_png_grey.py conv_o_0.png conv_o_6.png
    COMMAND ${Python3_EXECUTABLE} conv2d/test/compare_png_grey.py resizer_o_0.png resizer_o_6.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "compare two images"
)