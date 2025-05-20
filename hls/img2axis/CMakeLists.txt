cmake_minimum_required(VERSION 3.16.3)

project(functional-simulator VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if (CMAKE_BUILD_TYPE STREQUAL "Debug" )
	message("debug version")
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -fsanitize=address  -std=c++17 -O0  ")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g   -std=c++17 -O0  ")
else()
	message("optimised version")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -std=c++17 -O3  ")
endif()

set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ../bin)

# Check for the CONDA_PREFIX environment variable
if(DEFINED ENV{CONDA_PREFIX})
    set(CONDA_PREFIX $ENV{CONDA_PREFIX})
    message(STATUS "Conda environment detected at: ${CONDA_PREFIX}")
else()
    message(FATAL_ERROR "CONDA_PREFIX not found. Please activate your conda environment before running CMake.")
endif()

find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

execute_process(
    COMMAND python3 -c "import numpy; print(numpy.get_include())"
    OUTPUT_VARIABLE NUMPY_INCLUDE
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "numpy includes: ${NUMPY_INCLUDE}")

function(add_include_directories target)
    message(STATUS "Included  directories: ${CMAKE_SOURCE_DIR}/../operators ${CMAKE_SOURCE_DIR}/../include ${CMAKE_SOURCE_DIR}/src ")
    target_include_directories(${target} PUBLIC  ${CMAKE_SOURCE_DIR}/../operators ${CMAKE_SOURCE_DIR}/../include ${CMAKE_SOURCE_DIR}/src )
    target_include_directories(${target} PRIVATE ${Python3_INCLUDE_DIRS} ${NUMPY_INCLUDE})  
endfunction()

file(GLOB children RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*)

# parse all subdirectories from operators
foreach(child ${children})
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${child}
       AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${child}/CMakeLists.txt)
        add_subdirectory(${child})
    endif()
endforeach()

