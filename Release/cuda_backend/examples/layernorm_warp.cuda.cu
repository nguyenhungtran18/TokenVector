#include <cuda_runtime.h>

#include <stdint.h>

__device__ __forceinline__ float tkv_wreduce(float v) {
  for (int off = 16; off > 0; off >>= 1) {
    v += __shfl_down_sync(0xffffffff, v, off);
  }
  return v;
}


extern "C" __global__ void tkv_kernel_layernorm_warp(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps) {
__shared__ float s[32];
int r = blockIdx.x;
int t = threadIdx.x;
int lane = (threadIdx.x & 31);
int wid = t / 32;
if (r < rows) {
  int base = r * h;
  float v = 0.0;
  if (t < h) {
    v = x[base + t];
  }
  float sm = tkv_wreduce(v);
  if (lane == 0) {
    s[wid] = sm;
  }
  __syncthreads();
  /* warp 0: lane<8 reads s[lane], lane>=8 zero-fill for safe wreduce */;
  float m8 = 0.0;
  if (wid == 0) {
    float sv = 0.0;
    if (lane < 8) {
      sv = s[lane];
    }
    m8 = tkv_wreduce(sv) / h;
  }
  if (t == 0) {
    s[0] = m8;
  }
  __syncthreads();
  float mean = s[0];
  float v2 = 0.0;
  if (t < h) {
    float d2 = x[base + t] - mean;
    v2 = d2 * d2;
  }
  float sv2 = tkv_wreduce(v2);
  if (lane == 0) {
    s[wid] = sv2;
  }
  __syncthreads();
  float v8 = 0.0;
  if (wid == 0) {
    float svv = 0.0;
    if (lane < 8) {
      svv = s[lane];
    }
    v8 = tkv_wreduce(svv) / h;
  }
  if (t == 0) {
    s[0] = v8;
  }
  __syncthreads();
  float rstd = 1.0 / sqrtf(s[0] + eps);
  if (t < h) {
    out[base + t] = (x[base + t] - mean) * rstd * g[t] + b[t];
  }
}
}

extern "C" int tkv_launch_layernorm_warp(float* __restrict__ x, float* __restrict__ g, float* __restrict__ b, float* __restrict__ out, int rows, int h, float eps, int grid, int block) {
  tkv_kernel_layernorm_warp<<<grid, block>>>(x, g, b, out, rows, h, eps);
  cudaError_t launch_err = cudaGetLastError();
  cudaDeviceSynchronize();
  cudaError_t sync_err = cudaGetLastError();
  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);
}
