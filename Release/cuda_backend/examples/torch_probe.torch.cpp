int g_adamw_path = 0;
float* g_grad_buf = 0;
long long g_grad_len = 0;
#include <torch/extension.h>
#include <ATen/ATen.h>
#include <cuda_runtime.h>

#include <math.h>

#include <stdlib.h>

#define TKV_TORCH_EXPORT __attribute__((visibility("default")))


TKV_TORCH_EXPORT long long TkvFullPing(long long x) {
long long y = x + 42000;
return y;
}

TKV_TORCH_EXPORT int TkvFullAdamwPath() {
return g_adamw_path;
}

TKV_TORCH_EXPORT int TkvFullSetGrad(float* buf, long long n) {
g_grad_buf = buf;
g_grad_len = n;
return 0;
}
