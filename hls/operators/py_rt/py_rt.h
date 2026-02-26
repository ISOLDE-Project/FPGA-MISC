#pragma once

#include <Python.h>
#include <cstdint>
#include <numpy/arrayobject.h>
#include <stdexcept>
#include <string>
#include <vector>

PyObject *numpy_init();
void numpy_release(PyObject *numpy_module);

struct NumpyModule {
  NumpyModule() { numpy_module = numpy_init(); }
  ~NumpyModule() { numpy_release(numpy_module); }
  operator PyObject *() const { return numpy_module; }

  PyObject *numpy_module;
};

struct NumpyArray {
  void *data = nullptr;
  int numpy_type = -1;
  std::vector<npy_intp> shape;
  PyObject *array_obj = nullptr; // keeps data alive

  ~NumpyArray() {
    if (array_obj)
      Py_DECREF(array_obj);
  }

  template <typename T> T *as();

  template <typename T> void set_data(T *newdata);

  template <typename dim_t> void set_shape(dim_t new_shape) {
    assert(shape.size() == 0);
    for (int i = 0; i < dim_t::rank; ++i)
      shape.push_back(new_shape[i]);
  }

  size_t num_elements() const {
    size_t n = 1;
    for (auto s : shape)
      n *= s;
    return n;
  }
};
// Specialization for float
template <> inline float *NumpyArray::as<float>() {
  assert(numpy_type == NPY_FLOAT32);
  assert(data);
  return static_cast<float *>(data);
}

// Specialization for int32_t
template <> inline int32_t *NumpyArray::as<int32_t>() {
  assert(numpy_type == NPY_INT32);
  assert(data);
  return static_cast<int32_t *>(data);
}

// Specialization for int32_t
template <> inline uint32_t *NumpyArray::as<uint32_t>() {
  assert(numpy_type == NPY_UINT32);
  assert(data);
  return static_cast<uint32_t *>(data);
}

template <> inline void NumpyArray::set_data(float *newdata) {
  numpy_type = NPY_FLOAT32;
  data = newdata;
  assert(data);
}

template <> inline void NumpyArray::set_data(int32_t *newdata) {
  numpy_type = NPY_INT32;
  data = newdata;
  assert(data);
}

NumpyArray numpy_load(std::string fname, PyObject *numpy_module);
bool numpy_save(const std::string &filename, const NumpyArray &arr,
                PyObject *numpy_module);

/**
 * ******************8
 */

class PythonScriptRunner {
  bool runPy_Initialize;

public:
  explicit PythonScriptRunner(bool init = false) : runPy_Initialize(init) {
    if (runPy_Initialize)
      Py_Initialize();
    if (!Py_IsInitialized()) {
      throw std::runtime_error("Python interpreter initialization failed.");
    }

    // Optional: redirect output to real stdout/stderr
    // PyRun_SimpleString("import sys; sys.stdout = sys.__stdout__; sys.stderr =
    // sys.__stderr__");
       // Proper NumPy init for constructors
    if (_import_array() < 0) {
        PyErr_Print();
        throw std::runtime_error("NumPy import failed");
    }
  }

  ~PythonScriptRunner() {
    if (runPy_Initialize && Py_IsInitialized()) {
      Py_Finalize();
    }
  }

  void operator()(const std::string &scriptPath) {
    FILE *fp = fopen(scriptPath.c_str(), "r");
    if (!fp) {
      throw std::runtime_error("Failed to open Python script: " + scriptPath);
    }

    int result = PyRun_SimpleFile(fp, scriptPath.c_str());
    fclose(fp);

    if (result != 0) {
      throw std::runtime_error("Python script execution failed.");
    }
  }
/** 
************************************
** Python script template
************************************
import numpy as np

print("Integer from C++:", cpp_value)

print("Array info:")
print(" shape:", cpp_array.shape)
print(" dtype:", cpp_array.dtype)


**/
  void operator()(const std::string &scriptPath, int value, NumpyArray &arr) {
    // Open script
    FILE *fp = fopen(scriptPath.c_str(), "r");
    if (!fp)
      throw std::runtime_error("Failed to open Python script: " + scriptPath);

    // Get main module dictionary
    PyObject *main_module = PyImport_AddModule("__main__");
    PyObject *global_dict = PyModule_GetDict(main_module);

    //--------------------------------------------------
    // Inject integer
    //--------------------------------------------------
    PyObject *py_int = PyLong_FromLong(value);
    PyDict_SetItemString(global_dict, "cpp_value", py_int);
    Py_DECREF(py_int);

    //--------------------------------------------------
    // Create NumPy array from raw memory
    //--------------------------------------------------
    if (!arr.data)
      throw std::runtime_error("NumpyArray data is null.");

    PyObject *numpy_array = PyArray_SimpleNewFromData(
        (int)arr.shape.size(), arr.shape.data(), arr.numpy_type, arr.data);

    if (!numpy_array)
      throw std::runtime_error("Failed to create NumPy array.");

    // Keep ownership so memory is not freed prematurely
    arr.array_obj = numpy_array;

    PyDict_SetItemString(global_dict, "cpp_array", numpy_array);

    //--------------------------------------------------
    // Run script
    //--------------------------------------------------
    int result = PyRun_SimpleFile(fp, scriptPath.c_str());
    fclose(fp);

    if (result != 0)
      throw std::runtime_error("Python script execution failed.");
  }
};