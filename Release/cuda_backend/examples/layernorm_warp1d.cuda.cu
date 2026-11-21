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


extern "C" __global__ void tkv_kernel_layernorm_warp1d(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps) {
int r = blockIdx.x;
int lane = (threadIdx.x & 31);
if (r < rows) {
  int base = r * h;
  float x0 = x[base + lane];
  float x1 = x[base + lane + 32];
  float x2 = x[base + lane + 64];
  float x3 = x[base + lane + 96];
  float x4 = x[base + lane + 128];
  float x5 = x[base + lane + 160];
  float x6 = x[base + lane + 192];
  float x7 = x[base + lane + 224];
  double d_s = x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7;
  double d_q = x0*x0 + x1*x1 + x2*x2 + x3*x3 + x4*x4 + x5*x5 + x6*x6 + x7*x7;
  double d_st = tkv_wreduce_d(d_s);
  double d_qt = tkv_wreduce_d(d_q);
  double d_mean = d_st / h;
  double d_var = d_qt / h - d_mean * d_mean;
  float rstd = 1.0 / sqrtf(d_var + eps);
  float m = d_mean;
  out[base + lane] = (x0 - m) * rstd * g[lane] + b[lane];
  out[base + lane + 32] = (x1 - m) * rstd * g[lane + 32] + b[lane + 32];
  out[base + lane + 64] = (x2 - m) * rstd * g[lane + 64] + b[lane + 64];
  out[base + lane + 96] = (x3 - m) * rstd * g[lane + 96] + b[lane + 96];
  out[base + lane + 128] = (x4 - m) * rstd * g[lane + 128] + b[lane + 128];
  out[base + lane + 160] = (x5 - m) * rstd * g[lane + 160] + b[lane + 160];
  out[base + lane + 192] = (x6 - m) * rstd * g[lane + 192] + b[lane + 192];
  out[base + lane + 224] = (x7 - m) * rstd * g[lane + 224] + b[lane + 224];
}
}

extern "C" int tkv_launch_layernorm_warp1d(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps, int grid, int block) {
  tkv_kernel_layernorm_warp1d<<<grid, block>>>(x, g, b, out, rows, h, eps);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
