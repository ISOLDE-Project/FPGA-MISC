#pragma once

#include <Python.h>
#include <numpy/arrayobject.h>
#include <string>

PyObject *numpy_init() ;
float *numpy_load_float32(std::string fname, PyObject *numpy_module);

