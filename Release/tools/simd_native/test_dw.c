/* test_dw.c — so BIT LinearDwFused voi duong .tkv hien tai (YEU CAU #10 Ask A).
 *
 * Duong tham chieu = dung y nguyen `smm_fwd_at` + `gflat[goff+k] += dw[k]`:
 *   xT[i][p] = x[p][i]                      (trans-A cua _tile_a_at_w)
 *   SgemmFull(xT, gy, dw, ..., m=in_d, n=out_d, k=n, ndim=out_d, T, mode=1)
 * SgemmFull noi bo build tile T x T + goi DUNG SgemmF32 + ACC tang dan p0 —
 * chinh la chuoi phep tinh cua wrapper .tkv (da tung dat bit 0.0 o request #2).
 *
 * Kiem: (a) memcmp tung bit; (b) thoi gian best-of-5 cho shape that.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

__declspec(dllimport) int SgemmFull(const float* a, const float* b, float* c,
                                    int a_len, int b_len, int c_len,
                                    int m, int n, int k, int ndim, int trans_b,
                                    int T, int mode);
__declspec(dllimport) int LinearDwFused(const float* x, int x_len, const float* gy,
                                        int gy_len, float* gdw, int gdw_len,
                                        int gdw_off, int n, int in_d, int out_d);

static double now_ms(void) {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

static int rup64(int x) { int r = 64; while (r < x) r += 64; return r; }
static int tilek(int k) { int r = rup64(k); if (r > 1024) r = 1024; return r; }

static float rf(unsigned int* st) {
    *st = (*st * 1103515245u + 12345u) & 0x7fffffffu;
    return ((float)((*st >> 8) & 0xffff) / 65536.0f) * 2.0f - 1.0f;
}

int main(void) {
    int shapes[][3] = {
        {8, 3072, 768},     /* dw2 cua mlp_bwd (shape that, seq8)   */
        {8, 768, 2304},     /* dwqkv cua attention_bwd              */
        {8, 768, 3072},     /* dw1 cua linear_bwd (mlp)             */
        {8, 2304, 768},     /* dx2-like / qkv nguoc                  */
        {128, 768, 768},    /* k = 128 > GEMM_KC -> nhieu block 64  */
        {200, 96, 64},      /* k le, T nho                             */
        {3, 8, 16},         /* shape nho                              */
        {1, 64, 64},        /* k = 1                                  */
    };
    int ns = (int)(sizeof(shapes) / sizeof(shapes[0]));
    int fails = 0;

    for (int s = 0; s < ns; s++) {
        int k = shapes[s][0], in_d = shapes[s][1], out_d = shapes[s][2];
        long long nx = (long long)k * in_d, ny = (long long)k * out_d;
        long long nd = (long long)in_d * out_d;
        float* x   = (float*)malloc((size_t)nx * 4);
        float* gy  = (float*)malloc((size_t)ny * 4);
        float* xT  = (float*)malloc((size_t)nx * 4);
        float* ref = (float*)calloc((size_t)nd, 4);
        float* got = (float*)calloc((size_t)nd, 4);
        float* got2 = (float*)calloc((size_t)nd, 4);
        unsigned int st = 12345u + (unsigned int)s;
        for (long long i = 0; i < nx; i++) x[i] = rf(&st);
        for (long long i = 0; i < ny; i++) gy[i] = rf(&st);
        /* xT[i][p] = x[p][i] */
        for (int p = 0; p < k; p++)
            for (int i = 0; i < in_d; i++) xT[(long long)i * k + p] = x[(long long)p * in_d + i];

        int T = tilek(k);
        int rmin = rup64(in_d < out_d ? in_d : out_d);
        if (rmin < T) T = rmin;

        int rc_ref = SgemmFull(xT, gy, ref, (int)nx, (int)ny, (int)nd,
                               in_d, out_d, k, out_d, 0, T, 1);
        int rc_new = LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);

        /* (c) chay lan 2 vao cung mang (tich luy) — kiem duong += that */
        int rc_new2 = LinearDwFused(x, (int)nx, gy, (int)ny, got2, (int)nd, 0, k, in_d, out_d);
        int rc_new3 = LinearDwFused(x, (int)nx, gy, (int)ny, got2, (int)nd, 0, k, in_d, out_d);

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
        /* lan 2 phai bang ref*2 theo dung nghia cong don 2 lan */
        long long bad2 = 0;
        for (long long i = 0; i < nd; i++) {
            float want = ref[i] + ref[i];
            if (memcmp(&want, &got2[i], 4) != 0) bad2++;
        }

        /* timing best-of-5 */
        double tref = 1e30, tnew = 1e30;
        for (int rep = 0; rep < 5; rep++) {
            double t0 = now_ms();
            SgemmFull(xT, gy, ref, (int)nx, (int)ny, (int)nd, in_d, out_d, k, out_d, 0, T, 1);
            double t1 = now_ms();
            if (t1 - t0 < tref) tref = t1 - t0;
            t0 = now_ms();
            LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);
            t1 = now_ms();
            if (t1 - t0 < tnew) tnew = t1 - t0;
        }

        if (bad2) {
            for (long long i = 0; i < nd; i++) {
                float want = ref[i] + ref[i];
                if (memcmp(&want, &got2[i], 4) != 0) {
                    printf("    [bad2] i=%lld ref=%.9g want=%.9g got2=%.9g\n", i, ref[i], want, got2[i]);
                    break;
                }
            }
        }
        printf("k=%-5d in_d=%-5d out_d=%-5d T=%-4d rc=%d/%d/%d/%d bit_bad=%-6lld (maxd=%.3g) bit_bad2=%-6lld  ref=%7.3f ms  new=%7.3f ms  x%.2f\n",
               k, in_d, out_d, T, rc_ref, rc_new, rc_new2, rc_new3, bad, maxd, bad2, tref, tnew,
               tnew > 0 ? tref / tnew : 0.0);
        if (bad != 0 || bad2 != 0 || rc_new != 0 || rc_ref != 0) {
            fails++;
            for (long long i = 0; i < nd && i < 400000000LL; i++) {
                if (memcmp(&ref[i], &got[i], 4) != 0) {
                    printf("    first diff i=%lld ref=%.9g got=%.9g\n", i, ref[i], got[i]);
                    break;
                }
            }
        }
        free(x); free(gy); free(xT); free(ref); free(got); free(got2);
    }
    printf(fails == 0 ? "ALL BIT-EXACT\n" : "CO %d SHAPE LECH\n", fails);
    return fails == 0 ? 0 : 1;
}
