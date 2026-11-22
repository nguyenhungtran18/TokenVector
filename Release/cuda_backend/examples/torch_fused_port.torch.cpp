#include <torch/extension.h>
#include <ATen/ATen.h>
#include <cuda_runtime.h>

#include <math.h>

#include <stdlib.h>

#include <vector>

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
at::Tensor g_ids;
at::Tensor g_pos;
at::Tensor g_tgt;
std::vector<at::Tensor> g_p;
tensor[] g_p = 0;
std::vector<float*> g_p_src;
* g_p_src = 0;
std::vector<long long> g_p_numels;
i64[] g_p_numels = 0;


static inline bool tkv_want_cuda() { const char* s = getenv("TKV_TORCH_GPU"); return s && s[0] != 0; }

static inline torch::TensorOptions tkv_opt_long() { return tkv_want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA) : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU); }

static inline torch::Tensor tkv_to_long(const torch::Tensor& t) { return t.to(tkv_opt_long()); }

static inline torch::Tensor tkv_to_half(const torch::Tensor& t) { return t.to(at::ScalarType::Half); }

static inline void tkv_copy_(torch::Tensor& d, const torch::Tensor& s) { d.copy_(s); }

static inline bool tkv_defined(const at::Tensor& t) { return t.defined(); }

static inline long long tkv_numel(const at::Tensor& t) { return t.numel(); }

static inline torch::Tensor tkv_to_dev(const torch::Tensor& t) { return tkv_want_cuda() ? t.to(torch::TensorOptions().dtype(at::ScalarType::Half).device(torch::kCUDA)) : t; }

static inline long long tkv_vec_len(const std::vector<at::Tensor>& v) { return (long long)v.size(); }

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

TKV_TORCH_EXPORT int TkvFullSetIds(int* ids, long long T) {
auto t = torch::from_blob(const_cast<int*>(ids), {T}, torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
g_ids = tkv_to_long(t);
g_pos = at::arange(T, tkv_opt_long());
return 0;
}

TKV_TORCH_EXPORT int TkvFullSetTargets(int* ids, long long T) {
auto t = torch::from_blob(const_cast<int*>(ids), {T}, torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
g_tgt = tkv_to_long(t);
return 0;
}

TKV_TORCH_EXPORT int TkvFullSetTensor(long long idx, float* ptr, long long numel) {
if (idx < 0) {
  return -2;
}
if (idx >= tkv_vec_len(g_p)) {
  return -2;
}
if (tkv_defined(g_p[idx]) && tkv_numel(g_p[idx]) == numel && g_p_src[idx] == ptr) {
  return 0;
}
auto t = torch::from_blob(const_cast<float*>(ptr), {numel}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false));
ht = tkv_to_half(t);
if (tkv_defined(g_p[idx]) && tkv_numel(g_p[idx]) == numel) {
  tkv_copy_(g_p[idx], ht);
}
if (1) {
  g_p[idx] = tkv_to_dev(ht);
}
g_p_src[idx] = ptr;
g_p_numels[idx] = numel;
return 0;
}
