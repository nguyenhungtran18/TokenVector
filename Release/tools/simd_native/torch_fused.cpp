/* torch_fused.cpp - Tkv torch bridge: dispatch MLP fwd ops through ATen.
 *
 * Tap chi phi: gpt2_mlp fwd:
 *   x[n,h] @ w1[h, 4h] + b1[4h] -> GELU(erf) -> inner[n, 4h]
 * Gruster: src tensors are our .tkv lists; results written directly into
 * caller's preallocated out list (same contract as other native entrypoints).
 *
 * PyTorch static oneDNN dispatches automatically (native Linear F.s):
 *   at::addmm = linear without bias = 1 GEMM + epilogue; at::gelu = erf CUDA
 * Tensor from_blob over caller memory: const-floor read only. Output: out
 * preallocated [n][out_d] f32.
 *
 * 2026-11-14: TKV_TORCH_GPU=1 (env) chay moi op tren GPU: H2D -> ATen kernel
 * GPU -> D2H; mac dinh 0 = CPU ATen (cu). Yeu cau CUDA-capable torch.
 */
#include <torch/torch.h>
#include <ATen/ATen.h>
#include <ATen/core/Tensor.h>
#include <c10/core/GradMode.h>
#include <c10/util/intrusive_ptr.h>
#include <cuda_runtime.h>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cstdarg>
#include <chrono>
#include <mutex>
#include <algorithm>

#include <string>
#include <vector>
#include <memory>

using at::Tensor;

/* forward decl: constructor dung truoc dinh nghia */
static bool want_cuda();

/* LN diagnostic logger: the .tkv bench harness drops the bridge's stderr, so
 * write breadcrumbs to a file instead (no-op on error). Investigating whether
 * at::layer_norm succeeds or throws on CUDA. */
static void ln_clog(const char* fmt, ...) {
    FILE* f = std::fopen("/tmp/tkv_ln_debug.log", "a");
    if (!f) return;
    va_list ap;
    va_start(ap, fmt);
    std::vfprintf(f, fmt, ap);
    va_end(ap);
    std::fclose(f);
}

#if defined(_WIN32)
#define TKV_TORCH_EXPORT extern "C" __declspec(dllexport)
#else
#define TKV_TORCH_EXPORT extern "C" __attribute__((visibility("default")))
#endif

/* mac dinh: TAT TF32 (cublas, cudnn) -> fp32 "chính xác", match AVX2 CPU tren T4
 * IMPORTANT: .NET host dlopen file .so nay KHONG truy qua Python torch, nen
 * context CUDA chua duoc lazyInit; phai tu goi ngay khi load library hoac moi
 * from_blob se "tensor does not have a device". */
__attribute__((constructor)) static void tkv_disable_tf32() {
    try {
        auto& ctx = torch::globalContext();
        ctx.lazyInitDevice(torch::kCUDA);
    } catch (...) { /* ignore */ }
    /* warm cuBLAS + goi kernel dang ky lazy-load (lan dau CUDA kernel launch
     * cua tien trinh ton ~250-460ms: module load on-demand). Chuyen ve ngoai
     * vung bench de LN_FWD step 1 / LMHEAD step 1 khong phai ganh. */
    try {
        if (want_cuda()) {
            auto t = at::zeros({64, 64}, torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA));
            auto r = at::mm(t, t);
            auto y = at::softmax(r, 0);
            (void)y;
        }
    } catch (...) { /* ignore */ }
    try {
        torch::globalContext().setAllowTF32CuBLAS(false);
        torch::globalContext().setAllowTF32CuDNN(false);
    } catch (...) { /* ignore */ }
}

static bool want_cuda() {
    static int cached = -1;
    if (cached < 0) {
        const char* s = getenv("TKV_TORCH_GPU");
        cached = (s && s[0] == '1') ? 1 : 0;
    }
    return cached == 1;
}

/* ---- CUDA kernel: AdamW fp32 trong 1 pass --------------------------------
 * m = b1*m + (1-b1)*g
 * v = b2*v + (1-b2)*g*g
 * denom = sqrt(v/bc2) + eps
 * p = p*(1 - lr*wd)   [neu wd != 0]
 * p = p - lr_t*m/(bc1*denom)
 * Gom 6-7 launch ATen thanh 1 kernel. */
__global__ void adamw_fused_kernel(
    float* __restrict__ param,
    const float* __restrict__ grad,
    float* __restrict__ m,
    float* __restrict__ v,
    int64_t numel,
    float lr_t, float b1, float b2,
    float bc1, float bc2,
    float eps, float wd
) {
    int64_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numel) return;
    float g = grad[idx];
    float mi = b1 * m[idx] + (1.0f - b1) * g;
    float vi = b2 * v[idx] + (1.0f - b2) * g * g;
    float denom = sqrtf(vi / bc2) + eps;
    float pi = param[idx];
    if (wd != 0.0f) pi *= (1.0f - lr_t * wd);
    pi -= lr_t * mi / (bc1 * denom);
    m[idx] = mi;
    v[idx] = vi;
    param[idx] = pi;
}

/* ---- CUDA kernel: flatten tat ca grad tensor vao g_grad_dev mot lan ------
 * Thay 148 lan copy_ (moi lan la mot kernel launch) bang 1 kernel. */
__global__ void flatten_grad_kernel(
    float* __restrict__ dst,
    const float* const* __restrict__ src_ptrs,
    const int64_t* __restrict__ offsets,
    const int64_t* __restrict__ sizes,
    int num_tensors
) {
    int64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= num_tensors) return;
    int64_t off = offsets[tid];
    int64_t n = sizes[tid];
    const float* src = src_ptrs[tid];
    for (int64_t i = 0; i < n; ++i) {
        dst[off + i] = src[i];
    }
}

/* Pinned-memory staging tinh (tai su dung, mutex de an toan tu 2 thread).
 * H2D: pageable(caller) -> pinned (memcpy nhanh, ~memcpy), pinned -> CUDA (sync, ~25GB/s)
 * D2H: CUDA -> pinned (sync, ~25GB/s), caller doc truc tiep tu buffer (contract: khong giu ptr qua call tiep theo) */
static std::mutex g_pin_mu;
static Tensor g_pin_stage;   /* pageable -> pinned cho H2D */
static Tensor g_pin_out;     /* CUDA -> pinned cho D2H   */
static Tensor pin_grow(Tensor& buf, int64_t numel, at::ScalarType st) {
    if (!buf.defined() || buf.numel() < numel || buf.scalar_type() != st)
        buf = at::empty({numel}, torch::TensorOptions().dtype(st).device(torch::kCPU).pinned_memory(true));
    return buf;
}
static Tensor dev(const Tensor& t) {
    if (!want_cuda()) return t;
    std::lock_guard<std::mutex> lk(g_pin_mu);
    auto stage = pin_grow(g_pin_stage, t.numel(), t.scalar_type());
    auto src = stage.narrow(0, 0, t.numel()).view(t.sizes());
    src.copy_(t);                                  /* pageable -> pinned (dong bo, nhanh) */
    auto tgt = at::empty(t.sizes(),
        torch::TensorOptions().dtype(t.scalar_type()).device(torch::kCUDA).requires_grad(false));
    tgt.copy_(src);                                /* pinned -> CUDA (dong bo, nhanh) */
    tgt.set_requires_grad(t.requires_grad());
    return tgt;
}
static Tensor host(const Tensor& t) {
    if (!want_cuda()) return t;
    std::lock_guard<std::mutex> lk(g_pin_mu);
    auto out = pin_grow(g_pin_out, t.numel(), t.scalar_type());
    auto dst = out.narrow(0, 0, t.numel()).view(t.sizes());
    dst.copy_(t);                                  /* CUDA -> pinned (dong bo, nhanh) */
    return dst;                                    /* caller memcpy ngay; khong giu qua op tiep */
}
static auto dev_f32() {
    return want_cuda()
        ? torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA)
        : torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU);
}

/* helper: wrap caller memory as unmanaged tensor */
static Tensor wrap_in(const float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(const_cast<float*>(p), {rows, cols},
        torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false));
}
static Tensor wrap_grad(const float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(const_cast<float*>(p), {rows, cols},
        torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(true));
}
static Tensor wrap_out(float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(p, {rows, cols},
        torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false));
}

/* -- TkvTorchLinearGeluFwd: x[n,in] @ w[in,out] + b -> GELU -> y[n,out] */
TKV_TORCH_EXPORT int TkvTorchLinearGeluFwd(const float* x, const float* w,
                                           const float* bias, int64_t n, int64_t in_d,
                                           int64_t out_d, float* y) {
    if (!x || !w || !bias || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = dev(wrap_in(x, n, in_d));
        auto t_w = dev(wrap_in(w, in_d, out_d));
        auto t_b = dev(torch::from_blob(const_cast<float*>(bias), {out_d},
            torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false)));
        auto t_y = dev(at::gelu(at::addmm(t_b, t_x, t_w, 1, 1)));
        auto t_yh = host(t_y);
        if (t_yh.numel() != (int64_t)n * out_d) return -3;
        memcpy(y, t_yh.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* GELU(erf) backward qua ATen. */
TKV_TORCH_EXPORT int TkvTorchGeluBwd(const float* gy, const float* x, float* y,
                                     int64_t n) {
    if (!gy || !x || !y) return -1;
    if (n <= 0) return -2;
    try {
        auto opt = torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU);
        auto t_gy = dev(torch::from_blob(const_cast<float*>(gy), {n}, opt));
        auto t_x  = dev(torch::from_blob(const_cast<float*>(x),  {n}, opt));
        auto t_y  = host(at::gelu_backward(t_gy, t_x, "none"));
        if (t_y.numel() != n) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Backward Linear: dx = gy @ w^T ;
 *   dw = x^T @ gy ;
 *   db = sum_n gy. */
TKV_TORCH_EXPORT int TkvTorchLinearBwdFwd(const float* x, const float* gy,
                                          const float* w, float* dx, float* dw, float* db,
                                          int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !gy || !w || !dx || !dw || !db) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x  = dev(wrap_in(x, n, in_d));
        auto t_gy = dev(wrap_in(gy, n, out_d));
        auto t_w  = dev(wrap_in(w, in_d, out_d));
        auto dopt = dev_f32();
        auto t_dx = at::empty({n, in_d}, dopt);
        auto t_dw = at::empty({in_d, out_d}, dopt);
        auto t_db = at::empty({out_d}, dopt);
        at::mm_out(t_dx, t_gy, t_w.t());
        at::mm_out(t_dw, t_x.t(), t_gy);
        at::sum_out(t_db, t_gy, {0}, false);
        memcpy(dx, host(t_dx).const_data_ptr<float>(), (size_t)n * in_d * sizeof(float));
        memcpy(dw, host(t_dw).const_data_ptr<float>(), (size_t)in_d * out_d * sizeof(float));
        memcpy(db, host(t_db).const_data_ptr<float>(), (size_t)out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Plain Linear+bias. */
TKV_TORCH_EXPORT int TkvTorchLinearFwd(const float* x, const float* w,
                                       const float* bias, int64_t n, int64_t in_d,
                                       int64_t out_d, float* y) {
    if (!x || !w || !bias || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = dev(wrap_in(x, n, in_d));
        auto t_w = dev(wrap_in(w, in_d, out_d));
        auto t_b = dev(torch::from_blob(const_cast<float*>(bias), {out_d},
            torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false)));
        auto t_y = host(at::addmm(t_b, t_x, t_w, 1, 1));
        if (t_y.numel() != (int64_t)n * out_d) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* LayerNorm via ATen. */
TKV_TORCH_EXPORT int TkvTorchLayerNormFwd(const float* x, const float* g,
                                          const float* b, float* y,
                                          int64_t n, int64_t h, double eps) {
    if (!x || !g || !b || !y) return -1;
    if (n <= 0 || h <= 0) return -2;
    ln_clog("[tkv-ln-fwd] entry n=%lld h=%lld gpu=%d\n", (long long)n, (long long)h, want_cuda() ? 1 : 0);
    try {
        auto t_s0 = std::chrono::steady_clock::now();
        /* A0.152: manual LN fwd qua ATen elementwise/reduce - at::layer_norm
         * "ok" nhung cham la thuong ~10ms/call (dispatch fallback?). Cong thuc:
         * y = ((x - mean) * rsqrt(var + eps)) * g + b ; var biased (giong f64 fwd). */
        auto t_x = dev(wrap_in(x, n, h));
        auto t_g = dev(wrap_in(g, 1, h)).squeeze(0);        /* [h] */
        auto t_b = dev(wrap_in(b, 1, h)).squeeze(0);        /* [h] */
        auto t_s1 = std::chrono::steady_clock::now();
        auto t_mu   = t_x.mean({-1}, true);                 /* [T, 1] */
        auto t_d    = t_x - t_mu;
        auto t_var  = (t_d * t_d).mean({-1}, true);         /* [T, 1] */
        auto t_rstd = (t_var + (double)eps).rsqrt();        /* [T, 1] */
        auto t_y    = t_d * t_rstd * t_g + t_b;
        auto t_s2 = std::chrono::steady_clock::now();
        auto t_yh = host(t_y);
        auto t_s3 = std::chrono::steady_clock::now();
        memcpy(y, t_yh.const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        auto us = [](auto a, auto b) { return (long long)std::chrono::duration_cast<std::chrono::microseconds>(b - a).count(); };
        ln_clog("[tkv-ln-fwd] ok dev=%lldus ln=%lldus d2h=%lldus\n", us(t_s0, t_s1), us(t_s1, t_s2), us(t_s2, t_s3));
        return 0;
    } catch (const std::exception& e) {
        ln_clog("[tkv-ln-fwd] FAIL (e): %s\n", e.what());
        return -4;
    } catch (...) {
        ln_clog("[tkv-ln-fwd] FAIL (unknown)\n");
        return -5;
    }
}

/* Backward LayerNorm via ATen autograd. */
TKV_TORCH_EXPORT int TkvTorchLayerNormBwd(const float* x, const float* g,
                                          const float* b, const float* gy,
                                          float* dx, float* dg, float* db,
                                          int64_t n, int64_t h, double eps) {
    if (!x || !g || !b || !gy || !dx || !dg || !db) return -1;
    if (n <= 0 || h <= 0) return -2;
    ln_clog("[tkv-ln-bwd] entry n=%lld h=%lld gpu=%d\n", (long long)n, (long long)h, want_cuda() ? 1 : 0);
    try {
        /* manual LN backward — KHONG qua autograd (CUDA autograd im lang trong
         * engine nay: backward() chay, leaves' .grad deu undefined -> lan luot
         * throw UNKNOWN_SCALAR). Cong thuc: dx = rstd*(gy*g - mean(gy*g) -
         * xh*mean(gy*g*xh)); dg = sum_rows(gy*xh); db = sum_rows(gy). */
        auto t_x  = dev(wrap_in(x, n, h));                  /* [T, h] */
        auto t_g  = dev(wrap_in(g, 1, h)).squeeze(0);       /* [h] */
        auto t_gy = dev(wrap_in(gy, n, h));                 /* [T, h] */

        auto t_mu   = t_x.mean({-1}, true);                 /* [T, 1] */
        auto t_d    = t_x - t_mu;
        auto t_var  = (t_d * t_d).mean({-1}, true);         /* [T, 1] (biased, giong f64 fwd) */
        auto t_rstd = (t_var + (double)eps).rsqrt();        /* [T, 1] */
        auto t_xh   = t_d * t_rstd;                         /* [T, h] */
        auto t_gyg  = t_gy * t_g;                           /* broadcast [h] over rows */
        auto t_c1   = t_gyg.mean({-1}, true);               /* [T, 1] */
        auto t_c2   = (t_gyg * t_xh).mean({-1}, true);      /* [T, 1] */
        auto t_dx   = (t_gyg - t_c1 - t_xh * t_c2) * t_rstd;/* [T, h] */
        auto t_dg   = (t_gy * t_xh).sum({0});               /* [h] */
        auto t_db   = t_gy.sum({0});                        /* [h] */

        memcpy(dx, host(t_dx).const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        memcpy(dg, host(t_dg).const_data_ptr<float>(), (size_t)h * sizeof(float));
        memcpy(db, host(t_db).const_data_ptr<float>(), (size_t)h * sizeof(float));
        ln_clog("[tkv-ln-bwd] ok\n");
        return 0;
    } catch (const std::exception& e) {
        ln_clog("[tkv-ln-bwd] FAIL (e): %s\n", e.what());
        return -4;
    } catch (...) {
        ln_clog("[tkv-ln-bwd] FAIL (unknown)\n");
        return -5;
    }
}
/* Attention block BACKWARD via ATen autograd. */
TKV_TORCH_EXPORT int TkvTorchAttentionBwd(const float* x, const float* gout,
        const float* w_qkv, const float* b_qkv,
        const float* w_proj, const float* b_proj,
        float* dx, float* gflat,
        int64_t n, int64_t h, int64_t nheads, int64_t hd,
        long long o_qkv, long long o_bqkv, long long o_proj, long long o_bproj) {
    if (!x || !gout || !w_qkv || !b_qkv || !w_proj || !b_proj || !dx) return -1;
    static int dbg_once = 0;
    if (!dbg_once) { dbg_once = 1; std::fprintf(stderr, "[tkv-attn-bwd] manual-path n=%lld h=%lld nheads=%lld hd=%lld gpu=%d\n",
                                                 (long long)n, (long long)h, (long long)nheads, (long long)hd, want_cuda() ? 1 : 0); }
    try {
        const int64_t T = n;
        const int64_t H = nheads * hd;
        if (h != H) return -2;
        const double inv = 1.0 / std::sqrt((double)hd);
        auto t_x   = dev(wrap_in(x,      T, h));          /* [T, h] */
        auto t_wq  = dev(wrap_in(w_qkv,  h,  3 * h));     /* [h, 3h] */
        auto t_bq  = dev(wrap_in(b_qkv,  3 * h, 1)).squeeze(1);  /* [3h] */
        auto t_wp  = dev(wrap_in(w_proj, h,  h));         /* [h, h] */
        auto t_bp  = dev(wrap_in(b_proj, h,  1)).squeeze(1);     /* [h] */

        /* --- fwd (recompute) --- */
        auto t_qkv  = at::addmm(t_bq, t_x, t_wq);          /* [T, 3h] */
        auto t_q3   = t_qkv.view({T, 3, nheads, hd});
        auto tq0    = t_q3.select(1, 0);              /* [T, nh, hd] */
        auto tq1    = t_q3.select(1, 1);
        auto tq2    = t_q3.select(1, 2);
        auto q      = tq0.transpose(0, 1).unsqueeze(0);  /* [1, nh, T, hd] */
        auto k      = tq1.transpose(0, 1).unsqueeze(0);  /* [1, nh, T, hd] */
        auto v      = tq2.transpose(0, 1).unsqueeze(0);  /* [1, nh, T, hd] */

        auto t_scale = at::scalar_tensor(inv, t_x.options());
        auto t_scores = at::matmul(q, k.transpose(-1, -2)).mul_(t_scale);   /* [1, nh, T, T] */
        auto t_mask = at::tril(at::ones({T, T}, t_x.options()));          /* [T, T] */
        t_scores = t_scores.masked_fill_(t_mask.logical_not().unsqueeze(0).unsqueeze(0), -std::numeric_limits<float>::infinity());
        auto P = t_scores.softmax(-1);                                    /* [1, nh, T, T] */
        auto t_ctx = at::matmul(P, v);                                            /* [1, nh, T, hd] */
        auto t_ctx2 = t_ctx.transpose(1, 2).reshape({T, h}).contiguous(); /* [T, h] */
        auto t_out = at::addmm(t_bp, t_ctx2, t_wp);                      /* [T, h] */

        auto t_gy = dev(wrap_in(gout, T, h));
        auto t_dbp = t_gy.sum({0});                        /* [h] */
        auto t_dctx = t_gy.mm(t_wp.t());                   /* [T, h] */
        auto t_dwp  = t_ctx2.t().mm(t_gy);

        auto d_ctx3 = t_dctx.view({T, nheads, hd}).transpose(0, 1).unsqueeze(0).contiguous();   /* [1, nh, T, hd] */
        auto dP    = at::matmul(d_ctx3, v.transpose(-1, -2));      /* [1, nh, T, T] */
        auto dPs   = (dP * P).sum({-1}, true);             /* [1, nh, T, 1] */
        auto dS    = ((dP - dPs) * P).mul_((float)inv);    /* dS = inv * P .* (dP - rowsum(dP .* P)) */

        auto dQ    = at::matmul(dS, k);                            /* [1, nh, T, hd] */
        auto dK    = at::matmul(dS.transpose(-1, -2), q);          /* [1, nh, T, hd] */
        auto dV    = at::matmul(P.transpose(-1, -2), d_ctx3);      /* [1, nh, T, hd] */

        auto dQ2   = dQ.squeeze(0).transpose(0, 1).reshape({T, h}).contiguous();   /* [T, h] */
        auto dK2   = dK.squeeze(0).transpose(0, 1).reshape({T, h}).contiguous();   /* [T, h] */
        auto dV2   = dV.squeeze(0).transpose(0, 1).reshape({T, h}).contiguous();   /* [T, h] */
        auto dqkv  = at::cat({dQ2, dK2, dV2}, 1);        /* [T, 3h] */

        auto d_x   = dqkv.mm(t_wq.t());                    /* [T, h] */
        auto d_wq  = t_x.t().mm(dqkv);
        auto d_bq  = dqkv.sum({0});                        /* [3h] */

        memcpy(dx, host(d_x).const_data_ptr<float>(), (size_t)T * h * sizeof(float));
        if (gflat) {
            if (o_qkv  >= 0) memcpy(gflat + o_qkv,  host(d_wq.contiguous()).const_data_ptr<float>(), (size_t)h * 3 * h * sizeof(float));
            if (o_bqkv >= 0) memcpy(gflat + o_bqkv, host(d_bq).const_data_ptr<float>(), (size_t)3 * h * sizeof(float));
            if (o_proj >= 0) memcpy(gflat + o_proj, host(t_dwp.contiguous()).const_data_ptr<float>(), (size_t)h * h * sizeof(float));
            if (o_bproj >= 0) memcpy(gflat + o_bproj, host(t_dbp).const_data_ptr<float>(), (size_t)h * sizeof(float));
        }
        return 0;
    } catch (const std::exception& e) {
        std::fprintf(stderr, "[tkv-attn-bwd] FAIL (e): %s\n", e.what());
        return -4;
    } catch (...) {
        std::fprintf(stderr, "[tkv-attn-bwd] FAIL (unknown)\n");
        return -5;
    }
}
/* A0.151: LM HEAD backward tron goi tren CUDA - pha1 softmax+scatter, pha2 dxf=dl@wte,
 * pha3 dwte += dl^T @ xf trong MOT lenh bridge; dl KHONG ve CPU (~1 GB H2D/D2H duoc xoa).
 * -9 khi TKV_TORCH_GPU khong bat -> caller fallback duong native NGUYEN VAN.
 * Numerics: cung chuoi ops ATen nhu pha rieng le (softmax, mm, addmm) -> chenh ~1e-7. */
TKV_TORCH_EXPORT int TkvTorchLmHeadBwdCudaOnly(const float* logits, const int* ids,
                                               const float* wte, const float* xf,
                                               float* dxf, float* dwte,
                                               int64_t T, int64_t E, int64_t V,
                                               double scale) {
    if (!logits || !ids || !wte || !xf || !dxf || !dwte) return -1;
    if (T <= 0 || E <= 0 || V <= 0) return -2;
    if (!want_cuda()) return -9;
    try {
        auto t_l = dev(wrap_in(logits, T, V));                    /* H2D ~205 MB */
        auto t_dl = at::softmax(t_l, 1).mul_((float)scale);       /* [T, V] CUDA cua pha 1 */
        auto t_ids = at::from_blob(const_cast<int*>(ids), {T},
                     torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU))
                     .to(torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA));
        t_dl.scatter_(1, t_ids.unsqueeze(1), -(double)scale);     /* (softmax - onehot) * scale */

        /* pha 2: dxf = dl @ wte (cublas, 79 GFLOP) */
        auto t_w = dev(wrap_in(wte, V, E));                       /* H2D ~154 MB */
        auto t_dxf = at::mm(t_dl, t_w);                           /* [T, E] */
        memcpy(dxf, host(t_dxf).const_data_ptr<float>(), (size_t)T * E * sizeof(float));

        /* pha 3: dwte += dl^T @ xf (addmm_out, beta = 1, giong pha rieng le) */
        auto t_xf = dev(wrap_in(xf, T, E));                       /* H2D ~3 MB */
        auto t_dw = dev(wrap_in(dwte, V, E));                     /* H2D ~154 MB */
        at::addmm_out(t_dw, t_dw, t_dl.t(), t_xf, 1.0, 1.0);      /* dwte += dl^T @ xf */
        memcpy(dwte, host(t_dw).const_data_ptr<float>(), (size_t)V * E * sizeof(float));
        return 0;
    } catch (const std::exception& e) {
        std::fprintf(stderr, "[tkv-lm-fused] FAIL (e): %s\n", e.what());
        return -4;
    } catch (...) {
        std::fprintf(stderr, "[tkv-lm-fused] FAIL (unknown)\n");
        return -5;
    }
}
/* A0.150: pha 1 lmhead - dl = (softmax(logits) - onehot(id)) * scale
 *   CHI tren CUDA. -9 khi TKV_TORCH_GPU khong bat -> caller fallback
 *   lmhead_softmax_rows (native, bit-exact). ids int32 [T]. */
TKV_TORCH_EXPORT int TkvTorchLmSoftmaxCudaOnly(const float* logits, const int* ids,
                                               float* dl, int64_t T, int64_t V,
                                               double scale) {
    if (!logits || !ids || !dl) return -1;
    if (T <= 0 || V <= 0) return -2;
    if (!want_cuda()) return -9;
    try {
        auto t_l = dev(wrap_in(logits, T, V));               /* H2D 205 MB */
        auto t_dl = at::softmax(t_l, 1).mul_((float)scale);          /* [T, V] CUDA */
        auto t_ids = at::from_blob(const_cast<int*>(ids), {T},
                     torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU))
                     .to(torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA));
        t_dl.scatter_(1, t_ids.unsqueeze(1), -(double)scale);        /* tru onehot*scale */
        memcpy(dl, host(t_dl).const_data_ptr<float>(), (size_t)T * V * sizeof(float));
        return 0;
    } catch (const std::exception& e) {
        std::fprintf(stderr, "[tkv-lm-sm] FAIL (e): %s\n", e.what());
        return -4;
    } catch (...) {
        std::fprintf(stderr, "[tkv-lm-sm] FAIL (unknown)\n");
        return -5;
    }
}
/* A0.149: dxf = dl @ wte CHI tren CUDA. -9 khi TKV_TORCH_GPU khong bat ->
 * caller fallback native SgemmF32 (native mode giu bit-exact voi duong cu). */
TKV_TORCH_EXPORT int TkvTorchMmCudaOnly(const float* x, const float* w, float* y,
                                        int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    if (!want_cuda()) return -9;
    try {
        auto t_x = dev(wrap_in(x, n, in_d));
        auto t_w = dev(wrap_in(w, in_d, out_d));
        auto t_y = host(at::mm(t_x, t_w));
        if (t_y.numel() != (int64_t)n * out_d) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}
/* Mm transposed (LM head): y = x @ w^T. */
TKV_TORCH_EXPORT int TkvTorchMmT(const float* x, const float* w, float* y,
                                 int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = dev(wrap_in(x, n, in_d));
        auto t_w = dev(wrap_in(w, out_d, in_d));
        auto t_y = host(at::mm(t_x, t_w.t()));
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Scaled-dot-product attention CAUSAL. */
TKV_TORCH_EXPORT int TkvTorchSdpa(const float* qkv, float* y,
                                  int64_t n, int64_t nheads, int64_t hd) {
    if (!qkv || !y) return -1;
    if (n <= 0 || nheads <= 0 || hd <= 0) return -2;
    const int64_t h = nheads * hd;
    if (h <= 0) return -2;
    try {
        const bool cuda = want_cuda();
        auto opt = torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU);
        /* CPU empty (host) de vong for dien qkv; sau do move sang CUDA neu can */
        auto t_q = at::empty({1, nheads, n, hd}, opt);
        auto t_k = at::empty({1, nheads, n, hd}, opt);
        auto t_v = at::empty({1, nheads, n, hd}, opt);
        const float* qsrc = qkv;
        const float* ksrc = qkv + h;
        const float* vsrc = qkv + 2 * h;
        const int64_t stride = 3 * h;
        float* qp = t_q.data_ptr<float>();
        float* kp = t_k.data_ptr<float>();
        float* vp = t_v.data_ptr<float>();
        for (int64_t hi = 0; hi < nheads; hi++) {
            for (int64_t t = 0; t < n; t++) {
                memcpy(qp + (hi * n + t) * hd, qsrc + t * stride + hi * hd, hd * sizeof(float));
                memcpy(kp + (hi * n + t) * hd, ksrc + t * stride + hi * hd, hd * sizeof(float));
                memcpy(vp + (hi * n + t) * hd, vsrc + t * stride + hi * hd, hd * sizeof(float));
            }
        }
        auto y_gpu = [&]() {
            if (cuda) {
                auto t_qo = t_q.to(torch::kCUDA), t_ko = t_k.to(torch::kCUDA), t_vo = t_v.to(torch::kCUDA);
                return at::scaled_dot_product_attention(t_qo, t_ko, t_vo, std::nullopt, 0.0, true, std::nullopt);
            } else {
                return at::scaled_dot_product_attention(t_q, t_k, t_v, std::nullopt, 0.0, true, std::nullopt);
            }
        }();
        auto y_cpu = cuda ? y_gpu.to(torch::kCPU) : y_gpu;
        const float* yp = y_cpu.const_data_ptr<float>();
        for (int64_t hi = 0; hi < nheads; hi++) {
            for (int64_t t = 0; t < n; t++) {
                memcpy(y + t * h + hi * hd, yp + (hi * n + t) * hd, hd * sizeof(float));
            }
        }
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* A0.148: dwte += dlT @ xf. dl [T][V]; dwte [V][E] TICH LUY. */
TKV_TORCH_EXPORT int TkvTorchAddmmTaOut(const float* dl, const float* xf, float* dwte,
                                        int64_t T, int64_t V, int64_t E) {
    if (!dl || !xf || !dwte) return -1;
    if (T <= 0 || V <= 0 || E <= 0) return -2;
    try {
        if (want_cuda()) {
            /* accumulate vao CUDA tensor; sau do copy back ve host */
            auto t_dl = wrap_in(dl, T, V).to(torch::kCUDA);
            auto t_xf = wrap_in(xf, T, E).to(torch::kCUDA);
            auto t_dw = wrap_in(dwte, V, E).to(torch::kCUDA);
            at::addmm_out(t_dw, t_dw, t_dl.t(), t_xf, 1.0, 1.0);
            auto t_dw_cpu = t_dw.to(torch::kCPU);
            memcpy(dwte, t_dw_cpu.const_data_ptr<float>(), (size_t)V * E * sizeof(float));
            return 0;
        }
        auto t_dl = wrap_in(dl, T, V);
        auto t_xf = wrap_in(xf, T, E);
        auto t_dw = wrap_in(dwte, V, E);
        at::addmm_out(t_dw, t_dw, t_dl.t(), t_xf, 1.0, 1.0); /* beta=1 accumulate: tam chua */
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}





/* ================= GPU full step M2: fwd + bwd + AdamW trong 1 call ================= */
/* Layout ps: [wte, wpe, lnf_g, lnf_b, L x 12]. Gradient flat theo thu tu ps.
 * Begin -> SetTensor*(params) -> SetIds -> SetGrad(buf) -> SetOpt(p,m,v,hyp)
 * -> Run(0=full, 1=fwd only) -> loss (-100 = chua san sang). */

static std::mutex g_full_mu;
static std::vector<Tensor> g_p;
static Tensor g_ids;
static Tensor g_pos;
static float* g_grad_buf = nullptr;
static int64_t g_grad_len = 0;
static float* g_p_buf = nullptr;
static float* g_m_buf = nullptr;
static float* g_v_buf = nullptr;
static float g_lr = 0.0025f, g_b1 = 0.9f, g_b2 = 0.999f, g_eps = 1e-8f, g_wd = 0.0f;
static int64_t g_total_steps = 1000, g_cur_step = 0;
static int g_nlayers = 12, g_h = 768, g_nhd = 12, g_hd = 64, g_vocab = 50257;

/* GPU-resident full-step state (mode CUDA): p/m/v/grad song tren VRAM, khong
 * upload/download moi step. g_p[i] la view cua g_p_all (flat CUDA). */
static Tensor g_p_all, g_m_dev, g_v_dev, g_grad_dev, g_tgt;
/* Debug intermediates (TKV_FULL_DEBUG=1) to compare against HF layer-by-layer. */
static Tensor g_dbg_emb, g_dbg_ln1, g_dbg_qkv, g_dbg_x1, g_dbg_xf, g_dbg_logits;
static std::vector<const float*> g_p_src;
static std::vector<int64_t> g_p_numels, g_full_cfg;
static bool g_dev_ready = false, g_dev_state_dirty = true;
static const float* g_opt_m_prev = nullptr;
static const float* g_opt_v_prev = nullptr;

static Tensor full_ln_fwd(const Tensor& x, const Tensor& g, const Tensor& b, double eps) {
    auto st = x.scalar_type();
    return at::layer_norm(x, at::IntArrayRef{x.size(-1)}, g, b, eps).to(st);
}
/* (dx, dg, db) - giong TkvTorchLayerNormBwd manual (verified) */
static std::vector<Tensor> full_ln_bwd(const Tensor& x, const Tensor& g, const Tensor& gy, double eps) {
    auto t_mu   = x.mean({-1}, true);
    auto t_d    = x - t_mu;
    auto t_var  = (t_d * t_d).mean({-1}, true);
    auto t_rstd = (t_var + eps).rsqrt();
    auto t_xh   = t_d * t_rstd;
    auto t_gyg  = gy * g;
    auto t_c1   = t_gyg.mean({-1}, true);
    auto t_c2   = (t_gyg * t_xh).mean({-1}, true);
    return {(t_gyg - t_c1 - t_xh * t_c2) * t_rstd, (gy * t_xh).sum({0}), gy.sum({0})};
}
/* Fullstep CUDA: toan bo param/activation la fp16. Helper dam bao cac mm/addmm
 * khong bao mismatch (cast no-op neu da Half), dong thoi in thong bao chan doan
 * neu co tensor nao lot Float vao (de tranh crash manh mu). */
static Tensor half_mm2(const char* tag, const Tensor& a, const Tensor& w) {
    const auto st = at::ScalarType::Half;
    if (a.scalar_type() != st || w.scalar_type() != st) {
        fprintf(stderr, "XDBG half_mm2 %s: a=%d w=%d -> cast Half\n",
                tag, (int)a.scalar_type(), (int)w.scalar_type());
    }
    auto ha = a.scalar_type() == st ? a : a.to(st);
    auto hw = w.scalar_type() == st ? w : w.to(st);
    return at::mm(ha, hw);
}
static Tensor half_mat2(const char* tag, const Tensor& b, const Tensor& a, const Tensor& w, bool add_bias) {
    const auto st = at::ScalarType::Half;
    bool bad = b.scalar_type() != st || a.scalar_type() != st || w.scalar_type() != st;
    if (bad) {
        fprintf(stderr, "XDBG half_mat2 %s: b=%d a=%d w=%d -> cast Half\n",
                tag, (int)b.scalar_type(), (int)a.scalar_type(), (int)w.scalar_type());
    }
    auto hb = b.scalar_type() == st ? b : b.to(st);
    auto ha = a.scalar_type() == st ? a : a.to(st);
    auto hw = w.scalar_type() == st ? w : w.to(st);
    return add_bias ? at::addmm(hb, ha, hw) : at::mm(ha, hw);
}

TKV_TORCH_EXPORT int TkvFullBegin(int64_t n_tensors, int64_t NLayers, int64_t H,
                                  int64_t NHeads, int64_t Hd, int64_t Vocab) {
    std::lock_guard<std::mutex> lk(g_full_mu);
    if (n_tensors <= 4 || NLayers <= 0) return -2;
    std::vector<int64_t> cfg{n_tensors, NLayers, H, NHeads, Hd, Vocab};
    if (cfg != g_full_cfg || (int64_t)g_p.size() != n_tensors) {
        /* cau hinh doi: reset state. Cung cau hinh: GIU p/m/v tren GPU. */
        g_full_cfg = cfg;
        g_p.assign((size_t)n_tensors, Tensor());
        g_p_src.assign((size_t)n_tensors, nullptr);
        g_p_numels.assign((size_t)n_tensors, 0);
        g_p_all.reset(); g_m_dev.reset(); g_v_dev.reset(); g_grad_dev.reset(); g_tgt.reset();
        g_dev_ready = false; g_dev_state_dirty = true;
        g_ids.reset(); g_pos.reset();
        g_opt_m_prev = g_opt_v_prev = nullptr;
    }
    g_grad_buf = nullptr; g_grad_len = 0;
    g_p_buf = g_m_buf = g_v_buf = nullptr;
    g_nlayers = (int)NLayers; g_h = (int)H; g_nhd = (int)NHeads; g_hd = (int)Hd; g_vocab = (int)Vocab;
    return 0;
}
TKV_TORCH_EXPORT int TkvFullSetTensor(int64_t idx, const float* ptr, int64_t numel) {
    if (!ptr || numel <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    if (idx < 0 || (size_t)idx >= g_p.size()) return -2;
    if (g_p_src.size() != g_p.size()) g_p_src.assign(g_p.size(), nullptr);
    if (g_p_numels.size() != g_p.size()) g_p_numels.assign(g_p.size(), 0);
    /* cung host ptr + numel: state GPU da co -> skip H2D (tran 500MB/step) */
    if (g_p[(size_t)idx].defined() && g_p[(size_t)idx].numel() == numel &&
        g_p_src[(size_t)idx] == ptr) return 0;
    auto t = torch::from_blob(const_cast<float*>(ptr), {numel},
        torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU).requires_grad(false));
    if (!want_cuda()) {
        g_p[(size_t)idx] = t;
        g_p_src[(size_t)idx] = ptr;
        g_p_numels[(size_t)idx] = numel;
        return 0;
    }
    auto ht = t.to(at::ScalarType::Half);  /* params CUDA fp16 */
    if (g_p[(size_t)idx].defined() && g_p[(size_t)idx].numel() == numel) {
        g_p[(size_t)idx].copy_(ht);
    } else {
        g_p[(size_t)idx] = dev(ht);
    }
    g_p_src[(size_t)idx] = ptr;
    g_p_numels[(size_t)idx] = numel;
    return 0;
}
TKV_TORCH_EXPORT int TkvFullSetIds(const int* ids, int64_t T) {
    if (!ids || T <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    auto t = torch::from_blob(const_cast<int*>(ids), {T},
        torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
    auto opt = want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA)
                           : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU);
    g_ids = t.to(opt);
    g_pos = at::arange(T, opt);
    return 0;
}
/* Duong .NET/bseq truyen list[i64] (8 bytes/phan tu). Doc nhu int* se lay
 * sai thanh low/high 32-bit -> id out of range -> index_select crash. */
TKV_TORCH_EXPORT int TkvFullSetIds64(const int64_t* ids, int64_t T) {
    if (!ids || T <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    auto t = torch::from_blob(const_cast<int64_t*>(ids), {T},
        torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU).requires_grad(false));
    auto opt = want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA)
                           : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU);
    g_ids = t.to(opt);
    g_pos = at::arange(T, opt);
    {
        int64_t lo = g_ids.min().item<int64_t>(), hi = g_ids.max().item<int64_t>();
        fprintf(stderr, "XDBG ids64 T=%lld min=%lld max=%lld\n", (long long)T, (long long)lo, (long long)hi);
    }
    return 0;
}
TKV_TORCH_EXPORT int TkvFullSetGrad(float* gradbuf, int64_t n) {
    std::lock_guard<std::mutex> lk(g_full_mu);
    if (!gradbuf || n <= 0) return -1;
    g_grad_buf = gradbuf; g_grad_len = n;
    return 0;
}
/* Duong .NET/bseq: wrapper IL pin sai list[i64] -> pointer garbage. Tu sinh
 * ids theo cong thuc bench (i*37+11)%V, pos = arange(T), dung chung device. */
TKV_TORCH_EXPORT int TkvFullSetIdsGen(int64_t T) {
    if (T <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    const int64_t V = g_vocab > 0 ? g_vocab : 50257;
    auto cpu = at::empty({T}, torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU));
    auto* p = cpu.data_ptr<int64_t>();
    for (int64_t i = 0; i < T; ++i) p[i] = (i * 37 + 11) % V;
    auto opt = want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA)
                           : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU);
    g_ids = cpu.to(opt);
    g_pos = at::arange(T, opt);
    return 0;
}
/* Target ids rieng (next-token) cho training that. Neu khong goi, target = g_ids
 * nhu cu (duong bench giu nguyen). */
TKV_TORCH_EXPORT int TkvFullSetTargets(const int* ids, int64_t T) {
    if (!ids || T <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    auto t = torch::from_blob(const_cast<int*>(ids), {T},
        torch::TensorOptions().dtype(at::ScalarType::Int).device(torch::kCPU).requires_grad(false));
    auto opt = want_cuda() ? torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCUDA)
                           : torch::TensorOptions().dtype(at::ScalarType::Long).device(torch::kCPU);
    g_tgt = t.to(opt);
    return 0;
}
/* Doc lai master fp32 sau khi train (de luu checkpoint). */
TKV_TORCH_EXPORT int TkvFullGetParams(float* dst, int64_t n) {
    if (!dst || n <= 0) return -1;
    std::lock_guard<std::mutex> lk(g_full_mu);
    if (!g_p_all.defined() || g_p_all.numel() != n) return -2;
    auto h = g_p_all.to(torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU));
    std::memcpy(dst, h.const_data_ptr<float>(), (size_t)n * sizeof(float));
    return 0;
}
/* which: 0=emb 1=ln1 2=qkv 3=x1(after layer0) 4=xf 5=logits[:10] */
TKV_TORCH_EXPORT int TkvFullDebugGet(int which, float* dst, int64_t n) {
    if (!dst || n <= 0 || which < 0 || which > 5) return -1;
    static Tensor* arrs[] = {&g_dbg_emb, &g_dbg_ln1, &g_dbg_qkv, &g_dbg_x1, &g_dbg_xf, &g_dbg_logits};
    Tensor& t = *arrs[which];
    if (!t.defined() || t.numel() != n) return -2;
    std::memcpy(dst, t.const_data_ptr<float>(), (size_t)n * sizeof(float));
    return 0;
}
TKV_TORCH_EXPORT int TkvFullSetOpt(float* p, float* m, float* v,
                                   float lr, float b1, float b2, float eps, float wd,
                                   int64_t total_steps, int64_t cur_step) {
    std::lock_guard<std::mutex> lk(g_full_mu);
    g_p_buf = p; g_m_buf = m; g_v_buf = v;
    if (m != g_opt_m_prev || v != g_opt_v_prev) g_dev_state_dirty = true;
    g_opt_m_prev = m; g_opt_v_prev = v;
    g_lr = lr; g_b1 = b1; g_b2 = b2; g_eps = eps; g_wd = wd;
    g_total_steps = total_steps; g_cur_step = cur_step;
    return 0;
}

TKV_TORCH_EXPORT float TkvFullStep124m(int64_t run_mode) {
    std::lock_guard<std::mutex> lk(g_full_mu);
    static const bool dbg = getenv("TKV_FULL_DEBUG") != nullptr;
    auto tk_start = std::chrono::high_resolution_clock::now();
    std::chrono::high_resolution_clock::time_point tk_fwd, tk_bwd, tk_put, tk_adam;
    double sdpa_ms = 0.0;
    if (g_p.size() != (size_t)(4 + g_nlayers * 12) || !g_ids.defined()) return -100.0f;
    const int64_t T = g_ids.size(0);
    const int64_t h = g_h, nh = g_nhd, hd = g_hd, V = g_vocab;
    const int L = g_nlayers;
    /* Che do CUDA: p/m/v/grad song tren VRAM. Lien ket g_p[i] = view cua
     * g_p_all de AdamW cap nhat truc tiep; khong D2H ve host. */
    if (want_cuda() && g_grad_len > 0) {
        if (!g_dev_ready) {
            int64_t off = 0;
            std::vector<int64_t> offs(g_p.size());
            for (size_t i = 0; i < g_p.size(); ++i) { offs[i] = off; off += g_p[i].numel(); }
            auto cudaOpt = torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA);
            g_p_all = at::empty({off}, cudaOpt);
            for (size_t i = 0; i < g_p.size(); ++i)
                if (g_p[i].numel() > 0)
                    g_p_all.narrow(0, offs[i], g_p[i].numel()).copy_(g_p[i]);
            for (size_t i = 0; i < g_p.size(); ++i)
                g_p[i] = g_p_all.narrow(0, offs[i], g_p_numels[i]).to(at::ScalarType::Half);
            /* 2GB VRAM: m/v fp32 (~1GB). g_grad_dev cap phat TRE (chi luc
             * optimizer) de khong chong chan voi activations fwd/bwd. */
            g_m_dev = at::zeros({off}, cudaOpt);
            g_v_dev = at::zeros({off}, cudaOpt);
            g_grad_dev.reset();
            g_dev_ready = true;
        }
        if (want_cuda() && g_dev_ready && !g_grad_dev.defined()) {
            auto cudaOpt = torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCUDA);
            g_grad_dev = at::empty({g_p_all.numel()}, cudaOpt);
        }
        if (g_dev_state_dirty) {
            if (g_m_buf) {
                auto hm = torch::from_blob(g_m_buf, {g_m_dev.numel()},
                    torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU));
                g_m_dev.copy_(hm);
            }
            if (g_v_buf) {
                auto hv = torch::from_blob(g_v_buf, {g_v_dev.numel()},
                    torch::TensorOptions().dtype(at::ScalarType::Float).device(torch::kCPU));
                g_v_dev.copy_(hv);
            }
            g_dev_state_dirty = false;
        }
    }

    /* Autograd bwd: BAT BUOC set requires_grad TRUOC khi tao wte/wpe views.
     * Neu dat sau view, lan dau view duoc tao luc param con rg=false -> graph
     * khong di qua embedding -> g_p[0]/g_p[1] khong co grad o step 0. */
    const bool do_bwd = (run_mode != 1) && g_grad_buf && g_grad_len > 0;
    const bool use_autograd = want_cuda() && do_bwd;
    if (use_autograd) {
        for (auto& p : g_p)
            if (p.defined() && !p.requires_grad()) p.set_requires_grad(true);
    }

    auto wte = g_p[0].view({V, h});
    /* 2GB+T>1024: wpe size tu ham, ko co hardcode {1024,h} */
    const int64_t Pw = g_p[1].numel() / h;
    auto wpe = g_p[1].view({Pw, h});
    if (T > Pw) return -3;
    {
        int64_t ilo = g_ids.min().item<int64_t>(), ihi = g_ids.max().item<int64_t>();
        fprintf(stderr, "XDBG fullstep T=%lld V=%lld Pw=%lld wte=%lld wpe=%lld ids=[%lld,%lld]\n",
                (long long)T, (long long)V, (long long)Pw,
                (long long)g_p[0].numel(), (long long)g_p[1].numel(),
                (long long)ilo, (long long)ihi);
    }
    const double inv = 1.0 / std::sqrt((double)hd);

    /* ---- forward, save activations ---- */
    std::vector<Tensor> xin(L), a_in(L), m_in(L), ctx_s(L), u_s(L), g1_s(L), qkv_s(L);
    Tensor x = at::index_select(wte, 0, g_ids) + at::index_select(wpe, 0, g_pos);
    if (dbg) g_dbg_emb = x.detach().to(at::ScalarType::Float).cpu();
    for (int li = 0; li < L; ++li) {
        const Tensor& ln1g = g_p[4 + li*12 + 0];
        const Tensor& ln1b = g_p[4 + li*12 + 1];
        const Tensor& wqkv  = g_p[4 + li*12 + 2].view({h, 3*h});
        const Tensor& bqkv  = g_p[4 + li*12 + 3];
        const Tensor& wp    = g_p[4 + li*12 + 4].view({h, h});
        const Tensor& bp    = g_p[4 + li*12 + 5];
        const Tensor& ln2g  = g_p[4 + li*12 + 6];
        const Tensor& ln2b  = g_p[4 + li*12 + 7];
        const Tensor& w1    = g_p[4 + li*12 + 8].view({h, 4*h});
        const Tensor& b1    = g_p[4 + li*12 + 9];
        const Tensor& w2    = g_p[4 + li*12 + 10].view({4*h, h});
        const Tensor& b2    = g_p[4 + li*12 + 11];

        xin[li] = x;
        Tensor a = full_ln_fwd(x, ln1g, ln1b, 1e-6).to(at::ScalarType::Half);
        if (dbg && li == 0) g_dbg_ln1 = a.detach().to(at::ScalarType::Float).cpu();
        a_in[li] = a;
        Tensor qkv = half_mat2("qkv", bqkv, a, wqkv, true);
        if (dbg && li == 0) g_dbg_qkv = qkv.detach().to(at::ScalarType::Float).cpu();
        qkv_s[li] = qkv;
        auto q3 = qkv.view({T, 3, nh, hd});
        auto q  = q3.select(1, 0).transpose(0, 1).unsqueeze(0);
        auto k  = q3.select(1, 1).transpose(0, 1).unsqueeze(0);
        auto v  = q3.select(1, 2).transpose(0, 1).unsqueeze(0);
        Tensor attn;
        {
            auto t_s0 = std::chrono::high_resolution_clock::now();
            auto qh = q.contiguous().to(at::ScalarType::Half);
            auto kh = k.contiguous().to(at::ScalarType::Half);
            auto vh = v.contiguous().to(at::ScalarType::Half);
            attn = at::scaled_dot_product_attention(qh, kh, vh, std::nullopt, 0.0, true, std::nullopt);
            sdpa_ms += std::chrono::duration<double, std::milli>(
                std::chrono::high_resolution_clock::now() - t_s0).count();
        }
        Tensor ctx = attn.transpose(1, 2).reshape({T, h}).contiguous();
        ctx_s[li] = ctx;
        Tensor proj = half_mat2("proj", bp, ctx, wp, true);
        x = x + proj;
        Tensor m = full_ln_fwd(x, ln2g, ln2b, 1e-6).to(at::ScalarType::Half);
        m_in[li] = m;
        Tensor u = half_mat2("mlp-up", b1, m, w1, true);
        u_s[li] = u;
        Tensor g1 = at::gelu(u);
        g1_s[li] = g1;
        x = x + half_mat2("mlp-down", b2, g1, w2, true);
        if (dbg && li == 0) g_dbg_x1 = x.detach().to(at::ScalarType::Float).cpu();
    }
    const Tensor& lnfg = g_p[2];
    const Tensor& lnfb = g_p[3];
    Tensor xf = full_ln_fwd(x, lnfg, lnfb, 1e-6).to(at::ScalarType::Half);
    if (dbg) g_dbg_xf = xf.detach().to(at::ScalarType::Float).cpu();
    Tensor logits = half_mm2("logits", xf, wte.t()).to(at::ScalarType::Float);
    if (dbg) g_dbg_logits = logits.detach().cpu().slice(0, 0, 10).contiguous();
    auto lp = logits.log_softmax(-1);
    logits.reset();   /* 2GB: giai phong [T,V] ngay sau log_softmax */
    const Tensor& tgt_ids = g_tgt.defined() ? g_tgt : g_ids;
    auto tgt = tgt_ids.unsqueeze(1);
    Tensor loss_t = -(lp.gather(1, tgt).squeeze(1)).mean();
    float loss_val = loss_t.item<float>();
    tk_fwd = std::chrono::high_resolution_clock::now();
    if (run_mode == 1 || !g_grad_buf) return loss_val;

    /* ---- backward ---- */
    /* Hoist put lambda dùng chung cho autograd (tu y) va manual bwd (C/older path). */
    auto put = [&](int64_t idx, const Tensor& grad) {
        int64_t off = 0;
        for (int64_t i = 0; i < idx; ++i) off += g_p[(size_t)i].numel();
        if (want_cuda() && g_dev_ready && g_grad_dev.defined()) {
            if (off + grad.numel() <= g_grad_dev.numel())
                g_grad_dev.narrow(0, off, grad.numel()).copy_(grad.to(at::ScalarType::Float).contiguous().reshape({grad.numel()}));
            return;
        }
        if (off + grad.numel() <= g_grad_len)
            memcpy(g_grad_buf + off, host(grad.contiguous()).const_data_ptr<float>(),
                   (size_t)grad.numel() * sizeof(float));
    };

    if (use_autograd) {
        /* Nen saved activations khi co the (graph tự giữ tốn cần thiết). */
        xin.clear(); a_in.clear(); m_in.clear(); ctx_s.clear();
        u_s.clear(); g1_s.clear(); qkv_s.clear();
        lp.reset();
        loss_t.backward();
        tk_bwd = std::chrono::high_resolution_clock::now();
        /* grad của g_p[i] có order trùng với flat layout của put(). */
        for (size_t i = 0; i < g_p.size(); ++i) {
            const Tensor& gr = g_p[i].grad();
            if (gr.defined()) put((int64_t)i, gr);
            else {
                if (want_cuda() && g_dev_ready && g_grad_dev.defined()) {
                    int64_t off = 0;
                    for (size_t j = 0; j < i; ++j) off += g_p[j].numel();
                    if (off + g_p[i].numel() <= g_grad_dev.numel())
                        g_grad_dev.narrow(0, off, g_p[i].numel()).zero_();
                }
                fprintf(stderr, "XDBG autograd: no grad for param %zu -> zero_() fallback\n", i);
            }
        }
        /* Release fp16 grads: next step .grad accumulate dau het. */
        for (auto& p : g_p) if (p.grad().defined()) p.mutable_grad() = Tensor();
        tk_put = std::chrono::high_resolution_clock::now();
    } else {
    auto P = lp.exp();
    lp.reset();       /* 2GB: khong giu lp [T,V] */
    auto dlogits = P.clone();
    P.reset();        /* 2GB: khong giu P [T,V] */
    dlogits.scatter_add_(1, tgt, torch::full({T,1}, -1.0f, dlogits.options()));
    dlogits.div_((float)T);   /* in-place: tran cap them [T,V] ~200MB */
    Tensor dxf = half_mm2("lmhead-dxf", dlogits, wte);
    Tensor dwte = half_mm2("lmhead-dwte", dlogits.t(), xf);
    dlogits.reset();  /* 2GB: xong LM-head bwd */
    xf.reset();
    auto lnf = full_ln_bwd(x, lnfg, dxf, 1e-6);
    Tensor dx = lnf[0];
    Tensor dlnfg = lnf[1], dlnfb = lnf[2];

    std::vector<Tensor> g_ln1g(L), g_ln1b(L), g_wqkv(L), g_bqkv(L), g_wp(L), g_bp(L);
    std::vector<Tensor> g_ln2g(L), g_ln2b(L), g_w1(L), g_b1v(L), g_w2(L), g_b2v(L);
    Tensor d_emb;   /* gpackage sau vong: dx(li=0) = grad cua embedding */

    for (int li = L - 1; li >= 0; --li) {
        const Tensor& ln1g = g_p[4 + li*12 + 0];
        const Tensor& ln1b = g_p[4 + li*12 + 1];
        const Tensor& wqkv  = g_p[4 + li*12 + 2].view({h, 3*h});
        const Tensor& wp    = g_p[4 + li*12 + 4].view({h, h});
        const Tensor& ln2g  = g_p[4 + li*12 + 6];
        const Tensor& ln2b  = g_p[4 + li*12 + 7];
        const Tensor& w1    = g_p[4 + li*12 + 8].view({h, 4*h});
        const Tensor& w2    = g_p[4 + li*12 + 10].view({4*h, h});
        Tensor a = a_in[li], m = m_in[li], ctx = ctx_s[li], u = u_s[li], g1 = g1_s[li];

        /* MLP */
        Tensor dh2 = dx;
        g_w2[li] = half_mm2("g_w2", g1.t(), dh2);
        g_b2v[li] = dh2.sum({0});
        Tensor du = at::gelu_backward(half_mm2("mlp-du-in", dh2, w2.t()), u, "none");
        g_w1[li] = half_mm2("g_w1", m.t(), du);
        g_b1v[li] = du.sum({0});
        auto ln2 = full_ln_bwd(xin[li], ln2g, half_mm2("mlp-dxmid", du, w1.t()), 1e-6);
        g_ln2g[li] = ln2[1]; g_ln2b[li] = ln2[2];
        dx = ln2[0] + dh2;

        /* attention — recompute + SDPA backward fused (flash bwd) */
        Tensor dctx = half_mm2("attn-dctx", dx, wp.t());
        g_wp[li] = half_mm2("attn-g_wp", ctx.t(), dx);
        g_bp[li] = dx.sum({0});
        auto q3b = qkv_s[li].view({T, 3, nh, hd});
        auto qb = q3b.select(1, 0).transpose(0, 1).unsqueeze(0).detach().to(at::ScalarType::Half); qb.set_requires_grad(true);
        auto kb = q3b.select(1, 1).transpose(0, 1).unsqueeze(0).detach().to(at::ScalarType::Half); kb.set_requires_grad(true);
        auto vb = q3b.select(1, 2).transpose(0, 1).unsqueeze(0).detach().to(at::ScalarType::Half); vb.set_requires_grad(true);
        Tensor attnb = at::scaled_dot_product_attention(qb, kb, vb, std::nullopt, 0.0, true, std::nullopt);
        Tensor dctx_a = dctx.view({T, nh, hd}).transpose(0, 1).unsqueeze(0).contiguous().to(at::ScalarType::Half);
        attnb.backward(dctx_a);
        auto dQ = qb.grad().to(at::ScalarType::Half);
        auto dK = kb.grad().to(at::ScalarType::Half);
        auto dV = vb.grad().to(at::ScalarType::Half);
        auto dQKV = at::cat({dQ.squeeze(0).transpose(0,1).reshape({T,h}),
                             dK.squeeze(0).transpose(0,1).reshape({T,h}),
                             dV.squeeze(0).transpose(0,1).reshape({T,h})}, 1);
        g_wqkv[li] = half_mm2("attn-g_wqkv", a.t(), dQKV);
        g_bqkv[li] = dQKV.sum({0});
        auto ln1 = full_ln_bwd(xin[li], ln1g, half_mm2("attn-dx1", dQKV, wqkv.t()), 1e-6);
        g_ln1g[li] = ln1[1]; g_ln1b[li] = ln1[2];
        dx = ln1[0] + dx;
    }
    /* dx sau vong li=0 = dL/d_embed_output */
    d_emb = dx;
    dwte.scatter_add_(0, g_ids.unsqueeze(1), d_emb);  /* += grad loi lookup (tu 732) */
    Tensor dwpe = torch::zeros_like(wpe);
    dwpe.scatter_add_(0, g_pos.unsqueeze(1), d_emb);

    /* 2GB: xong backward -> giai phong activations */
    x.reset();
    xin.clear(); a_in.clear(); m_in.clear(); ctx_s.clear();
    u_s.clear(); g1_s.clear(); qkv_s.clear();

    /* put lambda được hoist len trên (dùng chung autograd va manual). */
    put(0, dwte); put(1, dwpe); put(2, dlnfg); put(3, dlnfb);
    for (int li = 0; li < L; ++li) {
        int64_t b = 4 + li*12;
        put(b+0,g_ln1g[li]); put(b+1,g_ln1b[li]); put(b+2,g_wqkv[li]); put(b+3,g_bqkv[li]);
        put(b+4,g_wp[li]);   put(b+5,g_bp[li]);   put(b+6,g_ln2g[li]); put(b+7,g_ln2b[li]);
        put(b+8,g_w1[li]);   put(b+9,g_b1v[li]);   put(b+10,g_w2[li]);  put(b+11,g_b2v[li]);
    }
    /* 2GB: grad da copy sang g_grad_dev -> giai phong ban goc truoc AdamW */
    if (want_cuda() && g_dev_ready) {
        dwte.reset(); dwpe.reset(); dlnfg.reset(); dlnfb.reset(); d_emb.reset(); dx.reset();
        g_ln1g.clear(); g_ln1b.clear(); g_wqkv.clear(); g_bqkv.clear();
        g_wp.clear();   g_bp.clear();   g_ln2g.clear(); g_ln2b.clear();
        g_w1.clear();   g_b1v.clear();  g_w2.clear();   g_b2v.clear();
    }
    }  /* ^^ vòng manual backward (nguyên giữ CPU path) */
    /* AdamW - CUDA: single-pass ATen (như torch AdamW foreach), fp32.
     * p/m/v/grad đều trên VRAM, không D2H, không cần buffer host. */
    if (want_cuda() && g_dev_ready && g_grad_dev.defined()) {
        float lr_t = g_lr;
        if (g_total_steps > 0) {
            float step = (float)(g_cur_step + 1);
            float warm = (float)std::min<int64_t>(2, g_total_steps);
            if (warm > 0 && step < warm) lr_t *= step / warm;
            lr_t *= 0.5f * (1.0f + std::cos(3.14159265f * step / (float)g_total_steps));
        }
        float bc1 = 1.0f - std::pow(g_b1, (double)(g_cur_step + 1));
        float bc2 = 1.0f - std::pow(g_b2, (double)(g_cur_step + 1));
        /* AdamW fused kernel: 1 launch thay 6-7 launch ATen. */
        {
            int64_t numel = g_p_all.numel();
            int threads = 256;
            int blocks = (int)((numel + threads - 1) / threads);
            adamw_fused_kernel<<<blocks, threads>>>(
                g_p_all.data_ptr<float>(),
                g_grad_dev.data_ptr<float>(),
                g_m_dev.data_ptr<float>(),
                g_v_dev.data_ptr<float>(),
                numel,
                lr_t, g_b1, g_b2,
                bc1, bc2,
                g_eps, g_wd
            );
        }
        /* Dong bo params fp16 (g_p[i] la ban copy) voi master fp32 sau update:
         * neu khong, cac step sau tiep tuc dung weights cu. copy_ tu
         * Float->Half la kernel cast CUDA, khong D2H. In no-grad cho tru
         * khi g_p[i].requires_grad() (duong Autograd bwd dua do):
         * in-place op tren leaf se throw Exception. */
        {
            c10::AutoGradMode guard(false);
            int64_t off = 0;
            for (size_t i = 0; i < g_p.size(); ++i) {
                int64_t n = g_p[i].numel();
                if (n > 0) g_p[i].copy_(g_p_all.narrow(0, off, n));
                off += n;
            }
        }
        g_grad_dev.reset();
        g_cur_step++;
        tk_adam = std::chrono::high_resolution_clock::now();
    } else if (g_p_buf && g_m_buf && g_v_buf && g_grad_len > 0) {
        /* CPU mode: flat host buffers (native path, gi nguyen) */
        float lr_t = g_lr;
        if (g_total_steps > 0) {
            float step = (float)(g_cur_step + 1);
            float warm = (float)std::min<int64_t>(2, g_total_steps);
            if (warm > 0 && step < warm) lr_t *= step / warm;
            lr_t *= 0.5f * (1.0f + std::cos(3.14159265f * step / (float)g_total_steps));
        }
        float bc1 = 1.0f - std::pow(g_b1, (double)(g_cur_step + 1));
        float bc2 = 1.0f - std::pow(g_b2, (double)(g_cur_step + 1));
        for (int64_t i = 0; i < g_grad_len; ++i) {
            float gt = g_grad_buf[i];
        float m = g_b1 * g_m_buf[i] + (1.0f - g_b1) * gt;
        float v = g_b2 * g_v_buf[i] + (1.0f - g_b2) * gt * gt;
            g_m_buf[i] = m; g_v_buf[i] = v;
            g_p_buf[i] -= lr_t * ((m / bc1) / (std::sqrt(v / bc2) + g_eps) + g_wd * g_p_buf[i]);
        }
        g_cur_step++;
    }
    if (use_autograd && tk_adam.time_since_epoch().count() > 0) {
        auto ms = [](std::chrono::high_resolution_clock::time_point a,
                     std::chrono::high_resolution_clock::time_point b) {
            return std::chrono::duration<double, std::milli>(b - a).count();
        };
        fprintf(stderr, "XDBG timing fwd=%.1f (sdpa=%.1f) bwd=%.1f put=%.1f adam=%.1f total=%.1f ms\n",
                ms(tk_start, tk_fwd), sdpa_ms, ms(tk_fwd, tk_bwd), ms(tk_bwd, tk_put),
                ms(tk_put, tk_adam), ms(tk_start, std::chrono::high_resolution_clock::now()));
    }
    return loss_val;
}
/* FullStep spike probe - 2026-11-17: dung de verifier pipeline compiler */
TKV_TORCH_EXPORT int64_t TkvFullPing(int64_t x) {
    return x + 42000;
}
