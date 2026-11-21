#include <cuda_runtime.h>

extern "C" __global__ void tkv_kernel_debug_mean(float* __restrict__ x, float* __restrict__ out, int rows, int h) {
__shared__ float s[1024];
int r = blockIdx.x;
int t = threadIdx.x;
if (r < rows) {
  int base = r * h;
  if (t < h) {
    s[t] = x[base + t];
  }
  __syncthreads();
  int stride = h / 2;
  for (int k = 0; k < (10); k++) {
    if (t < stride) {
      s[t] = s[t] + s[t + stride];
    }
    __syncthreads();
    stride = stride / 2;
  }
  if (t == 0) {
    out[r] = s[0] / h;
  }
}
}

extern "C" int tkv_launch_debug_mean(float* __restrict__ x, float* __restrict__ out, int rows, int h, int grid, int block) {
  tkv_kernel_debug_mean<<<grid, block>>>(x, out, rows, h);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
