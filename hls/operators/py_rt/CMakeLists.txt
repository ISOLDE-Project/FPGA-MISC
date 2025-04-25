

add_library(py_runtime
            numpy_rt.cpp
         )

target_include_directories(py_runtime PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})
target_link_libraries(py_runtime PRIVATE ${Python3_LIBRARIES})     