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
