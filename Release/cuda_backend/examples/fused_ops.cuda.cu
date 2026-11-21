#include <cuda_runtime.h>

extern "C" __global__ void tkv_kernel_embed_add(float* __restrict__ wte, float* __restrict__ wpe, int* __restrict__ ids, float* __restrict__ out, int n, int h) {
int i = (blockIdx.x * blockDim.x + threadIdx.x);
if (i < n) {
  int row = i / h;
  int col = i % h;
  int tok = ids[row];
  out[i] = wte[tok * h + col] + wpe[i];
}
}

extern "C" int tkv_launch_embed_add(float* __restrict__ wte, float* __restrict__ wpe, int* __restrict__ ids, float* __restrict__ out, int n, int h, int grid, int block) {
  tkv_kernel_embed_add<<<grid, block>>>(wte, wpe, ids, out, n, h);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}

extern "C" __global__ void tkv_kernel_gelu_erf(float* __restrict__ x, float* __restrict__ out, int n) {
int i = (blockIdx.x * blockDim.x + threadIdx.x);
if (i < n) {
  float v = x[i];
  out[i] = 0.5 * v * (1.0 + erff(v * 0.70710678));
}
}

extern "C" int tkv_launch_gelu_erf(float* __restrict__ x, float* __restrict__ out, int n, int grid, int block) {
  tkv_kernel_gelu_erf<<<grid, block>>>(x, out, n);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}

extern "C" __global__ void tkv_kernel_bias_add(float* __restrict__ x, float* __restrict__ b, float* __restrict__ out, int n, int h) {
int i = (blockIdx.x * blockDim.x + threadIdx.x);
if (i < n) {
  int col = i % h;
  out[i] = x[i] + b[col];
}
}

extern "C" int tkv_launch_bias_add(float* __restrict__ x, float* __restrict__ b, float* __restrict__ out, int n, int h, int grid, int block) {
  tkv_kernel_bias_add<<<grid, block>>>(x, b, out, n, h);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
