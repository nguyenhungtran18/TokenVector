#include <cuda_runtime.h>

#include <stdint.h>

__device__ __forceinline__ float tkv_wreduce(float v) {
  for (int off = 16; off > 0; off >>= 1) {
    v += __shfl_down_sync(0xffffffff, v, off);
  }
  return v;
}


__device__ __forceinline__ double tkv_wreduce_d(double v) {
  for (int off = 16; off > 0; off >>= 1) {
    v += __shfl_down_sync(0xffffffff, v, off);
  }
  return v;
}


extern "C" __global__ void tkv_kernel_adamw_step(float* __restrict__ p, float* __restrict__ g, float* __restrict__ m, float* __restrict__ v, int n, float lr, float b1, float b2, float bc1, float bc2, float eps, float wd) {
int i = (blockIdx.x * blockDim.x + threadIdx.x);
if (i < n) {
  float mi = b1 * m[i] + (1.0 - b1) * g[i];
  float vi = b2 * v[i] + (1.0 - b2) * g[i] * g[i];
  float denom = sqrtf(vi / bc2) + eps;
  float pi = p[i] - lr * mi / (bc1 * denom);
  p[i] = pi - lr * wd * p[i];
  m[i] = mi;
  v[i] = vi;
}
}

extern "C" int tkv_launch_adamw_step(float* __restrict__ p, float* __restrict__ g, float* __restrict__ m, float* __restrict__ v, int n, float lr, float b1, float b2, float bc1, float bc2, float eps, float wd, int grid, int block) {
  tkv_kernel_adamw_step<<<grid, block>>>(p, g, m, v, n, lr, b1, b2, bc1, bc2, eps, wd);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
