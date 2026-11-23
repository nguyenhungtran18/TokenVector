#include <torch/extension.h>
#include <ATen/ATen.h>
#include <cuda_runtime.h>

#include <math.h>

#include <stdlib.h>

#include <vector>

#include <cstring>

#include <dlfcn.h>

#include <cmath>

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
at::Tensor g_p_all;
int g_cfg0 = 0;
int g_cfg1 = 0;
int g_cfg2 = 0;
int g_cfg3 = 0;
int g_cfg4 = 0;
int g_cfg5 = 0;
int g_nlayers = 0;
int g_h = 0;
int g_nhd = 0;
int g_hd = 0;
int g_vocab = 0;
at::Tensor g_grad_dev;
at::Tensor g_m_dev;
at::Tensor g_v_dev;
int g_dev_ready = 0;


static inline bool tkv_want_cuda() { const char* s = getenv("TKV_TORCH_GPU"); return s && s[0] != 0; }

static inline torch::TensorOptions tkv_opt_long() { return tkv_want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA) : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU); }

static inline torch::Tensor tkv_to_long(const torch::Tensor& t) { return t.to(tkv_opt_long()); }

static inline torch::Tensor tkv_to_half(const torch::Tensor& t) { return t.to(at::ScalarType::Half); }

static inline void tkv_copy_(torch::Tensor& d, const torch::Tensor& s) { d.copy_(s); }

static inline bool tkv_defined(const at::Tensor& t) { return t.defined(); }

static inline long long tkv_numel(const at::Tensor& t) { return t.numel(); }

static inline torch::Tensor tkv_to_dev(const torch::Tensor& t) { return tkv_want_cuda() ? t.to(torch::TensorOptions().dtype(at::ScalarType::Half).device(torch::kCUDA)) : t; }

static inline long long tkv_vec_len(const std::vector<at::Tensor>& v) { return (long long)v.size(); }

static inline void tkv_assign_tensor(std::vector<at::Tensor>& v, long long n) { v.assign((size_t)n, at::Tensor()); }

static inline void tkv_assign_ptr(std::vector<float*>& v, long long n) { v.assign((size_t)n, nullptr); }

static inline void tkv_assign_i64(std::vector<long long>& v, long long n) { v.assign((size_t)n, 0); }

static inline void tkv_reset(at::Tensor& t) { t.reset(); }

static inline void tkv_copy_out(const at::Tensor& t, float* dst, long long n) { auto h = t.to(torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU)); std::memcpy(dst, h.const_data_ptr<float>(), (size_t)n * sizeof(float)); }

static inline at::Tensor tkv_empty_i64(long long n) { return at::empty({n}, torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU)); }

static inline long long* tkv_data_i64(at::Tensor& t) { return t.data_ptr<long long>(); }

static inline torch::Tensor tkv_contiguous(const torch::Tensor& t) { return t.contiguous(); }

static inline torch::Tensor tkv_view3(const torch::Tensor& t, long long a, long long b, long long c) { return t.view({a,b,c}); }

static inline torch::Tensor tkv_view2(const torch::Tensor& t, long long a, long long b) { return t.view({a,b}); }

static inline void tkv_backward(const torch::Tensor& t) { t.backward(); }

typedef int (*tkv_adamw_fn)(float*, const float*, float*, float*, long long, float, float, float, float, float, float, float, int, int);

static inline void tkv_adamw_launch() { const char* path = getenv("TKV_CUDA_KERNELS_SO"); if (!path) return; void* h = dlopen(path, RTLD_NOW); if (!h) return; tkv_adamw_fn fn = (tkv_adamw_fn)dlsym(h, "tkv_launch_adamw_step"); if (!fn) return; long long numel = g_p_all.numel(); int threads = 256; int blocks = (int)((numel + threads - 1) / threads); fn(g_p_all.data_ptr<float>(), g_grad_dev.data_ptr<float>(), g_m_dev.data_ptr<float>(), g_v_dev.data_ptr<float>(), numel, g_lr, g_b1, g_b2, 1.0f - pow(g_b1, (double)(g_cur_step + 1)), 1.0f - pow(g_b2, (double)(g_cur_step + 1)), g_eps, g_wd, blocks, threads); g_adamw_path = 1; }

static inline torch::Tensor tkv_grad(const torch::Tensor& t) { return t.grad(); }

static inline void tkv_clear_grad(torch::Tensor& t) { t.mutable_grad() = at::Tensor(); }

static inline void tkv_put_grad(long long idx, const torch::Tensor& gr) { long long off = 0; for (long long i = 0; i < idx; ++i) off += g_p[(size_t)i].numel(); if (tkv_defined(g_grad_dev) && off + gr.numel() <= g_grad_dev.numel()) g_grad_dev.narrow(0, off, gr.numel()).copy_(gr.to(at::ScalarType::Float).contiguous().reshape({gr.numel()})); }

static inline void tkv_zero_grad(long long idx) { long long off = 0; for (long long i = 0; i < idx; ++i) off += g_p[(size_t)i].numel(); if (tkv_defined(g_grad_dev) && off + g_p[(size_t)idx].numel() <= g_grad_dev.numel()) g_grad_dev.narrow(0, off, g_p[(size_t)idx].numel()).zero_(); }

static inline void tkv_sync_fp16() { c10::NoGradGuard g; long long off = 0; for (size_t i = 0; i < g_p.size(); ++i) { long long nn = g_p[i].numel(); if (nn > 0) g_p[i].copy_(g_p_all.narrow(0, off, nn)); off += nn; } }

static inline torch::Tensor tkv_view4(const torch::Tensor& t, long long a, long long b, long long c, long long d) { return t.view({a,b,c,d}); }

static inline torch::Tensor tkv_reshape2(const torch::Tensor& t, long long a, long long b) { return t.reshape({a,b}); }

static inline torch::Tensor tkv_select(const torch::Tensor& t, long long dim, long long idx) { return t.select(dim, idx); }

static inline torch::Tensor tkv_unsqueeze(const torch::Tensor& t, long long d) { return t.unsqueeze(d); }

static inline torch::Tensor tkv_transpose(const torch::Tensor& t, long long a, long long b) { return t.transpose(a,b); }

static inline torch::Tensor tkv_ln(const torch::Tensor& x, const torch::Tensor& g, const torch::Tensor& b, double eps) { return at::layer_norm(x, at::IntArrayRef{x.size(-1)}, g, b, eps).to(x.scalar_type()); }

static inline torch::Tensor tkv_half_mm(const torch::Tensor& a, const torch::Tensor& w) { return at::mm(a.to(at::ScalarType::Half), w.to(at::ScalarType::Half)); }

static inline torch::Tensor tkv_half_addmm(const torch::Tensor& bias, const torch::Tensor& a, const torch::Tensor& w) { return at::addmm(bias.to(at::ScalarType::Half), a.to(at::ScalarType::Half), w.to(at::ScalarType::Half)); }

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
auto g_ids = tkv_to_long(t);
auto g_pos = at::arange(T, tkv_opt_long());
return 0;
}

TKV_TORCH_EXPORT int TkvFullSetTargets(int* ids, long long T) {
auto t = torch::from_blob(const_cast<int*>(ids), {T}, torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
auto g_tgt = tkv_to_long(t);
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
auto ht = tkv_to_half(t);
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

TKV_TORCH_EXPORT int TkvFullBegin(long long n_tensors, long long NLayers, long long H, long long NHeads, long long Hd, long long Vocab) {
if (n_tensors <= 4) {
  return -2;
}
if (NLayers <= 0) {
  return -2;
}
changed = 0;
if (g_cfg0 != n_tensors) {
  changed = 1;
}
if (g_cfg1 != NLayers) {
  changed = 1;
}
if (g_cfg2 != H) {
  changed = 1;
}
if (g_cfg3 != NHeads) {
  changed = 1;
}
if (g_cfg4 != Hd) {
  changed = 1;
}
if (g_cfg5 != Vocab) {
  changed = 1;
}
if (changed == 1) {
  g_cfg0 = n_tensors;
  g_cfg1 = NLayers;
  g_cfg2 = H;
  g_cfg3 = NHeads;
  g_cfg4 = Hd;
  g_cfg5 = Vocab;
  tkv_assign_tensor(g_p, n_tensors);
  tkv_assign_ptr(g_p_src, n_tensors);
  tkv_assign_i64(g_p_numels, n_tensors);
  tkv_reset(g_p_all);
  tkv_reset(g_ids);
  tkv_reset(g_pos);
  tkv_reset(g_tgt);
}
g_grad_buf = 0;
g_grad_len = 0;
g_nlayers = NLayers;
g_h = H;
g_nhd = NHeads;
g_hd = Hd;
g_vocab = Vocab;
return 0;
}

TKV_TORCH_EXPORT int TkvFullGetParams(float* dst, long long n) {
if (n <= 0) {
  return -1;
}
if (tkv_defined(g_p_all) == 0) {
  return -2;
}
if (tkv_numel(g_p_all) != n) {
  return -2;
}
tkv_copy_out(g_p_all, dst, n);
return 0;
}

TKV_TORCH_EXPORT int TkvFullSetIdsGen(long long T) {
if (T <= 0) {
  return -1;
}
V = g_vocab;
if (V <= 0) {
  V = 50257;
}
auto cpu = tkv_empty_i64(T);
p = tkv_data_i64(cpu);
for (int i = 0; i < (T); i++) {
  p[i] = (i * 37 + 11) % V;
}
auto g_ids = tkv_to_long(cpu);
auto g_pos = at::arange(T, tkv_opt_long());
return 0;
}

TKV_TORCH_EXPORT float TkvFullStep124mFwd(long long run_mode) {
T = g_ids.numel();
h = g_h;
nh = g_nhd;
hd = g_hd;
V = g_vocab;
L = g_nlayers;
auto wte = tkv_view2(g_p[0], V, h);
Pw = g_p[1].numel() / h;
auto wpe = tkv_view2(g_p[1], Pw, h);
auto x = at::index_select(wte, 0, g_ids) + at::index_select(wpe, 0, g_pos);
for (int li = 0; li < (L); li++) {
  b0 = 4 + li * 12;
  auto a = tkv_ln(x, g_p[b0], g_p[b0 + 1], 1e-6);
  auto wqkv = tkv_view2(g_p[b0 + 2], h, 3 * h);
  auto qkv = tkv_half_addmm(g_p[b0 + 3], a, wqkv);
  qkv3 = tkv_view4(qkv, T, 3, nh, hd);
  q = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 0), 0, 1), 0);
  k = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 1), 0, 1), 0);
  v = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 2), 0, 1), 0);
  auto attn = at::scaled_dot_product_attention(q, k, v);
  ctx = tkv_reshape2(tkv_transpose(attn, 1, 2), T, h);
  auto wp = tkv_view2(g_p[b0 + 4], h, h);
  auto proj = tkv_half_addmm(g_p[b0 + 5], ctx, wp);
  x = x + proj;
  auto m = tkv_ln(x, g_p[b0 + 6], g_p[b0 + 7], 1e-6);
  auto w1 = tkv_view2(g_p[b0 + 8], h, 4 * h);
  auto u = tkv_half_addmm(g_p[b0 + 9], m, w1);
  auto g1 = at::gelu(u);
  auto w2 = tkv_view2(g_p[b0 + 10], 4 * h, h);
  x = x + tkv_half_addmm(g_p[b0 + 11], g1, w2);
}
auto xf = tkv_ln(x, g_p[2], g_p[3], 1e-6);
auto logits = tkv_half_mm(xf, tkv_transpose(wte, 0, 1));
auto lp = at::log_softmax(logits, -1);
tgt = tkv_unsqueeze(g_tgt, 1);
auto loss_t = -at::mean(at::gather(lp, 1, tgt));
return loss_t.item();
}

TKV_TORCH_EXPORT float TkvFullStep124m(long long run_mode) {
T = g_ids.numel();
h = g_h;
nh = g_nhd;
hd = g_hd;
V = g_vocab;
L = g_nlayers;
auto wte = tkv_view2(g_p[0], V, h);
Pw = g_p[1].numel() / h;
auto wpe = tkv_view2(g_p[1], Pw, h);
auto x = at::index_select(wte, 0, g_ids) + at::index_select(wpe, 0, g_pos);
for (int li = 0; li < (L); li++) {
  b0 = 4 + li * 12;
  auto a = tkv_ln(x, g_p[b0], g_p[b0 + 1], 1e-6);
  auto wqkv = tkv_view2(g_p[b0 + 2], h, 3 * h);
  auto qkv = tkv_half_addmm(g_p[b0 + 3], a, wqkv);
  qkv3 = tkv_view4(qkv, T, 3, nh, hd);
  q = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 0), 0, 1), 0);
  k = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 1), 0, 1), 0);
  v = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 2), 0, 1), 0);
  auto attn = at::scaled_dot_product_attention(q, k, v);
  ctx = tkv_reshape2(tkv_transpose(attn, 1, 2), T, h);
  auto wp = tkv_view2(g_p[b0 + 4], h, h);
  auto proj = tkv_half_addmm(g_p[b0 + 5], ctx, wp);
  x = x + proj;
  auto m = tkv_ln(x, g_p[b0 + 6], g_p[b0 + 7], 1e-6);
  auto w1 = tkv_view2(g_p[b0 + 8], h, 4 * h);
  auto u = tkv_half_addmm(g_p[b0 + 9], m, w1);
  auto g1 = at::gelu(u);
  auto w2 = tkv_view2(g_p[b0 + 10], 4 * h, h);
  x = x + tkv_half_addmm(g_p[b0 + 11], g1, w2);
}
auto xf = tkv_ln(x, g_p[2], g_p[3], 1e-6);
auto logits = tkv_half_mm(xf, tkv_transpose(wte, 0, 1));
auto lp = at::log_softmax(logits, -1);
tgt = tkv_unsqueeze(g_tgt, 1);
auto loss_t = -at::mean(at::gather(lp, 1, tgt));
loss_val = loss_t.item();
if (run_mode == 1) {
  return loss_val;
}
if (g_dev_ready == 0) {
  return loss_val;
}
for (int i = 0; i < (g_p.size()); i++) {
  if (g_p[i].requires_grad() == 0) {
    g_p[i].set_requires_grad(1);
  }
}
tkv_backward(loss_t);
for (int i = 0; i < (g_p.size()); i++) {
  auto gr = tkv_grad(g_p[i]);
  if (tkv_defined(gr) != 0) {
    tkv_put_grad(i, gr);
  }
  if (tkv_defined(gr) == 0) {
    tkv_zero_grad(i);
  }
  tkv_clear_grad(g_p[i]);
}
tkv_adamw_launch();
tkv_sync_fp16();
g_cur_step = g_cur_step + 1;
return loss_val;
}
