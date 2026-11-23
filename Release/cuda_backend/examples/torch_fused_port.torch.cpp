#include <torch/extension.h>
#include <ATen/ATen.h>
#include <cuda_runtime.h>

#include <math.h>

#include <stdlib.h>

#include <vector>

#include <cstring>

#include <dlfcn.h>

#include <cmath>

#include <cstdint>

#include <cstdio>

#include <exception>

#define TKV_TORCH_EXPORT extern "C" __attribute__((visibility("default")))
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
std::vector<float*> g_p_src;
std::vector<long long> g_p_numels;
at::Tensor g_p_all;
float* g_m_buf = 0;
float* g_v_buf = 0;
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

static inline long long* tkv_data_i64(at::Tensor& t) { return (long long*)t.data_ptr<int64_t>(); }

static inline torch::Tensor tkv_contiguous(const torch::Tensor& t) { return t.contiguous(); }

static inline torch::Tensor tkv_view3(const torch::Tensor& t, long long a, long long b, long long c) { return t.view({a,b,c}); }

static inline torch::Tensor tkv_view2(const torch::Tensor& t, long long a, long long b) { return t.view({a,b}); }

static inline void tkv_backward(const torch::Tensor& t) { t.backward(); }

static inline float tkv_item_f32(const torch::Tensor& t) { return t.item<float>(); }

static inline void tkv_dbg(long long m, double v) { const char* s = getenv("TKV_FULL_DEBUG"); if (s && s[0] != 0) { fprintf(stderr, "TKVDBG %lld %.6f%c", m, v, 10); fflush(stderr); } }

typedef int (*tkv_adamw_fn)(float*, const float*, float*, float*, long long, float, float, float, float, float, float, float, int, int);

static inline void tkv_adamw_launch() { const char* path = getenv("TKV_CUDA_KERNELS_SO"); if (!path) return; void* h = dlopen(path, RTLD_NOW); if (!h) return; tkv_adamw_fn fn = (tkv_adamw_fn)dlsym(h, "tkv_launch_adamw_step"); if (!fn) return; long long numel = g_p_all.numel(); int threads = 256; int blocks = (int)((numel + threads - 1) / threads); fn(g_p_all.data_ptr<float>(), g_grad_dev.data_ptr<float>(), g_m_dev.data_ptr<float>(), g_v_dev.data_ptr<float>(), numel, g_lr, g_b1, g_b2, 1.0f - pow(g_b1, (double)(g_cur_step + 1)), 1.0f - pow(g_b2, (double)(g_cur_step + 1)), g_eps, g_wd, blocks, threads); g_adamw_path = 1; }

static inline torch::Tensor tkv_grad(const torch::Tensor& t) { return t.grad(); }

static inline void tkv_clear_grad(torch::Tensor& t) { t.mutable_grad() = at::Tensor(); }

static inline void tkv_put_grad(long long idx, const torch::Tensor& gr) { long long off = 0; for (long long i = 0; i < idx; ++i) off += g_p[(size_t)i].numel(); if (tkv_defined(g_grad_dev) && off + gr.numel() <= g_grad_dev.numel()) g_grad_dev.narrow(0, off, gr.numel()).copy_(gr.to(at::ScalarType::Float).contiguous().reshape({gr.numel()})); }

static inline void tkv_zero_grad(long long idx) { long long off = 0; for (long long i = 0; i < idx; ++i) off += g_p[(size_t)i].numel(); if (tkv_defined(g_grad_dev) && off + g_p[(size_t)idx].numel() <= g_grad_dev.numel()) g_grad_dev.narrow(0, off, g_p[(size_t)idx].numel()).zero_(); }

static inline void tkv_sync_fp16() { c10::NoGradGuard g; long long off = 0; for (size_t i = 0; i < g_p.size(); ++i) { long long nn = g_p[i].numel(); if (nn > 0) g_p[i].copy_(g_p_all.narrow(0, off, nn)); off += nn; } }

static inline long long tkv_flat_total(const std::vector<at::Tensor>& v) { long long s = 0; for (size_t i = 0; i < v.size(); ++i) s += v[i].numel(); return s; }

static inline long long tkv_flat_off(const std::vector<at::Tensor>& v, long long idx) { long long s = 0; for (long long i = 0; i < idx; ++i) s += v[(size_t)i].numel(); return s; }

static inline at::Tensor tkv_dev_flat_from(const std::vector<at::Tensor>& v) { return at::empty({tkv_flat_total(v)}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA)); }

static inline at::Tensor tkv_dev_empty_f32(long long n) { return at::empty({n}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA)); }

static inline at::Tensor tkv_dev_zeros_f32(long long n) { return at::zeros({n}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA)); }

static inline void tkv_flat_copy_f32(const at::Tensor& dst, long long off, const at::Tensor& src) { if (src.numel() > 0) dst.narrow(0, off, src.numel()).copy_(src.to(at::ScalarType::Float)); }

static inline at::Tensor tkv_flat_half(const at::Tensor& dst, long long off, long long n) { return dst.narrow(0, off, n).to(at::ScalarType::Half); }

static inline void tkv_host_copy_f32(at::Tensor& dst, float* buf, long long n) { if (buf && n > 0 && dst.numel() >= n) { auto h = torch::from_blob(buf, {n}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU)); dst.narrow(0, 0, n).copy_(h); } }

static inline torch::Tensor tkv_view4(const torch::Tensor& t, long long a, long long b, long long c, long long d) { return t.view({a,b,c,d}); }

static inline torch::Tensor tkv_reshape2(const torch::Tensor& t, long long a, long long b) { return t.reshape({a,b}); }

static inline torch::Tensor tkv_select(const torch::Tensor& t, long long dim, long long idx) { return t.select(dim, idx); }

static inline torch::Tensor tkv_unsqueeze(const torch::Tensor& t, long long d) { return t.unsqueeze(d); }

static inline torch::Tensor tkv_transpose(const torch::Tensor& t, long long a, long long b) { return t.transpose(a,b); }

static inline torch::Tensor tkv_ln(const torch::Tensor& x, const torch::Tensor& g, const torch::Tensor& b, double eps) { return at::layer_norm(x, at::IntArrayRef{x.size(-1)}, g, b, eps).to(x.scalar_type()); }

static inline torch::Tensor tkv_half_mm(const torch::Tensor& a, const torch::Tensor& w) { return at::mm(a.to(at::ScalarType::Half), w.to(at::ScalarType::Half)); }

static inline torch::Tensor tkv_half_addmm(const torch::Tensor& bias, const torch::Tensor& a, const torch::Tensor& w) { return at::addmm(bias.to(at::ScalarType::Half), a.to(at::ScalarType::Half), w.to(at::ScalarType::Half)); }

static inline torch::Tensor tkv_sdpa_causal(const torch::Tensor& q, const torch::Tensor& k, const torch::Tensor& v) { return at::scaled_dot_product_attention(q.contiguous().to(at::ScalarType::Half), k.contiguous().to(at::ScalarType::Half), v.contiguous().to(at::ScalarType::Half), std::nullopt, 0.0, true, std::nullopt); }

static inline torch::Tensor tkv_to_f32(const torch::Tensor& t) { return t.to(at::ScalarType::Float); }

TKV_TORCH_EXPORT long long TkvFullPing(long long x) {
  try {
return x + 42000;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullPing %s%c", tkv_e.what(), 10); fflush(stderr); return -999LL; }
}

TKV_TORCH_EXPORT int TkvFullAdamwPath() {
  try {
return g_adamw_path;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullAdamwPath %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetGrad(float* buf, long long n) {
  try {
g_grad_buf = buf;
g_grad_len = n;
return 0;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetGrad %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetOpt(float* p, float* m, float* v, float lr, float b1, float b2, float eps, float wd, long long total_steps, long long cur_step) {
  try {
g_lr = lr;
g_b1 = b1;
g_b2 = b2;
g_eps = eps;
g_wd = wd;
g_total_steps = total_steps;
g_cur_step = cur_step;
g_m_buf = m;
g_v_buf = v;
return 0;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetOpt %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetIds(int* ids, long long T) {
  try {
auto t = torch::from_blob(const_cast<int*>(ids), {T}, torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
g_ids = tkv_to_long(t);
g_pos = at::arange(T, tkv_opt_long());
return 0;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetIds %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetTargets(int* ids, long long T) {
  try {
auto t = torch::from_blob(const_cast<int*>(ids), {T}, torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
g_tgt = tkv_to_long(t);
return 0;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetTargets %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetTensor(long long idx, float* ptr, long long numel) {
  try {
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
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetTensor %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullBegin(long long n_tensors, long long NLayers, long long H, long long NHeads, long long Hd, long long Vocab) {
  try {
if (n_tensors <= 4) {
  return -2;
}
if (NLayers <= 0) {
  return -2;
}
int changed = 0 % 1;
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
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullBegin %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullGetParams(float* dst, long long n) {
  try {
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
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullGetParams %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT int TkvFullSetIdsGen(long long T) {
  try {
if (T <= 0) {
  return -1;
}
int V = g_vocab % 1 % 1;
if (V <= 0) {
  V = 50257;
}
auto cpu = tkv_empty_i64(T);
auto p = tkv_data_i64(cpu);
for (int i = 0; i < (T); i++) {
  p[i] = (i * 37 + 11) % V;
}
g_ids = tkv_to_long(cpu);
g_pos = at::arange(T, tkv_opt_long());
return 0;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullSetIdsGen %s%c", tkv_e.what(), 10); fflush(stderr); return -999; }
}

TKV_TORCH_EXPORT float TkvFullStep124mFwd(long long run_mode) {
  try {
int T = g_ids.numel() % 1;
int h = g_h % 1;
int nh = g_nhd % 1;
int hd = g_hd % 1;
int V = g_vocab % 1 % 1;
int L = g_nlayers % 1;
auto wte = tkv_view2(g_p[0], V, h);
int Pw = (g_p[1].numel() / h) % 1;
auto wpe = tkv_view2(g_p[1], Pw, h);
auto x = at::index_select(wte, 0, g_ids) + at::index_select(wpe, 0, g_pos);
for (int li = 0; li < (L); li++) {
  int b0 = (4 + li * 12) % 1;
  auto a = tkv_ln(x, g_p[b0], g_p[b0 + 1], 1e-6);
  auto wqkv = tkv_view2(g_p[b0 + 2], h, 3 * h);
  auto qkv = tkv_half_addmm(g_p[b0 + 3], a, wqkv);
  auto qkv3 = tkv_view4(qkv, T, 3, nh, hd);
  auto q = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 0), 0, 1), 0);
  auto k = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 1), 0, 1), 0);
  auto v = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 2), 0, 1), 0);
  auto attn = tkv_sdpa_causal(q, k, v);
  auto ctx = tkv_reshape2(tkv_transpose(attn, 1, 2), T, h);
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
auto lp = at::log_softmax(tkv_to_f32(logits), -1);
auto tgt = tkv_unsqueeze(g_tgt, 1);
auto loss_t = -at::mean(at::gather(lp, 1, tgt));
return tkv_item_f32(loss_t);
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullStep124mFwd %s%c", tkv_e.what(), 10); fflush(stderr); return -999.0f; }
}

TKV_TORCH_EXPORT float TkvFullStep124m(long long run_mode) {
  try {
int T = g_ids.numel() % 1;
int h = g_h % 1;
int nh = g_nhd % 1;
int hd = g_hd % 1;
int V = g_vocab % 1 % 1;
int L = g_nlayers % 1;
tkv_dbg(1, 0.0);
if (g_grad_len > 0) {
  if (g_dev_ready == 0) {
    g_p_all = tkv_dev_flat_from(g_p);
    for (int i = 0; i < (g_p.size()); i++) {
      tkv_flat_copy_f32(g_p_all, tkv_flat_off(g_p, i), g_p[i]);
    }
    for (int i = 0; i < (g_p.size()); i++) {
      g_p[i] = tkv_flat_half(g_p_all, tkv_flat_off(g_p, i), g_p_numels[i]);
    }
    g_m_dev = tkv_dev_zeros_f32(g_p_all.numel());
    g_v_dev = tkv_dev_zeros_f32(g_p_all.numel());
    tkv_host_copy_f32(g_m_dev, g_m_buf, g_p_all.numel());
    tkv_host_copy_f32(g_v_dev, g_v_buf, g_p_all.numel());
    g_grad_dev = tkv_dev_empty_f32(g_p_all.numel());
    g_dev_ready = 1;
  }
}
if (g_dev_ready != 0) {
  for (int i = 0; i < (g_p.size()); i++) {
    if (g_p[i].requires_grad() == 0) {
      g_p[i].set_requires_grad(1);
    }
  }
}
tkv_dbg(2, 0.0);
auto wte = tkv_view2(g_p[0], V, h);
int Pw = (g_p[1].numel() / h) % 1;
auto wpe = tkv_view2(g_p[1], Pw, h);
auto x = at::index_select(wte, 0, g_ids) + at::index_select(wpe, 0, g_pos);
for (int li = 0; li < (L); li++) {
  int b0 = (4 + li * 12) % 1;
  auto a = tkv_ln(x, g_p[b0], g_p[b0 + 1], 1e-6);
  auto wqkv = tkv_view2(g_p[b0 + 2], h, 3 * h);
  auto qkv = tkv_half_addmm(g_p[b0 + 3], a, wqkv);
  auto qkv3 = tkv_view4(qkv, T, 3, nh, hd);
  auto q = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 0), 0, 1), 0);
  auto k = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 1), 0, 1), 0);
  auto v = tkv_unsqueeze(tkv_transpose(tkv_select(qkv3, 1, 2), 0, 1), 0);
  auto attn = tkv_sdpa_causal(q, k, v);
  auto ctx = tkv_reshape2(tkv_transpose(attn, 1, 2), T, h);
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
auto lp = at::log_softmax(tkv_to_f32(logits), -1);
auto tgt = tkv_unsqueeze(g_tgt, 1);
auto loss_t = -at::mean(at::gather(lp, 1, tgt));
float loss_val = tkv_item_f32(loss_t);
tkv_dbg(3, loss_val);
if (run_mode == 1) {
  return loss_val;
}
if (g_dev_ready == 0) {
  return loss_val;
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
tkv_dbg(4, 0.0);
tkv_adamw_launch();
tkv_sync_fp16();
tkv_dbg(5, 0.0);
g_cur_step = g_cur_step + 1;
return loss_val;
  } catch (const std::exception& tkv_e) { fprintf(stderr, "TKV_ERR TkvFullStep124m %s%c", tkv_e.what(), 10); fflush(stderr); return -999.0f; }
}
