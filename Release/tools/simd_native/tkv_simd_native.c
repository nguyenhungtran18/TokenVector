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
#include <string.h>

#define EXPORT __declspec(dllexport)

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1, int j0, int j1);
static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1, int j0, int j1);

/* Tile cache-blocking (co the ghi de bang /DGEMM_* khi build). */
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
#define GEMM_BPL (GEMM_NC + 4)    /* leading dim panel B f32: +4 tranh stride luy thua 2 */
#endif
#ifndef GEMM_KC64
#define GEMM_KC64 64
#endif
#ifndef GEMM_MC64
#define GEMM_MC64 32
#endif
#ifndef GEMM_NC64
#define GEMM_NC64 64
#endif
#ifndef GEMM_BPL64
#define GEMM_BPL64 (GEMM_NC64 + 2) /* leading dim panel B f64: +2 tranh stride luy thua 2 */
#endif

/* So luong thread cho kernel GEMM: 1 neu n nho (tranh overhead), nguoc lai
 * theo so CORE VAT LY (khong dung hyperthread - 2 luong/core tranh nhau bang
 * thong L3 lam GEMM cham di ro ret). Co the ep bang TKV_GEMM_THREADS. */
#define TKV_MAXT 32
static int tkv_min_n = -1;
static int tkv_cap = -1;   /* >0: ep buoc; -1: chua doc env; 0: auto */

/* Dem so core VAT LY (RelationProcessorCore) - tren Windows >= Vista. */
static int tkv_ncores(void) {
    DWORD len = 0;
    if (!GetLogicalProcessorInformationEx(RelationProcessorCore, NULL, &len) || len == 0)
        return 0;
    char* buf = (char*)malloc(len);
    if (!buf) return 0;
    int nc = 0;
    if (GetLogicalProcessorInformationEx(RelationProcessorCore,
            (SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX*)buf, &len)) {
        DWORD off = 0;
        while (off < len) {
            SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX* p =
                (SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX*)(buf + off);
            if (p->Relationship == RelationProcessorCore) nc++;
            if (p->Size == 0) break;
            off += p->Size;
        }
    }
    free(buf);
    return nc;
}

/* So processor LOGICAL (co the gap doi neu co hyperthread). */
static int tkv_nlogical(void) {
    DWORD lc = GetActiveProcessorCount(0xFFFF /* ALL_PROCESSOR_GROUPS */);
    return lc >= 1 ? (int)lc : 1;
}

static int tkv_nthreads(int n) {
    if (tkv_min_n < 0) {
        char buf[32];
        DWORD k = GetEnvironmentVariableA("TKV_GEMM_MIN_N", buf, 32);
        tkv_min_n = (k > 0 && k < 64) ? atoi(buf) : 96;
        k = GetEnvironmentVariableA("TKV_GEMM_THREADS", buf, 32);
        tkv_cap = (k > 0 && k < 64) ? atoi(buf) : 0;   /* 0 = auto */
    }
    if (n < tkv_min_n) return 1;
    int c;
    if (tkv_cap > 0) {
        c = tkv_cap;
    } else {
        int nphys = tkv_ncores();
        if (nphys < 1) {
            int lc = tkv_nlogical();
            nphys = (lc >= 2) ? (lc / 2) : lc;         /* uoc luong HT */
        }
        c = nphys;
        /* n lon (>=512): working-set/thread da nho nho padding panel B -> dung them
         * hyperthread (2x vat ly) cho loi. n nho thi chi core vat ly. */
        if (n >= 512) {
            int lc = tkv_nlogical();
            int ht = nphys * 2;
            if (ht > lc) ht = lc;
            if (ht > nphys) c = ht;
        }
    }
    if (c < 1) c = 1;
    if (c > TKV_MAXT) c = TKV_MAXT;
    if (c > n) c = n;
    return c;
}

static int tkv_cols = -1;   /* so nhom COT chia cho thread (>=1); -1 chua doc env, 0 auto */

static int tkv_ncols(int nt, int n) {
    if (tkv_cols < 0) {
        char buf[32];
        DWORD k = GetEnvironmentVariableA("TKV_GEMM_COLS", buf, 32);
        tkv_cols = (k > 0 && k < 64) ? atoi(buf) : 0;   /* 0 = auto */
    }
    if (tkv_cols > 0) return tkv_cols;
    /* auto: chia 2 chieu khi n du lon va nt chia het (moi thread working-set nho
     * hon -> chiu hyperthread tot hon). */
    if (n >= 512 && nt >= 8 && (nt % 4) == 0 && (n % 4) == 0) return 4;
    if (n >= 512 && nt >= 8 && (nt % 2) == 0 && (n % 2) == 0) return 2;
    return 1;
}

/* --- thread pool co dinh (tranh ~0.6ms tao thread moi lan goi) --- */
typedef struct { const void* a; const void* b; void* o; int n; int i0; int i1; int j0; int j1; int f64; } GemmJob;
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
            gemm_rows_f64((const double*)j->a, (const double*)j->b, (double*)j->o, j->n, j->i0, j->i1, j->j0, j->j1);
        else
            gemm_rows_f32((const float*)j->a, (const float*)j->b, (float*)j->o, j->n, j->i0, j->i1, j->j0, j->j1);
        SetEvent(g_done[t]);
    }
    return 0;
}

static BOOL CALLBACK tkv_pool_init(PINIT_ONCE o, PVOID p, PVOID* c) {
    (void)o; (void)p; (void)c;
    int cap = (tkv_cap > 0) ? tkv_cap : tkv_nlogical();
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
    int align = 8;
    int ncstep = f64 ? GEMM_NC64 : GEMM_NC;

    /* Luoi 2 chieu rows x cols (cols>=1). Chia cot de moi thread chi doc/pack
     * mot dai cot cua B -> giam working-set va bang thong khi chay hyperthread. */
    int cols = tkv_ncols(nt, n);
    if (cols < 1) cols = 1;
    if (cols > nt) cols = nt;
    while (cols > 1 && (nt % cols) != 0) cols--;
    int rows = nt / cols;
    if (rows < 1) { rows = 1; cols = 1; }

    int rper = (n + rows - 1) / rows;
    rper = ((rper + align - 1) / align) * align;
    int cper = (n + cols - 1) / cols;
    cper = ((cper + ncstep - 1) / ncstep) * ncstep;

    int used = 0;
    for (int r = 0; r < rows && used < nt; r++) {
        int i0 = r * rper, i1 = i0 + rper;
        if (i1 > n) i1 = n;
        if (i0 >= i1) continue;
        for (int c = 0; c < cols && used < nt; c++) {
            int j0 = c * cper, j1 = j0 + cper;
            if (j1 > n) j1 = n;
            if (j0 >= j1) continue;
            g_job[used].a = a; g_job[used].b = b; g_job[used].o = o;
            g_job[used].n = n; g_job[used].i0 = i0; g_job[used].i1 = i1;
            g_job[used].j0 = j0; g_job[used].j1 = j1; g_job[used].f64 = f64;
            used++;
        }
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

/* SGEMM C = A*B, A/B/C deu n x n, row-major, C ghi de (duoc goi 1 lan). */
/* Cache blocking: micro-kernel 8x8 + j-block (NC) + k-block (KC), PACK B
 * panel (KC x NC) de no nam trong L1/L2 va duoc tai lai re cho moi i-block.
 * A doc truc tiep theo hang (a[ii*lda+p], lien tuc theo p) -> khong can pack. */
#ifndef GEMM_KC
#define GEMM_KC 64
#endif
#ifndef GEMM_MC
#define GEMM_MC 64
#endif
#ifndef GEMM_NC
#define GEMM_NC 64
#endif

static void pack_b_f32(const float* b, float* bp, int n, int pc, int kc, int jc, int nc) {
    for (int p = 0; p < kc; p++) {
        const float* src = b + (long long)(pc + p) * n + jc;
        float* dst = bp + (long long)p * GEMM_BPL;
        for (int j = 0; j < nc; j++) dst[j] = src[j];
    }
}

/* Micro-kernel 4x16: 4 hang x 16 cot = 8 ymm accumulator + 2 ymm B.
 * Moi vong p: 2 load B + 4 broadcast A + 8 FMA -> FMA-bound (4 chu ky FMA
 * so voi 3 chu ky load) => dat dinh 32 FLOP/cycle/core tren Haswell. */
static void micro_f32(const float* a, int lda, const float* bp, float* c, int n, int mc, int nc, int kc) {
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
                const float* brow = bp + (long long)p * GEMM_BPL + j;
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
        for (; j < nc; j++) {
            float s0 = 0.0f, s1 = 0.0f, s2 = 0.0f, s3 = 0.0f;
            for (int p = 0; p < kc; p++) {
                float bv = bp[(long long)p * GEMM_BPL + j];
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
    for (; i < mc; i++) {
        const float* ai = a + (long long)i * lda;
        float* ci = c + (long long)i * n;
        for (int j = 0; j < nc; j++) {
            float s = 0.0f;
            for (int p = 0; p < kc; p++)
                s += ai[p] * bp[(long long)p * GEMM_BPL + j];
            ci[j] += s;
        }
    }
}

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1, int j0, int j1) {
    if (i1 <= i0 || j1 <= j0) return;
    if (j0 == 0 && j1 == n)
        memset(o + (long long)i0 * n, 0, (size_t)(i1 - i0) * n * sizeof(float));
    else
        for (int ii = i0; ii < i1; ii++)
            memset(o + (long long)ii * n + j0, 0, (size_t)(j1 - j0) * sizeof(float));
    static __declspec(thread) float bp[GEMM_KC * GEMM_BPL];
    for (int jc = j0; jc < j1; jc += GEMM_NC) {
        int nc = j1 - jc; if (nc > GEMM_NC) nc = GEMM_NC;
        for (int pc = 0; pc < n; pc += GEMM_KC) {
            int kc = n - pc; if (kc > GEMM_KC) kc = GEMM_KC;
            pack_b_f32(b, bp, n, pc, kc, jc, nc);
            for (int ic = i0; ic < i1; ic += GEMM_MC) {
                int mc = i1 - ic; if (mc > GEMM_MC) mc = GEMM_MC;
                micro_f32(a + (long long)ic * n + pc, n, bp, o + (long long)ic * n + jc, n, mc, nc, kc);
            }
        }
    }
}

EXPORT void SgemmF32(float* a, float* b, float* o, int n) {
    int nt = tkv_nthreads(n);
    if (nt <= 1) { gemm_rows_f32(a, b, o, n, 0, n, 0, n); return; }
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

/* SGEMM f64: C = A*B, n x n row-major, C ghi de. Cache blocking kieu Goto. */
#ifndef GEMM_KC64
#define GEMM_KC64 64
#endif
#ifndef GEMM_MC64
#define GEMM_MC64 32
#endif
#ifndef GEMM_NC64
#define GEMM_NC64 64
#endif

static void pack_b_f64(const double* b, double* bp, int n, int pc, int kc, int jc, int nc) {
    for (int p = 0; p < kc; p++) {
        const double* src = b + (long long)(pc + p) * n + jc;
        double* dst = bp + (long long)p * GEMM_BPL64;
        for (int j = 0; j < nc; j++) dst[j] = src[j];
    }
}

/* Micro-kernel 4x8: 4 hang x 8 cot = 8 ymm accumulator + 2 ymm B.
 * Moi vong p: 2 load B + 4 broadcast A + 8 FMA -> FMA-bound (4 vs 3 chu ky)
 * => dat dinh 16 FLOP/cycle/core cho f64 tren Haswell. */
static void micro_f64(const double* a, int lda, const double* bp, double* c, int n, int mc, int nc, int kc) {
    int i = 0;
    for (; i + 4 <= mc; i += 4) {
        const double* ai = a + (long long)i * lda;
        double* ci = c + (long long)i * n;
        int j = 0;
        for (; j + 8 <= nc; j += 8) {
            __m256d c0a = _mm256_setzero_pd(), c0b = _mm256_setzero_pd();
            __m256d c1a = _mm256_setzero_pd(), c1b = _mm256_setzero_pd();
            __m256d c2a = _mm256_setzero_pd(), c2b = _mm256_setzero_pd();
            __m256d c3a = _mm256_setzero_pd(), c3b = _mm256_setzero_pd();
            for (int p = 0; p < kc; p++) {
                const double* brow = bp + (long long)p * GEMM_BPL64 + j;
                __m256d vb0 = _mm256_loadu_pd(brow);
                __m256d vb1 = _mm256_loadu_pd(brow + 4);
                __m256d va0 = _mm256_set1_pd(ai[p]);
                __m256d va1 = _mm256_set1_pd(ai[lda + p]);
                __m256d va2 = _mm256_set1_pd(ai[2 * lda + p]);
                __m256d va3 = _mm256_set1_pd(ai[3 * lda + p]);
                c0a = _mm256_fmadd_pd(va0, vb0, c0a);
                c0b = _mm256_fmadd_pd(va0, vb1, c0b);
                c1a = _mm256_fmadd_pd(va1, vb0, c1a);
                c1b = _mm256_fmadd_pd(va1, vb1, c1b);
                c2a = _mm256_fmadd_pd(va2, vb0, c2a);
                c2b = _mm256_fmadd_pd(va2, vb1, c2b);
                c3a = _mm256_fmadd_pd(va3, vb0, c3a);
                c3b = _mm256_fmadd_pd(va3, vb1, c3b);
            }
            double* cj = ci + j;
            _mm256_storeu_pd(cj, _mm256_add_pd(_mm256_loadu_pd(cj), c0a));
            _mm256_storeu_pd(cj + 4, _mm256_add_pd(_mm256_loadu_pd(cj + 4), c0b));
            _mm256_storeu_pd(cj + n, _mm256_add_pd(_mm256_loadu_pd(cj + n), c1a));
            _mm256_storeu_pd(cj + n + 4, _mm256_add_pd(_mm256_loadu_pd(cj + n + 4), c1b));
            _mm256_storeu_pd(cj + 2 * n, _mm256_add_pd(_mm256_loadu_pd(cj + 2 * n), c2a));
            _mm256_storeu_pd(cj + 2 * n + 4, _mm256_add_pd(_mm256_loadu_pd(cj + 2 * n + 4), c2b));
            _mm256_storeu_pd(cj + 3 * n, _mm256_add_pd(_mm256_loadu_pd(cj + 3 * n), c3a));
            _mm256_storeu_pd(cj + 3 * n + 4, _mm256_add_pd(_mm256_loadu_pd(cj + 3 * n + 4), c3b));
        }
        for (; j < nc; j++) {
            double s0 = 0.0, s1 = 0.0, s2 = 0.0, s3 = 0.0;
            for (int p = 0; p < kc; p++) {
                double bv = bp[(long long)p * GEMM_BPL64 + j];
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
    for (; i < mc; i++) {
        const double* ai = a + (long long)i * lda;
        double* ci = c + (long long)i * n;
        for (int j = 0; j < nc; j++) {
            double s = 0.0;
            for (int p = 0; p < kc; p++)
                s += ai[p] * bp[(long long)p * GEMM_BPL64 + j];
            ci[j] += s;
        }
    }
}

static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1, int j0, int j1) {
    if (i1 <= i0 || j1 <= j0) return;
    if (j0 == 0 && j1 == n)
        memset(o + (long long)i0 * n, 0, (size_t)(i1 - i0) * n * sizeof(double));
    else
        for (int ii = i0; ii < i1; ii++)
            memset(o + (long long)ii * n + j0, 0, (size_t)(j1 - j0) * sizeof(double));
    static __declspec(thread) double bp[GEMM_KC64 * GEMM_BPL64];
    for (int jc = j0; jc < j1; jc += GEMM_NC64) {
        int nc = j1 - jc; if (nc > GEMM_NC64) nc = GEMM_NC64;
        for (int pc = 0; pc < n; pc += GEMM_KC64) {
            int kc = n - pc; if (kc > GEMM_KC64) kc = GEMM_KC64;
            pack_b_f64(b, bp, n, pc, kc, jc, nc);
            for (int ic = i0; ic < i1; ic += GEMM_MC64) {
                int mc = i1 - ic; if (mc > GEMM_MC64) mc = GEMM_MC64;
                micro_f64(a + (long long)ic * n + pc, n, bp, o + (long long)ic * n + jc, n, mc, nc, kc);
            }
        }
    }
}

EXPORT void SgemmF64(double* a, double* b, double* o, int n) {
    int nt = tkv_nthreads(n);
    if (nt <= 1) { gemm_rows_f64(a, b, o, n, 0, n, 0, n); return; }
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
