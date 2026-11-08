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
