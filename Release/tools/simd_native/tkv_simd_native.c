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
#include <stdint.h>
#include <math.h>

#define EXPORT __declspec(dllexport)

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl);
static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1, int j0, int j1);
static void gemm_rect_f32(const float* a, int lda, const float* b, int ldb, float* o, int ldc,
                          int m, int n, int k, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl);

/* M6 v2 (lmhead) - khai truoc truoc khi dung trong tkv_worker. */
static void lmhead_softmax_rows(const float* logits, const int* ids, float* dl,
                                int V, int t0, int t1, float scale);
static void lmhead_transpose_rows(const float* dl, float* dlT, int V, int T,
                                  int t0, int t1);
static void lmhead_add_rows(float* dst, const float* src, int E, int v0, int v1);

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

/* M7 (SPEC M4-M7 §M7): NC toi da khi phan lop shape chon NC lon (bpl = NC + 4).
 * Buffer thread-local duoc cap theo BPL_MAX nhung duong DEFAULT (NC=64, bpl=68)
 * van dan hang bang GEMM_BPL cu -> khong doi cache behavior cua duong cu. */
#ifndef GEMM_NC_MAX
#define GEMM_NC_MAX 128
#endif
#ifndef GEMM_BPL_MAX
#define GEMM_BPL_MAX (GEMM_NC_MAX + 4)
#endif
#define GEMM_MC_RG 128   /* rect grad: MC/NC rieng (M7) */
#define GEMM_NC_RG 128

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

static void tkv_env_init(void) {
    if (tkv_min_n < 0) {
        char buf[32];
        DWORD k = GetEnvironmentVariableA("TKV_GEMM_MIN_N", buf, 32);
        tkv_min_n = (k > 0 && k < 64) ? atoi(buf) : 96;
        k = GetEnvironmentVariableA("TKV_GEMM_THREADS", buf, 32);
        tkv_cap = (k > 0 && k < 64) ? atoi(buf) : 0;   /* 0 = auto */
    }
}

static int tkv_nthreads(int n) {
    tkv_env_init();
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

/* ---------------- M7: shape-class dispatch (SPEC M4-M7 §M7) ----------------
 * Phan lop theo (m,n,k) de chon (1 luong / cot manh / MC-NC rieng). Chi doi
 * thread + tiling; KC GIU NGUYEN 64 -> thu tu tich luy k moi phan tu khong doi
 * -> numerics bit-giong legacy (gate + A/B stdout chung minh).
 * Env `TKV_GEMM_DISPATCH`: mac dinh/`shape` = phan lop; `legacy` = thu tu cu
 * y hieu (A/B so sanh). Gia tri MC/NC/cols la KHOI TAO - team Inference do lai
 * T-grid sau khi BUILD/ACC ra native (§M7) roi ghi vao bang ban giao.
 *   nho (m nhoac n nhoac k < MIN_N, mac dinh 96) -> 1 luong
 *   square lon      -> pattern hien tai (tkv_nthreads + tkv_ncols)
 *   vocab 50257     -> chia cot manh + NC 128 (giam traffic doc A/B)
 *   rect (max(C) >= 4*min(C)) -> MC/NC rieng 128/128 */
#define TKV_VOCAB 50257
#define TKV_CLS_SMALL 0
#define TKV_CLS_SQUARE 1
#define TKV_CLS_VOCAB 2
#define TKV_CLS_RECT 3
static int tkv_dispatch = -1;   /* -1 chua doc env; 1 = shape (mac dinh); 0 = legacy */

static int tkv_shape_on(void) {
    if (tkv_dispatch < 0) {
        char buf[32];
        DWORD k = GetEnvironmentVariableA("TKV_GEMM_DISPATCH", buf, 32);
        tkv_dispatch = (k > 0 && (buf[0] == 'l' || buf[0] == 'L')) ? 0 : 1;
    }
    return tkv_dispatch;
}

static int tkv_shape_class(int m, int n, int k) {
    tkv_env_init();
    if (m < tkv_min_n || n < tkv_min_n || k < tkv_min_n) return TKV_CLS_SMALL;
    if (m == TKV_VOCAB || n == TKV_VOCAB || k == TKV_VOCAB) return TKV_CLS_VOCAB;
    {
        int mx = m > n ? m : n;
        int mn = m < n ? m : n;
        if (mx >= 4 * mn) return TKV_CLS_RECT;
    }
    return TKV_CLS_SQUARE;
}

/* Cot manh cho VOCAB: uoc so LON nhat cua nt (toi da 16) de moi strip van du
 * rong (n/d >= 8); run_mt_rect dung rows = nt/cols nen chia het la tot nhat. */
static int tkv_ncols_vocab(int nt, int n) {
    int d;
    for (d = 16; d > 1; d--) {
        if ((nt % d) == 0 && d <= n && (n / d) >= 8) return d;
    }
    return 1;
}

/* --- thread pool co dinh (tranh ~0.6ms tao thread moi lan goi) --- */
typedef struct { const void* a; const void* b; void* o; int n; int i0; int i1; int j0; int j1; int mode; int lda; int ldb; int m; int k; int mc; int nc; int bpl; float alpha; } GemmJob;
static GemmJob  g_job[TKV_MAXT];
static HANDLE   g_start[TKV_MAXT];
static HANDLE   g_done[TKV_MAXT];
static int      g_nw = 0;
static INIT_ONCE g_once = INIT_ONCE_STATIC_INIT;
/* SRWLOCK serialize entry point cua pool (spec M4-M7 §3.1): truoc day g_job
 * toan cuc KHONG khoa -> 2 thread goi simd_gemm dong thoi = race dispatcher,
 * bieu hien deadlock/hang > 90s. Mot lock quanh submit+wait la du. */
static SRWLOCK g_gemm_lock = SRWLOCK_INIT;

static DWORD WINAPI tkv_worker(LPVOID p) {
    int t = (int)(INT_PTR)p;
    for (;;) {
        WaitForSingleObject(g_start[t], INFINITE);
        GemmJob* j = &g_job[t];
        if (j->mode == 2)
            gemm_rect_f32((const float*)j->a, j->lda, (const float*)j->b, j->ldb,
                          (float*)j->o, j->n, j->m, j->n, j->k, j->i0, j->i1, j->j0, j->j1,
                          j->mc, j->nc, j->bpl);
        else if (j->mode == 1)
            gemm_rows_f64((const double*)j->a, (const double*)j->b, (double*)j->o, j->n, j->i0, j->i1, j->j0, j->j1);
        else if (j->mode == 3)
            lmhead_softmax_rows((const float*)j->a, (const int*)j->b, (float*)j->o,
                                j->n, j->i0, j->i1, j->alpha);
        else if (j->mode == 4)
            lmhead_transpose_rows((const float*)j->a, (float*)j->o, j->n, j->m,
                                  j->i0, j->i1);
        else if (j->mode == 5)
            lmhead_add_rows((float*)j->o, (const float*)j->a, j->n, j->i0, j->i1);
        else
            gemm_rows_f32((const float*)j->a, (const float*)j->b, (float*)j->o, j->n, j->i0, j->i1, j->j0, j->j1,
                          j->mc, j->nc, j->bpl);
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

static void tkv_run_mt(int nt, const void* a, const void* b, void* o, int n, int f64,
                       int cols_req, int mc, int nc, int bpl) {
    AcquireSRWLockExclusive(&g_gemm_lock);
    InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL);
    if (nt > g_nw) nt = g_nw;
    int align = 8;
    int ncstep = f64 ? GEMM_NC64 : GEMM_NC;

    /* Luoi 2 chieu rows x cols (cols>=1). Chia cot de moi thread chi doc/pack
     * mot dai cot cua B -> giam working-set va bang thong khi chay hyperthread.
     * cols_req > 0 (M7 lop VOCAB) thay quy tac tu dong tkv_ncols. */
    int cols = (cols_req > 0) ? cols_req : tkv_ncols(nt, n);
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
            g_job[used].j0 = j0; g_job[used].j1 = j1; g_job[used].mode = f64;
            g_job[used].mc = mc; g_job[used].nc = nc; g_job[used].bpl = bpl;
            used++;
        }
    }
    for (int t = 0; t < used; t++) SetEvent(g_start[t]);
    if (used > 0) WaitForMultipleObjects((DWORD)used, g_done, TRUE, INFINITE);
    ReleaseSRWLockExclusive(&g_gemm_lock);
}

/* Rect submit - luoi 2D rows x cols (M7; cols=1 = pattern cu chi chia theo
 * hang), dung cung pool + cung lock. Moi job tinh vung [i0,i1)x[j0,j1) rieng
 * -> memset + ghi C khong trung; thu tu tich luy k giu nguyen -> bit-giong. */
static void tkv_run_mt_rect(int nt, const float* a, int lda, const float* b, int ldb,
                            float* c, int ldc, int m, int n, int k,
                            int cols_req, int mc, int nc, int bpl) {
    AcquireSRWLockExclusive(&g_gemm_lock);
    InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL);
    if (nt > g_nw) nt = g_nw;
    if (nt < 1) nt = 1;
    int cols = cols_req;
    if (cols < 1) cols = 1;
    if (cols > nt) cols = nt;
    if (cols > n) cols = n;
    int rows = nt / cols;
    if (rows < 1) { rows = 1; cols = 1; }
    int per_i = (m + rows - 1) / rows;
    int per_j = (n + cols - 1) / cols;
    if (per_i < 1) per_i = 1;
    if (per_j < 1) per_j = 1;
    int used = 0;
    for (int r = 0; r < rows && used < nt; r++) {
        int i0 = r * per_i, i1 = i0 + per_i;
        if (i1 > m) i1 = m;
        if (i0 >= i1) continue;
        for (int cc = 0; cc < cols && used < nt; cc++) {
            int j0 = cc * per_j, j1 = j0 + per_j;
            if (j1 > n) j1 = n;
            if (j0 >= j1) continue;
            g_job[used].a = a; g_job[used].b = b; g_job[used].o = c;
            g_job[used].mode = 2;
            g_job[used].lda = lda; g_job[used].ldb = ldb;
            g_job[used].n = ldc; g_job[used].m = m; g_job[used].k = k;
            g_job[used].i0 = i0; g_job[used].i1 = i1;
            g_job[used].j0 = j0; g_job[used].j1 = j1;
            g_job[used].mc = mc; g_job[used].nc = nc; g_job[used].bpl = bpl;
            used++;
        }
    }
    for (int t = 0; t < used; t++) SetEvent(g_start[t]);
    if (used > 0) WaitForMultipleObjects((DWORD)used, g_done, TRUE, INFINITE);
    ReleaseSRWLockExclusive(&g_gemm_lock);
}

/* Aux submit (M6 v2): chia `count` phan tu thanh nt job bien doc rieng (khong
 * trung) - dung cung pool + cung lock giong run_mt. mode 3 = softmax->dl,
 * 4 = transpose dl->dlT, 5 = dwte += tmp. n = V (mode 3/4) hoac E (mode 5),
 * m = T (mode 4), alpha = scale (mode 3). */
static void tkv_run_aux(int nt, int mode, const void* a, const void* b, void* o,
                        int n, int m, float alpha, long long count) {
    AcquireSRWLockExclusive(&g_gemm_lock);
    InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL);
    if (nt > g_nw) nt = g_nw;
    if (nt < 1) nt = 1;
    long long per = (count + nt - 1) / nt;
    int used = 0;
    for (int t = 0; t < nt; t++) {
        long long i0 = (long long)t * per;
        if (i0 >= count) break;
        long long i1 = i0 + per;
        if (i1 > count) i1 = count;
        g_job[used].a = a; g_job[used].b = b; g_job[used].o = o;
        g_job[used].mode = mode; g_job[used].n = n; g_job[used].m = m;
        g_job[used].alpha = alpha;
        g_job[used].i0 = (int)i0; g_job[used].i1 = (int)i1;
        used++;
    }
    for (int t = 0; t < used; t++) SetEvent(g_start[t]);
    if (used > 0) WaitForMultipleObjects((DWORD)used, g_done, TRUE, INFINITE);
    ReleaseSRWLockExclusive(&g_gemm_lock);
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

static void pack_b_f32(const float* b, float* bp, int n, int pc, int kc, int jc, int nc, int bpl) {
    for (int p = 0; p < kc; p++) {
        const float* src = b + (long long)(pc + p) * n + jc;
        float* dst = bp + (long long)p * bpl;
        for (int j = 0; j < nc; j++) dst[j] = src[j];
    }
}

/* Micro-kernel 4x16: 4 hang x 16 cot = 8 ymm accumulator + 2 ymm B.
 * Moi vong p: 2 load B + 4 broadcast A + 8 FMA -> FMA-bound (4 chu ky FMA
 * so voi 3 chu ky load) => dat dinh 32 FLOP/cycle/core tren Haswell. */
static void micro_f32(const float* a, int lda, const float* bp, float* c, int n, int mc, int nc, int kc, int bpl) {
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
        for (; j < nc; j++) {
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
    for (; i < mc; i++) {
        const float* ai = a + (long long)i * lda;
        float* ci = c + (long long)i * n;
        for (int j = 0; j < nc; j++) {
            float s = 0.0f;
            for (int p = 0; p < kc; p++)
                s += ai[p] * bp[(long long)p * bpl + j];  /* M7 fix: i-tail phai dung bpl nhu duong chinh - dung GEMM_BPL khi bpl=132 (VOCAB/RECT) la doc nham panel -> C sai (vocab_C_bang_A 883.0) */
            ci[j] += s;
        }
    }
}

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl) {
    if (i1 <= i0 || j1 <= j0) return;
    if (j0 == 0 && j1 == n)
        memset(o + (long long)i0 * n, 0, (size_t)(i1 - i0) * n * sizeof(float));
    else
        for (int ii = i0; ii < i1; ii++)
            memset(o + (long long)ii * n + j0, 0, (size_t)(j1 - j0) * sizeof(float));
    static __declspec(thread) float bp[GEMM_KC * GEMM_BPL_MAX];
    /* bao ve buffer (M7): bpl trong [GEMM_BPL, GEMM_BPL_MAX], nc <= bpl - 4 */
    if (bpl < GEMM_BPL) bpl = GEMM_BPL;
    if (bpl > GEMM_BPL_MAX) bpl = GEMM_BPL_MAX;
    if (nc_b > bpl - 4) nc_b = bpl - 4;
    if (nc_b < 1) nc_b = 1;
    if (mc_b < 1) mc_b = 1;
    for (int jc = j0; jc < j1; jc += nc_b) {
        int nc = j1 - jc; if (nc > nc_b) nc = nc_b;
        for (int pc = 0; pc < n; pc += GEMM_KC) {
            int kc = n - pc; if (kc > GEMM_KC) kc = GEMM_KC;
            pack_b_f32(b, bp, n, pc, kc, jc, nc, bpl);
            for (int ic = i0; ic < i1; ic += mc_b) {
                int mc = i1 - ic; if (mc > mc_b) mc = mc_b;
                micro_f32(a + (long long)ic * n + pc, n, bp, o + (long long)ic * n + jc, n, mc, nc, kc, bpl);
            }
        }
    }
}

/* Rectangular SGEMM: C[i0:i1][j0:j1] = A * B, A m x k (lda), B k x n (ldb),
 * C m x n (ldc). dung lai micro_f32 + pack_b_f32 da co (chi doi leading dim).
 * C duoc ghi de (zero + accumulate) trong vung [i0:i1)x[j0:j1). */
static void gemm_rect_f32(const float* a, int lda, const float* b, int ldb, float* o, int ldc,
                          int m, int n, int k, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl) {
    if (i1 <= i0 || j1 <= j0) return;
    for (int ii = i0; ii < i1; ii++)
        memset(o + (long long)ii * ldc + j0, 0, (size_t)(j1 - j0) * sizeof(float));
    static __declspec(thread) float bp[GEMM_KC * GEMM_BPL_MAX];
    /* bao ve buffer (M7): bpl trong [GEMM_BPL, GEMM_BPL_MAX], nc <= bpl - 4 */
    if (bpl < GEMM_BPL) bpl = GEMM_BPL;
    if (bpl > GEMM_BPL_MAX) bpl = GEMM_BPL_MAX;
    if (nc_b > bpl - 4) nc_b = bpl - 4;
    if (nc_b < 1) nc_b = 1;
    if (mc_b < 1) mc_b = 1;
    for (int jc = j0; jc < j1; jc += nc_b) {
        int nc = j1 - jc; if (nc > nc_b) nc = nc_b;
        for (int pc = 0; pc < k; pc += GEMM_KC) {
            int kc = k - pc; if (kc > GEMM_KC) kc = GEMM_KC;
            pack_b_f32(b, bp, ldb, pc, kc, jc, nc, bpl);
            for (int ic = i0; ic < i1; ic += mc_b) {
                int mc = i1 - ic; if (mc > mc_b) mc = mc_b;
                micro_f32(a + (long long)ic * lda + pc, lda, bp,
                          o + (long long)ic * ldc + jc, ldc, mc, nc, kc, bpl);
            }
        }
    }
    (void)m;
}

EXPORT void SgemmF32(float* a, float* b, float* o, int n) {
    /* M7: lop VOCAB (n == 50257) chia cot manh + NC lon; con lai pattern cu.
     * nho (< MIN_N mac dinh 96) da tro thanh nt = 1 trong tkv_nthreads. */
    int nt = tkv_nthreads(n);
    int nc = GEMM_NC, bpl = GEMM_BPL, cols_req = -1;
    if (tkv_shape_on() && n == TKV_VOCAB) {
        nc = GEMM_NC_RG;
        bpl = GEMM_BPL_MAX;
        if (nt > 1) cols_req = tkv_ncols_vocab(nt, n);
    }
    if (nt <= 1) { gemm_rows_f32(a, b, o, n, 0, n, 0, n, GEMM_MC, nc, bpl); return; }
    tkv_run_mt(nt, a, b, o, n, 0, cols_req, GEMM_MC, nc, bpl);
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
    tkv_run_mt(nt, a, b, o, n, 1, -1, GEMM_MC, GEMM_NC, GEMM_BPL);
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

/* ---------------- M4: packed GEMM (prepack 1 lan / step) ----------------
 * Handle do DLL quan ly, lifetime do .tkv giu (free tra 0, khong GC - giong
 * free_bytes). create() copy + pad ve T, zero-fill; run() nhan tile tu pack;
 * free() giai phong. Moi handle luu shape logics (sau trans) + leading dim. */
#define TKV_PACKED_MAGIC 0x504D3031u

typedef struct {
    unsigned int magic;
    int m;      /* so hang logics (sau trans) */
    int n;      /* so cot logics (sau trans) */
    int ld;     /* leading dim cua buffer = roundup(n, T) */
    int T;
    float* buf; /* padded mpad x ld, zero-filled */
} PackedMat;

/* src goc la rows x cols, row stride `stride`. trans=1 -> luu ban transpose
 * (logical shape cols x rows). Tra ve handle > 0, hoac 0 neu tham so sai. */
static long long packed_create(const float* srcf, const double* srcd, int src_len, int rows, int cols,
                               int stride, int T, int trans) {
    if ((!srcf && !srcd) || rows <= 0 || cols <= 0 || T <= 0 || stride < cols) return 0;
    if (trans != 0 && trans != 1) return 0;
    if (src_len < (int)((long long)(rows - 1) * stride + cols)) return 0;
    int m = trans ? cols : rows;
    int n = trans ? rows : cols;
    int ld = ((n + T - 1) / T) * T;
    int mpad = ((m + T - 1) / T) * T;
    float* buf = (float*)calloc((size_t)mpad * (size_t)ld, sizeof(float));
    if (!buf) return 0;
    if (!trans) {
        for (int i = 0; i < rows; i++) {
            float* d = buf + (long long)i * ld;
            if (srcd) {
                const double* s = srcd + (long long)i * stride;
                for (int j = 0; j < cols; j++) d[j] = (float)s[j];   /* convert f64->f32 TRONG pack */
            } else {
                const float* s = srcf + (long long)i * stride;
                for (int j = 0; j < cols; j++) d[j] = s[j];
            }
        }
    } else {
        /* M[i][j] = src[j*stride + i], i in [0,cols), j in [0,rows) */
        for (int j = 0; j < rows; j++) {
            if (srcd) {
                const double* s = srcd + (long long)j * stride;
                for (int i = 0; i < cols; i++)
                    buf[(long long)i * ld + j] = (float)s[i];
            } else {
                const float* s = srcf + (long long)j * stride;
                for (int i = 0; i < cols; i++)
                    buf[(long long)i * ld + j] = s[i];
            }
        }
    }
    PackedMat* h = (PackedMat*)malloc(sizeof(PackedMat));
    if (!h) { free(buf); return 0; }
    h->magic = TKV_PACKED_MAGIC;
    h->m = m; h->n = n; h->ld = ld; h->T = T; h->buf = buf;
    return (long long)(intptr_t)h;
}

EXPORT long long SgemmPackedCreate(const float* src, int src_len, int rows, int cols,
                                   int stride, int T, int trans) {
    return packed_create(src, NULL, src_len, rows, cols, stride, T, trans);
}

/* M4 ABI f64 (SPEC §6 ask 1): Tensor production la List[Double] - pack truc tiep
 * tu double, khong qua convert interpreted (CJ do: 343ms/38M an het gain CY). */
EXPORT long long SgemmPackedCreate64(const double* src, int src_len, int rows, int cols,
                                     int stride, int T, int trans) {
    return packed_create(NULL, src, src_len, rows, cols, stride, T, trans);
}

/* Kiem tra 2 handle + T: -1 magic, -2 T khong khop, -3 inner dim, -4 shape am. */
static int packed_check(long long hA, long long hB, int T, PackedMat** pa, PackedMat** pb) {
    PackedMat* A = (PackedMat*)(intptr_t)hA;
    PackedMat* B = (PackedMat*)(intptr_t)hB;
    if (!A || !B || A->magic != TKV_PACKED_MAGIC || B->magic != TKV_PACKED_MAGIC) return -1;
    if (T <= 0 || A->T != T || B->T != T) return -2;
    if (A->n != B->m) return -3;
    if (A->m <= 0 || B->n <= 0 || A->n <= 0) return -4;
    *pa = A;
    *pb = B;
    return 0;
}

/* GEMM chu nhat co shape-dispatch M7 (env TKV_GEMM_DISPATCH; legacy = thu tu cu
 * y hieu): SMALL -> 1 luong; VOCAB -> cot manh + NC 128; RECT -> MC/NC 128/128;
 * SQUARE -> pattern hien tai. KC khong doi -> thu tu tich luy k giu nguyen ->
 * bit-giong. Dung CHUNG cho packed (M4) va lmhead v2 (M6). */
static void run_rect_shaped(const float* a, int lda, const float* b, int ldb,
                            float* c, int ldc, int m, int n, int k) {
    int mc = GEMM_MC, nc = GEMM_NC, cols_req = 1, bpl = GEMM_BPL;
    int nt;
    if (tkv_shape_on()) {
        int cls = tkv_shape_class(m, n, k);
        if (cls == TKV_CLS_SMALL) {
            nt = 1;
        } else {
            nt = tkv_nthreads(m > n ? m : n);
            if (cls == TKV_CLS_VOCAB) {
                if (nt > 1) cols_req = tkv_ncols_vocab(nt, n);
                nc = GEMM_NC_RG;
                bpl = GEMM_BPL_MAX;
            } else if (cls == TKV_CLS_RECT) {
                mc = GEMM_MC_RG;
                nc = GEMM_NC_RG;
                bpl = GEMM_BPL_MAX;
            }
        }
    } else {
        nt = tkv_nthreads(m > n ? m : n);
    }
    if (nt <= 1)
        gemm_rect_f32(a, lda, b, ldb, c, ldc, m, n, k, 0, m, 0, n, mc, nc, bpl);
    else
        tkv_run_mt_rect(nt, a, lda, b, ldb, c, ldc, m, n, k, cols_req, mc, nc, bpl);
}

/* Nhanh chinh packed: A/B + c (m*n f32) da valid. */
static void packed_core(PackedMat* A, PackedMat* B, float* c) {
    run_rect_shaped(A->buf, A->ld, B->buf, B->ld, c, B->n, A->m, B->n, A->n);
}

/* C = A * B tu 2 handle. Tra ve 0 = OK, am = loi ro (khong im lang):
 * -1 handle sai/sai magic, -2 T khong khop handle, -3 inner dim khong khop,
 * -4 shape am, -5 C qua ngai, -6 khong du bo nho tam (ban f64). */
EXPORT int SgemmPacked(long long hA, long long hB, float* c, int c_len, int T) {
    PackedMat* A = NULL;
    PackedMat* B = NULL;
    int rc = packed_check(hA, hB, T, &A, &B);
    if (rc != 0) return rc;
    if (!c || c_len < (int)((long long)A->m * B->n)) return -5;
    packed_core(A, B, c);
    return 0;
}

/* M4 ABI f64 (SPEC §6 ask 1): C = A*B ghi ra double. Kernel van tinh f32 (buf
 * pack la float) -> chuyen 1 lan cuoi: bit-giong duong f32, thu tu tich luy khong doi. */
EXPORT int SgemmPacked64(long long hA, long long hB, double* c, int c_len, int T) {
    PackedMat* A = NULL;
    PackedMat* B = NULL;
    int rc = packed_check(hA, hB, T, &A, &B);
    if (rc != 0) return rc;
    long long nn = (long long)A->m * (long long)B->n;
    if (!c || c_len < (int)nn) return -5;
    float* tmp = (float*)malloc((size_t)nn * sizeof(float));
    if (!tmp) return -6;
    packed_core(A, B, tmp);
    for (long long i = 0; i < nn; i++) c[i] = tmp[i];
    free(tmp);
    return 0;
}

EXPORT long long SgemmPackedFree(long long h) {
    PackedMat* p = (PackedMat*)(intptr_t)h;
    if (p && p->magic == TKV_PACKED_MAGIC) {
        p->magic = 0;
        free(p->buf);
        p->buf = NULL;
        free(p);
    }
    return 0;
}

/* ---------------- M5: buffer f32 native + fused AdamW/elementwise ------------
 * SPEC M4-M7 §M5. Bo dem = vung nho native da co (alloc_bytes + f32buf_wrap) -
 * KHONG container moi, KHONG boxing. Day chi them kernel tren con tro i64.
 * Moi entry MOT diem (§3.1); cac kernel nay 1 luong (no memory-bound/ptu) va
 * .tkv khong duoc goi 2 cung luc. Numerics: fp32, thu tu co dinh, 1 chia/ptu,
 * sqrt PSD chinh xac (KHONG rsqrt) de khop trainer_tests 15/15 + loss exact.
 */

/* f32_zero(p, n) -> i64: memset 0 = zero_grad, xu ly vung AllocHGlobal chua
 * khoi tao. Tra ve 0 (mau free_bytes/alloc_bytes). */
EXPORT long long F32Zero(float* p, int n) {
    if (!p || n <= 0) return 0;
    memset(p, 0, (size_t)n * sizeof(float));
    return 0;
}

/* f32_copy_to_buf(src, src_len, p, n) -> i64: memcpy mang/list -> buffer native.
 * Tra ve n da copy, -1 neu tham so sai (src qua ngan). */
EXPORT long long F32CopyTo(const float* src, int src_len, float* p, int n) {
    if (!src || !p || n <= 0 || src_len < n) return -1;
    memcpy(p, src, (size_t)n * sizeof(float));
    return n;
}

/* f32_copy_from_buf(p, n, dst, dst_len) -> i64: memcpy native -> mang/list
 * (ghi thang vao `_items`). Tra ve n da copy, -1 neu tham so sai. */
EXPORT long long F32CopyFrom(const float* p, int n, float* dst, int dst_len) {
    if (!p || !dst || n <= 0 || dst_len < n) return -1;
    memcpy(dst, p, (size_t)n * sizeof(float));
    return n;
}

/* f32_addcmul(dst, x, y, scale, n) -> i32: dst += scale * x * y (fused, 1 pass).
 * Tra ve 0 = OK, -1 tham so sai. */
EXPORT int F32Addcmul(float* dst, const float* x, const float* y, float scale, int n) {
    if (!dst || !x || !y || n <= 0) return -1;
    __m256 vs = _mm256_set1_ps(scale);
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 vx = _mm256_loadu_ps(x + i);
        __m256 vy = _mm256_loadu_ps(y + i);
        __m256 vd = _mm256_loadu_ps(dst + i);
        vd = _mm256_fmadd_ps(_mm256_mul_ps(vx, vy), vs, vd);
        _mm256_storeu_ps(dst + i, vd);
    }
    for (; i < n; i++) dst[i] += scale * x[i] * y[i];
    return 0;
}

/* adamw_step(p, m, v, g, n, lr, b1, b2, eps, wd, bc1s, bc2s) -> i32
 * Fused AdamW per-element DUNG cong thuc GĐ10 (spec §M5):
 *   m <- b1*m + (1-b1)*g
 *   v <- b2*v + (1-b2)*g^2
 *   p <- p - lr*(m*bc2s)/(sqrt(v)+eps*bc2s) - lr*wd*p
 * fp32, 1 chia/ptu, thu tu co dinh, sqrt PSD (khong rsqrt). bc1s truyen vao
 * theo ABI nhung cong thuc spec p-update dung bc2s - giu cho team Inference
 * giu nguyen dinh nghia bias-correction (cua so confirm het Phase 2).
 * Tra ve 0 = OK, -1 tham so sai. */
EXPORT int AdamwStepF32(float* p, float* m, float* v, const float* g, int n,
                        float lr, float b1, float b2, float eps, float wd,
                        float bc1s, float bc2s) {
    (void)bc1s;
    if (!p || !m || !v || !g || n <= 0) return -1;
    float one_mb1 = 1.0f - b1;
    float one_mb2 = 1.0f - b2;
    float lr_wd = lr * wd;
    float eps_bc2s = eps * bc2s;
    __m256 vb1 = _mm256_set1_ps(b1);
    __m256 vomb1 = _mm256_set1_ps(one_mb1);
    __m256 vb2 = _mm256_set1_ps(b2);
    __m256 vomb2 = _mm256_set1_ps(one_mb2);
    __m256 vlr = _mm256_set1_ps(lr);
    __m256 vbc2s = _mm256_set1_ps(bc2s);
    __m256 vepsbc = _mm256_set1_ps(eps_bc2s);
    __m256 vlrwd = _mm256_set1_ps(lr_wd);
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 vg = _mm256_loadu_ps(g + i);
        __m256 vm = _mm256_loadu_ps(m + i);
        __m256 vv = _mm256_loadu_ps(v + i);
        __m256 vp = _mm256_loadu_ps(p + i);
        /* m <- b1*m + (1-b1)*g */
        vm = _mm256_fmadd_ps(vomb1, vg, _mm256_mul_ps(vb1, vm));
        /* v <- b2*v + (1-b2)*g*g */
        vv = _mm256_fmadd_ps(vomb2, _mm256_mul_ps(vg, vg), _mm256_mul_ps(vb2, vv));
        _mm256_storeu_ps(m + i, vm);
        _mm256_storeu_ps(v + i, vv);
        /* p <- p - lr*(m*bc2s)/(sqrt(v)+eps*bc2s) - lr*wd*p */
        __m256 num = _mm256_mul_ps(vlr, _mm256_mul_ps(vm, vbc2s));
        __m256 den = _mm256_add_ps(_mm256_sqrt_ps(vv), vepsbc);
        __m256 upd = _mm256_div_ps(num, den);
        __m256 decay = _mm256_mul_ps(vlrwd, vp);   /* dung p CU */
        vp = _mm256_sub_ps(vp, _mm256_add_ps(upd, decay));
        _mm256_storeu_ps(p + i, vp);
    }
    for (; i < n; i++) {
        float gi = g[i];
        float mi = b1 * m[i] + one_mb1 * gi;
        float vi = b2 * v[i] + one_mb2 * gi * gi;
        m[i] = mi;
        v[i] = vi;
        /* ca 2 lan `p[i]` o RHS deu la p CU (gan sau khi tinh xong RHS) */
        p[i] = p[i] - lr * (mi * bc2s) / (sqrtf(vi) + eps_bc2s) - lr_wd * p[i];
    }
    return 0;
}

/* ---------------- M6: fused lm-head backward (SPEC M4-M7 §M6) --------------
 * lmhead_bwd_fused: doc logits + ids -> softmax-grad (fp32, max-sub, giam tu
 * tu v=0..V-1) -> dxf = dlogits @ wte -> tich luy dwte += dlogits^T @ xf.
 * Goi mong loai bo merge serial 1.33s (probe AV).
 *
 * shapes (T = B*S, row-major f32):
 *   logits: (T x V)  [input, KHONG doi]
 *   ids:    (T) i32  [input, id dich moi vi tri]
 *   wte:    (V x E)  [input, trong so lm-head (linked)]
 *   xf:     (T x E)  [input, dac trung]
 *   dxf:    (T x E)  [OUTPUT, ghi de]
 *   dwte:   (V x E)  [OUTPUT, TICH LUY += - goi phai zero truoc]
 *
 * v2 (2026-10-25, doi chieu so do v1 = 38.6s): 5 pha, dung thread pool +
 * GEMM blocked da co (run_rect_shaped):
 *   1. softmax-grad song song theo t -> scratch dl (T x V)   [pool mode 3]
 *   2. dxf = dl @ wte        -> run_rect_shaped (blocked/threaded, ghi de)
 *   3. dlT = transpose(dl)   -> theo o tile 64 cot           [pool mode 4]
 *   4. tmp = dlT @ xf        -> run_rect_shaped
 *   5. dwte += tmp           -> AVX2                          [pool mode 5]
 * v1 single-thread bi memory-bound: moi t re-read toan wte + RMW toan dwte
 * (~630 GB) -> 38.6s. v2 moi buffer chi doc/ghi 1 lan + GEMM blocked.
 * Scratch tam: dl + dlT (2 x T*V*4) + tmp (V*E*4), free ngay trong loi
 * (peak dl+dlT ≈ 412 MB voi T=1024 V=50257).
 * Numerics: cong thuc dl (p-onehot)*scale va thu tu tich luy k tang dan (KC=64)
 * giu nguyen -> test scalar ref tol 1e-5 van ghim; A/B shape vs legacy bit-giong.
 * Tra ve 0 = OK, -1 tham so sai, -6 khong du bo nho tam. */
static void lmhead_softmax_rows(const float* logits, const int* ids, float* dl,
                                int V, int t0, int t1, float scale) {
    for (int t = t0; t < t1; t++) {
        const float* lg = logits + (long long)t * V;
        int id = ids[t];
        int v;
        float m = lg[0];
        for (v = 1; v < V; v++) if (lg[v] > m) m = lg[v];
        float sumexp = 0.0f;
        for (v = 0; v < V; v++) sumexp += expf(lg[v] - m);
        float* d = dl + (long long)t * V;
        for (v = 0; v < V; v++) {
            float p = expf(lg[v] - m) / sumexp;   /* softmax (max-sub -> sumexp >= 1) */
            float g = p;
            if (v == id) g -= 1.0f;               /* p - onehot */
            d[v] = g * scale;                     /* hop dong (p - onehot)/n, n = 1/scale */
        }
    }
}

static void lmhead_transpose_rows(const float* dl, float* dlT, int V, int T,
                                  int t0, int t1) {
    /* Tile theo 64 cot ngoai, t cua job noi: doc dl[t][vv:ve] lien tuc va
     * ghi dlT[v][t0:t1] lien tuc -> ca hai huong deu cache-friendly. */
    for (int vv = 0; vv < V; vv += 64) {
        int ve = vv + 64;
        if (ve > V) ve = V;
        for (int t = t0; t < t1; t++) {
            const float* s = dl + (long long)t * V + vv;
            for (int v = vv; v < ve; v++)
                dlT[(long long)v * T + t] = s[v - vv];
        }
    }
}

static void lmhead_add_rows(float* dst, const float* src, int E, int v0, int v1) {
    for (int v = v0; v < v1; v++) {
        float* d = dst + (long long)v * E;
        const float* s = src + (long long)v * E;
        int e = 0;
        for (; e + 8 <= E; e += 8) {
            _mm256_storeu_ps(d + e, _mm256_add_ps(_mm256_loadu_ps(d + e),
                                                  _mm256_loadu_ps(s + e)));
        }
        for (; e < E; e++) d[e] += s[e];
    }
}

EXPORT int lmhead_bwd_fused(const float* logits, const int* ids, const float* wte,
                            const float* xf, float* dxf, float* dwte,
                            int B, int S, int E, int V, float scale) {
    if (!logits || !ids || !wte || !xf || !dxf || !dwte) return -1;
    if (B <= 0 || S <= 0 || E <= 0 || V <= 0) return -1;
    long long Tll = (long long)B * (long long)S;
    if (Tll <= 0 || Tll > 2000000000LL) return -1;
    int T = (int)Tll;
    long long nlg = (long long)T * V;

    /* pha 1: softmax-grad song song theo t -> dl (T x V) */
    float* dl = (float*)malloc((size_t)nlg * sizeof(float));
    if (!dl) return -6;
    int nt = tkv_nthreads(T);
    if (nt <= 1)
        lmhead_softmax_rows(logits, ids, dl, V, 0, T, scale);
    else
        tkv_run_aux(nt, 3, logits, ids, dl, V, 0, scale, T);

    /* pha 2: dxf = dl @ wte - GEMM blocked/threaded, ghi de (dxf la OUTPUT) */
    run_rect_shaped(dl, V, wte, E, dxf, E, T, E, V);

    /* pha 3: dlT = transpose(dl); doc dl xong -> free truoc khi cap tmp */
    float* dlT = (float*)malloc((size_t)nlg * sizeof(float));
    if (!dlT) { free(dl); return -6; }
    if (nt <= 1)
        lmhead_transpose_rows(dl, dlT, V, T, 0, T);
    else
        tkv_run_aux(nt, 4, dl, NULL, dlT, V, T, 0.0f, T);
    free(dl);

    /* pha 4: tmp = dlT @ xf */
    long long nwe = (long long)V * E;
    float* tmp = (float*)malloc((size_t)nwe * sizeof(float));
    if (!tmp) { free(dlT); return -6; }
    run_rect_shaped(dlT, T, xf, E, tmp, E, V, E, T);
    free(dlT);

    /* pha 5: dwte += tmp (dwte TICH LUY +=) */
    int nta = tkv_nthreads(V);
    if (nta <= 1)
        lmhead_add_rows(dwte, tmp, E, 0, V);
    else
        tkv_run_aux(nta, 5, tmp, NULL, dwte, E, 0, 0.0f, V);
    free(tmp);
    return 0;
}

/* ---------------- YEU CAU #2 UU TIEN A (2026-10-26): simd_gemm_full --------
 * MOT lan goi tron BUILD tile + GEMM + ACC trong DLL (spec M4-M7 request #2
 * Uu tien A): .tkv khong con vong while quanh GEMM. Truoc day wrapper
 * `_smm_core` mat 76-89% FULL cho BUILD+ACC+ALLOC vi ghi list interpreted
 * (spec §2.1) - GEMM kernel da parity nen root cause la dieu phoi .tkv.
 *
 * Layout (giong wrapper hien tai - simd_matmul.tkv::_smm_core/_tile_*_w):
 *   a [m][k] row-major (stride k)
 *   b [k][ndim] neu trans_b = 0 (ndim = n); [n][ndim] neu trans_b = 1
 *     (ndim = k) - stride row LUON la `ndim` (doc giong _tile_b_w)
 *   c [m][n] row-major
 *   mode 0: ghi de c (C = A x B); mode 1: tich lu (c += A x B)
 *
 * Numerics (contract §3.3 - dat BIT=0.0 voi wrapper):
 *   - thu tu vong i0 -> p0 -> j0 (P0.1 cua wrapper), tile A/B build day du
 *     T^2 (copy + zero-pad) giong _tile_a_w/_tile_b_w;
 *   - GEMM moi tile qua DUNG `SgemmF32` (cung pool + cung shape dispatch)
 *     nhu `simd_gemm` wrapper goi -> Ct cung bit;
 *   - acc `cd[bc] = cd[bc] + Ct[bt]` tang dan p0 giong _acc_f; mode 0 memset
 *     region +0.0f tai p0==0 (bit) truoc khi cong -> giong _smm_cd zero-fill.
 *
 * Re-entrancy (§3.1): buffer At/Bt/Ct la LOCAL moi call (khong global), GEMM
 * tile van di qua g_gemm_lock cua pool -> 2 thread cung goi khong hang (khac
 * g_job global truoc day khi 2 thread goi simd_gemm -> HANG > 90s). */
static void full_tile_a(float* out, const float* d, int k, int i0, int ib,
                        int p0, int pw, int T) {
    /* Giong _tile_a_w: row-major T^2, A[i0+i, p0+j] khi i<ib, j<pw, con lai 0 */
    int dst = 0;
    for (int i = 0; i < ib; i++) {
        const float* row = d + (long long)(i0 + i) * k + p0;
        for (int j = 0; j < pw; j++) out[dst++] = row[j];
        for (int j = pw; j < T; j++) out[dst++] = 0.0f;
    }
    for (int i = ib; i < T; i++)
        for (int j = 0; j < T; j++) out[dst++] = 0.0f;
}

static void full_tile_b(float* out, const float* d, int ndim, int p0, int pw,
                        int r0, int br, int T, int trans_b) {
    /* Giong _tile_b_w: hang = chi so giam (p), cot = chi so dau ra (r);
     * trans_b=0 doc HANG [p0+i][r0+j], trans_b=1 doc DOC [r0+j][p0+i]. */
    int dst = 0;
    for (int i = 0; i < pw; i++) {
        if (trans_b) {
            for (int j = 0; j < br; j++)
                out[dst++] = d[(long long)(r0 + j) * ndim + (p0 + i)];
        } else {
            const float* row = d + (long long)(p0 + i) * ndim + r0;
            for (int j = 0; j < br; j++) out[dst++] = row[j];
        }
        for (int j = br; j < T; j++) out[dst++] = 0.0f;
    }
    for (int i = pw; i < T; i++)
        for (int j = 0; j < T; j++) out[dst++] = 0.0f;
}

/* Tra ve 0 = OK; am = loi ro (khong im lang):
 * -1 tham so NULL, -2 shape am, -3 trans_b khong 0/1, -4 mode khong 0/1,
 * -5 list qua ngan (a_len < m*k, b_len < k*ndim hoac n*ndim, c_len < m*n),
 * -6 khong du bo nho tam, -7 T ngoai [4, 4096], -8 ndim khong khop layout. */
EXPORT int SgemmFull(const float* a, const float* b, float* c,
                     int a_len, int b_len, int c_len,
                     int m, int n, int k, int ndim, int trans_b, int T, int mode) {
    if (!a || !b || !c) return -1;
    if (m <= 0 || n <= 0 || k <= 0 || ndim <= 0) return -2;
    if (trans_b != 0 && trans_b != 1) return -3;
    if (mode != 0 && mode != 1) return -4;
    if (T < 4 || T > 4096) return -7;
    long long need_a = (long long)m * k;
    long long need_c = (long long)m * n;
    long long need_b;
    if (trans_b == 0) {
        if (ndim < n) return -8;
        need_b = (long long)k * ndim;      /* max idx (k-1)*ndim + (n-1) */
    } else {
        if (ndim < k) return -8;
        need_b = (long long)n * ndim;      /* max idx (n-1)*ndim + (k-1) */
    }
    if ((long long)a_len < need_a || (long long)b_len < need_b || (long long)c_len < need_c)
        return -5;

    long long tsq = (long long)T * (long long)T;
    float* At = (float*)malloc((size_t)tsq * sizeof(float));
    float* Bt = (float*)malloc((size_t)tsq * sizeof(float));
    float* Ct = (float*)malloc((size_t)tsq * sizeof(float));
    if (!At || !Bt || !Ct) { free(At); free(Bt); free(Ct); return -6; }

    for (int i0 = 0; i0 < m; i0 += T) {
        int ib = m - i0; if (ib > T) ib = T;
        for (int p0 = 0; p0 < k; p0 += T) {
            int pw = k - p0; if (pw > T) pw = T;
            full_tile_a(At, a, k, i0, ib, p0, pw, T);
            for (int j0 = 0; j0 < n; j0 += T) {
                int jb = n - j0; if (jb > T) jb = T;
                full_tile_b(Bt, b, ndim, p0, pw, j0, jb, T, trans_b);
                /* Ct = At x Bt, GHI DE - dung dung SgemmF32 nhu `simd_gemm`
                 * wrapper (pool + shape dispatch cung -> Ct cung bit) */
                SgemmF32(At, Bt, Ct, T);
                if (mode == 0 && p0 == 0) {
                    /* Ghi de: region = +0.0f (memset bit) truoc khi cong -
                     * tuong duong _smm_cd zero-fill truoc khi _acc_f, de
                     * `cd = cd + Ct` bit-giong wrapper (khong dung `= Ct`
                     * vi do doi -0.0f thanh +0.0f/khac corner case). */
                    for (int r = 0; r < ib; r++)
                        memset(c + (long long)(i0 + r) * n + j0, 0,
                               (size_t)jb * sizeof(float));
                }
                /* _acc_f: cd[(i0+r)*n + (j0+c)] += Ct[r*T+c], tang dan p0 */
                for (int r = 0; r < ib; r++) {
                    float* cd = c + (long long)(i0 + r) * n + j0;
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

/* ---------------- YEU CAU #3 UU TIEN A (2026-10-26): native data plane -----
 * 3 kernel doc/ghi TRUC TIEP mang nen `_items` cua `list[f32]` (Tensor.data)
 * - khong ToArray, khong boxing, khong container moi (spec M4-M7 request #3).
 * Moi entry MOT diem (§3.1), cac kernel nay 1 luong (memory-bound/ptu).
 * Dien tu copy-back interpreted 844 ms/step + 2 vong dense BWD 1202 ms (§2.1-
 * §2.2 cua don). Buffer/i64 (p, m, van dung cac entry M5 cu: f32_copy_to_buf,
 * adamw_step...).
 */

/* f32_list_copy(dst, dst_len, src, src_len, n) -> i32
 * dst[i] = src[i] voi i = 0..n-1 (memcpy - BIT-EXACT, ghi de het phan con lai
 * cua dst). Tra ve 0 = OK; -1 tham so sai (con tro NULL, n < 0, dst hoac src
 * NGAN hon n). n == 0 la nop (0). Wrapper .tkv kiem len truoc va nem
 * ArgumentException de nguoi dung thay loi ro - day chi la lat phong cuoi. */
EXPORT int F32ListCopy(float* dst, int dst_len, const float* src, int src_len, int n) {
    if (!dst || !src || n < 0 || dst_len < n || src_len < n) return -1;
    if (n == 0) return 0;
    memcpy(dst, src, (size_t)n * sizeof(float));
    return 0;
}

/* f32_list_add(dst, dst_len, src, src_len, n) -> i32
 * dst[i] += src[i] voi i = 0..n-1 - tich lu 1 pass, thay 2 vong dense
 * interpreted `a[k] = a[k] + b[k]` (38.6M ptu, 1202 ms/step - spec §2.1).
 * Elementwise fp32 KHONG co giam tong -> khong phai thu tu cong: AVX2 cung
 * bit voi interpreted (moi ptu 1 phep cong f32). Tra ve 0 = OK; -1 loi. */
EXPORT int F32ListAdd(float* dst, int dst_len, const float* src, int src_len, int n) {
    if (!dst || !src || n < 0 || dst_len < n || src_len < n) return -1;
    if (n == 0) return 0;
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        __m256 vd = _mm256_loadu_ps(dst + i);
        __m256 vs = _mm256_loadu_ps(src + i);
        _mm256_storeu_ps(dst + i, _mm256_add_ps(vd, vs));
    }
    for (; i < n; i++) dst[i] = dst[i] + src[i];
    return 0;
}

/* f32_grad_norm(g, g_len, n) -> f64: sqrt(sum g[i]^2), 1 pass (spec §2.3 -
 * thay cho vong interpreted doc 124M phan tu ~390 ms/step).
 *
 * HOP DONG SO LIEU (de doc khi doi chieu voi phien interpreted):
 *   - binh phuong TREN FLOAT32: `float p = g[i]*g[i]` - giong phep toan
 *     `s = s + g[i]*g[i]` (f32*f32 -> f32, roi mo rong len f64) cua .tkv;
 *   - tich luy f64 TUAN TU i = 0..n-1 (KHONG gom lai, KHONG song song) -
 *     cung thu tu voi phien interpreted (parity §2.3 yeu cau chinh xac);
 *   - sqrt tren f64, tra f64.
 * Vong for thuan so (khong AVX2): giam tong khong duoc phep reassociate -
 * chinh thu tu tinh la han che parity. Doc 4B/ptu nen van memory-bound. */
EXPORT double F32GradNorm(const float* g, int g_len, int n) {
    if (!g || n < 0 || g_len < n) return -1.0;
    double acc = 0.0;
    for (int i = 0; i < n; i++) {
        float p = g[i] * g[i];   /* binh phuong fp32 - khop `g[i]*g[i]` .tkv */
        acc += (double)p;        /* tich luy f64 tuan tu */
    }
    return sqrt(acc);
}

/* CountByte(p, n, b) -> i64: dem so byte bang gia tri b trong [p, p+n).
 * AVX2 pcmpeqb + movemask + dem bit (SWAR - khong can intrinsic popcnt),
 * duoi scalar cho 32 byte cuoi. Goi tu .tkv qua simd_count_byte (P/Invoke
 * trong class TkvSimd, xem il_features/simd_feature.tkv).
 *
 * Dung cho quet chuoi UTF-16LE ASCII (BSTR cua bstr_alloc): byte thap = ma
 * ky tu, byte cao = 0 -> dem byte == 101 trong 2n byte = dem ky tu 'e'.
 * Chuoi khong phai ASCII co the lech (byte cao 0x65 cua U+65xx) - chi dung
 * voi workload ASCII da biet. */
EXPORT long long CountByte(const unsigned char* p, int n, int b) {
    long long cnt = 0;
    long long i = 0;
    unsigned char bb = (unsigned char)b;
    if (!p || n <= 0) return 0;
    __m256i vp = _mm256_set1_epi8((char)bb);
    for (; i + 32 <= n; i += 32) {
        __m256i d = _mm256_loadu_si256((const __m256i*)(const void*)(p + i));
        __m256i eq = _mm256_cmpeq_epi8(d, vp);
        unsigned int m = (unsigned int)_mm256_movemask_epi8(eq);
        m = m - ((m >> 1) & 0x55555555u);
        m = (m & 0x33333333u) + ((m >> 2) & 0x33333333u);
        m = (m + (m >> 4)) & 0x0F0F0F0Fu;
        cnt += (long long)((m * 0x01010101u) >> 24);
    }
    for (; i < n; i++) if (p[i] == bb) cnt++;
    return cnt;
}
