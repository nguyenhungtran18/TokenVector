/* probe_flash2.c - verify flash fwd/bwd + BwdFusedLse vs naive f64 reference, then time.
 * Chay: probe_flash2.exe [n]
 */
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#include <time.h>

typedef int (*fwd_t)(const float*, int, float*, int, int, int, int, int, double);
typedef int (*fwdlse_t)(const float*, int, float*, int, float*, int, int, int, int, int, double);
typedef int (*bwd_t)(const float*, int, const float*, int, float*, int, float*, int, int, int, int, int, double);
typedef int (*bwdlse_t)(const float*, int, const float*, int, const float*, int, const float*, int,
                        float*, int, float*, int, int, int, int, int, double);

static double now_ms(void) {
    struct timespec ts; timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(int argc, char** argv) {
    int n = (argc > 1) ? atoi(argv[1]) : 256;
    int hh = 768, hd = 64, head = 5;
    double inv = 1.0 / 8.0;
    long long qkv_len = (long long)n * 3 * hh;
    long long dctx_len = (long long)n * hh;
    long long ctx_len = (long long)n * hd;
    long long dqo_len = (long long)n * 3 * hd;
    float* qkv  = (float*)malloc(qkv_len * 4);
    float* dctx = (float*)malloc(dctx_len * 4);
    float* ctx  = (float*)malloc(ctx_len * 4);
    float* ctx2 = (float*)malloc(ctx_len * 4);
    float* lse  = (float*)malloc((size_t)n * 4);
    float* dqo  = (float*)malloc(dqo_len * 4);
    float* dqo2 = (float*)malloc(dqo_len * 4);
    srand(12345);
    for (long long i = 0; i < qkv_len; i++)  qkv[i]  = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
    for (long long i = 0; i < dctx_len; i++) dctx[i] = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;

    HMODULE hmod = LoadLibraryA("tkv_simd_native.dll");
    if (!hmod) { printf("load fail\n"); return 1; }
    fwd_t    fwd    = (fwd_t)GetProcAddress(hmod, "FlashAttentionFwdFused");
    fwdlse_t fwdlse = (fwdlse_t)GetProcAddress(hmod, "FlashAttentionFwdLse");
    bwd_t    bwd    = (bwd_t)GetProcAddress(hmod, "FlashAttentionBwdFused");
    bwdlse_t bwdlse = (bwdlse_t)GetProcAddress(hmod, "FlashAttentionBwdFusedLse");
    if (!fwd || !bwd) { printf("sym fail\n"); return 1; }

    int rc = fwd(qkv, (int)qkv_len, ctx, (int)ctx_len, n, hh, hd, head, inv);
    printf("fwd rc=%d\n", rc);
    if (rc != 0) return 2;

    /* ---- naive reference (f64) ---- */
    int coff_q = head * hd, coff_k = coff_q + hh, coff_v = coff_q + 2 * hh;
    double* P = (double*)calloc((size_t)n * n, sizeof(double));
    double* dsum = (double*)malloc(sizeof(double) * n);
    double maxf = 0.0;
    for (int t = 0; t < n; t++) {
        double m = -1e30;
        for (int u = 0; u <= t; u++) {
            double acc = 0.0;
            for (int d = 0; d < hd; d++)
                acc += (double)qkv[(long long)t * 3 * hh + coff_q + d] *
                       (double)qkv[(long long)u * 3 * hh + coff_k + d];
            acc *= inv;
            P[(long long)t * n + u] = acc;
            if (acc > m) m = acc;
        }
        double ssum = 0.0;
        for (int u = 0; u <= t; u++) { double e = exp(P[(long long)t * n + u] - m); P[(long long)t * n + u] = e; ssum += e; }
        for (int u = 0; u <= t; u++) P[(long long)t * n + u] /= ssum;
        for (int d = 0; d < hd; d++) {
            double acc = 0.0;
            for (int u = 0; u <= t; u++) acc += P[(long long)t * n + u] * (double)qkv[(long long)u * 3 * hh + coff_v + d];
            double diff = fabs(acc - (double)ctx[(long long)t * hd + d]);
            if (diff > maxf) maxf = diff;
        }
        double ds = 0.0;
        for (int d = 0; d < hd; d++)
            ds += (double)dctx[(long long)t * hh + coff_q + d] * (double)ctx[(long long)t * hd + d];
        dsum[t] = ds;
    }
    printf("fwd  vs naive: max_abs=%.4e\n", maxf);

    rc = bwd(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx, (int)ctx_len, dqo, (int)dqo_len, n, hh, hd, head, inv);
    printf("bwd rc=%d\n", rc);
    if (rc != 0) return 3;

    double maxdq = 0.0, maxdk = 0.0, maxdv = 0.0;
    for (int t = 0; t < n; t++) {
        for (int d = 0; d < hd; d++) {
            double sumd = 0.0;
            for (int u = 0; u <= t; u++) {
                double dp = 0.0;
                for (int dd = 0; dd < hd; dd++)
                    dp += (double)dctx[(long long)t * hh + coff_q + dd] * (double)qkv[(long long)u * 3 * hh + coff_v + dd];
                double ds = P[(long long)t * n + u] * (dp - dsum[t]);
                sumd += ds * (double)qkv[(long long)u * 3 * hh + coff_k + d];
            }
            double diff = fabs(sumd * inv - (double)dqo[(long long)t * 3 * hd + d]);
            if (diff > maxdq) maxdq = diff;
        }
    }
    for (int u = 0; u < n; u++) {
        for (int d = 0; d < hd; d++) {
            double sumdv = 0.0, sumdk = 0.0;
            for (int t = u; t < n; t++) {
                double dp = 0.0;
                for (int dd = 0; dd < hd; dd++)
                    dp += (double)dctx[(long long)t * hh + coff_q + dd] * (double)qkv[(long long)u * 3 * hh + coff_v + dd];
                double ds = P[(long long)t * n + u] * (dp - dsum[t]);
                sumdv += P[(long long)t * n + u] * (double)dctx[(long long)t * hh + coff_q + d];
                sumdk += ds * (double)qkv[(long long)t * 3 * hh + coff_q + d];
            }
            double dv2 = fabs(sumdv - (double)dqo[(long long)u * 3 * hd + 2 * hd + d]);
            double dk2 = fabs(sumdk * inv - (double)dqo[(long long)u * 3 * hd + hd + d]);
            if (dv2 > maxdv) maxdv = dv2;
            if (dk2 > maxdk) maxdk = dk2;
        }
    }
    printf("bwd  vs naive: dq=%.4e dk=%.4e dv=%.4e\n", maxdq, maxdk, maxdv);

    /* ---- BwdFusedLse path: must match BwdFused ---- */
    if (fwdlse && bwdlse) {
        int rc2 = fwdlse(qkv, (int)qkv_len, ctx2, (int)ctx_len, lse, n, n, hh, hd, head, inv);
        int rc3 = bwdlse(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx2, (int)ctx_len, lse, n,
                         ctx2, (int)ctx_len, dqo2, (int)dqo_len, n, hh, hd, head, inv);
        double md = 0.0, mc = 0.0;
        for (long long i = 0; i < dqo_len; i++) { double x = fabs((double)dqo[i] - (double)dqo2[i]); if (x > md) md = x; }
        for (long long i = 0; i < ctx_len; i++) { double x = fabs((double)ctx[i] - (double)ctx2[i]); if (x > mc) mc = x; }
        printf("BwdFusedLse rc=%d/%d  dqo max_diff=%.4e  ctx max_diff=%.4e\n", rc2, rc3, md, mc);
    } else {
        printf("BwdFusedLse: NOT EXPORTED\n");
    }

    /* ---- timing ---- */
    for (int rep = 0; rep < 3; rep++) {
        double t0 = now_ms();
        fwd(qkv, (int)qkv_len, ctx, (int)ctx_len, n, hh, hd, head, inv);
        double t1 = now_ms();
        bwd(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx, (int)ctx_len, dqo, (int)dqo_len, n, hh, hd, head, inv);
        double t2 = now_ms();
        printf("t  fwd=%.2f ms  bwd(recompute)=%.2f ms", t1 - t0, t2 - t1);
        if (fwdlse && bwdlse) {
            double t3 = now_ms();
            fwdlse(qkv, (int)qkv_len, ctx2, (int)ctx_len, lse, n, n, hh, hd, head, inv);
            double t4 = now_ms();
            bwdlse(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx2, (int)ctx_len, lse, n,
                   ctx2, (int)ctx_len, dqo2, (int)dqo_len, n, hh, hd, head, inv);
            double t5 = now_ms();
            printf("  | fwd_lse=%.2f  bwd_lse=%.2f  TOTAL_lse=%.2f", t4 - t3, t5 - t4, (t4 - t3) + (t5 - t4));
        }
        printf("\n");
    }
    return 0;
}
