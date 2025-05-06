#pragma once

#include <Python.h>
#include <cstdint>
#include <numpy/arrayobject.h>
#include <string>
#include <vector>
#include <stdexcept>

PyObject *numpy_init();
void numpy_release(PyObject *numpy_module);

struct NumpyModule
{
  NumpyModule() { numpy_module = numpy_init(); }
  ~NumpyModule() { numpy_release(numpy_module); }
  operator PyObject *() const { return numpy_module; }

  PyObject *numpy_module;
};

struct NumpyArray
{
  void *data = nullptr;
  int numpy_type = -1;
  std::vector<npy_intp> shape;
  PyObject *array_obj = nullptr; // keeps data alive

  ~NumpyArray()
  {
    if (array_obj)
      Py_DECREF(array_obj);
  }

  template <typename T>
  T *as();

  template <typename T>
  void set_data(T *newdata);

  template <typename dim_t>
  void set_shape(dim_t new_shape)
  {
    assert(shape.size() == 0);
    for (int i = 0; i < dim_t::rank; ++i)
      shape.push_back(new_shape[i]);
  }

  size_t num_elements() const
  {
    size_t n = 1;
    for (auto s : shape)
      n *= s;
    return n;
  }
};
// Specialization for float
template <>
inline float *NumpyArray::as<float>()
{
  assert(numpy_type == NPY_FLOAT32);
  assert(data);
  return static_cast<float *>(data);
}

// Specialization for int32_t
template <>
inline int32_t *NumpyArray::as<int32_t>()
{
  assert(numpy_type == NPY_INT32);
  assert(data);
  return static_cast<int32_t *>(data);
}

// Specialization for int32_t
template <>
inline uint32_t *NumpyArray::as<uint32_t>()
{
  assert(numpy_type == NPY_UINT32);
  assert(data);
  return static_cast<uint32_t *>(data);
}

template <>
inline void NumpyArray::set_data(float *newdata)
{
  numpy_type = NPY_FLOAT32;
  data = newdata;
  assert(data);
}

template <>
inline void NumpyArray::set_data(int32_t *newdata)
{
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

class PythonScriptRunner
{
public:
explicit PythonScriptRunner(bool init=false) :runPy_Initialize(init){
  if(runPy_Initialize) Py_Initialize();
  if (!Py_IsInitialized()) {
      throw std::runtime_error("Python interpreter initialization failed.");
  }

  // Optional: redirect output to real stdout/stderr
  //PyRun_SimpleString("import sys; sys.stdout = sys.__stdout__; sys.stderr = sys.__stderr__");
}

~PythonScriptRunner() {
  if (runPy_Initialize && Py_IsInitialized()) {
      Py_Finalize();
  }
}

  void operator()(const std::string &scriptPath)
  {
    FILE *fp = fopen(scriptPath.c_str(), "r");
    if (!fp)
    {
      throw std::runtime_error("Failed to open Python script: " + scriptPath);
    }

    int result = PyRun_SimpleFile(fp, scriptPath.c_str());
    fclose(fp);

    if (result != 0)
    {
      throw std::runtime_error("Python script execution failed.");
    }
  }
  bool runPy_Initialize;
};