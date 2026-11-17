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
#include <c10/util/intrusive_ptr.h>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cstdarg>

#include <string>
#include <vector>
#include <memory>

using at::Tensor;

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
static Tensor dev(const Tensor& t) {
    if (!want_cuda()) return t;
    auto opts = torch::TensorOptions().dtype(t.scalar_type()).device(torch::kCUDA).requires_grad(false);
    auto tgt = at::empty(t.sizes(), opts);
    if (tgt.numel()) {
        tgt.copy_(t);
    }
    tgt.set_requires_grad(t.requires_grad());
    return tgt;
}
static Tensor host(const Tensor& t) {
    if (!want_cuda()) return t;
    auto opts = torch::TensorOptions().dtype(t.scalar_type()).device(torch::kCPU);
    auto tgt = at::empty(t.sizes(), opts);
    if (tgt.numel()) {
        tgt.copy_(t);
    }
    return tgt;
}
static auto dev_f32() {
    return want_cuda()
        ? torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCUDA)
        : torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
}

/* helper: wrap caller memory as unmanaged tensor */
static Tensor wrap_in(const float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(const_cast<float*>(p), {rows, cols},
        torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false));
}
static Tensor wrap_grad(const float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(const_cast<float*>(p), {rows, cols},
        torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(true));
}
static Tensor wrap_out(float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(p, {rows, cols},
        torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false));
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
            torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false)));
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
        auto opt = torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
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
            torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false)));
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
        auto t_x = dev(wrap_in(x, n, h));
        auto t_g = dev(torch::from_blob(const_cast<float*>(g), {h},
            torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false)));
        auto t_b = dev(torch::from_blob(const_cast<float*>(b), {h},
            torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(false)));
        auto t_y = host(at::layer_norm(t_x, {h}, t_g, t_b, eps));
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        ln_clog("[tkv-ln-fwd] ok\n");
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
        auto opt = torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU).requires_grad(true);
        auto t_x  = dev(torch::from_blob(const_cast<float*>(x), {n, h}, opt.requires_grad(true)));
        auto t_g  = dev(torch::from_blob(const_cast<float*>(g), {h},   opt.requires_grad(true)));
        auto t_b  = dev(torch::from_blob(const_cast<float*>(b), {h},   opt.requires_grad(true)));
        auto t_gy = dev(torch::from_blob(const_cast<float*>(gy), {n, h},
             torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU)));
        auto t_y  = at::layer_norm(t_x, {h}, t_g, t_b, eps);
        t_y.backward(t_gy);
        memcpy(dx, host(t_x.grad()).const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        memcpy(dg, host(t_g.grad()).const_data_ptr<float>(), (size_t)h * sizeof(float));
        memcpy(db, host(t_b.grad()).const_data_ptr<float>(), (size_t)h * sizeof(float));
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
                     torch::TensorOptions().dtype(torch::kInt32).device(torch::kCPU))
                     .to(torch::TensorOptions().dtype(torch::kLong).device(torch::kCUDA));
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
        auto opt = torch::TensorOptions().dtype(torch::kFloat32).device(torch::kCPU);
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


