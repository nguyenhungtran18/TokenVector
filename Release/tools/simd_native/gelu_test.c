/* gelu_test.c - so sanh gelu AVX2 vs scalar (cung cong thuc A&S 7.1.26) */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

static inline float scalar_gelu_erf_f(float v) {
    float arg = v / 1.4142135623730951f;
    double sg = 1.0;
    if (arg < 0.0f) sg = -1.0;
    float ax = fabsf(arg);
    double t = 1.0 / (1.0 + 0.3275911 * (double)ax);
    double poly = 1.061405429;
    poly = poly * t + -1.453152027;
    poly = poly * t + 1.421413741;
    poly = poly * t + -0.284496736;
    poly = poly * t + 0.254829592;
    poly = poly * t;
    float e = (float)exp((double)((-ax) * ax));
    return (float)(sg * (1.0 - (double)e * poly));
}
static inline float scalar_gelu_f_one(float v) {
    float e = scalar_gelu_erf_f(v);
    return 0.5f * v * (1.0f + e);
}
static inline float scalar_gelu_erf_b(float v) {
    float arg = (float)((double)v / 1.4142135623730951);
    double sg = 1.0;
    if (arg < 0.0f) sg = -1.0;
    float ax = fabsf(arg);
    double t = 1.0 / (1.0 + 0.3275911 * (double)ax);
    double poly = 1.061405429;
    poly = poly * t + -1.453152027;
    poly = poly * t + 1.421413741;
    poly = poly * t + -0.284496736;
    poly = poly * t + 0.254829592;
    poly = poly * t;
    float e = (float)exp((double)((-ax) * ax));
    return (float)(sg * (1.0 - (double)e * poly));
}
static inline float scalar_gelu_b_one(float v) {
    float ef = scalar_gelu_erf_b(v);
    double d = 0.5 * (1.0 + (double)ef)
             + ((double)v * 0.3989422804014327) * exp(((-0.5) * (double)v) * (double)v);
    return (float)d;
}

#include "tkv_gelu_avx2.h"

int main(void) {
    const int N = 1 << 20;
    float* xs = malloc(N * sizeof(float));
    srand(12345);
    /* range [-10, 10] */
    for (int i = 0; i < N; i++) xs[i] = ((float)(rand() % 20000) / 1000.0f) - 10.0f;
    /* special points */
    xs[0] = 0.0f; xs[1] = 6.0f; xs[2] = -6.0f; xs[3] = 3.0f; xs[4] = -3.0f;

    float maxd_f = 0, maxd_b = 0;
    int i = 0;
    for (; i + 8 <= N; i += 8) {
        __m256 v = _mm256_loadu_ps(xs + i);
        __m256 f8 = tkv_gelu_fwd_one(v);
        __m256 b8 = tkv_gelu_bwd_one(v);
        float fs[8], bs[8];
        _mm256_storeu_ps(fs, f8);
        _mm256_storeu_ps(bs, b8);
        for (int j = 0; j < 8; j++) {
            float sf = scalar_gelu_f_one(xs[i + j]);
            float sb = scalar_gelu_b_one(xs[i + j]);
            float df = fabsf(fs[j] - sf), db = fabsf(bs[j] - sb);
            if (df > maxd_f) maxd_f = df;
            if (db > maxd_b) maxd_b = db;
        }
    }
    printf("max |diff| gelu_fwd = %.3e\n", maxd_f);
    printf("max |diff| gelu_bwd = %.3e\n", maxd_b);
    return 0;
}
