#include "py_rt.h"
#include <iostream>

PyObject *numpy_init() {
    //*
    Py_Initialize();
    import_array(); // Required to use NumPy C API
  
    // Import numpy
    PyObject *numpy_module = PyImport_ImportModule("numpy");
    if (!numpy_module) {
      PyErr_Print();
      std::cerr << "Failed to import numpy\n";
      return nullptr;
    }
    return numpy_module;
  }
  float *numpy_load_float32(std::string fname, PyObject *numpy_module) {
    assert(numpy_module);
    PyObject *numpy_load = PyObject_GetAttrString(numpy_module, "load");
    PyObject *py_filename = PyUnicode_FromString(fname.c_str());
    PyObject *args = PyTuple_Pack(1, py_filename);
    PyObject *np_array_obj = PyObject_CallObject(numpy_load, args);
  
    if (!np_array_obj || !PyArray_Check(np_array_obj)) {
      PyErr_Print();
      std::cerr
          << "Failed to load NumPy array or object is not a valid ndarray.\n";
      return nullptr;
    }
    // Cast to PyArrayObject
    PyArrayObject *np_array = reinterpret_cast<PyArrayObject *>(np_array_obj);
    // Get raw pointer
    float *data = static_cast<float *>(PyArray_DATA(np_array));
    return data;
  }