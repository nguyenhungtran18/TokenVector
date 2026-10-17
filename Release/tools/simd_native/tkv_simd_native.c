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
#include <windows.h>
#include <stdlib.h>

#define EXPORT __declspec(dllexport)

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1);
static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1);

/* So luong thread cho kernel GEMM: 1 neu n nho (tranh overhead), nguoc lai
 * theo so logical processor (toi da 16, khong qua n). */
#define TKV_MAXT 16
static int tkv_min_n = -1;
static int tkv_cap = -1;

static int tkv_nthreads(int n) {
    if (tkv_min_n < 0) {
        char buf[32];
        DWORD k = GetEnvironmentVariableA("TKV_GEMM_MIN_N", buf, 32);
        tkv_min_n = (k > 0 && k < 32) ? atoi(buf) : 96;
        k = GetEnvironmentVariableA("TKV_GEMM_THREADS", buf, 32);
        tkv_cap = (k > 0 && k < 32) ? atoi(buf) : TKV_MAXT;
        if (tkv_cap < 1) tkv_cap = 1;
        if (tkv_cap > TKV_MAXT) tkv_cap = TKV_MAXT;
    }
    if (n < tkv_min_n) return 1;
    DWORD c = GetActiveProcessorCount(0xFFFF /* ALL_PROCESSOR_GROUPS */);
    if (c < 1) c = 1;
    if (c > (DWORD)tkv_cap) c = (DWORD)tkv_cap;
    if ((int)c > n) c = (DWORD)n;
    return (int)c;
}

/* --- thread pool co dinh (tranh ~0.6ms tao thread moi lan goi) --- */
typedef struct { const void* a; const void* b; void* o; int n; int i0; int i1; int f64; } GemmJob;
static GemmJob  g_job[TKV_MAXT];
static HANDLE   g_start[TKV_MAXT];
static HANDLE   g_done[TKV_MAXT];
static int      g_nw = 0;
static INIT_ONCE g_once = INIT_ONCE_STATIC_INIT;

static DWORD WINAPI tkv_worker(LPVOID p) {
    int t = (int)(INT_PTR)p;
    for (;;) {
        WaitForSingleObject(g_start[t], INFINITE);
        GemmJob* j = &g_job[t];
        if (j->f64)
            gemm_rows_f64((const double*)j->a, (const double*)j->b, (double*)j->o, j->n, j->i0, j->i1);
        else
            gemm_rows_f32((const float*)j->a, (const float*)j->b, (float*)j->o, j->n, j->i0, j->i1);
        SetEvent(g_done[t]);
    }
    return 0;
}

static BOOL CALLBACK tkv_pool_init(PINIT_ONCE o, PVOID p, PVOID* c) {
    (void)o; (void)p; (void)c;
    int cap = tkv_cap;
    if (cap < 1) cap = TKV_MAXT;
    if (cap > TKV_MAXT) cap = TKV_MAXT;
    for (int t = 0; t < cap; t++) {
        g_start[t] = CreateEventA(NULL, FALSE, FALSE, NULL);
        g_done[t]  = CreateEventA(NULL, FALSE, FALSE, NULL);
        if (g_start[t] && g_done[t])
            CreateThread(NULL, 0, tkv_worker, (LPVOID)(INT_PTR)t, 0, NULL);
    }
    g_nw = cap;
    return TRUE;
}

static void tkv_run_mt(int nt, const void* a, const void* b, void* o, int n, int f64) {
    InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL);
    if (nt > g_nw) nt = g_nw;
    int per = (n + nt - 1) / nt;
    int used = 0;
    for (int t = 0; t < nt; t++) {
        int i0 = t * per, i1 = i0 + per;
        if (i1 > n) i1 = n;
        if (i0 >= i1) break;
        g_job[t].a = a; g_job[t].b = b; g_job[t].o = o;
        g_job[t].n = n; g_job[t].i0 = i0; g_job[t].i1 = i1; g_job[t].f64 = f64;
        used++;
    }
    for (int t = 0; t < used; t++) SetEvent(g_start[t]);
    WaitForMultipleObjects((DWORD)used, g_done, TRUE, INFINITE);
}

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
/* Micro-kernel 8 hang x 8 cot: tai b[k][j..j+7] MOT lan, dung cho 8 hang A.
 * Tang cuong so hoc ~8x so voi row-broadcast (diem nghen cua ban dau). */
static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1) {
    int i = i0;
    for (; i + 8 <= i1; i += 8) {
        const float* a0 = a + (long long)i * n;
        float* o0 = o + (long long)i * n;
        int j = 0;
        for (; j + 8 <= n; j += 8) {
            __m256 c0 = _mm256_setzero_ps(), c1 = _mm256_setzero_ps();
            __m256 c2 = _mm256_setzero_ps(), c3 = _mm256_setzero_ps();
            __m256 c4 = _mm256_setzero_ps(), c5 = _mm256_setzero_ps();
            __m256 c6 = _mm256_setzero_ps(), c7 = _mm256_setzero_ps();
            for (int k = 0; k < n; k++) {
                __m256 vb = _mm256_loadu_ps(b + (long long)k * n + j);
                c0 = _mm256_fmadd_ps(_mm256_set1_ps(a0[k]), vb, c0);
                c1 = _mm256_fmadd_ps(_mm256_set1_ps(a0[n + k]), vb, c1);
                c2 = _mm256_fmadd_ps(_mm256_set1_ps(a0[2 * n + k]), vb, c2);
                c3 = _mm256_fmadd_ps(_mm256_set1_ps(a0[3 * n + k]), vb, c3);
                c4 = _mm256_fmadd_ps(_mm256_set1_ps(a0[4 * n + k]), vb, c4);
                c5 = _mm256_fmadd_ps(_mm256_set1_ps(a0[5 * n + k]), vb, c5);
                c6 = _mm256_fmadd_ps(_mm256_set1_ps(a0[6 * n + k]), vb, c6);
                c7 = _mm256_fmadd_ps(_mm256_set1_ps(a0[7 * n + k]), vb, c7);
            }
            _mm256_storeu_ps(o0 + j, c0);
            _mm256_storeu_ps(o0 + n + j, c1);
            _mm256_storeu_ps(o0 + 2 * n + j, c2);
            _mm256_storeu_ps(o0 + 3 * n + j, c3);
            _mm256_storeu_ps(o0 + 4 * n + j, c4);
            _mm256_storeu_ps(o0 + 5 * n + j, c5);
            _mm256_storeu_ps(o0 + 6 * n + j, c6);
            _mm256_storeu_ps(o0 + 7 * n + j, c7);
        }
        for (; j < n; j++) {
            for (int r = 0; r < 8; r++) {
                float s = 0.0f;
                for (int k = 0; k < n; k++) s += a0[r * n + k] * b[(long long)k * n + j];
                o0[r * n + j] = s;
            }
        }
    }
    for (; i < i1; i++) {
        const float* ai = a + (long long)i * n;
        float* oi = o + (long long)i * n;
        int j = 0;
        for (; j + 8 <= n; j += 8) {
            __m256 acc = _mm256_setzero_ps();
            for (int k = 0; k < n; k++)
                acc = _mm256_fmadd_ps(_mm256_set1_ps(ai[k]), _mm256_loadu_ps(b + (long long)k * n + j), acc);
            _mm256_storeu_ps(oi + j, acc);
        }
        for (; j < n; j++) {
            float acc = 0.0f;
            for (int k = 0; k < n; k++) acc += ai[k] * b[(long long)k * n + j];
            oi[j] = acc;
        }
    }
}

EXPORT void SgemmF32(float* a, float* b, float* o, int n) {
    int nt = tkv_nthreads(n);
    if (nt <= 1) { gemm_rows_f32(a, b, o, n, 0, n); return; }
    tkv_run_mt(nt, a, b, o, n, 0);
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
/* Micro-kernel 4 hang x 4 cot (f64). */
static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1) {
    int i = i0;
    for (; i + 4 <= i1; i += 4) {
        const double* a0 = a + (long long)i * n;
        double* o0 = o + (long long)i * n;
        int j = 0;
        for (; j + 4 <= n; j += 4) {
            __m256d c0 = _mm256_setzero_pd(), c1 = _mm256_setzero_pd();
            __m256d c2 = _mm256_setzero_pd(), c3 = _mm256_setzero_pd();
            for (int k = 0; k < n; k++) {
                __m256d vb = _mm256_loadu_pd(b + (long long)k * n + j);
                c0 = _mm256_fmadd_pd(_mm256_set1_pd(a0[k]), vb, c0);
                c1 = _mm256_fmadd_pd(_mm256_set1_pd(a0[n + k]), vb, c1);
                c2 = _mm256_fmadd_pd(_mm256_set1_pd(a0[2 * n + k]), vb, c2);
                c3 = _mm256_fmadd_pd(_mm256_set1_pd(a0[3 * n + k]), vb, c3);
            }
            _mm256_storeu_pd(o0 + j, c0);
            _mm256_storeu_pd(o0 + n + j, c1);
            _mm256_storeu_pd(o0 + 2 * n + j, c2);
            _mm256_storeu_pd(o0 + 3 * n + j, c3);
        }
        for (; j < n; j++) {
            for (int r = 0; r < 4; r++) {
                double s = 0.0;
                for (int k = 0; k < n; k++) s += a0[r * n + k] * b[(long long)k * n + j];
                o0[r * n + j] = s;
            }
        }
    }
    for (; i < i1; i++) {
        const double* ai = a + (long long)i * n;
        double* oi = o + (long long)i * n;
        int j = 0;
        for (; j + 4 <= n; j += 4) {
            __m256d acc = _mm256_setzero_pd();
            for (int k = 0; k < n; k++)
                acc = _mm256_fmadd_pd(_mm256_set1_pd(ai[k]), _mm256_loadu_pd(b + (long long)k * n + j), acc);
            _mm256_storeu_pd(oi + j, acc);
        }
        for (; j < n; j++) {
            double acc = 0.0;
            for (int k = 0; k < n; k++) acc += ai[k] * b[(long long)k * n + j];
            oi[j] = acc;
        }
    }
}

EXPORT void SgemmF64(double* a, double* b, double* o, int n) {
    int nt = tkv_nthreads(n);
    if (nt <= 1) { gemm_rows_f64(a, b, o, n, 0, n); return; }
    tkv_run_mt(nt, a, b, o, n, 1);
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
