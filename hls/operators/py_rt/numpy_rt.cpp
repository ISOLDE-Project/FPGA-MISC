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

  void numpy_release(PyObject *numpy_module){
    if(numpy_module) Py_DECREF(numpy_module);
    Py_Finalize();
  }

  NumpyArray numpy_load(std::string fname, PyObject *numpy_module) {
    assert(numpy_module);
    NumpyArray result;
    PyObject *numpy_load = PyObject_GetAttrString(numpy_module, "load");
    PyObject *py_filename = PyUnicode_FromString(fname.c_str());
    PyObject *args = PyTuple_Pack(1, py_filename);
    PyObject *np_array_obj = PyObject_CallObject(numpy_load, args);
  
    if (!np_array_obj || !PyArray_Check(np_array_obj)) {
      PyErr_Print();
      std::cerr
          << "Failed to load NumPy array or object is not a valid ndarray.\n";
    
    }
    // Cast to PyArrayObject
    PyArrayObject *np_array = reinterpret_cast<PyArrayObject *>(np_array_obj);
    result.numpy_type = PyArray_TYPE(np_array);
    result.data = PyArray_DATA(np_array);

    int ndim = PyArray_NDIM(np_array);
    npy_intp* dims = PyArray_SHAPE(np_array);
    result.shape.assign(dims, dims + ndim);

    result.array_obj = np_array_obj; // Keep reference alive
    //
    Py_DECREF(args);
    Py_DECREF(py_filename);
    Py_DECREF(numpy_load);
    return result;
  }

  bool numpy_save(const std::string& filename, const NumpyArray& arr, PyObject* numpy_module) {
    assert(numpy_module);
    
    PyObject* numpy_save = PyObject_GetAttrString(numpy_module, "save");
    if (!numpy_save || !PyCallable_Check(numpy_save)) {
        PyErr_Print();
        std::cerr << "Could not find or call numpy.save\n";
        return false;
    }

    PyObject* ndarray = PyArray_SimpleNewFromData(arr.shape.size(), arr.shape.data(), arr.numpy_type, arr.data);

    if (!ndarray) {
        PyErr_Print();
        std::cerr << "Failed to create NumPy array from C++ data\n";
        return false;
    }

    PyObject* py_filename = PyUnicode_FromString(filename.c_str());
    PyObject* args = PyTuple_Pack(2, py_filename, ndarray);

    PyObject* result = PyObject_CallObject(numpy_save, args);


    if (!result) {
        PyErr_Print();
        std::cerr << "Failed to save NumPy array to file\n";
        return false;
    }

    Py_DECREF(result);
    Py_DECREF(args);
    Py_DECREF(py_filename);
    Py_DECREF(ndarray);
    Py_DECREF(numpy_save);
   
    return true;
}
