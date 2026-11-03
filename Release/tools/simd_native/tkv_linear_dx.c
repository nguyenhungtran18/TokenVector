/* tkv_linear_dx.c — YEU CAU #10 ASK B (2026-11-01)
 * ================================================================
 * dx[m x n] = gy[m x k] * w[n x k]^T   (trans_b = 1, ndim = k)
 *   dx[i*n + j] = sum_{p<k} gy[i*k + p] * w[j*k + p]
 *
 * Thay cho `dx = smm_dot(gy, w, m, n, k)` trong gpt2_linear_bwd.
 *
 * VI SAO NHANH
 * -------------
 * `smm_dot` -> _smm_core: k >= 256 va m <= 256 -> _smm_full ->
 *   simd_gemm_full(ad, bd, cd, m, n, k, ndim=k, trans_b=1, T=256, mode=0).
 * Trong SgemmFull: i0 chi lap 1 lan vi ib = min(256, m) = m, NHUNG
 * SgemmF32(At, Bt, Ct, 256) van tinh day du 256 hang; chi r < ib = 8 hang
 * duoc _acc_f cong vao cd.  => 248/256 hang = 32x phep nhan THUA.
 * Do la nguon 12.69 ms cua dx1 (w1: m=8, n=768, k=3072).
 *
 * O day: giu NGUYEN toan bo cau truc tich luy, chi bo hang thua.
 *
 * BIT-EXACT (bat buoc — loss phai EXACT)
 * ---------------------------------------
 * Doi chieu chinh xac voi chuoi .tkv (T = 256, k = 3072 chia het 256):
 *   dx[i*n+j] = ((((0 + Ct_0) + Ct_1) + ... ) + Ct_11)   (12 p-tile)
 *
 * 1. TILE BUILD — giong y het full_tile_a / full_tile_b (row-major T x T):
 *      At[i][p] = (p < pw) ? gy[i*k + p0 + p] : 0
 *      Bt[p][j] = (p < pw && j < jb) ? w[(j0+j)*ndim + p0 + p] : 0
 *    At[i >= m] = 0 -> Ct[i >= m] = 0, va _acc_f chi doc r < ib = m
 *    nen viec chi tinh r < m KHONG doi 1 phan tu nao duoc dung.
 *
 * 2. k_eff = tkv_k_eff(Bt, At, T) — DAT BUOC.
 *    SgemmF32 rut kc cua block cuoi xuong k_eff khi hang (T-1) cua Bt toan 0.
 *    Neu bo qua, chuoi FMA dai hon va KET QUA KHAC BIT.
 *    tkv_k_eff doc day du At[T x T] — hang i >= m = 0 khong phai Inf/NaN
 *    nen khong the trigger -> tinh tren day du T hang giong ban goc.
 *
 * 3. GEMM — goi lai DUNG SgemmF32 (cung pool + cung shape dispatch + cung
 *    MT) voi Ct 256 x 256. SgemmF32 luon tinh n x n = 256 x 256 nen PHAI
 *    giu At/Ct 256 x 256 -> KHONG bot duoc 32x bang cach nay.
 *
 *    => Goi micro kernel TRUC TIEP (ban sao doc thu tu cung tu
 *    tkv_simd_native.c: pack_b_f32 + micro_f32 + GEMM_KC/MC/NC/BPL).
 *    Moi phan tu Ct[r][c] chi phu thuoc At[r][:] va Bt[:][c] (micro_f32
 *    moi lane = 1 cot, vong p tang dan FMA) -> cat i1 = m cho CUNG BIT.
 *    KC = 64 giu nguyen -> thu tu tich luy k moi phan tu khong doi.
 *    NC/BPL/MC cung so voi SgemmF32 voi n = 256 (nc = GEMM_NC = 64,
 *    bpl = GEMM_BPL = 68, khong phai lop VOCAB) -> cung so luong block.
 *
 *    Chuoi tich luy moi o (giong nghia voi SgemmF32):
 *      Ct[r][c] = 0
 *      for pc = 0; pc < k_eff; pc += 64:  kc = min(64, k_eff - pc)
 *          s = chuoi FMA tuan tu p = pc..pc+kc-1, bat dau tu 0
 *          Ct[r][c] = Ct[r][c] + s
 *    (Day chinh xac la micro_f32: setzero moi block kc, roi load-add-store.)
 *
 * 4. ACC — mode 0 && p0 == 0: memset +0.0f (KHONG dung "= Ct" — do doi
 *    -0.0f), roi cd[bc] = cd[bc] + Ct[bt] tang dan p0, giong _acc_f.
 *
 * KHONG can /fp:precise: khong co cau `a + b + c` thuong — chi intrinsics
 * (_mm256_fmadd_ps = FMA that, khong doi voi /fp) va tung phep cong don
 * doc/ghi (khong tai lien ket duoc). Nen dat trong cung TU /fp:fast.
 *
 * TRA VE 0 = OK; am = loi ro (caller .tkv fallback duong cu nguyen ven):
 *   -1 tham so NULL, -2 shape <= 0, -5 list qua ngan, -6 khong du bo nho,
 *   -7 T ngoai [4, 4096], -8 ndim < k (layout trans_b=1 khong kha thi),
 *   -9 k < 256 (khong di qua _smm_full: duong .tkv dung
 *        T = min(_tilek(k), roundup64(min(m,n))) khac -> khong dam bao bit),
 *   -10 m > 256 (_smm_full chi duoc chon khi m <= 256; m > 256 -> _smm_pk
 *        = packed native, thu tu tich luy khac hoan toan),
 *   -11 m % 4 != 0 (micro_f32 i-tail di duong scalar `s0 += a*b` — khac FMA
 *        neu /fp khac; duong goc (i1 = 256) luon het i-loop -> khong co tail).
 *
 * Caller truyen T = 256 (cung so voi _smm_full — HARDCODE 256). Neu
 * _smm_full doi T, phai sua dong nay cung luc.
 */
#include <immintrin.h>
#include <stdlib.h>
#include <string.h>

#define EXPORT __declspec(dllexport)

/* ==== Ban sao DOC THU TU tu tkv_simd_native.c (cung TU /fp:fast) ==== */
#ifndef GEMM_KC
#define GEMM_KC 64
#endif
#ifndef GEMM_MC
#define GEMM_MC 64
#endif
#ifndef GEMM_NC
#define GEMM_NC 64
#endif
#ifndef GEMM_BPL
#define GEMM_BPL (GEMM_NC + 4)
#endif
#ifndef GEMM_BPL_MAX
#define GEMM_BPL_MAX (128 + 4)
#endif
#ifndef GEMM_BPL_MAX
#define GEMM_BPL_MAX (128 + 4)
#endif

/* pack_b_f32 — y het ban goc: copy kc hang cua B (stride n) vao panel bp. */
static void dx_pack_b_f32(const float* b, float* bp, int n, int pc, int kc,
                          int jc, int nc, int bpl) {
    for (int p = 0; p < kc; p++) {
        const float* src = b + (long long)(pc + p) * n + jc;
        float* dst = bp + (long long)p * bpl;
        for (int j = 0; j < nc; j++) dst[j] = src[j];
    }
}

/* micro_f32 — y het ban goc (4x16, FMA that, moi lane = 1 cot, vong p tang
 * dan). Chi khac o vi tri goi: ta goi voi mc = ib (m) thay vi 64.
 * i-tail (mc % 4 != 0) bi tu choi truoc (-11) nen khong bao gio xay ra. */
static void dx_micro_f32(const float* a, int lda, const float* bp, float* c,
                         int n, int mc, int nc, int kc, int bpl) {
    int i = 0;
    for (; i + 4 <= mc; i += 4) {
        const float* ai = a + (long long)i * lda;
        float* ci = c + (long long)i * n;
        int j = 0;
        for (; j + 16 <= nc; j += 16) {
            __m256 c0a = _mm256_setzero_ps(), c0b = _mm256_setzero_ps();
            __m256 c1a = _mm256_setzero_ps(), c1b = _mm256_setzero_ps();
            __m256 c2a = _mm256_setzero_ps(), c2b = _mm256_setzero_ps();
            __m256 c3a = _mm256_setzero_ps(), c3b = _mm256_setzero_ps();
            for (int p = 0; p < kc; p++) {
                const float* brow = bp + (long long)p * bpl + j;
                __m256 vb0 = _mm256_loadu_ps(brow);
                __m256 vb1 = _mm256_loadu_ps(brow + 8);
                __m256 va0 = _mm256_set1_ps(ai[p]);
                __m256 va1 = _mm256_set1_ps(ai[lda + p]);
                __m256 va2 = _mm256_set1_ps(ai[2 * lda + p]);
                __m256 va3 = _mm256_set1_ps(ai[3 * lda + p]);
                c0a = _mm256_fmadd_ps(va0, vb0, c0a);
                c0b = _mm256_fmadd_ps(va0, vb1, c0b);
                c1a = _mm256_fmadd_ps(va1, vb0, c1a);
                c1b = _mm256_fmadd_ps(va1, vb1, c1b);
                c2a = _mm256_fmadd_ps(va2, vb0, c2a);
                c2b = _mm256_fmadd_ps(va2, vb1, c2b);
                c3a = _mm256_fmadd_ps(va3, vb0, c3a);
                c3b = _mm256_fmadd_ps(va3, vb1, c3b);
            }
            float* cj = ci + j;
            _mm256_storeu_ps(cj, _mm256_add_ps(_mm256_loadu_ps(cj), c0a));
            _mm256_storeu_ps(cj + 8, _mm256_add_ps(_mm256_loadu_ps(cj + 8), c0b));
            _mm256_storeu_ps(cj + n, _mm256_add_ps(_mm256_loadu_ps(cj + n), c1a));
            _mm256_storeu_ps(cj + n + 8, _mm256_add_ps(_mm256_loadu_ps(cj + n + 8), c1b));
            _mm256_storeu_ps(cj + 2 * n, _mm256_add_ps(_mm256_loadu_ps(cj + 2 * n), c2a));
            _mm256_storeu_ps(cj + 2 * n + 8, _mm256_add_ps(_mm256_loadu_ps(cj + 2 * n + 8), c2b));
            _mm256_storeu_ps(cj + 3 * n, _mm256_add_ps(_mm256_loadu_ps(cj + 3 * n), c3a));
            _mm256_storeu_ps(cj + 3 * n + 8, _mm256_add_ps(_mm256_loadu_ps(cj + 3 * n + 8), c3b));
        }
        for (; j < nc; j++) {          /* j-tail: chi xay ra neu nc % 16 != 0 */
            float s0 = 0.0f, s1 = 0.0f, s2 = 0.0f, s3 = 0.0f;
            for (int p = 0; p < kc; p++) {
                float bv = bp[(long long)p * bpl + j];
                s0 += ai[p] * bv;
                s1 += ai[lda + p] * bv;
                s2 += ai[2 * lda + p] * bv;
                s3 += ai[3 * lda + p] * bv;
            }
            ci[j] += s0;
            ci[n + j] += s1;
            ci[2 * n + j] += s2;
            ci[3 * n + j] += s3;
        }
    }
    for (; i < mc; i++) {               /* i-tail: bi tu choi (-11) */
        const float* ai = a + (long long)i * lda;
        float* ci = c + (long long)i * n;
        for (int j = 0; j < nc; j++) {
            float s = 0.0f;
            for (int p = 0; p < kc; p++)
                s += ai[p] * bp[(long long)p * bpl + j];
            ci[j] += s;
        }
    }
}

/* gemm_rect: Ct[i0:i1][j0:j1] = At x Bt, zero-fill truoc, tich luy k tang
 * dan pc. Y het gemm_rect_f32 ban goc (mc/nc/bpl cung so). */
static void dx_gemm_rect(const float* a, int lda, const float* b, int ldb,
                         float* o, int ldc, int k, int i0, int i1, int j0,
                         int j1, int mc_b, int nc_b, int bpl) {
    if (i1 <= i0 || j1 <= j0) return;
    for (int ii = i0; ii < i1; ii++)
        memset(o + (long long)ii * ldc + j0, 0,
               (size_t)(j1 - j0) * sizeof(float));
    static __declspec(thread) float bp[GEMM_KC * (GEMM_NC + 4)];
    if (bpl < GEMM_BPL) bpl = GEMM_BPL;
    if (bpl > GEMM_NC + 4) bpl = GEMM_NC + 4;
    /* nc_b PHAI <= bpl - 16 (khong phai bpl - 4): micro_f32 doc 2 ymm = 16
     * float/lan tai bp[p*bpl + j] va bp[p*bpl + j + 8]. Neu nc_b > bpl - 16
     * thi lan cuoi doc vuot qua vung pack (gia tri rac). Ban goc cung clamp
     * bpl - 4 nhung do chi an toan vi nc = 64 <= 68 - 4 = 64; tai day ta
     * dang dung dung nc_b = 64 = bpl - 4 nen van AN TOAN, nhung giu nguyen
     * dieu kien goc de khong lech hanh vi neu ai do doi nc_b. */
    if (nc_b > bpl - 4) nc_b = bpl - 4;
    if (nc_b < 1) nc_b = 1;
    if (mc_b < 1) mc_b = 1;
    for (int jc = j0; jc < j1; jc += nc_b) {
        int nc = j1 - jc; if (nc > nc_b) nc = nc_b;
        for (int pc = 0; pc < k; pc += GEMM_KC) {
            int kc = k - pc; if (kc > GEMM_KC) kc = GEMM_KC;
            dx_pack_b_f32(b, bp, ldb, pc, kc, jc, nc, bpl);
            for (int ic = i0; ic < i1; ic += mc_b) {
                int mc = i1 - ic; if (mc > mc_b) mc = mc_b;
                dx_micro_f32(a + (long long)ic * lda + pc, lda, bp,
                             o + (long long)ic * ldc + jc, ldc, mc, nc, kc, bpl);
            }
        }
    }
}

/* tkv_k_eff — y het ban goc: doc Bt row-major n x n, At row-major n x n. */
static int dx_k_eff(const float* b, const float* a, int n) {
    if (n <= 0) return 0;
    for (int p = n - 1; p >= 0; p--) {
        const float* br = b + (long long)p * n;
        int j;
        for (j = 0; j < n; j++)
            if (br[j] != 0.0f) return p + 1;
        for (int r = 0; r < n; r++) {
            unsigned int bits;
            float av = a[(long long)r * n + p];
            memcpy(&bits, &av, sizeof bits);
            if ((bits & 0x7F800000u) == 0x7F800000u) return p + 1;   /* Inf/NaN */
        }
    }
    return 0;
}

EXPORT int LinearDxFused(const float* gy, int gy_len,
                         const float* w, int w_len,
                         float* dx, int dx_len,
                         int m, int n, int k, int ndim, int T) {
    if (!gy || !w || !dx) return -1;
    if (m <= 0 || n <= 0 || k <= 0 || ndim <= 0) return -2;
    if (T < 4 || T > 4096) return -7;
    if (ndim < k) return -8;
    if (k < 256) return -9;      /* khong di qua _smm_full */
    if (m > 256) return -10;     /* m > 256 -> _smm_pk, khac hoan toan */
    if ((m & 3) != 0) return -11;/* micro_f32 i-tail -> khong dam bao bit */
    long long need_g = (long long)m * k;
    long long need_w = (long long)n * ndim;
    long long need_d = (long long)m * n;
    if ((long long)gy_len < need_g || (long long)w_len < need_w ||
        (long long)dx_len < need_d)
        return -5;

    long long tsq = (long long)T * (long long)T;
    float* At = (float*)malloc((size_t)tsq * sizeof(float));
    float* Bt = (float*)malloc((size_t)tsq * sizeof(float));
    float* Ct = (float*)malloc((size_t)tsq * sizeof(float));
    if (!At || !Bt || !Ct) { free(At); free(Bt); free(Ct); return -6; }

    int nc = GEMM_NC, bpl = GEMM_BPL;   /* SgemmF32 voi n = T != TKV_VOCAB */
    for (int i0 = 0; i0 < m; i0 += T) {          /* m <= 256 <= T -> 1 lan */
        int ib = m - i0; if (ib > T) ib = T;
        for (int p0 = 0; p0 < k; p0 += T) {
            int pw = k - p0; if (pw > T) pw = T;
            /* full_tile_a — day du T^2 (hang i >= m = 0, de dx_k_eff doc
             * dung vung a[r*T + p] nhu ban goc) */
            {
                int dst = 0;
                for (int i = 0; i < ib; i++) {
                    const float* row = gy + (long long)(i0 + i) * k + p0;
                    for (int j = 0; j < pw; j++) At[dst++] = row[j];
                    for (int j = pw; j < T; j++) At[dst++] = 0.0f;
                }
                for (int i = ib; i < T; i++)
                    for (int j = 0; j < T; j++) At[dst++] = 0.0f;
            }
            for (int j0 = 0; j0 < n; j0 += T) {
                int jb = n - j0; if (jb > T) jb = T;
                /* full_tile_b trans_b = 1 — day du T^2 */
                {
                    int dst = 0;
                    for (int i = 0; i < pw; i++) {
                        for (int j = 0; j < jb; j++)
                            Bt[dst++] = w[(long long)(j0 + j) * ndim + (p0 + i)];
                        for (int j = jb; j < T; j++) Bt[dst++] = 0.0f;
                    }
                    for (int i = pw; i < T; i++)
                        for (int j = 0; j < T; j++) Bt[dst++] = 0.0f;
                }
                int k_eff = dx_k_eff(Bt, At, T);
                /* Ct = At x Bt, chi r < ib (hang thua = 0, khong doc) */
                memset(Ct, 0, (size_t)ib * (size_t)T * sizeof(float));
                if (k_eff > 0)
                    dx_gemm_rect(At, T, Bt, T, Ct, T, k_eff,
                                 0, ib, 0, T, GEMM_MC, nc, bpl);
                if (p0 == 0) {
                    /* mode 0 + p0 == 0: memset +0.0f (KHONG "= Ct" — do doi
                     * -0.0f) truoc khi cong, giong _smm_cd zero-fill */
                    for (int r = 0; r < ib; r++)
                        memset(dx + (long long)(i0 + r) * n + j0, 0,
                               (size_t)jb * sizeof(float));
                }
                /* _acc_f: cd[(i0+r)*n + (j0+c)] += Ct[r*T+c], tang dan p0 */
                for (int r = 0; r < ib; r++) {
                    float* cd = dx + (long long)(i0 + r) * n + j0;
                    const float* ct = Ct + (long long)r * T;
                    for (int cc = 0; cc < jb; cc++)
                        cd[cc] = cd[cc] + ct[cc];
                }
            }
        }
    }
    free(At); free(Bt); free(Ct);
    return 0;
}
