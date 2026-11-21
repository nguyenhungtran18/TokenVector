#include <cuda_runtime.h>

extern "C" __global__ void tkv_kernel_layernorm_fwd(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps) {
int r = blockIdx.x;
if (r < rows) {
  int base = r * h;
  float mean = 0.0;
  for (int j = 0; j < (h); j++) {
    mean = mean + x[base + j];
  }
  mean = mean / h;
  float var = 0.0;
  for (int j = 0; j < (h); j++) {
    float d = x[base + j] - mean;
    var = var + d * d;
  }
  var = var / h;
  float rstd = 1.0 / sqrtf(var + eps);
  for (int j = 0; j < (h); j++) {
    out[base + j] = (x[base + j] - mean) * rstd * g[j] + b[j];
  }
}
}

extern "C" int tkv_launch_layernorm_fwd(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps, int grid, int block) {
  tkv_kernel_layernorm_fwd<<<grid, block>>>(x, g, b, out, rows, h, eps);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
