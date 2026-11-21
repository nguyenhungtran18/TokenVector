#include <cuda_runtime.h>

extern "C" __global__ void tkv_kernel_vec_add(float* __restrict__ a, float* __restrict__ b, float* __restrict__ c, int n) {
int i = (blockIdx.x * blockDim.x + threadIdx.x);
if (i < n) {
  c[i] = a[i] + b[i];
}
}

extern "C" int tkv_launch_vec_add(float* __restrict__ a, float* __restrict__ b, float* __restrict__ c, int n, int grid, int block) {
  tkv_kernel_vec_add<<<grid, block>>>(a, b, c, n);
  return (int)cudaGetLastError();
}
