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
 * Optional runtime: torch_cpu.dll must be reachable at load time of this
 * bridge DLL. Caller falls back to old kernels when load fails.
 */
#include <torch/torch.h>
#include <ATen/ATen.h>
#include <ATen/core/Tensor.h>
#include <c10/util/intrusive_ptr.h>
#include <cstring>

#include <string>
#include <vector>
#include <memory>

using at::Tensor;

#define TKV_TORCH_EXPORT extern "C" __declspec(dllexport)

/* helper: wrap caller memory as unmanaged tensor */
static Tensor wrap_in(const float* p, int64_t rows, int64_t cols) {
    return torch::from_blob(const_cast<float*>(p), {rows, cols},
        torch::TensorOptions().dtype(torch::kFloat32).requires_grad(false));
}

/* Scales/transposes: oneDNN linear layout is [input, output] right now (w1 in
 * ours is [in_d, out_d]). Direct at::addmm(bias, x, w) uses this layout.
 * Returns 0 on OK, <0 on error. */
TKV_TORCH_EXPORT int TkvTorchLinearGeluFwd(const float* x, const float* w,
                                           const float* bias, int64_t n, int64_t in_d,
                                           int64_t out_d, float* y) {
    if (!x || !w || !bias || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = wrap_in(x, n, in_d);
        auto t_w = wrap_in(w, in_d, out_d);
        auto t_b = torch::from_blob(const_cast<float*>(bias), {out_d},
            torch::TensorOptions().dtype(torch::kFloat32).requires_grad(false));
        auto t_y = at::gelu(at::addmm(t_b, t_x, t_w, 1, 1));
        if (t_y.numel() != (int64_t)n * out_d) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* GELU(erf) backward qua ATen: y[i] = gy[i] * d/dx gelu(x[i]).
 * Cung cong thuc voi duong .tkv (0.5*(1+erf(x/sqrt2)) + x*phi(x)) nhung
 * ATen tinh vectorized + multithread -> ~2 ms/3.1M thay vi ~47 ms.
 * rc < 0 -> caller fallback duong .tkv nguyen van. */
TKV_TORCH_EXPORT int TkvTorchGeluBwd(const float* gy, const float* x, float* y,
                                     int64_t n) {
    if (!gy || !x || !y) return -1;
    if (n <= 0) return -2;
    try {
        auto opt = torch::TensorOptions().dtype(torch::kFloat32);
        auto t_gy = torch::from_blob(const_cast<float*>(gy), {n}, opt);
        auto t_x  = torch::from_blob(const_cast<float*>(x),  {n}, opt);
        auto t_y  = at::gelu_backward(t_gy, t_x, "none");
        if (t_y.numel() != n) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Backward Linear (Conv1D layout: w [in_d, out_d]).
 *   dx = gy @ w^T
 *   dw = x^T @ gy
 *   db = sum_n gy
 * Uses g32 from_blob (no copy) and at::addmm/mm. Outputs written straight
 * into caller buffers — caller owns lifetime. Optional rc guard. */
TKV_TORCH_EXPORT int TkvTorchLinearBwdFwd(const float* x, const float* gy,
                                          const float* w, float* dx, float* dw, float* db,
                                          int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !gy || !w || !dx || !dw || !db) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x  = wrap_in(x, n, in_d);
        auto t_gy = wrap_in(gy, n, out_d);
        auto t_w  = wrap_in(w, in_d, out_d);
        auto t_dx = at::empty({n, in_d}, torch::TensorOptions().dtype(torch::kFloat32));
        auto t_dw = at::empty({in_d, out_d}, torch::TensorOptions().dtype(torch::kFloat32));
        auto t_db = at::empty({out_d}, torch::TensorOptions().dtype(torch::kFloat32));
        at::mm_out(t_dx, t_gy, t_w.t());     /* gy @ w^T */
        at::mm_out(t_dw, t_x.t(), t_gy);     /* x^T @ gy */
        at::sum_out(t_db, t_gy, {0}, false); /* sum over n */
        memcpy(dx, t_dx.const_data_ptr<float>(), (size_t)n * in_d * sizeof(float));
        memcpy(dw, t_dw.const_data_ptr<float>(), (size_t)in_d * out_d * sizeof(float));
        memcpy(db, t_db.const_data_ptr<float>(), (size_t)out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Plain Linear+bias (no gelu), for qkv/c_proj sites later. */
TKV_TORCH_EXPORT int TkvTorchLinearFwd(const float* x, const float* w,
                                       const float* bias, int64_t n, int64_t in_d,
                                       int64_t out_d, float* y) {
    if (!x || !w || !bias || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = wrap_in(x, n, in_d);
        auto t_w = wrap_in(w, in_d, out_d);
        auto t_b = torch::from_blob(const_cast<float*>(bias), {out_d},
            torch::TensorOptions().dtype(torch::kFloat32).requires_grad(false));
        auto t_y = at::addmm(t_b, t_x, t_w, 1, 1);
        if (t_y.numel() != (int64_t)n * out_d) return -3;
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* LayerNorm via ATen (same kernel HF GPT-2 uses: at::layer_norm).
 *   y = (x - mu) * rstd * g + b. Welford vectorized f32 — bit-identical to
 *   torch.nn.functional.layer_norm on the same build/dispatch, not to the
 *   repo's f64-accumulation native path (intentional: parity goal). */
TKV_TORCH_EXPORT int TkvTorchLayerNormFwd(const float* x, const float* g,
                                          const float* b, float* y,
                                          int64_t n, int64_t h, double eps) {
    if (!x || !g || !b || !y) return -1;
    if (n <= 0 || h <= 0) return -2;
    try {
        auto t_x = wrap_in(x, n, h);
        auto t_g = torch::from_blob(const_cast<float*>(g), {h},
            torch::TensorOptions().dtype(torch::kFloat32).requires_grad(false));
        auto t_b = torch::from_blob(const_cast<float*>(b), {h},
            torch::TensorOptions().dtype(torch::kFloat32).requires_grad(false));
        auto t_y = at::layer_norm(t_x, {h}, t_g, t_b, eps);
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Backward LayerNorm via ATen autograd (same graph PyTorch uses for HF
 * gpt2 LN backward — at::layer_norm + .backward()). Outputs dx/dg/db into
 * caller's buffers. eps must match fwd (1e-6 here, HF default). */
TKV_TORCH_EXPORT int TkvTorchLayerNormBwd(const float* x, const float* g,
                                          const float* b, const float* gy,
                                          float* dx, float* dg, float* db,
                                          int64_t n, int64_t h, double eps) {
    if (!x || !g || !b || !gy || !dx || !dg || !db) return -1;
    if (n <= 0 || h <= 0) return -2;
    try {
        auto opt = torch::TensorOptions().dtype(torch::kFloat32);
        auto t_x  = torch::from_blob(const_cast<float*>(x), {n, h}, opt.requires_grad(true));
        auto t_g  = torch::from_blob(const_cast<float*>(g), {h},   opt.requires_grad(true));
        auto t_b  = torch::from_blob(const_cast<float*>(b), {h},   opt.requires_grad(true));
        auto t_gy = torch::from_blob(const_cast<float*>(gy), {n, h}, opt);
        auto t_y  = at::layer_norm(t_x, {h}, t_g, t_b, eps);
        t_y.backward(t_gy);
        memcpy(dx, t_x.grad().const_data_ptr<float>(), (size_t)n * h * sizeof(float));
        memcpy(dg, t_g.grad().const_data_ptr<float>(), (size_t)h * sizeof(float));
        memcpy(db, t_b.grad().const_data_ptr<float>(), (size_t)h * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}
/* Attention block BACKWARD via ATen autograd (same graph HF GPT2 uses:
 *   x -> c_attn(addmm) -> [q,k,v split views] -> sdpa(is_causal=true) ->
 *   reshape -> c_proj(addmm) -> seed(gout).backward()
 * Outputs: dx into caller buffer; dw_qkv/db_qkv/dw_proj/db_proj DIRECTLY into
 * gflat at element offsets o_qkv/o_bqkv/o_proj/o_bproj (gflat zeroed per
 * step, each offset written once). rc < 0 -> caller fallback. */
TKV_TORCH_EXPORT int TkvTorchAttentionBwd(const float* x, const float* gout,
        const float* w_qkv, const float* b_qkv,
        const float* w_proj, const float* b_proj,
        float* dx, float* gflat,
        int64_t n, int64_t h, int64_t nheads, int64_t hd,
        long long o_qkv, long long o_bqkv, long long o_proj, long long o_bproj) {
    if (!x || !gout || !w_qkv || !b_qkv || !w_proj || !b_proj || !dx) return -1;
    try {
        auto opt = torch::TensorOptions().dtype(torch::kFloat32);
        const int64_t T = n;
        const int64_t H = nheads * hd;
        if (h != H) return -2;
        auto t_x   = torch::from_blob(const_cast<float*>(x),   {T, h},   opt.requires_grad(true));
        auto t_wq  = torch::from_blob(const_cast<float*>(w_qkv), {h, 3 * h}, opt.requires_grad(true));
        auto t_bq  = torch::from_blob(const_cast<float*>(b_qkv), {3 * h},   opt.requires_grad(true));
        auto t_wp  = torch::from_blob(const_cast<float*>(w_proj), {h, h},  opt.requires_grad(true));
        auto t_bp  = torch::from_blob(const_cast<float*>(b_proj), {h},     opt.requires_grad(true));

        auto t_qkv = at::addmm(t_bq, t_x, t_wq);              /* [T, 3h] */
        auto t_q3  = t_qkv.view({T, 3, nheads, hd});          /* contiguous view */
        auto q = t_q3.select(1, 0).transpose(0, 1).unsqueeze(0);  /* [B(=1), H, T, hd] */
        auto k = t_q3.select(1, 1).transpose(0, 1).unsqueeze(0);
        auto v = t_q3.select(1, 2).transpose(0, 1).unsqueeze(0);

        auto t_attn = at::scaled_dot_product_attention(q, k, v, std::nullopt,
                                                       0.0, true, std::nullopt);
        auto t_ctx  = t_attn.transpose(1, 2).reshape({T, h}).contiguous();  /* [T, h] */
        auto t_proj = at::addmm(t_bp, t_ctx, t_wp);

        auto t_gy = torch::from_blob(const_cast<float*>(gout), {T, h}, opt);
        t_proj.backward(t_gy);

        memcpy(dx, t_x.grad().const_data_ptr<float>(),
               (size_t)T * h * sizeof(float));
        if (gflat && o_qkv  >= 0)
            memcpy(gflat + o_qkv,  t_wq.grad().const_data_ptr<float>(),
                   (size_t)h * 3 * h * sizeof(float));
        if (gflat && o_bqkv >= 0)
            memcpy(gflat + o_bqkv, t_bq.grad().const_data_ptr<float>(),
                   (size_t)3 * h * sizeof(float));
        if (gflat && o_proj >= 0)
            memcpy(gflat + o_proj, t_wp.grad().const_data_ptr<float>(),
                   (size_t)h * h * sizeof(float));
        if (gflat && o_bproj >= 0)
            memcpy(gflat + o_bproj, t_bp.grad().const_data_ptr<float>(),
                   (size_t)h * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Mm transposed (LM head): y = x @ w^T. w [out_d, in_d] (tied-embedding layout,
 * HF lm_head does at::linear(x, W, None) internally -> at::mm(x, W^T)). */
TKV_TORCH_EXPORT int TkvTorchMmT(const float* x, const float* w, float* y,
                                 int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !y) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    try {
        auto t_x = wrap_in(x, n, in_d);
        auto t_w = wrap_in(w, out_d, in_d);
        auto t_y = at::mm(t_x, t_w.t());
        memcpy(y, t_y.const_data_ptr<float>(), (size_t)n * out_d * sizeof(float));
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}

/* Scaled-dot-product attention CAUSAL (HF sdpa: is_causal=true, scale =
 * 1/sqrt(hd), dropout 0). q/k/v slices from qkv [n, 3*h] rows; h = nheads*hd.
 * Contiguous copies are made so the ATen CPU flash dispatch path matches what
 * HF sdpa sees (identical kernel -> identical bits). Output interleaved per
 * head into y [n, h] (same layout as repo ctxT). */
TKV_TORCH_EXPORT int TkvTorchSdpa(const float* qkv, float* y,
                                  int64_t n, int64_t nheads, int64_t hd) {
    if (!qkv || !y) return -1;
    if (n <= 0 || nheads <= 0 || hd <= 0) return -2;
    const int64_t h = nheads * hd;
    if (h <= 0) return -2;
    try {
        auto opt = torch::TensorOptions().dtype(torch::kFloat32);
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
        auto t_y = at::scaled_dot_product_attention(t_q, t_k, t_v, std::nullopt,
                                                    0.0, true, std::nullopt);
        const float* yp = t_y.const_data_ptr<float>();
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

/* §0.148 (2026-11-11): dwte += dlT @ xf trong MOT lenh ATen.
 * dl [T][V] row-major; doc thang bang .t() -> khong transpose vat ly, khong buffer tmp.
 * dwte [V][E] TICH LUY (beta=1) -> caller phai zero truoc (giong hop dong cu).
 * Thay 2 buoc cu: tmp = dlT @ xf (openblas 255 ms) + dwte += tmp (36.5 ms).
 * Do truoc: addmm_out 195.9 ms vs 298.8 ms -> -102.9 ms/step.
 * Numerics: khac thu vien tich luy (ATen/oneDNN vs scipy-openblas) -> loss lech ~1e-7. */
TKV_TORCH_EXPORT int TkvTorchAddmmTaOut(const float* dl, const float* xf, float* dwte,
                                        int64_t T, int64_t V, int64_t E) {
    if (!dl || !xf || !dwte) return -1;
    if (T <= 0 || V <= 0 || E <= 0) return -2;
    try {
        auto t_dl = wrap_in(dl, T, V);
        auto t_xf = wrap_in(xf, T, E);
        auto t_dw = wrap_in(dwte, V, E);
        at::addmm_out(t_dw, t_dw, t_dl.t(), t_xf, 1.0, 1.0);
        return 0;
    } catch (const std::exception&) {
        return -4;
    } catch (...) {
        return -5;
    }
}
