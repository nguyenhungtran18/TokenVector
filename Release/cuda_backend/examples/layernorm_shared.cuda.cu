#include <cuda_runtime.h>

extern "C" __global__ void tkv_kernel_layernorm_shared(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps) {
__shared__ float s[1024];
int r = blockIdx.x;
int t = (blockIdx.x * blockDim.x + threadIdx.x);
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
  float mean = s[0] / h;
  __syncthreads();
  float var = 0.0;
  if (t == 0) {
    for (int j = 0; j < (h); j++) {
      float d = x[base + j] - mean;
      var = var + d * d;
    }
    s[0] = var / h;
  }
  __syncthreads();
  float rstd = 1.0 / sqrtf(s[0] + eps);
  if (t < h) {
    out[base + t] = (x[base + t] - mean) * rstd * g[t] + b[t];
  }
}
}

extern "C" int tkv_launch_layernorm_shared(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps, int grid, int block) {
  tkv_kernel_layernorm_shared<<<grid, block>>>(x, g, b, out, rows, h, eps);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
