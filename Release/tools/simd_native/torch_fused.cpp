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
