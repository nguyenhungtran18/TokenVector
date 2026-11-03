/* test_dx.c — so BIT LinearDxFused voi duong tham chieu SgemmFull (Ask B).
 *
 * dx = smm_dot(gy, w, m, n, k) -> _smm_core (k>=256, m<=256) -> _smm_full ->
 *   SgemmFull(gy, w, dx, ..., m, n, k, ndim=k, trans_b=1, T=256, mode=0).
 * SgemmFull noi bo build tile T x T + goi DUNG SgemmF32 + ACC tang dan p0.
 *
 * LinearDxFused goi TRUC TIEP gemm_rect_f32/gemm_rows_f32 voi i1 = m (chi hang
 * that) — bo hang thua [m, T) ma SgemmF32 van tinh nhung khong doc.
 *
 * Kiem: (a) memcmp tung bit tren shape that + shape le; (b) rc != 0 cho shape
 * bi tu choi (m>256, m%4, k<256) de caller fallback; (c) thoi gian best-of-5.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

__declspec(dllimport) int SgemmFull(const float* a, const float* b, float* c,
                                    int a_len, int b_len, int c_len,
                                    int m, int n, int k, int ndim, int trans_b,
                                    int T, int mode);
__declspec(dllimport) int LinearDxFused(const float* gy, int gy_len,
                                        const float* w, int w_len,
                                        float* dx, int dx_len,
                                        int m, int n, int k);

static double now_ms(void) {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

static float rf(unsigned int* st) {
    *st = (*st * 1103515245u + 12345u) & 0x7fffffffu;
    return ((float)((*st >> 8) & 0xffff) / 65536.0f) * 2.0f - 1.0f;
}

int main(void) {
    /* {m, n=in_d, k=out_d, rc_ mong_doi} — dx = gy[m,k] @ w[n,k]^T -> dx[m,n]
     * rc_ mong_doi = 0 -> native PHAI tinh va BIT-EXACT;
     *               am -> native PHAI tu choi (caller fallback smm_dot). */
    int shapes[][4] = {
        {8, 768, 3072, 0},    /* dx1 mlp w1 (shape that, seq8)              */
        {8, 3072, 768, 0},    /* dx2 mlp w2 (shape that)                    */
        {8, 768, 2304, 0},    /* dxqkv attn w_qkv (shape that)              */
        {8, 768, 768, 0},     /* dxproj attn w_proj (shape that)             */
        {256, 768, 3072, 0},  /* m = T (full rows — khong cat hang nhung van bit) */
        {4, 64, 300, -12},    /* k=300 le 256 -> p-tile le -> -12 (guard)     */
        {12, 300, 512, 0},    /* n=300 khong chia 256 -> jb le                */
        {8, 100, 256, 0},     /* n=100 -> jb le + j-tail trong micro_f32      */
        {16, 256, 256, 0},    /* n = T, k = T (tile vuong nho)                */
        {200, 768, 768, 0},   /* nhieu block ic (m > GEMM_MC), p day           */
    };
    int ns = (int)(sizeof(shapes) / sizeof(shapes[0]));
    int fails = 0;

    for (int s = 0; s < ns; s++) {
        int m = shapes[s][0], n = shapes[s][1], k = shapes[s][2];
        int rc_want = shapes[s][3];
        long long ng = (long long)m * k, nw = (long long)n * k;
        long long nd = (long long)m * n;
        float* gy  = (float*)malloc((size_t)ng * 4);
        float* w   = (float*)malloc((size_t)nw * 4);
        float* ref = (float*)calloc((size_t)nd, 4);
        float* got = (float*)calloc((size_t)nd, 4);
        unsigned int st = 12345u + (unsigned int)s;
        for (long long i = 0; i < ng; i++) gy[i] = rf(&st);
        for (long long i = 0; i < nw; i++) w[i] = rf(&st);

        /* tham chieu: SgemmFull(gy, w, dx, m, n, k, ndim=k, trans_b=1, T=256, mode=0) */
        int rc_ref = SgemmFull(gy, w, ref, (int)ng, (int)nw, (int)nd,
                               m, n, k, k, 1, 256, 0);
        int rc_new = LinearDxFused(gy, (int)ng, w, (int)nw, got, (int)nd, m, n, k);

        /* native tu choi dung mong doi -> caller fallback, KHONG so bit */
        if (rc_want != 0) {
            printf("m=%-4d n=%-5d k=%-5d rc=%d/%d (want %d) -> NATIVE TU CHOI, caller fallback\n",
                   m, n, k, rc_ref, rc_new, rc_want);
            if (rc_new != rc_want) { fails++; printf("    SAI: muon rc=%d\n", rc_want); }
            free(gy); free(w); free(ref); free(got);
            continue;
        }
        if (rc_new != 0) {
            printf("m=%-4d n=%-5d k=%-5d rc=%d (muon 0 nhung bi tu choi)\n", m, n, k, rc_new);
            fails++;
            free(gy); free(w); free(ref); free(got);
            continue;
        }

        long long bad = 0;
        double maxd = 0.0;
        for (long long i = 0; i < nd; i++) {
            if (memcmp(&ref[i], &got[i], 4) != 0) {
                bad++;
                double d = (double)ref[i] - (double)got[i];
                if (d < 0) d = -d;
                if (d > maxd) maxd = d;
            }
        }

        /* timing best-of-5 */
        double tref = 1e30, tnew = 1e30;
        for (int rep = 0; rep < 5; rep++) {
            double t0 = now_ms();
            SgemmFull(gy, w, ref, (int)ng, (int)nw, (int)nd, m, n, k, k, 1, 256, 0);
            double t1 = now_ms();
            if (t1 - t0 < tref) tref = t1 - t0;
            t0 = now_ms();
            LinearDxFused(gy, (int)ng, w, (int)nw, got, (int)nd, m, n, k);
            t1 = now_ms();
            if (t1 - t0 < tnew) tnew = t1 - t0;
        }

        printf("m=%-4d n=%-5d k=%-5d rc=%d/%d bit_bad=%-6lld (maxd=%.3g)  ref=%8.3f ms  new=%8.3f ms  x%.2f\n",
               m, n, k, rc_ref, rc_new, bad, maxd, tref, tnew,
               tnew > 0 ? tref / tnew : 0.0);
        if (bad != 0 || rc_ref != 0) {
            fails++;
            for (long long i = 0; i < nd; i++) {
                if (memcmp(&ref[i], &got[i], 4) != 0) {
                    printf("    first diff i=%lld ref=%.9g got=%.9g\n", i, ref[i], got[i]);
                    break;
                }
            }
        }
        free(gy); free(w); free(ref); free(got);
    }

    /* ---- kiem tu choi (caller phai fallback smm_dot) ---- */
    {
        int m = 512, n = 768, k = 3072;   /* m > 256 -> _smm_pk -> -10 */
        long long ng = (long long)m * k, nw = (long long)n * k, nd = (long long)m * n;
        float* gy = (float*)malloc((size_t)ng * 4);
        float* w  = (float*)malloc((size_t)nw * 4);
        float* dx = (float*)malloc((size_t)nd * 4);
        unsigned int st = 99u;
        for (long long i = 0; i < ng; i++) gy[i] = rf(&st);
        for (long long i = 0; i < nw; i++) w[i] = rf(&st);
        int rc = LinearDxFused(gy, (int)ng, w, (int)nw, dx, (int)nd, m, n, k);
        printf("reject m=512 (m>256):     rc=%d (want -10) %s\n", rc, rc == -10 ? "OK" : "SAI");
        if (rc != -10) fails++;
        free(gy); free(w); free(dx);
    }
    {
        int m = 6, n = 768, k = 3072;      /* m % 4 != 0 -> i-tail -> -11 */
        long long ng = (long long)m * k, nw = (long long)n * k, nd = (long long)m * n;
        float* gy = (float*)malloc((size_t)ng * 4);
        float* w  = (float*)malloc((size_t)nw * 4);
        float* dx = (float*)malloc((size_t)nd * 4);
        unsigned int st = 98u;
        for (long long i = 0; i < ng; i++) gy[i] = rf(&st);
        for (long long i = 0; i < nw; i++) w[i] = rf(&st);
        int rc = LinearDxFused(gy, (int)ng, w, (int)nw, dx, (int)nd, m, n, k);
        printf("reject m=6 (m%%4):        rc=%d (want -11) %s\n", rc, rc == -11 ? "OK" : "SAI");
        if (rc != -11) fails++;
        free(gy); free(w); free(dx);
    }
    {
        int m = 8, n = 768, k = 128;       /* k < 256 -> khong di _smm_full -> -9 */
        long long ng = (long long)m * k, nw = (long long)n * k, nd = (long long)m * n;
        float* gy = (float*)malloc((size_t)ng * 4);
        float* w  = (float*)malloc((size_t)nw * 4);
        float* dx = (float*)malloc((size_t)nd * 4);
        unsigned int st = 97u;
        for (long long i = 0; i < ng; i++) gy[i] = rf(&st);
        for (long long i = 0; i < nw; i++) w[i] = rf(&st);
        int rc = LinearDxFused(gy, (int)ng, w, (int)nw, dx, (int)nd, m, n, k);
        printf("reject k=128 (k<256):    rc=%d (want -9)  %s\n", rc, rc == -9 ? "OK" : "SAI");
        if (rc != -9) fails++;
        free(gy); free(w); free(dx);
    }

    {
        int m = 8, n = 768, k = 300;       /* k % 256 != 0 -> p-tile le -> -12 */
        long long ng = (long long)m * k, nw = (long long)n * k, nd = (long long)m * n;
        float* gy = (float*)malloc((size_t)ng * 4);
        float* w  = (float*)malloc((size_t)nw * 4);
        float* dx = (float*)malloc((size_t)nd * 4);
        unsigned int st = 96u;
        for (long long i = 0; i < ng; i++) gy[i] = rf(&st);
        for (long long i = 0; i < nw; i++) w[i] = rf(&st);
        int rc = LinearDxFused(gy, (int)ng, w, (int)nw, dx, (int)nd, m, n, k);
        printf("reject k=300 (k%%256):    rc=%d (want -12) %s\n", rc, rc == -12 ? "OK" : "SAI");
        if (rc != -12) fails++;
        free(gy); free(w); free(dx);
    }

    printf(fails == 0 ? "ALL BIT-EXACT\n" : "CO %d TRUONG HOP LECH\n", fails);
    return fails == 0 ? 0 : 1;
}
