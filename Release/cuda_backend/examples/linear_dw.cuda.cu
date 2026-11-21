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


extern "C" __global__ void tkv_kernel_linear_dw(float* __restrict__ x, float* __restrict__ gy, float* __restrict__ gdw, int n, int in_d, int out_d) {
int tid = (blockIdx.x * blockDim.x + threadIdx.x);
int total = in_d * out_d;
if (tid < total) {
  int i = tid / out_d;
  int c = tid % out_d;
  float s = gdw[tid];
  for (int p = 0; p < (n); p++) {
    s = x[p * in_d + i] * gy[p * out_d + c] + s;
  }
  gdw[tid] = s;
}
}

extern "C" int tkv_launch_linear_dw(float* __restrict__ x, float* __restrict__ gy, float* __restrict__ gdw, int n, int in_d, int out_d, int grid, int block) {
  tkv_kernel_linear_dw<<<grid, block>>>(x, gy, gdw, n, in_d, out_d);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
