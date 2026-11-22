#include <torch/extension.h>
#include <ATen/ATen.h>
#include <cuda_runtime.h>

#include <math.h>

#include <stdlib.h>

#define TKV_TORCH_EXPORT __attribute__((visibility("default")))
int g_adamw_path = 0;
float* g_grad_buf = 0;
long long g_grad_len = 0;
float g_lr = 0.00005;
float g_b1 = 0.9;
float g_b2 = 0.999;
float g_eps = 0.00000001;
float g_wd = 0.0;
long long g_total_steps = 0;
long long g_cur_step = 0;


TKV_TORCH_EXPORT long long TkvFullPing(long long x) {
return x + 42000;
}

TKV_TORCH_EXPORT int TkvFullAdamwPath() {
return g_adamw_path;
}

TKV_TORCH_EXPORT int TkvFullSetGrad(float* buf, long long n) {
g_grad_buf = buf;
g_grad_len = n;
return 0;
}

TKV_TORCH_EXPORT int TkvFullSetOpt(float* p, float* m, float* v, float lr, float b1, float b2, float eps, float wd, long long total_steps, long long cur_step) {
g_lr = lr;
g_b1 = b1;
g_b2 = b2;
g_eps = eps;
g_wd = wd;
g_total_steps = total_steps;
g_cur_step = cur_step;
return 0;
}
