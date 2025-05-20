#
add_library(py_runtime
            ../../operators/py_rt/numpy_rt.cpp
         )

target_include_directories(py_runtime PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})
target_link_libraries(py_runtime PRIVATE ${Python3_LIBRARIES})   
#

add_executable(img2axis 
               ../src/img2axis.cpp
               img2axis_tb.cpp
               ../../operators/conv2d/scratchpad_memory.cpp
               )

target_compile_definitions(img2axis PRIVATE LINUX_APP DTYPE_I32 SCALE=256 GRAYING NO_BIAS)
add_include_directories (img2axis )
target_link_libraries(img2axis PRIVATE py_runtime)

# Add a "test-conv2d" target that runs the Python smoke test
add_custom_target(test-img2axis
    COMMAND $<TARGET_FILE:img2axis>
    #COMMAND ${Python3_EXECUTABLE} conv2d/test/smoke_test_conv2d_i32.py
    DEPENDS img2axis
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python smoke test for img2axis"
)

add_custom_target(test-generate
    COMMAND ${Python3_EXECUTABLE} conv2d/test/generate.py
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python to generate test data"
)

add_custom_target(test-clean
    COMMAND rm -f conv2d/test/*.npy
    COMMAND rm -f conv2d/test/*.bin
    COMMAND rm -f conv2d/shapes.inc
    COMMAND rm -f conv2d/test/output*.png
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/../operators
    COMMENT "Running Python to generate test data"
)