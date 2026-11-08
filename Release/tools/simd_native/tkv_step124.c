/* tkv_step124.c - D5-2: native trampoline skeleton for GPT-2 124M step.
 * Lazy-load the ATen bridge (tkv_torch_fused.dll) and run ONE native op
 * (TkvTorchLinearFwd, tiny [2,2] @ [2,2]) against it as a sanity check.
 * No IL wiring yet - this is the load-and-call proof before any real fusion.
 * Build: powershell -ExecutionPolicy Bypass -File build_tkv_step124.ps1 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <windows.h>
#include <immintrin.h>

#define EXPORT __declspec(dllexport)
#define TKV_TORCH_PATH_ENV "TKV_TORCH_PATH"

// TkvTorchLinearFwd(x, w, b, n, in_d, out_d, y) -> i32  (y LAST, x64 fastcall)
typedef int (*tkv_lin_fn)(const float* x, const float* w, const float* b,
                          int64_t n, int64_t in_d, int64_t out_d, float* y);

static HMODULE g_torch_fused = NULL;
static tkv_lin_fn p_lin = NULL;

static int load_bridge(void) {
    if (g_torch_fused) return 1;
    const char* env = getenv(TKV_TORCH_PATH_ENV);
    HMODULE h = NULL;
    HMODULE self = NULL;
    if (env && env[0]) {
        h = LoadLibraryA(env);
    } else {
        /* 1) look alongside this module first */
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
                               (LPCTSTR)&load_bridge, &self) && self) {
            char dir[MAX_PATH] = {0};
            DWORD n = GetModuleFileNameA(self, dir, MAX_PATH);
            if (n > 0 && n < MAX_PATH) {
                char* slash = strrchr(dir, '\\');
                if (slash) {
                    strcpy(slash + 1, "tkv_torch_fused.dll");
                    h = LoadLibraryExA(dir, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
                }
            }
        }
        /* 2) fall back to PATH/CWD search */
        if (!h) h = LoadLibraryA("tkv_torch_fused.dll");
    }
    if (!h) return 0;
    p_lin = (tkv_lin_fn)GetProcAddress(h, "TkvTorchLinearFwd");
    if (!p_lin) { FreeLibrary(h); return 0; }
    g_torch_fused = h;
    return 1;
}

/* Tiny probe: y = x @ w + b in-place into caller buffer.
 * x/w/b are [2,2]/[2,2]/[2].  rc<0 = load/call error -> caller falls back. */
EXPORT int TkvStep124Probe(const float* x, const float* w, const float* b,
                           float* y, int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !b || !y) return -1;
    if (!load_bridge()) return -9;
    return p_lin(x, w, b, n, in_d, out_d, y);
}

/* D5-3 segment I: native embed helper.
 *   out[t, j] = wte[ids[t], j] + wpe[pos[t], j]
 * ids/pos: [n] int64; wte/wpe: [V, h] float32 contiguous; out: [n, h].
 * BIT-EXACT với đường interpreted .tkv (cùng phép: f32 add, cùng thứ tự). */
EXPORT int TkvStep124Embed(const int64_t* ids, const int64_t* pos,
                           const float* wte, const float* wpe,
                           float* out, int64_t n, int64_t h) {
    if (!ids || !pos || !wte || !wpe || !out) return -1;
    if (n <= 0 || h <= 0) return -2;
    for (int64_t t = 0; t < n; t++) {
        int64_t r = ids[t];
        int64_t p = pos[t];
        const float* rw = wte + r * h;
        const float* rp = wpe + p * h;
        float* o = out + t * h;
        int64_t j = 0;
        /* AVX2: 8 floats at a time; tail handled scalar. */
#if defined(__AVX2__) || defined(_M_AVX2)
        for (; j + 8 <= h; j += 8) {
            __m256 av = _mm256_loadu_ps(rw + j);
            __m256 ap = _mm256_loadu_ps(rp + j);
            _mm256_storeu_ps(o + j, _mm256_add_ps(av, ap));
        }
#endif
        for (; j < h; j++) o[j] = rw[j] + rp[j];
    }
    return 0;
}
