/* tkv_simd_native.c - kernel SIMD that bang C (AVX2 + FMA) cho TokenVector.
 *
 * Muc dich: thay the duong Vector<T>/Vector4 (bi JIT dich thanh METHOD CALL
 * tren .NET Framework AOT) bang ma may SIMD that.
 *
 * Quy uoc goi (x64 Windows - mot convention duy nhat, stdcall bi bo qua):
 *   void  <Op>F32(float* a, float* b, float* o, int n)
 *   float <Red>F32(float* a, float* b, int n)
 *   void  ScaleF32(float* a, float s, float* o, int n)
 *   void  AxpyF32(float alpha, float* x, float* y, int n)
 *   void  SgemmF32(float* a, float* b, float* o, int n)
 * va ban f64 tuong tu.
 */
#include <immintrin.h>

#define EXPORT __declspec(dllexport)

/* ---------------- f32 ---------------- */
EXPORT void AddF32(float* a, float* b, float* o, int n) {
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 va = _mm256_loadu_ps(a + i);
        __m256 vb = _mm256_loadu_ps(b + i);
        _mm256_storeu_ps(o + i, _mm256_add_ps(va, vb));
    }
    for (; i < n; i++) o[i] = a[i] + b[i];
}

EXPORT void SubF32(float* a, float* b, float* o, int n) {
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 va = _mm256_loadu_ps(a + i);
        __m256 vb = _mm256_loadu_ps(b + i);
        _mm256_storeu_ps(o + i, _mm256_sub_ps(va, vb));
    }
    for (; i < n; i++) o[i] = a[i] - b[i];
}

EXPORT void MulF32(float* a, float* b, float* o, int n) {
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 va = _mm256_loadu_ps(a + i);
        __m256 vb = _mm256_loadu_ps(b + i);
        _mm256_storeu_ps(o + i, _mm256_mul_ps(va, vb));
    }
    for (; i < n; i++) o[i] = a[i] * b[i];
}

EXPORT void ScaleF32(float* a, float s, float* o, int n) {
    __m256 vs = _mm256_set1_ps(s);
    int i = 0;
    for (; i + 8 <= n; i += 8)
        _mm256_storeu_ps(o + i, _mm256_mul_ps(_mm256_loadu_ps(a + i), vs));
    for (; i < n; i++) o[i] = a[i] * s;
}

EXPORT void AxpyF32(float alpha, float* x, float* y, int n) {
    __m256 va = _mm256_set1_ps(alpha);
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 vx = _mm256_loadu_ps(x + i);
        __m256 vy = _mm256_loadu_ps(y + i);
        _mm256_storeu_ps(y + i, _mm256_fmadd_ps(va, vx, vy));
    }
    for (; i < n; i++) y[i] += alpha * x[i];
}

EXPORT float DotF32(float* a, float* b, int n) {
    __m256 acc = _mm256_setzero_ps();
    int i = 0;
    for (; i + 8 <= n; i += 8)
        acc = _mm256_fmadd_ps(_mm256_loadu_ps(a + i), _mm256_loadu_ps(b + i), acc);
    __m128 lo = _mm256_castps256_ps128(acc);
    __m128 hi = _mm256_extractf128_ps(acc, 1);
    __m128 s = _mm_add_ps(lo, hi);
    s = _mm_hadd_ps(s, s);
    s = _mm_hadd_ps(s, s);
    float r = _mm_cvtss_f32(s);
    for (; i < n; i++) r += a[i] * b[i];
    return r;
}

EXPORT float SumF32(float* a, int n) {
    __m256 acc = _mm256_setzero_ps();
    int i = 0;
    for (; i + 8 <= n; i += 8) acc = _mm256_add_ps(acc, _mm256_loadu_ps(a + i));
    __m128 lo = _mm256_castps256_ps128(acc);
    __m128 hi = _mm256_extractf128_ps(acc, 1);
    __m128 s = _mm_add_ps(lo, hi);
    s = _mm_hadd_ps(s, s);
    s = _mm_hadd_ps(s, s);
    float r = _mm_cvtss_f32(s);
    for (; i < n; i++) r += a[i];
    return r;
}

EXPORT float MaxF32(float* a, int n) {
    if (n <= 0) return 0.0f;
    __m256 m = _mm256_set1_ps(a[0]);
    int i = 0;
    for (; i + 8 <= n; i += 8) m = _mm256_max_ps(m, _mm256_loadu_ps(a + i));
    __m128 lo = _mm256_castps256_ps128(m);
    __m128 hi = _mm256_extractf128_ps(m, 1);
    __m128 s = _mm_max_ps(lo, hi);
    s = _mm_max_ps(s, _mm_shuffle_ps(s, s, 0x4E));
    s = _mm_max_ps(s, _mm_shuffle_ps(s, s, 0xB1));
    float r = _mm_cvtss_f32(s);
    for (; i < n; i++) if (a[i] > r) r = a[i];
    return r;
}

EXPORT float MinF32(float* a, int n) {
    if (n <= 0) return 0.0f;
    __m256 m = _mm256_set1_ps(a[0]);
    int i = 0;
    for (; i + 8 <= n; i += 8) m = _mm256_min_ps(m, _mm256_loadu_ps(a + i));
    __m128 lo = _mm256_castps256_ps128(m);
    __m128 hi = _mm256_extractf128_ps(m, 1);
    __m128 s = _mm_min_ps(lo, hi);
    s = _mm_min_ps(s, _mm_shuffle_ps(s, s, 0x4E));
    s = _mm_min_ps(s, _mm_shuffle_ps(s, s, 0xB1));
    float r = _mm_cvtss_f32(s);
    for (; i < n; i++) if (a[i] < r) r = a[i];
    return r;
}

/* SGEMM C = A*B, A/B/C deu n x n, row-major, C ghi de. */
EXPORT void SgemmF32(float* a, float* b, float* o, int n) {
    for (int i = 0; i < n; i++) {
        float* ai = a + (long long)i * n;
        float* oi = o + (long long)i * n;
        int j = 0;
        for (; j + 8 <= n; j += 8) {
            __m256 acc = _mm256_setzero_ps();
            for (int k = 0; k < n; k++) {
                __m256 va = _mm256_set1_ps(ai[k]);
                __m256 vb = _mm256_loadu_ps(b + (long long)k * n + j);
                acc = _mm256_fmadd_ps(va, vb, acc);
            }
            _mm256_storeu_ps(oi + j, acc);
        }
        for (; j < n; j++) {
            float acc = 0.0f;
            for (int k = 0; k < n; k++) acc += ai[k] * b[(long long)k * n + j];
            oi[j] = acc;
        }
    }
}

/* ---------------- f64 ---------------- */
EXPORT void AddF64(double* a, double* b, double* o, int n) {
    int i = 0;
    for (; i + 4 <= n; i += 4)
        _mm256_storeu_pd(o + i, _mm256_add_pd(_mm256_loadu_pd(a + i), _mm256_loadu_pd(b + i)));
    for (; i < n; i++) o[i] = a[i] + b[i];
}

EXPORT void SubF64(double* a, double* b, double* o, int n) {
    int i = 0;
    for (; i + 4 <= n; i += 4)
        _mm256_storeu_pd(o + i, _mm256_sub_pd(_mm256_loadu_pd(a + i), _mm256_loadu_pd(b + i)));
    for (; i < n; i++) o[i] = a[i] - b[i];
}

EXPORT void MulF64(double* a, double* b, double* o, int n) {
    int i = 0;
    for (; i + 4 <= n; i += 4)
        _mm256_storeu_pd(o + i, _mm256_mul_pd(_mm256_loadu_pd(a + i), _mm256_loadu_pd(b + i)));
    for (; i < n; i++) o[i] = a[i] * b[i];
}

EXPORT void ScaleF64(double* a, double s, double* o, int n) {
    __m256d vs = _mm256_set1_pd(s);
    int i = 0;
    for (; i + 4 <= n; i += 4)
        _mm256_storeu_pd(o + i, _mm256_mul_pd(_mm256_loadu_pd(a + i), vs));
    for (; i < n; i++) o[i] = a[i] * s;
}

EXPORT void AxpyF64(double alpha, double* x, double* y, int n) {
    __m256d va = _mm256_set1_pd(alpha);
    int i = 0;
    for (; i + 4 <= n; i += 4)
        _mm256_storeu_pd(y + i, _mm256_fmadd_pd(va, _mm256_loadu_pd(x + i), _mm256_loadu_pd(y + i)));
    for (; i < n; i++) y[i] += alpha * x[i];
}

EXPORT double DotF64(double* a, double* b, int n) {
    __m256d acc = _mm256_setzero_pd();
    int i = 0;
    for (; i + 4 <= n; i += 4)
        acc = _mm256_fmadd_pd(_mm256_loadu_pd(a + i), _mm256_loadu_pd(b + i), acc);
    __m128d lo = _mm256_castpd256_pd128(acc);
    __m128d hi = _mm256_extractf128_pd(acc, 1);
    __m128d s = _mm_add_pd(lo, hi);
    s = _mm_hadd_pd(s, s);
    double r = _mm_cvtsd_f64(s);
    for (; i < n; i++) r += a[i] * b[i];
    return r;
}

EXPORT double SumF64(double* a, int n) {
    __m256d acc = _mm256_setzero_pd();
    int i = 0;
    for (; i + 4 <= n; i += 4) acc = _mm256_add_pd(acc, _mm256_loadu_pd(a + i));
    __m128d lo = _mm256_castpd256_pd128(acc);
    __m128d hi = _mm256_extractf128_pd(acc, 1);
    __m128d s = _mm_add_pd(lo, hi);
    s = _mm_hadd_pd(s, s);
    double r = _mm_cvtsd_f64(s);
    for (; i < n; i++) r += a[i];
    return r;
}

EXPORT double MaxF64(double* a, int n) {
    if (n <= 0) return 0.0;
    __m256d m = _mm256_set1_pd(a[0]);
    int i = 0;
    for (; i + 4 <= n; i += 4) m = _mm256_max_pd(m, _mm256_loadu_pd(a + i));
    __m128d lo = _mm256_castpd256_pd128(m);
    __m128d hi = _mm256_extractf128_pd(m, 1);
    __m128d s = _mm_max_pd(lo, hi);
    s = _mm_max_pd(s, _mm_shuffle_pd(s, s, 1));
    double r = _mm_cvtsd_f64(s);
    for (; i < n; i++) if (a[i] > r) r = a[i];
    return r;
}

/* SGEMM f64: C = A*B, n x n row-major. */
EXPORT void SgemmF64(double* a, double* b, double* o, int n) {
    for (int i = 0; i < n; i++) {
        double* ai = a + (long long)i * n;
        double* oi = o + (long long)i * n;
        int j = 0;
        for (; j + 4 <= n; j += 4) {
            __m256d acc = _mm256_setzero_pd();
            for (int k = 0; k < n; k++) {
                __m256d va = _mm256_set1_pd(ai[k]);
                __m256d vb = _mm256_loadu_pd(b + (long long)k * n + j);
                acc = _mm256_fmadd_pd(va, vb, acc);
            }
            _mm256_storeu_pd(oi + j, acc);
        }
        for (; j < n; j++) {
            double acc = 0.0;
            for (int k = 0; k < n; k++) acc += ai[k] * b[(long long)k * n + j];
            oi[j] = acc;
        }
    }
}

EXPORT double MinF64(double* a, int n) {
    if (n <= 0) return 0.0;
    __m256d m = _mm256_set1_pd(a[0]);
    int i = 0;
    for (; i + 4 <= n; i += 4) m = _mm256_min_pd(m, _mm256_loadu_pd(a + i));
    __m128d lo = _mm256_castpd256_pd128(m);
    __m128d hi = _mm256_extractf128_pd(m, 1);
    __m128d s = _mm_min_pd(lo, hi);
    s = _mm_min_pd(s, _mm_shuffle_pd(s, s, 1));
    double r = _mm_cvtsd_f64(s);
    for (; i < n; i++) if (a[i] < r) r = a[i];
    return r;
}
