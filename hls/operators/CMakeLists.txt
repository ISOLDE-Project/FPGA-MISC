cmake_minimum_required(VERSION 3.16.3)

project(functional-simulator VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if (CMAKE_BUILD_TYPE STREQUAL "Debug" )
	message("debug version")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -std=c++17 -O0  -D_NO_SYNTH_ -D_NO_CSIM_ -D_NO_COSIM_")
else()
	message("optimised version")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -std=c++17 -O3  -D_NO_SYNTH_ -D_NO_CSIM_ -D_NO_COSIM_")
endif()

set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ../bin)

# define build folder for tosa_utils
#set(tosa_utils_build_dir ${CMAKE_CURRENT_SOURCE_DIR}/tosa_utils/build)
#add_subdirectory(tosa_utils ${tosa_utils_build_dir})

file(GLOB children RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*)

# parse all subdirectories from operators
foreach(child ${children})
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${child}
       AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${child}/CMakeLists.txt)
        add_subdirectory(${child})
    endif()
endforeach()