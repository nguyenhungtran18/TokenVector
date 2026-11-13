/* tkv_gelu_avx2.h - AVX2 GELU (erf) : test-only cho wsltest truoc khi sua tkv_bwd_ops.c */
#pragma once
#include <immintrin.h>
#include <math.h>

static inline __m256 tkv_exp_ps(__m256 x) {
    const __m256 LOG2E = _mm256_set1_ps(1.4426950408889634f);
    const __m256 LN2   = _mm256_set1_ps(0.6931471805599453f);
    __m256 kf = _mm256_round_ps(_mm256_mul_ps(x, LOG2E),
                                _MM_FROUND_TO_NEAREST_INT | _MM_FROUND_NO_EXC);
    __m256 r  = _mm256_fnmadd_ps(kf, LN2, x);      /* |r| <= 0.347 */
    __m256 p  = _mm256_set1_ps(2.48015873e-05f);   /* 1/8!  */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(1.98412698e-04f)); /* 1/7! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(1.38888889e-03f)); /* 1/6! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(8.33333333e-03f)); /* 1/5! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(4.16666667e-02f)); /* 1/4! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(1.66666667e-01f)); /* 1/3! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(5.00000000e-01f)); /* 1/2! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(1.00000000e+00f)); /* 1/1! */
    p = _mm256_fmadd_ps(p, r, _mm256_set1_ps(1.00000000e+00f)); /* 1    */
    __m256i ki = _mm256_cvtps_epi32(kf);
    ki = _mm256_add_epi32(ki, _mm256_set1_epi32(127));
    ki = _mm256_slli_epi32(ki, 23);
    return _mm256_mul_ps(p, _mm256_castsi256_ps(ki));
}

/* erf(arg) vectorized, arg bat ky dau. A&S 7.1.26, sai so <= 1.5e-7. */
static inline __m256 tkv_erf_ps(__m256 v) {
    const __m256 SQRT2INV = _mm256_set1_ps(0.70710678118654752f);
    __m256 arg = _mm256_mul_ps(v, SQRT2INV);
    __m256 sg  = _mm256_blendv_ps(_mm256_set1_ps(1.0f), _mm256_set1_ps(-1.0f),
                                  _mm256_cmp_ps(arg, _mm256_setzero_ps(), _CMP_LT_OQ));
    __m256 ax  = _mm256_andnot_ps(_mm256_set1_ps(-0.0f), arg); /* fabs = arg with sign bit cleared */
    ax = _mm256_max_ps(ax, _mm256_setzero_ps());
    __m256 t   = _mm256_div_ps(_mm256_set1_ps(1.0f),
                               _mm256_fmadd_ps(_mm256_set1_ps(0.3275911f), ax, _mm256_set1_ps(1.0f)));
    __m256 p   = _mm256_set1_ps(1.061405429f);
    p = _mm256_fmadd_ps(p, t, _mm256_set1_ps(-1.453152027f));
    p = _mm256_fmadd_ps(p, t, _mm256_set1_ps(1.421413741f));
    p = _mm256_fmadd_ps(p, t, _mm256_set1_ps(-0.284496736f));
    p = _mm256_fmadd_ps(p, t, _mm256_set1_ps(0.254829592f));
    p = _mm256_fmadd_ps(p, t, _mm256_setzero_ps());
    __m256 negax2 = _mm256_max_ps(_mm256_mul_ps(_mm256_mul_ps(ax, ax), _mm256_set1_ps(-1.0f)),
                                  _mm256_set1_ps(-90.0f));
    __m256 e  = tkv_exp_ps(negax2);
    __m256 erf = _mm256_fnmadd_ps(e, p, _mm256_set1_ps(1.0f)); /* 1 - e*poly */
    return _mm256_mul_ps(sg, erf);
}

static inline __m256 tkv_gelu_fwd_one(__m256 v) {
    __m256 erf = tkv_erf_ps(v);
    __m256 op  = _mm256_add_ps(_mm256_set1_ps(1.0f), erf);
    return _mm256_mul_ps(_mm256_mul_ps(_mm256_set1_ps(0.5f), v), op);
}

static inline __m256 tkv_gelu_bwd_one(__m256 v) {
    __m256 erf = tkv_erf_ps(v);
    __m256 d   = _mm256_mul_ps(_mm256_add_ps(_mm256_set1_ps(1.0f), erf),
                               _mm256_set1_ps(0.5f));
    __m256 neg = _mm256_max_ps(_mm256_mul_ps(_mm256_mul_ps(v, v), _mm256_set1_ps(-0.5f)),
                               _mm256_set1_ps(-90.0f));
    __m256 e   = tkv_exp_ps(neg);
    d = _mm256_fmadd_ps(_mm256_mul_ps(v, _mm256_set1_ps(0.3989422804014327f)), e, d);
    return d;
}
