/* tkv_flash_attn.c - flash-attention fwd + bwd (fp32, causal, head_dim=64).
 *
 * PORT: thuat toan online-softmax flash attention (khoi tao -inf, block theo
 * KV, accumulate dst truc tiep, luu logsumexp) duoc viet lai tu NGUYEN MAU
 * THUAT TOAN cua PyTorch ATen `FlashAttentionKernel.cpp` (aten/src/ATen/
 * native/cpu/) - Port of the fp32 causal CPU flash-attention algorithm,
 * re-implemented in C against AVX2 + FMA intrinsics. KHONG co ATen/MKL
 * dependency, khong phai build hay copy DLL nay cua PyTorch, va khong
 * "chay trong PyTorch". Py torch BSD-3-Clause; attribution giu lai o day va
 * trong HANDOFF.md.
 *
 * Khac reference (co y):
 *   - online max/sum f32 (qk_max/qk_sum) thay f64; exp bang poly AVX2 (m256_exp_ps)
 *   - hd = 64 cung dinh (n >= 64 moi chap nhan)
 *   - khong ap pack/VNNI (bf16), khong mask tuy y - causal mask tinh tai cho
 *   - GEMM bang micro-kernel AVX2 FMA (thu tu tich luy KHAC BLAS/MKL -> loss
 *     khong bit-exact nhu kernel cu; user da nhan relax gate s0.125)
 *
 * Layout (giong AttentionBwdFused):
 *   qkv:    [n, 3*h]  f32,  Q = +0, K = +h, V = +2h (moi token h float)
 *   dctx:   [n, h]    f32 (gradient dau vao cua ctx)
 *   ctx_out:[n, hd]   packed theo head (caller ghep lai)
 *   dq_out: [n, 3*hd] packed theo head: [t*3hd+d]=dq*inv, [+hd]=dk*inv,
 *           [+2hd]=dv. CTXO = out recompute (giong out fwd vi cung duong).
 *
 * rc: 0 OK; <0 = fail (caller fallback duong cu nguyen van).
 *   -1 NULL; -2 tham so sai; -5 buffer qua ngan; -13 shape khong ho tro
 *   (n < 64, hd != 64) -> caller dung kernel cu.
 *
 * ---------------------------------------------------------------------------
 * LICH SU TOI UU
 *
 * Phase 1 (s0.126): m256_exp_ps / exp_row_fast / exp_sum_row_fast.
 * Phase 2a (s0.128): row_max_fast / ds_row_fast.
 *
 * Phase 2b (2026-11-09) - file nay:
 *   0) FIX BUG NGHIEM TRONG: ban Phase 2a goi row_max_fast / exp_sum_row_fast
 *      trong flash_fwd_head TRUOC khi chung duoc dinh nghia -> MSVC C4013
 *      "undefined; assuming extern returning int" -> gia tri tra ve bi cat
 *      thanh int -> FORWARD SAI HOAN TOAN (probe: max_abs 0.98 vs naive).
 *      Nay moi helper dinh nghia TRUOC moi cho goi. bwd khong bi anh huong
 *      vi pass-1 cua no nam sau phan dinh nghia -> do la ly do bug chi lo ra
 *      o fwd. Da verify: fwd max_abs 5.9e-07.
 *   1) PACK: Q/K/V/dctx duoc copy 1 lan sang buffer [n][64] contiguous. Truoc
 *      day moi lan doc 1 hang la 256B cach nhau 9216B (stride 3*h) -> TLB va
 *      cache line deu phi. Sau pack moi GEMM doc tuan tu.
 *   2) gemm_nt_block: S = Q*K^T va gA = dctx*V^T bang K-transposed (BT[d][j])
 *      -> 8 output / 8 FMA, KHONG horizontal-reduce moi phan tu. Thay dot64
 *      per-element (8 FMA + hsum cho 1 scalar).
 *   3) dq/dk/dv/PV accumulate trong 8 thanh ghi ymm, flush 1 lan / block
 *      thay vi fma_row vao bo nho cho tung (i,j).
 *   4) causal_mask_zero_row / causal_mask_neginf_row: blendv_ps thay branch.
 *   5) FlashAttentionBwdFusedLse: caller da co ctx + lse tu fwd -> BO HAN
 *      pass-1 recompute (tiet kiem ~1/3 khoi luong).
 * ---------------------------------------------------------------------------
 */
#include <immintrin.h>
#include <malloc.h>
#include <math.h>
#include <string.h>
#include <stdint.h>

#define EXPORT __declspec(dllexport)

#define FL_QS 64
#define FL_KS 64
#define FL_HD 64

/* ===========================================================================
 * Helpers - TAT CA dinh nghia TRUOC moi cho goi.
 * =========================================================================== */

static inline float hsum256_ps(__m256 x) {
    __m128 lo = _mm256_castps256_ps128(x);
    __m128 hi = _mm256_extractf128_ps(x, 1);
    __m128 s = _mm_add_ps(lo, hi);
    __m128 shuf = _mm_movehdup_ps(s);
    s = _mm_add_ps(s, shuf);
    shuf = _mm_movehl_ps(s, s);
    s = _mm_add_ss(s, shuf);
    return _mm_cvtss_f32(s);
}

static inline float hmax256_ps(__m256 x) {
    __m128 lo = _mm256_castps256_ps128(x);
    __m128 hi = _mm256_extractf128_ps(x, 1);
    __m128 s = _mm_max_ps(lo, hi);
    __m128 shuf = _mm_movehdup_ps(s);
    s = _mm_max_ps(s, shuf);
    shuf = _mm_movehl_ps(s, s);
    s = _mm_max_ss(s, shuf);
    return _mm_cvtss_f32(s);
}

/* fast expf AVX2: polynomial + scalef; clamp [-87, 88] -> finite; ULP < ~2.
 * KHONG bit-exact (path da waiver user s0.125). */
static inline __m256 m256_exp_ps(__m256 x) {
    const __m256 vexp_fast_lo = _mm256_set1_ps(-87.3f);
    const __m256 vexp_fast_hi = _mm256_set1_ps(88.7f);
    const __m256 vexp_magic   = _mm256_set1_ps(12582912.0f);   /* 1.5 * 2^23 */
    const __m256 vexp_invln2  = _mm256_set1_ps(1.4426950408889634f);
    const __m256 vexp_ln2     = _mm256_set1_ps(0.6931471805599453f);
    x = _mm256_max_ps(x, vexp_fast_lo);
    x = _mm256_min_ps(x, vexp_fast_hi);
    __m256 t  = _mm256_mul_ps(x, vexp_invln2);
    __m256 n  = _mm256_sub_ps(_mm256_add_ps(t, vexp_magic), vexp_magic);
    __m256 f  = _mm256_sub_ps(t, n);
    f  = _mm256_mul_ps(f, vexp_ln2);
    __m256 r = _mm256_set1_ps(1.388888654e-04f);
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(8.333333e-03f));
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(4.1666665e-02f));
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(1.6666666e-01f));
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(5.0000000e-01f));
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(1.0000000e+00f));
    r = _mm256_fmadd_ps(r, f, _mm256_set1_ps(1.0000000e+00f));
    __m256i ni = _mm256_cvttps_epi32(n);
    __m256i bits = _mm256_slli_epi32(_mm256_add_epi32(ni, _mm256_set1_epi32(127)), 23);
    return _mm256_mul_ps(r, _mm256_castsi256_ps(bits));
}

/* dot 64 phan tu (chi con dung cho dsum - 1 lan/token, khong phai hot loop) */
static inline float dot64(const float* a, const float* b) {
    __m256 acc = _mm256_setzero_ps();
    for (int i = 0; i < 64; i += 8) {
        acc = _mm256_fmadd_ps(_mm256_loadu_ps(a + i), _mm256_loadu_ps(b + i), acc);
    }
    return hsum256_ps(acc);
}

static inline void mul_row(float* dst, float s) {
    __m256 vs = _mm256_set1_ps(s);
    for (int d = 0; d < 64; d += 8) {
        _mm256_storeu_ps(dst + d, _mm256_mul_ps(_mm256_loadu_ps(dst + d), vs));
    }
}

/* vectorized row maximum */
static inline float row_max_fast(const float* v, int kvb) {
    int j = 0;
    __m256 rmax = _mm256_set1_ps(-INFINITY);
    for (; j + 8 <= kvb; j += 8) rmax = _mm256_max_ps(rmax, _mm256_loadu_ps(v + j));
    float m = hmax256_ps(rmax);
    for (; j < kvb; j++) if (v[j] > m) m = v[j];
    return m;
}

/* vectorized expf row + sum: qk[j] = exp(qk[j] - newmax), tra ve tong */
static inline float exp_sum_row_fast(float* qk, float newmax, int kvb) {
    int j = 0;
    __m256 vmax = _mm256_set1_ps(newmax);
    __m256 bsum_vec = _mm256_setzero_ps();
    for (; j + 8 <= kvb; j += 8) {
        __m256 v = m256_exp_ps(_mm256_sub_ps(_mm256_loadu_ps(qk + j), vmax));
        _mm256_storeu_ps(qk + j, v);
        bsum_vec = _mm256_add_ps(bsum_vec, v);
    }
    float bsum = hsum256_ps(bsum_vec);
    for (; j < kvb; j++) {
        float e = expf(qk[j] - newmax);
        qk[j] = e;
        bsum += e;
    }
    return bsum;
}

/* vectorized ds = attn * (gA - dsum_i) cho row [0, kvb) */
static inline void ds_row_fast(const float* attn, const float* gA, float* ds, float dsum_i, int kvb) {
    int j = 0;
    __m256 vdsum = _mm256_set1_ps(dsum_i);
    for (; j + 8 <= kvb; j += 8) {
        __m256 va = _mm256_loadu_ps(attn + j);
        __m256 vg = _mm256_loadu_ps(gA + j);
        _mm256_storeu_ps(ds + j, _mm256_mul_ps(va, _mm256_sub_ps(vg, vdsum)));
    }
    for (; j < kvb; j++) ds[j] = attn[j] * (gA[j] - dsum_i);
}

/* Phase 2b: causal mask bang blendv_ps.
 * v[j] = 0.0f khi (col_base + j) > t. Dung SAU exp. */
static inline void causal_mask_zero_row(float* v, int kvb, int t, int col_base) {
    int j = 0;
    const __m256 vzero = _mm256_setzero_ps();
    const __m256i vt = _mm256_set1_epi32(t);
    for (; j + 8 <= kvb; j += 8) {
        __m256i idx = _mm256_setr_epi32(col_base + j, col_base + j + 1,
                                        col_base + j + 2, col_base + j + 3,
                                        col_base + j + 4, col_base + j + 5,
                                        col_base + j + 6, col_base + j + 7);
        __m256i m = _mm256_cmpgt_epi32(idx, vt);
        _mm256_storeu_ps(v + j, _mm256_blendv_ps(_mm256_loadu_ps(v + j), vzero,
                                                 _mm256_castsi256_ps(m)));
    }
    for (; j < kvb; j++) if (col_base + j > t) v[j] = 0.0f;
}

/* Phase 2b: causal mask -> -INF (truoc row_max trong fwd). */
static inline void causal_mask_neginf_row(float* v, int kvb, int t, int col_base) {
    int j = 0;
    const __m256 vninf = _mm256_set1_ps(-INFINITY);
    const __m256i vt = _mm256_set1_epi32(t);
    for (; j + 8 <= kvb; j += 8) {
        __m256i idx = _mm256_setr_epi32(col_base + j, col_base + j + 1,
                                        col_base + j + 2, col_base + j + 3,
                                        col_base + j + 4, col_base + j + 5,
                                        col_base + j + 6, col_base + j + 7);
        __m256i m = _mm256_cmpgt_epi32(idx, vt);
        _mm256_storeu_ps(v + j, _mm256_blendv_ps(_mm256_loadu_ps(v + j), vninf,
                                                 _mm256_castsi256_ps(m)));
    }
    for (; j < kvb; j++) if (col_base + j > t) v[j] = -INFINITY;
}

/* attn = exp(S - lse_t), roi mask 0 cho u > t. */
static inline void attn_row_from_lse(float* s, float lse_t, int kvb, int t, int col_base) {
    int j = 0;
    __m256 vlse = _mm256_set1_ps(lse_t);
    for (; j + 8 <= kvb; j += 8) {
        _mm256_storeu_ps(s + j, m256_exp_ps(_mm256_sub_ps(_mm256_loadu_ps(s + j), vlse)));
    }
    for (; j < kvb; j++) s[j] = expf(s[j] - lse_t);
    causal_mask_zero_row(s, kvb, t, col_base);
}

/* ===========================================================================
 * Transposed micro-GEMM
 *
 * C[i][j] = scale * sum_d A[i][d] * B[j][d]   (i<qb, j<kvb, d<64)
 *
 * Transpose khoi B thanh BT[d][j] (j lien tuc) roi tich luy 8 output cung luc
 * trong 8 thanh ghi ymm: 8 FMA / 8 output, KHONG reduce.
 * =========================================================================== */

/* transpose khoi 64x64: BT[d*64 + j] = B[j*64 + d]; j >= kvb -> 0.
 * bstride = 64 (buffer da pack contiguous). */
static void transpose_block64(const float* B, float* BT, int kvb) {
    for (int d = 0; d < 64; d += 8) {
        for (int j = 0; j < 64; j += 8) {
            __m256 r0, r1, r2, r3, r4, r5, r6, r7;
            if (j + 8 <= kvb) {
                r0 = _mm256_loadu_ps(B + (j + 0) * 64 + d);
                r1 = _mm256_loadu_ps(B + (j + 1) * 64 + d);
                r2 = _mm256_loadu_ps(B + (j + 2) * 64 + d);
                r3 = _mm256_loadu_ps(B + (j + 3) * 64 + d);
                r4 = _mm256_loadu_ps(B + (j + 4) * 64 + d);
                r5 = _mm256_loadu_ps(B + (j + 5) * 64 + d);
                r6 = _mm256_loadu_ps(B + (j + 6) * 64 + d);
                r7 = _mm256_loadu_ps(B + (j + 7) * 64 + d);
            } else {
                float tmp[8];
                r0 = r1 = r2 = r3 = r4 = r5 = r6 = r7 = _mm256_setzero_ps();
                for (int q = 0; q < 8; q++) {
                    int jj = j + q;
                    if (jj < kvb) {
                        memcpy(tmp, B + jj * 64 + d, 8 * sizeof(float));
                    } else {
                        for (int z = 0; z < 8; z++) tmp[z] = 0.0f;
                    }
                    __m256 rv = _mm256_loadu_ps(tmp);
                    switch (q) {
                        case 0: r0 = rv; break;
                        case 1: r1 = rv; break;
                        case 2: r2 = rv; break;
                        case 3: r3 = rv; break;
                        case 4: r4 = rv; break;
                        case 5: r5 = rv; break;
                        case 6: r6 = rv; break;
                        default: r7 = rv; break;
                    }
                }
            }
            __m256 t0 = _mm256_unpacklo_ps(r0, r1);
            __m256 t1 = _mm256_unpackhi_ps(r0, r1);
            __m256 t2 = _mm256_unpacklo_ps(r2, r3);
            __m256 t3 = _mm256_unpackhi_ps(r2, r3);
            __m256 t4 = _mm256_unpacklo_ps(r4, r5);
            __m256 t5 = _mm256_unpackhi_ps(r4, r5);
            __m256 t6 = _mm256_unpacklo_ps(r6, r7);
            __m256 t7 = _mm256_unpackhi_ps(r6, r7);
            __m256 u0 = _mm256_shuffle_ps(t0, t2, 0x44);
            __m256 u1 = _mm256_shuffle_ps(t0, t2, 0xEE);
            __m256 u2 = _mm256_shuffle_ps(t1, t3, 0x44);
            __m256 u3 = _mm256_shuffle_ps(t1, t3, 0xEE);
            __m256 u4 = _mm256_shuffle_ps(t4, t6, 0x44);
            __m256 u5 = _mm256_shuffle_ps(t4, t6, 0xEE);
            __m256 u6 = _mm256_shuffle_ps(t5, t7, 0x44);
            __m256 u7 = _mm256_shuffle_ps(t5, t7, 0xEE);
            _mm256_storeu_ps(BT + (d + 0) * 64 + j, _mm256_permute2f128_ps(u0, u4, 0x20));
            _mm256_storeu_ps(BT + (d + 1) * 64 + j, _mm256_permute2f128_ps(u1, u5, 0x20));
            _mm256_storeu_ps(BT + (d + 2) * 64 + j, _mm256_permute2f128_ps(u2, u6, 0x20));
            _mm256_storeu_ps(BT + (d + 3) * 64 + j, _mm256_permute2f128_ps(u3, u7, 0x20));
            _mm256_storeu_ps(BT + (d + 4) * 64 + j, _mm256_permute2f128_ps(u0, u4, 0x31));
            _mm256_storeu_ps(BT + (d + 5) * 64 + j, _mm256_permute2f128_ps(u1, u5, 0x31));
            _mm256_storeu_ps(BT + (d + 6) * 64 + j, _mm256_permute2f128_ps(u2, u6, 0x31));
            _mm256_storeu_ps(BT + (d + 7) * 64 + j, _mm256_permute2f128_ps(u3, u7, 0x31));
        }
    }
}

/* C[i*64 + j] = scale * sum_d A[i*64 + d] * BT[d*64 + j] */
static inline void gemm_nt_block(const float* A, const float* BT,
                                 float* C, int qb, int kvb, float scale) {
    const __m256 vscale = _mm256_set1_ps(scale);
    for (int i = 0; i < qb; i++) {
        const float* arow = A + (long long)i * 64;
        __m256 c0 = _mm256_setzero_ps(), c1 = _mm256_setzero_ps();
        __m256 c2 = _mm256_setzero_ps(), c3 = _mm256_setzero_ps();
        __m256 c4 = _mm256_setzero_ps(), c5 = _mm256_setzero_ps();
        __m256 c6 = _mm256_setzero_ps(), c7 = _mm256_setzero_ps();
        for (int d = 0; d < 64; d++) {
            __m256 va = _mm256_broadcast_ss(arow + d);
            const float* bt = BT + (long long)d * 64;
            c0 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 0),  c0);
            c1 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 8),  c1);
            c2 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 16), c2);
            c3 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 24), c3);
            c4 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 32), c4);
            c5 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 40), c5);
            c6 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 48), c6);
            c7 = _mm256_fmadd_ps(va, _mm256_loadu_ps(bt + 56), c7);
        }
        float* crow = C + (long long)i * 64;
        if (kvb == 64) {
            _mm256_storeu_ps(crow + 0,  _mm256_mul_ps(c0, vscale));
            _mm256_storeu_ps(crow + 8,  _mm256_mul_ps(c1, vscale));
            _mm256_storeu_ps(crow + 16, _mm256_mul_ps(c2, vscale));
            _mm256_storeu_ps(crow + 24, _mm256_mul_ps(c3, vscale));
            _mm256_storeu_ps(crow + 32, _mm256_mul_ps(c4, vscale));
            _mm256_storeu_ps(crow + 40, _mm256_mul_ps(c5, vscale));
            _mm256_storeu_ps(crow + 48, _mm256_mul_ps(c6, vscale));
            _mm256_storeu_ps(crow + 56, _mm256_mul_ps(c7, vscale));
        } else {
            float tmp[64];
            _mm256_storeu_ps(tmp + 0,  _mm256_mul_ps(c0, vscale));
            _mm256_storeu_ps(tmp + 8,  _mm256_mul_ps(c1, vscale));
            _mm256_storeu_ps(tmp + 16, _mm256_mul_ps(c2, vscale));
            _mm256_storeu_ps(tmp + 24, _mm256_mul_ps(c3, vscale));
            _mm256_storeu_ps(tmp + 32, _mm256_mul_ps(c4, vscale));
            _mm256_storeu_ps(tmp + 40, _mm256_mul_ps(c5, vscale));
            _mm256_storeu_ps(tmp + 48, _mm256_mul_ps(c6, vscale));
            _mm256_storeu_ps(tmp + 56, _mm256_mul_ps(c7, vscale));
            for (int q = 0; q < kvb; q++) crow[q] = tmp[q];
        }
    }
}

/* Accumulate: DST[i][:] += sum_j P[i*64+j] * X[j][:]  (X contiguous [n][64])
 * Dung chung cho: PV (fwd), dq, dk, dv. */
static inline void acc_block(float* DST, const float* P, const float* X,
                             int qb, int kvb, int xoff) {
    for (int i = 0; i < qb; i++) {
        float* dst = DST + (long long)i * FL_HD;
        __m256 a0 = _mm256_loadu_ps(dst + 0),  a1 = _mm256_loadu_ps(dst + 8);
        __m256 a2 = _mm256_loadu_ps(dst + 16), a3 = _mm256_loadu_ps(dst + 24);
        __m256 a4 = _mm256_loadu_ps(dst + 32), a5 = _mm256_loadu_ps(dst + 40);
        __m256 a6 = _mm256_loadu_ps(dst + 48), a7 = _mm256_loadu_ps(dst + 56);
        const float* prow = P + (long long)i * FL_KS;
        for (int j = 0; j < kvb; j++) {
            __m256 p = _mm256_broadcast_ss(prow + j);
            const float* xrow = X + (long long)(xoff + j) * FL_HD;
            a0 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 0),  a0);
            a1 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 8),  a1);
            a2 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 16), a2);
            a3 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 24), a3);
            a4 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 32), a4);
            a5 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 40), a5);
            a6 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 48), a6);
            a7 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 56), a7);
        }
        _mm256_storeu_ps(dst + 0,  a0); _mm256_storeu_ps(dst + 8,  a1);
        _mm256_storeu_ps(dst + 16, a2); _mm256_storeu_ps(dst + 24, a3);
        _mm256_storeu_ps(dst + 32, a4); _mm256_storeu_ps(dst + 40, a5);
        _mm256_storeu_ps(dst + 48, a6); _mm256_storeu_ps(dst + 56, a7);
    }
}

/* Accumulate transposed: DST[j][:] += sum_i P[i*64+j] * X[i][:]
 * DST va X deu la con tro DA OFFSET boi caller (block base). */
static inline void acc_block_t(float* DST, const float* P, const float* X,
                               int qb, int kvb) {
    for (int j = 0; j < kvb; j++) {
        float* dst = DST + (long long)j * FL_HD;
        __m256 a0 = _mm256_loadu_ps(dst + 0),  a1 = _mm256_loadu_ps(dst + 8);
        __m256 a2 = _mm256_loadu_ps(dst + 16), a3 = _mm256_loadu_ps(dst + 24);
        __m256 a4 = _mm256_loadu_ps(dst + 32), a5 = _mm256_loadu_ps(dst + 40);
        __m256 a6 = _mm256_loadu_ps(dst + 48), a7 = _mm256_loadu_ps(dst + 56);
        for (int i = 0; i < qb; i++) {
            __m256 p = _mm256_broadcast_ss(P + (long long)i * FL_KS + j);
            const float* xrow = X + (long long)i * FL_HD;
            a0 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 0),  a0);
            a1 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 8),  a1);
            a2 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 16), a2);
            a3 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 24), a3);
            a4 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 32), a4);
            a5 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 40), a5);
            a6 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 48), a6);
            a7 = _mm256_fmadd_ps(p, _mm256_loadu_ps(xrow + 56), a7);
        }
        _mm256_storeu_ps(dst + 0,  a0); _mm256_storeu_ps(dst + 8,  a1);
        _mm256_storeu_ps(dst + 16, a2); _mm256_storeu_ps(dst + 24, a3);
        _mm256_storeu_ps(dst + 32, a4); _mm256_storeu_ps(dst + 40, a5);
        _mm256_storeu_ps(dst + 48, a6); _mm256_storeu_ps(dst + 56, a7);
    }
}

/* pack 1 head tu qkv [n][3h] (stride) -> Qp/Kp/Vp [n][64] contiguous */
static void pack_qkv(const float* qkv, int n, int h, int coff_q,
                     float* Qp, float* Kp, float* Vp) {
    long long stride3 = (long long)3 * h;
    for (int t = 0; t < n; t++) {
        const float* base = qkv + (long long)t * stride3 + coff_q;
        memcpy(Qp + (long long)t * 64, base,        64 * sizeof(float));
        memcpy(Kp + (long long)t * 64, base + h,    64 * sizeof(float));
        memcpy(Vp + (long long)t * 64, base + 2 * h, 64 * sizeof(float));
    }
}

/* pack dctx [n][h] (stride) -> Dp [n][64] contiguous */
static void pack_dctx(const float* dctx, int n, int h, int coff_q, float* Dp) {
    for (int t = 0; t < n; t++) {
        memcpy(Dp + (long long)t * 64, dctx + (long long)t * h + coff_q, 64 * sizeof(float));
    }
}

/* ===========================================================================
 * Flash fwd 1 head (causal)
 * =========================================================================== */
static int flash_fwd_head(const float* qkv, float* ctx_out, float* lse_out,
                          int n, int h, int head, double inv) {
    float* Qp  = (float*)malloc((size_t)n * 64 * 4);
    float* Kp  = (float*)malloc((size_t)n * 64 * 4);
    float* Vp  = (float*)malloc((size_t)n * 64 * 4);
    float* qk  = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* dst = (float*)malloc((size_t)FL_QS * FL_HD * 4);
    float* BTK = (float*)malloc((size_t)64 * 64 * 4);
    float mx[FL_QS], sm[FL_QS];
    int coff_q = head * FL_HD;
    float finv = (float)inv;
    int rc = 0;
    if (!Qp || !Kp || !Vp || !qk || !dst || !BTK) { rc = -6; goto done; }

    pack_qkv(qkv, n, h, coff_q, Qp, Kp, Vp);

    for (int m0 = 0; m0 < n; m0 += FL_QS) {
        int qb = n - m0; if (qb > FL_QS) qb = FL_QS;
        int num_keys = m0 + qb; if (num_keys > n) num_keys = n;
        for (int i = 0; i < qb; i++) { mx[i] = -INFINITY; sm[i] = 0.0f; }
        for (int i = 0; i < qb * FL_HD; i++) dst[i] = 0.0f;
        for (int n0 = 0; n0 < num_keys; n0 += FL_KS) {
            int kvb = num_keys - n0; if (kvb > FL_KS) kvb = FL_KS;

            transpose_block64(Kp + (long long)n0 * 64, BTK, kvb);
            gemm_nt_block(Qp + (long long)m0 * 64, BTK, qk, qb, kvb, finv);
            for (int i = 0; i < qb; i++) {
                causal_mask_neginf_row(qk + (long long)i * FL_KS, kvb, m0 + i, n0);
            }

            for (int i = 0; i < qb; i++) {
                float rmax = row_max_fast(qk + (long long)i * FL_KS, kvb);
                float newmax = (mx[i] > rmax) ? mx[i] : rmax;
                if (newmax == -INFINITY) {
                    for (int j = 0; j < kvb; j++) qk[i * FL_KS + j] = 0.0f;
                    for (int d = 0; d < FL_HD; d++) dst[i * FL_HD + d] = 0.0f;
                    mx[i] = newmax;
                    continue;
                }
                float exp_tmp = (n0 == 0) ? 1.0f : expf(mx[i] - newmax);
                if (mx[i] == -INFINITY) exp_tmp = 0.0f;
                float bsum = exp_sum_row_fast(qk + (long long)i * FL_KS, newmax, kvb);
                if (n0 > 0) mul_row(dst + i * FL_HD, exp_tmp);
                sm[i] = bsum + exp_tmp * sm[i];
                mx[i] = newmax;
            }
            /* dst[i] += sum_j p[i,j] * V[j]  (block GEMM, 1 lan cho ca qb) */
            acc_block(dst, qk, Vp, qb, kvb, n0);
        }
        for (int i = 0; i < qb; i++) {
            int t = m0 + i;
            float sinv = 1.0f / sm[i];
            float* orow = ctx_out + (long long)t * FL_HD;
            __m256 vs = _mm256_set1_ps(sinv);
            for (int d = 0; d < FL_HD; d += 8) {
                _mm256_storeu_ps(orow + d, _mm256_mul_ps(_mm256_loadu_ps(dst + i * FL_HD + d), vs));
            }
            if (lse_out) lse_out[t] = mx[i] + logf(sm[i]);
        }
    }
done:
    free(Qp); free(Kp); free(Vp); free(qk); free(dst); free(BTK);
    return rc;
}

EXPORT int FlashAttentionFwdFused(const float* qkv, int qkv_len,
                                  float* ctx_out, int ctx_len,
                                  int n, int h, int hd, int head, double inv) {
    if (!qkv || !ctx_out) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    if (head < 0 || head >= h / FL_HD) return -2;
    long long stride3 = (long long)3 * h;
    if ((long long)qkv_len < (long long)n * stride3) return -5;
    if ((long long)ctx_len < (long long)n * FL_HD) return -5;
    return flash_fwd_head(qkv, ctx_out, NULL, n, h, head, inv);
}

EXPORT int FlashAttentionFwdLse(const float* qkv, int qkv_len,
                                float* ctx_out, int ctx_len,
                                float* lse, int lse_len,
                                int n, int h, int hd, int head, double inv) {
    if (!qkv || !ctx_out || !lse) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    if (head < 0 || head >= h / FL_HD) return -2;
    long long stride3 = (long long)3 * h;
    if ((long long)qkv_len < (long long)n * stride3) return -5;
    if ((long long)ctx_len < (long long)n * FL_HD) return -5;
    if ((long long)lse_len < n) return -5;
    return flash_fwd_head(qkv, ctx_out, lse, n, h, head, inv);
}

/* ===========================================================================
 * Flash bwd 1 head (causal)
 *
 * have_lse != 0: caller da co ctx_in (ket qua fwd) + lse_in -> BO pass-1.
 * have_lse == 0: recompute out + lse bang pass-1 (duong cu, giu nguyen).
 * =========================================================================== */
static int flash_bwd_head(const float* qkv, const float* dctx,
                          float* ctxo, float* dqo,
                          int n, int h, int head, double inv,
                          const float* ctx_in, const float* lse_in) {
    int coff_q = head * FL_HD;
    float finv = (float)inv;
    int rc = 0;
    int have_lse = (ctx_in != NULL && lse_in != NULL);

    float* Qp = (float*)malloc((size_t)n * 64 * 4);
    float* Kp = (float*)malloc((size_t)n * 64 * 4);
    float* Vp = (float*)malloc((size_t)n * 64 * 4);
    float* Dp = (float*)malloc((size_t)n * 64 * 4);
    float* out_buf = NULL;
    float* lse = NULL;
    float* dsum = (float*)malloc((size_t)n * 4);
    float* dq = (float*)malloc((size_t)n * FL_HD * 4);
    float* dk = (float*)malloc((size_t)n * FL_HD * 4);
    float* dv = (float*)malloc((size_t)n * FL_HD * 4);
    float* attn = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* gA = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* ds = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* BTK = (float*)malloc((size_t)64 * 64 * 4);
    float* BTV = (float*)malloc((size_t)64 * 64 * 4);
    if (!Qp || !Kp || !Vp || !Dp || !dsum || !dq || !dk || !dv ||
        !attn || !gA || !ds || !BTK || !BTV) { rc = -6; goto done; }
    memset(dq, 0, (size_t)n * FL_HD * 4);
    memset(dk, 0, (size_t)n * FL_HD * 4);
    memset(dv, 0, (size_t)n * FL_HD * 4);

    pack_qkv(qkv, n, h, coff_q, Qp, Kp, Vp);
    pack_dctx(dctx, n, h, coff_q, Dp);

    if (have_lse) {
        out_buf = (float*)ctx_in;
        lse = (float*)lse_in;
    } else {
        /* pass 1: recompute out + lse */
        out_buf = (float*)malloc((size_t)n * FL_HD * 4);
        lse = (float*)malloc((size_t)n * 4);
        if (!out_buf || !lse) { rc = -6; goto done; }
        {
            float* qk = (float*)malloc((size_t)FL_QS * FL_KS * 4);
            float* dst = (float*)malloc((size_t)FL_QS * FL_HD * 4);
            float mx[FL_QS], sm[FL_QS];
            if (!qk || !dst) { free(qk); free(dst); rc = -6; goto done; }
            for (int m0 = 0; m0 < n; m0 += FL_QS) {
                int qb = n - m0; if (qb > FL_QS) qb = FL_QS;
                int num_keys = m0 + qb; if (num_keys > n) num_keys = n;
                for (int i = 0; i < qb; i++) { mx[i] = -INFINITY; sm[i] = 0.0f; }
                for (int i = 0; i < qb * FL_HD; i++) dst[i] = 0.0f;
                for (int n0 = 0; n0 < num_keys; n0 += FL_KS) {
                    int kvb = num_keys - n0; if (kvb > FL_KS) kvb = FL_KS;
                    transpose_block64(Kp + (long long)n0 * 64, BTK, kvb);
                    gemm_nt_block(Qp + (long long)m0 * 64, BTK, qk, qb, kvb, finv);
                    for (int i = 0; i < qb; i++)
                        causal_mask_neginf_row(qk + (long long)i * FL_KS, kvb, m0 + i, n0);
                    for (int i = 0; i < qb; i++) {
                        float rmax = row_max_fast(qk + (long long)i * FL_KS, kvb);
                        float newmax = (mx[i] > rmax) ? mx[i] : rmax;
                        if (newmax == -INFINITY) {
                            for (int j = 0; j < kvb; j++) qk[i * FL_KS + j] = 0.0f;
                            mx[i] = newmax;
                            continue;
                        }
                        float exp_tmp = (n0 == 0) ? 1.0f : expf(mx[i] - newmax);
                        if (mx[i] == -INFINITY) exp_tmp = 0.0f;
                        float bsum = exp_sum_row_fast(qk + (long long)i * FL_KS, newmax, kvb);
                        if (n0 > 0) mul_row(dst + i * FL_HD, exp_tmp);
                        sm[i] = bsum + exp_tmp * sm[i];
                        mx[i] = newmax;
                    }
                    acc_block(dst, qk, Vp, qb, kvb, n0);
                }
                for (int i = 0; i < qb; i++) {
                    int t = m0 + i;
                    float sinv = 1.0f / sm[i];
                    float* orow = out_buf + (long long)t * FL_HD;
                    __m256 vs = _mm256_set1_ps(sinv);
                    for (int d = 0; d < FL_HD; d += 8) {
                        _mm256_storeu_ps(orow + d, _mm256_mul_ps(_mm256_loadu_ps(dst + i * FL_HD + d), vs));
                    }
                    lse[t] = mx[i] + logf(sm[i]);
                }
            }
            free(qk);
            free(dst);
        }
    }

    /* dsum[t] = sum_d dctx[t,d] * out[t,d] */
    for (int t = 0; t < n; t++) {
        dsum[t] = dot64(Dp + (long long)t * 64, out_buf + (long long)t * FL_HD);
    }

    /* pass 2: kv outer, q inner */
    for (int n0 = 0; n0 < n; n0 += FL_KS) {
        int kvb = n - n0; if (kvb > FL_KS) kvb = FL_KS;
        transpose_block64(Kp + (long long)n0 * 64, BTK, kvb);
        transpose_block64(Vp + (long long)n0 * 64, BTV, kvb);
        for (int m0 = n0; m0 < n; m0 += FL_QS) {
            int qb = n - m0; if (qb > FL_QS) qb = FL_QS;
            if (m0 + qb <= n0) continue;

#ifndef ABL_NO_S
            /* attn = exp(Q.K^T * inv - lse) + causal mask */
            gemm_nt_block(Qp + (long long)m0 * 64, BTK, attn, qb, kvb, finv);
            for (int i = 0; i < qb; i++)
                attn_row_from_lse(attn + (long long)i * FL_KS, lse[m0 + i], kvb, m0 + i, n0);
#endif
#ifndef ABL_NO_GA

            /* gA = dctx . V^T */
            gemm_nt_block(Dp + (long long)m0 * 64, BTV, gA, qb, kvb, 1.0f);
#endif
#ifndef ABL_NO_DS

            /* ds = attn * (gA - dsum) */
            for (int i = 0; i < qb; i++)
                ds_row_fast(attn + (long long)i * FL_KS, gA + (long long)i * FL_KS,
                            ds + (long long)i * FL_KS, dsum[m0 + i], kvb);
#endif
#ifndef ABL_NO_DV

            /* dv[j] += sum_i attn[i,j] * dctx[i] */
            acc_block_t(dv + (long long)n0 * FL_HD, attn, Dp + (long long)m0 * 64, qb, kvb);
#endif
#ifndef ABL_NO_DQ
            /* dq[i] += sum_j ds[i,j] * K[j] */
            acc_block(dq + (long long)m0 * FL_HD, ds, Kp, qb, kvb, n0);
#endif
#ifndef ABL_NO_DK
            /* dk[j] += sum_i ds[i,j] * Q[i] */
            acc_block_t(dk + (long long)n0 * FL_HD, ds, Qp + (long long)m0 * 64, qb, kvb);
#endif
        }
    }

    /* writeback */
    for (int t = 0; t < n; t++) {
        long long d0 = (long long)t * FL_HD;
        long long p0 = (long long)t * 3 * FL_HD;
        memcpy(ctxo + d0, out_buf + d0, 64 * sizeof(float));
        __m256 vf = _mm256_set1_ps(finv);
        for (int d = 0; d < FL_HD; d += 8) {
            _mm256_storeu_ps(dqo + p0 + d,          _mm256_mul_ps(_mm256_loadu_ps(dq + d0 + d), vf));
            _mm256_storeu_ps(dqo + p0 + FL_HD + d,  _mm256_mul_ps(_mm256_loadu_ps(dk + d0 + d), vf));
            _mm256_storeu_ps(dqo + p0 + 2*FL_HD + d, _mm256_loadu_ps(dv + d0 + d));
        }
    }

done:
    if (!have_lse) { free(out_buf); free(lse); }
    free(Qp); free(Kp); free(Vp); free(Dp);
    free(dsum); free(dq); free(dk); free(dv);
    free(attn); free(gA); free(ds); free(BTK); free(BTV);
    return rc;
}

EXPORT int FlashAttentionBwdFused(const float* qkv, int qkv_len,
                                  const float* dctx, int dctx_len,
                                  float* ctxo, int ctxo_len,
                                  float* dqo, int dqo_len,
                                  int n, int h, int hd, int head, double inv) {
    if (!qkv || !dctx || !ctxo || !dqo) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    if (head < 0 || head >= h / FL_HD) return -2;
    if ((long long)qkv_len < (long long)n * 3 * h) return -5;
    if ((long long)dctx_len < (long long)n * h) return -5;
    if ((long long)ctxo_len < (long long)n * FL_HD) return -5;
    if ((long long)dqo_len < (long long)n * 3 * FL_HD) return -5;
    return flash_bwd_head(qkv, dctx, ctxo, dqo, n, h, head, inv, NULL, NULL);
}

/* Phase 2b: caller da co ctx (tu fwd) + lse -> bo pass-1 recompute. */
EXPORT int FlashAttentionBwdFusedLse(const float* qkv, int qkv_len,
                                     const float* dctx, int dctx_len,
                                     const float* ctx_in, int ctx_in_len,
                                     const float* lse_in, int lse_in_len,
                                     float* ctxo, int ctxo_len,
                                     float* dqo, int dqo_len,
                                     int n, int h, int hd, int head, double inv) {
    if (!qkv || !dctx || !ctx_in || !lse_in || !ctxo || !dqo) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    if (head < 0 || head >= h / FL_HD) return -2;
    if ((long long)qkv_len < (long long)n * 3 * h) return -5;
    if ((long long)dctx_len < (long long)n * h) return -5;
    if ((long long)ctx_in_len < (long long)n * FL_HD) return -5;
    if ((long long)lse_in_len < n) return -5;
    if ((long long)ctxo_len < (long long)n * FL_HD) return -5;
    if ((long long)dqo_len < (long long)n * 3 * FL_HD) return -5;
    return flash_bwd_head(qkv, dctx, ctxo, dqo, n, h, head, inv, ctx_in, lse_in);
}

/* ===========================================================================
 * Multi-head parallel driver (Phase 2c)
 *
 * Van de: kernel nay xu ly 1 head/lan goi, va production goi 12 lan TUAN TU
 * tren 1 core. ATen SDPA bwd chia head ra nhieu thread -> do la ly do that su
 * khien no thang (101 ms/layer vs 131 ms/layer cua ta o 12 head, single-thread).
 *
 * Moi head doc qkv/dctx chi-doc va ghi vao slice RIENG cua ctxo/dqo
 * (head * n * hd va head * n * 3 * hd) -> khong co data race, khong can lock,
 * ket qua BIT-IDENTICAL voi duong goi tuan tu.
 * =========================================================================== */
#include <windows.h>

typedef struct {
    const float* qkv;
    const float* dctx;
    const float* ctx_in;
    const float* lse_in;
    float* ctxo;
    float* dqo;
    int n, h, nh, hd;
    double inv;
    volatile LONG next;
    volatile LONG rc;
} mh_job_t;

static DWORD WINAPI mh_bwd_worker(LPVOID p) {
    mh_job_t* c = (mh_job_t*)p;
    for (;;) {
        LONG head = InterlockedIncrement(&c->next);
        if (head >= c->nh) break;
        int rc = flash_bwd_head(
            c->qkv, c->dctx,
            c->ctxo + (long long)head * c->n * c->hd,
            c->dqo  + (long long)head * c->n * 3 * c->hd,
            c->n, c->h, (int)head, c->inv,
            c->ctx_in ? c->ctx_in + (long long)head * c->n * c->hd : NULL,
            c->lse_in ? c->lse_in + (long long)head * c->n : NULL);
        if (rc != 0) InterlockedCompareExchange(&c->rc, rc, 0);
    }
    return 0;
}

static DWORD WINAPI mh_fwd_worker(LPVOID p) {
    mh_job_t* c = (mh_job_t*)p;
    for (;;) {
        LONG head = InterlockedIncrement(&c->next);
        if (head >= c->nh) break;
        int rc = flash_fwd_head(
            c->qkv,
            c->ctxo + (long long)head * c->n * c->hd,
            c->lse_in ? (float*)c->lse_in + (long long)head * c->n : NULL,
            c->n, c->h, (int)head, c->inv);
        if (rc != 0) InterlockedCompareExchange(&c->rc, rc, 0);
    }
    return 0;
}

static int mh_run(mh_job_t* c, int nthreads, LPTHREAD_START_ROUTINE fn) {
    if (nthreads > c->nh) nthreads = c->nh;
    if (nthreads < 1) nthreads = 1;
    if (nthreads == 1) { fn(c); return c->rc; }
    HANDLE th[64];
    int spawned = 0;
    for (int i = 0; i < nthreads; i++) {
        HANDLE h = CreateThread(NULL, 0, fn, c, 0, NULL);
        if (h) th[spawned++] = h;
    }
    if (spawned == 0) { fn(c); return c->rc; }
    WaitForMultipleObjects(spawned, th, TRUE, INFINITE);
    for (int i = 0; i < spawned; i++) CloseHandle(th[i]);
    return c->rc;
}

EXPORT int FlashAttentionBwdFusedLseMulti(
        const float* qkv, int qkv_len,
        const float* dctx, int dctx_len,
        const float* ctx_in, int ctx_in_len,
        const float* lse_in, int lse_in_len,
        float* ctxo, int ctxo_len,
        float* dqo, int dqo_len,
        int n, int h, int hd, double inv, int nthreads) {
    if (!qkv || !dctx || !ctx_in || !lse_in || !ctxo || !dqo) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    int nh = h / FL_HD;
    if ((long long)qkv_len  < (long long)n * 3 * h) return -5;
    if ((long long)dctx_len < (long long)n * h) return -5;
    if ((long long)ctx_in_len < (long long)n * nh * FL_HD) return -5;
    if ((long long)lse_in_len < (long long)n * nh) return -5;
    if ((long long)ctxo_len < (long long)n * nh * FL_HD) return -5;
    if ((long long)dqo_len  < (long long)n * nh * 3 * FL_HD) return -5;
    mh_job_t c;
    c.qkv = qkv; c.dctx = dctx; c.ctx_in = ctx_in; c.lse_in = lse_in;
    c.ctxo = ctxo; c.dqo = dqo;
    c.n = n; c.h = h; c.nh = nh; c.hd = FL_HD; c.inv = inv;
    c.next = -1; c.rc = 0;
    return mh_run(&c, nthreads, mh_bwd_worker);
}

EXPORT int FlashAttentionFwdLseMulti(
        const float* qkv, int qkv_len,
        float* ctx_out, int ctx_len,
        float* lse, int lse_len,
        int n, int h, int hd, double inv, int nthreads) {
    if (!qkv || !ctx_out || !lse) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    int nh = h / FL_HD;
    if ((long long)qkv_len < (long long)n * 3 * h) return -5;
    if ((long long)ctx_len < (long long)n * nh * FL_HD) return -5;
    if ((long long)lse_len < (long long)n * nh) return -5;
    mh_job_t c;
    c.qkv = qkv; c.dctx = NULL; c.ctx_in = NULL; c.lse_in = lse;
    c.ctxo = ctx_out; c.dqo = NULL;
    c.n = n; c.h = h; c.nh = nh; c.hd = FL_HD; c.inv = inv;
    c.next = -1; c.rc = 0;
    return mh_run(&c, nthreads, mh_fwd_worker);
}

/* ===========================================================================
 * Phase 2c-2 (2026-11-10): MULTI-HEAD + MERGE trong MOT lenh goi
 *
 * Van de con lai: AttentionBwdFusedMulti da dat 6.17x (29.15 ms/layer vs
 * 179.77) nhung production van phai lam 12 lan `_attn_hb_merge` (goi
 * MergeHbHead rieng, moi lan 1 head) de rai ctxo/dqo vao ctxT/dqkv.
 *
 * Ham nay lam ca 12 head + merge trong 1 lan goi:
 *   - worker bwd ghi thang vao ctxT/dqkv theo vi tri (t, head, d)
 *     -> KHONG con buffer trung gian ctxo/dqo, KHONG con pass merge
 *   - moi head chi cham vao cot [head*hd, head*hd+hd) cua moi hang t
 *     -> khong data race, khong lock
 *   - gia tri ghi y het MergeHbHead (cung cong thuc, cung thu tu doc)
 *     -> BIT-IDENTICAL voi duong 12x one + 12x merge
 *
 * Voi n=1024, h=768: tiet kiem ~2 x 3.15M ptu doc/ghi (ctxo + dqo vao-ra)
 * va 12 lan goi qua bien DLL.
 * =========================================================================== */

typedef struct {
    const float* qkv;
    const float* dctx;
    const float* ctx_in;
    const float* lse_in;
    float* ctxT;      /* [n][h]  - ghi truc tiep cot (head*hd + d) */
    float* dqkv;      /* [n][3h] - ghi truc tiep cot (head*hd + d) 3 lan */
    int n, h, nh, hd;
    double inv;
    volatile LONG next;
    volatile LONG rc;
} mh_merge_job_t;

/* Scatter 1 head tu buffer PACKED sang ctxT/dqkv - y het MergeHbHead
 * (tkv_bwd_ops.c) nhung nhan con tro nguon rieng thay vi mang 12 buffer. */
static void mh_scatter_head(const float* co, const float* dq,
                            float* ctxT, float* dqkv,
                            int n, int h, int hd, int head) {
    int ho = head * hd;
    for (int t2 = 0; t2 < n; t2++) {
        long long c0 = (long long)t2 * h + ho;
        long long p0 = (long long)t2 * 3 * hd;
        long long r0 = (long long)t2 * 3 * h + ho;
        const float* src_dq = dq + p0;
        for (int d = 0; d < hd; d++) {
            ctxT[c0 + d]         = co[(long long)t2 * hd + d];
            dqkv[r0 + d]         = src_dq[d];
            dqkv[r0 + h + d]     = src_dq[hd + d];
            dqkv[r0 + 2 * h + d] = src_dq[2 * hd + d];
        }
    }
}

static DWORD WINAPI mh_merge_worker(LPVOID p) {
    mh_merge_job_t* c = (mh_merge_job_t*)p;
    long long ctx_len = (long long)c->n * c->hd;
    long long dq_len  = (long long)c->n * 3 * c->hd;
    float* co = (float*)malloc((size_t)ctx_len * 4);
    float* dq = (float*)malloc((size_t)dq_len * 4);
    if (!co || !dq) {
        free(co); free(dq);
        InterlockedCompareExchange(&c->rc, -6, 0);
        return 0;
    }
    for (;;) {
        LONG head = InterlockedIncrement(&c->next);
        if (head >= c->nh) break;
        int rc = flash_bwd_head(
            c->qkv, c->dctx, co, dq,
            c->n, c->h, (int)head, c->inv,
            c->ctx_in ? c->ctx_in + (long long)head * c->n * c->hd : NULL,
            c->lse_in ? c->lse_in + (long long)head * c->n : NULL);
        if (rc != 0) { InterlockedCompareExchange(&c->rc, rc, 0); break; }
        mh_scatter_head(co, dq, c->ctxT, c->dqkv, c->n, c->h, c->hd, (int)head);
    }
    free(co); free(dq);
    return 0;
}

static int mh_merge_run(mh_merge_job_t* c, int nthreads) {
    if (nthreads > c->nh) nthreads = c->nh;
    if (nthreads < 1) nthreads = 1;
    if (nthreads == 1) { mh_merge_worker(c); return c->rc; }
    HANDLE th[64];
    int spawned = 0;
    for (int i = 0; i < nthreads; i++) {
        HANDLE h = CreateThread(NULL, 0, mh_merge_worker, c, 0, NULL);
        if (h) th[spawned++] = h;
    }
    if (spawned == 0) { mh_merge_worker(c); return c->rc; }
    WaitForMultipleObjects(spawned, th, TRUE, INFINITE);
    for (int i = 0; i < spawned; i++) CloseHandle(th[i]);
    return c->rc;
}

/* FlashAttentionBwdMergeMulti: bwd 12 head + scatter thang vao ctxT/dqkv.
 * ctxT: [n][h]   (caller cap, ghi DE toan bo cot head*hd..+hd)
 * dqkv: [n][3h]  (caller cap, ghi DE tai (t, {0,h,2h}+head*hd+d))
 * rc != 0 -> caller fallback duong cu (12x one + 12x merge). */
EXPORT int FlashAttentionBwdMergeMulti(
        const float* qkv, int qkv_len,
        const float* dctx, int dctx_len,
        const float* ctx_in, int ctx_in_len,
        const float* lse_in, int lse_in_len,
        float* ctxT, int ctxT_len,
        float* dqkv, int dqkv_len,
        int n, int h, int hd, double inv, int nthreads) {
    if (!qkv || !dctx || !ctx_in || !lse_in || !ctxT || !dqkv) return -1;
    if (n < 64 || h <= 0 || hd != FL_HD) return -13;
    int nh = h / FL_HD;
    if ((long long)qkv_len   < (long long)n * 3 * h) return -5;
    if ((long long)dctx_len  < (long long)n * h) return -5;
    if ((long long)ctx_in_len < (long long)n * nh * FL_HD) return -5;
    if ((long long)lse_in_len < (long long)n * nh) return -5;
    if ((long long)ctxT_len  < (long long)n * h) return -5;
    if ((long long)dqkv_len  < (long long)n * 3 * h) return -5;
    mh_merge_job_t c;
    c.qkv = qkv; c.dctx = dctx; c.ctx_in = ctx_in; c.lse_in = lse_in;
    c.ctxT = ctxT; c.dqkv = dqkv;
    c.n = n; c.h = h; c.nh = nh; c.hd = FL_HD; c.inv = inv;
    c.next = -1; c.rc = 0;
    return mh_merge_run(&c, nthreads);
}