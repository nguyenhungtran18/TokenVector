/* tkv_prof.c - TKV_PROF=1 in thong so tuan luot tung op (stderr) khi process thoat. */
#include "tkv_prof.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

long long g_tkv_prof_ns[TKV_PROF_N];
int g_tkv_prof_n[TKV_PROF_N];
int g_tkv_prof_on = -1;   /* -1 chua doc env */

#if defined(__GNUC__) || defined(__clang__)
__attribute__((constructor)) static void tkv_prof_init(void) {
    const char* s = getenv("TKV_PROF");
    g_tkv_prof_on = (s && s[0] && s[0] != '0') ? 1 : 0;
}
#else
/* Windows/MSVC: invarian thi TKV_PROF TAT; gate Linux-only (WSL/Colab). */
static void tkv_prof_init(void) { g_tkv_prof_on = 0; }
#endif

static const char* tkv_prof_names[TKV_PROF_N] = {
    "LN_BWD", "LN_FWD", "GELU_BWD", "GELU_FWD", "SOFTMAX_BWD",
    "ATTN_BWD", "ATTN_BWD_MULTI", "ATTN_BWD_MERGE", "ATTN_FWD",
    "LIN_DX", "LIN_DW", "LMHEAD_BWD", "EMB_BWD", "BIAS_GRAD"
};

__attribute__((destructor)) static void tkv_prof_dump(void) {
    if (g_tkv_prof_on != 1) return;
    long long tot = 0;
    int i;
    for (i = 0; i < TKV_PROF_N; i++) tot += g_tkv_prof_ns[i];
    fprintf(stderr, "[TKV_PROF] tong op-time = %.3f ms  (cac op co the chay song song -> tong > wall time)\n",
            (double)tot / 1e6);
    for (i = 0; i < TKV_PROF_N; i++) {
        if (g_tkv_prof_n[i] == 0) continue;
        fprintf(stderr, "[TKV_PROF] %-14s n=%2d  %8.3f ms  (%5.1f%%)\n",
                tkv_prof_names[i], g_tkv_prof_n[i],
                (double)g_tkv_prof_ns[i] / 1e6,
                tot > 0 ? 100.0 * (double)g_tkv_prof_ns[i] / (double)tot : 0.0);
    }
    fflush(stderr);
}
