/* probe_flash.c - verify flash fwd/bwd vs naive reference (double accum).
 * Chay tu tools/simd_native/ :  probe_flash.exe [n]
 */
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#include <time.h>

typedef int (*fwd_t)(const float*, int, float*, int, int, int, int, int, double);
typedef int (*bwd_t)(const float*, int, const float*, int, float*, int, float*, int, int, int, int, int, double);

static double now_ms(void) {
    struct timespec ts; timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(int argc, char** argv) {
    int n = (argc > 1) ? atoi(argv[1]) : 256;
    int hh = 64, hd = 64; /* 1 head, h=64 -> headCount=1 */
    /* giu 1 head + h=768 de giong production (head=3 vi tri giua) */
    hh = 768;
    long long qkv_len = (long long)n * 3 * hh;
    long long dctx_len = (long long)n * hh;
    long long ctx_len = (long long)n * hd;
    long long dqo_len = (long long)n * 3 * hd;
    float* qkv = (float*)malloc(qkv_len * 4);
    float* dctx = (float*)malloc(dctx_len * 4);
    float* ctx = (float*)malloc(ctx_len * 4);
    float* dqo = (float*)malloc(dqo_len * 4);
    srand(12345);
    for (long long i = 0; i < qkv_len; i++) qkv[i] = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
    for (long long i = 0; i < dctx_len; i++) dctx[i] = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;

    HMODULE hmod = LoadLibraryA("tkv_simd_native.dll");
    if (!hmod) { printf("load fail\n"); return 1; }
    fwd_t fwd = (fwd_t)GetProcAddress(hmod, "FlashAttentionFwdFused");
    bwd_t bwd = (bwd_t)GetProcAddress(hmod, "FlashAttentionBwdFused");
    if (!fwd || !bwd) { printf("sym fail fwd=%p bwd=%p\n", (void*)fwd, (void*)bwd); return 1; }
    int head = 5;
    double inv = 1.0 / 8.0;
    int rc = fwd(qkv, (int)qkv_len, ctx, (int)ctx_len, n, hh, hd, head, inv);
    printf("fwd rc=%d\n", rc);
    if (rc != 0) return 2;

    /* naive reference: q@k^T * inv -> causal softmax (f64) -> @v */
    int coff_q = head * hd, coff_k = coff_q + hh, coff_v = coff_q + 2 * hh;
    double max_abs = 0.0, max_rel = 0.0;
    for (int t = 0; t < n; t++) {
        /* row t: diem so */
        double* sc = (double*)malloc(sizeof(double) * n);
        double m = -1e30;
        for (int u = 0; u < n; u++) {
            if (u > t) { sc[u] = 0.0; continue; }
            double acc = 0.0;
            for (int d = 0; d < hd; d++)
                acc += (double)qkv[(long long)t * 3 * hh + coff_q + d] *
                       (double)qkv[(long long)u * 3 * hh + coff_k + d];
            sc[u] = acc * inv;
            if (sc[u] > m) m = sc[u];
        }
        double ssum = 0.0;
        for (int u = 0; u <= t; u++) { sc[u] = exp(sc[u] - m); ssum += sc[u]; }
        for (int d = 0; d < hd; d++) {
            double acc = 0.0;
            for (int u = 0; u <= t; u++)
                acc += sc[u] * (double)qkv[(long long)u * 3 * hh + coff_v + d];
            acc /= ssum;
            double got = (double)ctx[(long long)t * hd + d];
            double diff = fabs(acc - got);
            double rel = diff / (fabs(acc) > 1e-6 ? fabs(acc) : 1e-6);
            if (diff > max_abs) max_abs = diff;
            if (rel > max_rel) max_rel = rel;
        }
        free(sc);
    }
    printf("fwd vs naive: max_abs=%.6e max_rel=%.6e\n", max_abs, max_rel);

    rc = bwd(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx, (int)ctx_len, dqo, (int)dqo_len, n, hh, hd, head, inv);
    printf("bwd rc=%d\n", rc);
    if (rc != 0) return 3;

    /* naive bwd check: recompute P, dV = P^T dctx, dP = dctx V^T, ds = P*(dP - rowsum(dctx*out)),
     *      dq = ds K * inv, dk = ds^T Q * inv  (so voi dqo) */
    {
        double* P = (double*)calloc((size_t)n * n, sizeof(double));
        for (int t = 0; t < n; t++) {
            double m = -1e30, ssum = 0.0;
            for (int u = 0; u <= t; u++) {
                double acc = 0.0;
                for (int d = 0; d < hd; d++)
                    acc += (double)qkv[(long long)t * 3 * hh + coff_q + d] *
                           (double)qkv[(long long)u * 3 * hh + coff_k + d];
                acc *= inv;
                P[(long long)t * n + u] = acc;
                if (acc > m) m = acc;
            }
            for (int u = 0; u <= t; u++) { double e = exp(P[(long long)t * n + u] - m); P[(long long)t * n + u] = e; ssum += e; }
            for (int u = 0; u <= t; u++) P[(long long)t * n + u] /= ssum;
        }
        double maxdq = 0.0, maxdk = 0.0, maxdv = 0.0;
        for (int t = 0; t < n; t++) {
            for (int d = 0; d < hd; d++) {
                /* dq[t,d] = inv * sum_u ds[t,u] * K[u,d] */
                double sumd = 0.0;
                double dotd = 0.0;
                for (int dd = 0; dd < hd; dd++)
                    dotd += (double)dctx[(long long)t * hh + coff_q + dd] * (double)ctx[(long long)t * hd + dd];
                for (int u = 0; u <= t; u++) {
                    double dp = 0.0;
                    for (int dd = 0; dd < hd; dd++)
                        dp += (double)dctx[(long long)t * hh + coff_q + dd] *
                              (double)qkv[(long long)u * 3 * hh + coff_v + dd];
                    double ds = P[(long long)t * n + u] * (dp - dotd);
                    sumd += ds * (double)qkv[(long long)u * 3 * hh + coff_k + d];
                }
                sumd *= inv;
                double got = (double)dqo[(long long)t * 3 * hd + d];
                double diff = fabs(sumd - got);
                if (diff > maxdq) maxdq = diff;
            }
        }
        /* vdv/vdk: O(n^2 * hd) nho hon: tinh full nhung so diff */
        for (int d = 0; d < hd; d++) {
            for (int u = 0; u < n; u++) {
                double sumdv = 0.0, sumdk = 0.0;
                for (int t = u; t < n; t++) {
                    double dp = 0.0;
                    for (int dd = 0; dd < hd; dd++)
                        dp += (double)dctx[(long long)t * hh + coff_q + dd] *
                              (double)qkv[(long long)u * 3 * hh + coff_v + dd];
                    double dotd = 0.0;
                    for (int dd = 0; dd < hd; dd++)
                        dotd += (double)dctx[(long long)t * hh + coff_q + dd] * (double)ctx[(long long)t * hd + dd];
                    double ds = P[(long long)t * n + u] * (dp - dotd);
                    sumdv += P[(long long)t * n + u] * (double)dctx[(long long)t * hh + coff_q + d];
                    sumdk += ds * (double)qkv[(long long)t * 3 * hh + coff_q + d];
                }
                double gotv = (double)dqo[(long long)u * 3 * hd + 2 * hd + d];
                double gotk = (double)dqo[(long long)u * 3 * hd + hd + d];
                double diffv = fabs(sumdv - gotv);
                double diffk = fabs(sumdk * inv - gotk);
                if (diffv > maxdv) maxdv = diffv;
                if (diffk > maxdk) maxdk = diffk;
            }
        }
        printf("bwd vs naive: dq max_abs=%.6e  dk max_abs=%.6e  dv max_abs=%.6e\n", maxdq, maxdk, maxdv);
        free(P);
    }

    /* timing: fwd + bwd 1 head */
    for (int rep = 0; rep < 3; rep++) {
        double t0 = now_ms();
        fwd(qkv, (int)qkv_len, ctx, (int)ctx_len, n, hh, hd, head, inv);
        double t1 = now_ms();
        bwd(qkv, (int)qkv_len, dctx, (int)dctx_len, ctx, (int)ctx_len, dqo, (int)dqo_len, n, hh, hd, head, inv);
        double t2 = now_ms();
        printf("t fwd=%.1f ms  bwd=%.1f ms\n", t1 - t0, t2 - t1);
    }
    return 0;
}
