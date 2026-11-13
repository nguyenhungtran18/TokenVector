/* tkv_prof.h - per-op timing khi TKV_PROF=1 (env). 2 nhánh/lần gọi khi tắt. */
#ifndef TKV_PROF_H
#define TKV_PROF_H

#if defined(_WIN32)
#include <windows.h>
static inline long long TkvProfNowNs(void) {
    LARGE_INTEGER f, c;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&c);
    return (long long)(c.QuadPart * 1000000000LL / f.QuadPart);
}
#else
#include <time.h>
static inline long long TkvProfNowNs(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000000000LL + (long long)ts.tv_nsec;
}
#endif

typedef enum {
    TKV_PROF_LN_BWD = 0,
    TKV_PROF_LN_FWD,
    TKV_PROF_GELU_BWD,
    TKV_PROF_GELU_FWD,
    TKV_PROF_SOFTMAX_BWD,
    TKV_PROF_ATTN_BWD,
    TKV_PROF_ATTN_BWD_MULTI,
    TKV_PROF_ATTN_BWD_MERGE,
    TKV_PROF_ATTN_FWD,
    TKV_PROF_LIN_DX,
    TKV_PROF_LIN_DW,
    TKV_PROF_LMHEAD_BWD,
    TKV_PROF_EMB_BWD,
    TKV_PROF_BIAS_GRAD,
    TKV_PROF_N
} TkvProfId;

#ifdef __cplusplus
extern "C" {
#endif

extern long long g_tkv_prof_ns[TKV_PROF_N];
extern int g_tkv_prof_n[TKV_PROF_N];
extern int g_tkv_prof_on;

#ifdef __cplusplus
}
#endif

#endif /* TKV_PROF_H */
