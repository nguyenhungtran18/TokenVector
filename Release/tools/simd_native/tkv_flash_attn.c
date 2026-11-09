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
 *   - online max/sum f32 (qk_max/qk_sum) thay f64; exp bang expf (MSVC /fp:fast)
 *   - hd = 64 cung dinh (truoc watergate: n >= 64 moi chap nhan)
 *   - khong ap pack/VNNI (bf16), khong mask tuy y - causal mask tinh tai cho
 *     (u > t -> -INF) nhu ref cua .tkv
 *   - GEMM bang dot64() AVX2 FMA (thu tu tich luy KHAC BLAS/MKL -> loss
 *     khong bit-exact nhu kernel cu; user da nhan relax gate)
 *   - softmax recompute TRONG bwd (du tru lse) de .tkv khong phai tiep luyen
 *     them buffer
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

/* dot 64 phan tu, tich luy f32 theo thu tu lane (khac BLAS -> khong bit-exact, user da nhan) */
/* fast expf AVX2: polynomial + scalef; clamp [-87, 88] -> finite; KHONG bat buoc bit-exact
 * (path da waiver user s0.125); ULP < ~2. Thay the expf scalar trong flash_bwd de giam
 * ~12.6M expf/layer @seq1024. */
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
    __m256 pow2n = _mm256_castsi256_ps(bits);
    return _mm256_mul_ps(r, pow2n);
}

static inline float dot64(const float* a, const float* b) {
    __m256 acc = _mm256_setzero_ps();
    for (int i = 0; i < 64; i += 8) {
        acc = _mm256_fmadd_ps(_mm256_loadu_ps(a + i), _mm256_loadu_ps(b + i), acc);
    }
    __m128 lo = _mm256_castps256_ps128(acc);
    __m128 hi = _mm256_extractf128_ps(acc, 1);
    __m128 s = _mm_add_ps(lo, hi);
    __m128 shuf = _mm_movehdup_ps(s);
    s = _mm_add_ps(s, shuf);
    shuf = _mm_movehl_ps(s, s);
    s = _mm_add_ss(s, shuf);
    return _mm_cvtss_f32(s);
}

/* P x V khoi: dst[64] += p * v_row (hd=64, 8 x _mm256_fmadd) */
static inline void fma_row(float* dst, float p, const float* v_row) {
    __m256 vp = _mm256_set1_ps(p);
    for (int d = 0; d < 64; d += 8) {
        __m256 cur = _mm256_loadu_ps(dst + d);
        __m256 vr = _mm256_loadu_ps(v_row + d);
        _mm256_storeu_ps(dst + d, _mm256_fmadd_ps(vp, vr, cur));
    }
}
static inline void mul_row(float* dst, float s) {
    __m256 vs = _mm256_set1_ps(s);
    for (int d = 0; d < 64; d += 8) {
        _mm256_storeu_ps(dst + d, _mm256_mul_ps(_mm256_loadu_ps(dst + d), vs));
    }
}

/* ---- Flash fwd 1 head (causal, no mask) ---- */
static int flash_fwd_head(const float* qkv, float* ctx_out, float* lse_out,
                          int n, int h, int head, double inv) {
    float* qk = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* dst = (float*)malloc((size_t)FL_QS * FL_HD * 4);
    float mx[FL_QS], sm[FL_QS];
    long long stride3 = (long long)3 * h;
    int coff_q = head * FL_HD;
    int coff_k = coff_q + h;
    int coff_v = coff_q + 2 * h;
    float finv = (float)inv;
    if (!qk || !dst) { free(qk); free(dst); return -6; }

    for (int m0 = 0; m0 < n; m0 += FL_QS) {
        int qb = n - m0; if (qb > FL_QS) qb = FL_QS;
        int num_keys = m0 + qb; if (num_keys > n) num_keys = n;
        for (int i = 0; i < qb; i++) { mx[i] = -INFINITY; sm[i] = 0.0f; }
        for (int i = 0; i < qb * FL_HD; i++) dst[i] = 0.0f;
        for (int n0 = 0; n0 < num_keys; n0 += FL_KS) {
            int kvb = num_keys - n0; if (kvb > FL_KS) kvb = FL_KS;
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                const float* qrow = qkv + (long long)t * stride3 + coff_q;
                for (int j = 0; j < kvb; j++) {
                    int u = n0 + j;
                    float v;
                    if (u > t) {
                        qk[i * FL_KS + j] = -INFINITY;
                        continue;
                    }
                    v = dot64(qrow, qkv + (long long)u * stride3 + coff_k) * finv;
                    qk[i * FL_KS + j] = v;
                }
            }
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                float rmax = -INFINITY;
                for (int j = 0; j < kvb; j++) {
                    float v = qk[i * FL_KS + j];
                    if (v > rmax) rmax = v;
                }
                float newmax = (mx[i] > rmax) ? mx[i] : rmax;
                if (newmax == -INFINITY) {
                    /* dong bi che hoan toan (chi khi n0 block dau) - fill 0 */
                    for (int j = 0; j < kvb; j++) qk[i * FL_KS + j] = 0.0f;
                    for (int d = 0; d < FL_HD; d++) dst[i * FL_HD + d] = 0.0f;
                    mx[i] = newmax;
                    continue;
                }
                float exp_tmp = (n0 == 0) ? 1.0f : expf(mx[i] - newmax); /* mx[i]=-inf -> 0 */
                if (mx[i] == -INFINITY) exp_tmp = 0.0f;
                float bsum = exp_sum_row_fast(qk + i * FL_KS, newmax, kvb);
                if (n0 > 0) mul_row(dst + i * FL_HD, exp_tmp);
                sm[i] = bsum + exp_tmp * sm[i];
                mx[i] = newmax;
                for (int j = 0; j < kvb; j++) {
                    float p = qk[i * FL_KS + j];
                    if (p == 0.0f) continue;
                    int u = n0 + j;
                    fma_row(dst + i * FL_HD, p, qkv + (long long)u * stride3 + coff_v);
                }
            }
        }
        for (int i = 0; i < qb; i++) {
            int t = m0 + i;
            float sinv = 1.0f / sm[i];
            float* orow = ctx_out + (long long)t * FL_HD;
            for (int d = 0; d < FL_HD; d += 8) {
                __m256 dv = _mm256_loadu_ps(dst + i * FL_HD + d);
                _mm256_storeu_ps(orow + d, _mm256_mul_ps(dv, _mm256_set1_ps(sinv)));
            }
            if (lse_out) lse_out[t] = mx[i] + logf(sm[i]);
        }
    }
    free(qk);
    free(dst);
    return 0;
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

/* lse buffer phu tro (tuy chon) - dung trong probe; khong wire .tkv */
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

/* ---- Flash bwd 1 head (causal) ---- */
/* vectorized expf row: exp(x - newmax) cho row [0, kvb) - clamp thay vi branch cho -inf */
static inline void exp_row_fast(float* qk, float newmax, int kvb) {
    int j = 0;
    __m256 vmax = _mm256_set1_ps(newmax);
    for (; j + 8 <= kvb; j += 8) {
        __m256 v = _mm256_loadu_ps(qk + j);
        v = _mm256_sub_ps(v, vmax);
        v = m256_exp_ps(v);
        _mm256_storeu_ps(qk + j, v);
    }
    for (; j < kvb; j++) qk[j] = expf(qk[j] - newmax);
}

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

/* vectorized expf row va sum cua row : thay vong scalar bsum=expf(qk[.]) style */
static inline float exp_sum_row_fast(float* qk, float newmax, int kvb) {
    int j = 0;
    __m256 vmax = _mm256_set1_ps(newmax);
    __m256 bsum_vec = _mm256_setzero_ps();
    for (; j + 8 <= kvb; j += 8) {
        __m256 v = _mm256_loadu_ps(qk + j);
        v = _mm256_sub_ps(v, vmax);
        v = m256_exp_ps(v);
        _mm256_storeu_ps(qk + j, v);
        bsum_vec = _mm256_add_ps(bsum_vec, v);
    }
    float bsum = 0.0f;
    __m128 lo = _mm256_castps256_ps128(bsum_vec);
    __m128 hi = _mm256_extractf128_ps(bsum_vec, 1);
    __m128 s = _mm_add_ps(lo, hi);
    __m128 shuf = _mm_movehdup_ps(s);
    s = _mm_add_ps(s, shuf);
    shuf = _mm_movehl_ps(s, s);
    s = _mm_add_ss(s, shuf);
    bsum = _mm_cvtss_f32(s);
    for (; j < kvb; j++) {
        float e = expf(qk[j] - newmax);
        qk[j] = e;
        bsum += e;
    }
    return bsum;
}

    static int flash_bwd_head(const float* qkv, const float* dctx,
                          float* ctxo, float* dqo,
                          int n, int h, int head, double inv) {
    long long stride3 = (long long)3 * h;
    long long stridet = (long long)h;
    int coff_q = head * FL_HD;
    int coff_k = coff_q + h;
    int coff_v = coff_q + 2 * h;
    float finv = (float)inv;
    int rc = 0;

    float* out_buf = (float*)malloc((size_t)n * FL_HD * 4);
    float* lse = (float*)malloc((size_t)n * 4);
    float* dsum = (float*)malloc((size_t)n * 4);
    float* dq = (float*)malloc((size_t)n * FL_HD * 4);
    float* dk = (float*)malloc((size_t)n * FL_HD * 4);
    float* dv = (float*)malloc((size_t)n * FL_HD * 4);
    float* attn = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* gA = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    float* ds = (float*)malloc((size_t)FL_QS * FL_KS * 4);
    if (!out_buf || !lse || !dsum || !dq || !dk || !dv || !attn || !gA || !ds) { rc = -6; goto done; }
    memset(dq, 0, (size_t)n * FL_HD * 4);
    memset(dk, 0, (size_t)n * FL_HD * 4);
    memset(dv, 0, (size_t)n * FL_HD * 4);

    /* pass 1: recompute out + lse (giong fwd nhung ghi vao out_buf) */
    {
        /* dung lai code fwd inline de giu chinh xac 1 duong tinh toan */
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
                for (int i = 0; i < qb; i++) {
                    int t = m0 + i;
                    const float* qrow = qkv + (long long)t * stride3 + coff_q;
                    for (int j = 0; j < kvb; j++) {
                        int u = n0 + j;
                        if (u > t) { qk[i * FL_KS + j] = -INFINITY; continue; }
                        qk[i * FL_KS + j] = dot64(qrow, qkv + (long long)u * stride3 + coff_k) * finv;
                    }
                }
                for (int i = 0; i < qb; i++) {
                    int t = m0 + i;
                    float rmax = -INFINITY;
                    for (int j = 0; j < kvb; j++) {
                        float v = qk[i * FL_KS + j]; if (v > rmax) rmax = v;
                    }
                    float newmax = (mx[i] > rmax) ? mx[i] : rmax;
                    if (newmax == -INFINITY) {
                        for (int j = 0; j < kvb; j++) qk[i * FL_KS + j] = 0.0f;
                        mx[i] = newmax;
                        continue;
                    }
                    float exp_tmp = (n0 == 0) ? 1.0f : expf(mx[i] - newmax);
                    if (mx[i] == -INFINITY) exp_tmp = 0.0f;
                    float bsum = exp_sum_row_fast(qk + i * FL_KS, newmax, kvb);
                    if (n0 > 0) mul_row(dst + i * FL_HD, exp_tmp);
                    sm[i] = bsum + exp_tmp * sm[i];
                    mx[i] = newmax;
                    for (int j = 0; j < kvb; j++) {
                        float p = qk[i * FL_KS + j];
                        if (p == 0.0f) continue;
                        int u = n0 + j;
                        fma_row(dst + i * FL_HD, p, qkv + (long long)u * stride3 + coff_v);
                    }
                }
            }
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                float sinv = 1.0f / sm[i];
                float* orow = out_buf + (long long)t * FL_HD;
                for (int d = 0; d < FL_HD; d += 8) {
                    __m256 dvrow = _mm256_loadu_ps(dst + i * FL_HD + d);
                    _mm256_storeu_ps(orow + d, _mm256_mul_ps(dvrow, _mm256_set1_ps(sinv)));
                }
                lse[t] = mx[i] + logf(sm[i]);
            }
        }
        free(qk);
        free(dst);
    }
    /* dsum[t] = sum_d dctx[t,d] * out[t,d] (tich luy THUAN lenh hd, f32) */
    for (int t = 0; t < n; t++) {
        float acc = dot64(dctx + (long long)t * stridet + coff_q, out_buf + (long long)t * FL_HD);
        dsum[t] = acc;
    }

/* pass 2: kv outer, q inner; recompute attn block tu lse */
    for (int n0 = 0; n0 < n; n0 += FL_KS) {
        int kvb = n - n0; if (kvb > FL_KS) kvb = FL_KS;
        for (int m0 = (n0 / FL_QS) * FL_QS; m0 < n; m0 += FL_QS) {
            int qb = n - m0; if (qb > FL_QS) qb = FL_QS;
            /* blocks hoan toan che (u >= n0 > m0+qb-1) bo qua */
            if (m0 + qb <= n0) continue;
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                const float* qrow = qkv + (long long)t * stride3 + coff_q;
                for (int j = 0; j < kvb; j++) {
                    int u = n0 + j;
                    if (u > t) { attn[i * FL_KS + j] = 0.0f; continue; }
                    attn[i * FL_KS + j] = expf(dot64(qrow, qkv + (long long)u * stride3 + coff_k) * finv - lse[t]);
                }
            }
            /* gA[i,u] = dot(dctx[i], V[u])  */
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                const float* drow = dctx + (long long)t * stridet + coff_q;
                for (int j = 0; j < kvb; j++) {
                    int u = n0 + j;
                    gA[i * FL_KS + j] = dot64(drow, qkv + (long long)u * stride3 + coff_v);
                }
            }
            /* ds = attn * (gA - dsum[i]) */
            for (int i = 0; i < qb; i++) {
                float di = dsum[m0 + i];
                for (int j = 0; j < kvb; j++) {
                    ds[i * FL_KS + j] = attn[i * FL_KS + j] * (gA[i * FL_KS + j] - di);
                }
            }
            /* dv[u] += sum_i attn[i,u] * dctx[i] */
            for (int j = 0; j < kvb; j++) {
                int u = n0 + j;
                float* vDst = dv + (long long)u * FL_HD;
                for (int i = 0; i < qb; i++) {
                    float p = attn[i * FL_KS + j];
                    if (p == 0.0f) continue;
                    int t = m0 + i;
                    fma_row(vDst, p, dctx + (long long)t * stridet + coff_q);
                }
            }
            /* dq[i] += sum_u ds[i,u] * K[u] */
            for (int i = 0; i < qb; i++) {
                int t = m0 + i;
                float* qDst = dq + (long long)t * FL_HD;
                const float* kRowBase = qkv + coff_k;
                for (int j = 0; j < kvb; j++) {
                    float p = ds[i * FL_KS + j];
                    if (p == 0.0f) continue;
                    fma_row(qDst, p, kRowBase + (long long)(n0 + j) * stride3);
                }
            }
            /* dk[u] += sum_i ds[i,u] * Q[i] */
            for (int j = 0; j < kvb; j++) {
                int u = n0 + j;
                float* kDst = dk + (long long)u * FL_HD;
                for (int i = 0; i < qb; i++) {
                    float p = ds[i * FL_KS + j];
                    if (p == 0.0f) continue;
                    int t = m0 + i;
                    fma_row(kDst, p, qkv + (long long)t * stride3 + coff_q);
                }
            }
        }
    }

    /* writeback: ctxo = out_buf; dqo = [dq*inv | dk*inv | dv] */
    for (int t = 0; t < n; t++) {
        long long d0 = (long long)t * FL_HD;
        long long p0 = (long long)t * 3 * FL_HD;
        for (int d = 0; d < FL_HD; d++) ctxo[d0 + d] = out_buf[d0 + d];
        for (int d = 0; d < FL_HD; d++) {
            dqo[p0 + d] = dq[d0 + d] * finv;
            dqo[p0 + FL_HD + d] = dk[d0 + d] * finv;
            dqo[p0 + 2 * FL_HD + d] = dv[d0 + d];
        }
    }

done:
    free(out_buf); free(lse); free(dsum);
    free(dq); free(dk); free(dv);
    free(attn); free(gA); free(ds);
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
    return flash_bwd_head(qkv, dctx, ctxo, dqo, n, h, head, inv);
}
