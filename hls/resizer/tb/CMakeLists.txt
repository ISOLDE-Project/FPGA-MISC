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
               ../../operators/conv2d/scratchpad_memory.cpp
               )

target_compile_definitions(resizer PRIVATE LINUX_APP DTYPE_I32 SCALE=256 GRAYING NO_BIAS)
add_include_directories (resizer )
target_link_libraries(resizer PRIVATE py_runtime)

# Add a "test-conv2d" target that runs the Python smoke test
add_custom_target(test-resizer
    COMMAND $<TARGET_FILE:resizer>
    COMMAND ${Python3_EXECUTABLE} conv2d/test/smoke_test_xsim.py
    DEPENDS resizer
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python smoke test for resizer"
)

add_custom_target(test-generate
    COMMAND ${Python3_EXECUTABLE} conv2d/test/generate.py
    COMMAND cp conv2d/shapes.inc ../resizer/src/
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python to generate test data"
)

add_custom_target(test-clean
    COMMAND rm -f conv2d/test/*.npy
    COMMAND rm -f conv2d/test/*.bin
    COMMAND rm -f conv2d/shapes.inc
    COMMAND rm -f ../resizer/src/shapes.inc
    COMMAND rm -f conv2d/test/output*.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python to generate test data"
)