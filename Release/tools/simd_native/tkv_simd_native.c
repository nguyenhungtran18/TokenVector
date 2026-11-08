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
#include <stdio.h>

#define EXPORT __declspec(dllexport)

static void gemm_rows_f32(const float* a, const float* b, float* o, int n, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl);
static void gemm_rows_f64(const double* a, const double* b, double* o, int n, int i0, int i1, int j0, int j1);
static void gemm_rect_f32(const float* a, int lda, const float* b, int ldb, float* o, int ldc,
                          int m, int n, int k, int i0, int i1, int j0, int j1,
                          int mc_b, int nc_b, int bpl);
static void gemm_rect_ta_f32(const float* a, int lda, const float* b, int ldb, float* o, int ldc,
                             int m, int n, int k, int i0, int i1, int j0, int j1,
                             int mc_b, int nc_b, int bpl);

/* M6 v2 (lmhead) - khai truoc truoc khi dung trong tkv_worker. */
static void lmhead_softmax_rows(const float* logits, const int* ids, float* dl,
                                int V, int t0, int t1, float scale);
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

/* ==== BLAS integration (2026-11-06): scipy-openblas64 =====================
 * gd: neu `TKV_GEMM_BLAS != 0` (mac dinh = ON theo quyet dinh se mat Loss
 * EXACT) va DLL nap duoc, SgemmF32 se goi `cblas_sgemm` (row-major) thay
 * vi kernel AVX2 noi bo — tao ra full cuong do BLAS cho MOI GEMM (packed,
 * full, attention fused...). `TKV_GEMM_BLAS=0` -> quay lai kernel native.
 * neu DLL khong co -> fallback native silently.
 *
 * Build voi MKL (TKV_LINK_MKL=1, xem build.ps1): linked with import lib
 * (mkl_intel_lp64_dll.lib + mkl_intel_thread_dll.lib + mkl_core_dll.lib)
 * -> cblas_sgemm resolve AT LINK TIME (nhu Py torch nhúng oneDNN+MKL tĩnh).
 * Runtime van can mkl_avx2.3.dll (hoac mkl_def.3.dll), mkl_mc3.3.dll,
 * mkl_core.3.dll, mkl_intel_thread.3.dll (thuong) + libiomp5md.dll
 * sao chép cạnh tkv_simd_native.dll. */
typedef long long TKV_BLASINT;
static HMODULE g_blas_mod;
static void (*p_cblas_sgemm)(int layout, int transA, int transB,
                             TKV_BLASINT M, TKV_BLASINT N, TKV_BLASINT K,
                             float alpha,
                             const float* A, TKV_BLASINT lda,
                             const float* B, TKV_BLASINT ldb,
                             float beta,
                             float* C, TKV_BLASINT ldc);
static void (*p_openblas_set_num_threads)(int);
static int g_blas_state = 0; /* 0 unknown, 1 ok, -1 unavailable */

#ifdef TKV_LINK_MKL
#include <mkl_cblas.h>
#include <mkl.h>
static int tkv_blas_load(void);
static void tkv_mkl_set_threads(int nt) {
    mkl_set_num_threads_local(nt > 0 ? nt : 1);
}
static void tkv_mkl_gemm(int transA, int m, int n, int k,
                         const float* a, int lda, const float* b, int ldb,
                         float* c, int ldc) {
    cblas_sgemm(CblasRowMajor, (CBLAS_TRANSPOSE)transA, CblasNoTrans,
                (MKL_INT)m, (MKL_INT)n, (MKL_INT)k, 1.0f, a, (MKL_INT)lda, b,
                (MKL_INT)ldb, 0.0f, c, (MKL_INT)ldc);
}
#endif

static int tkv_blas_load(void) {
    if (g_blas_state != 0) return g_blas_state;
#ifdef TKV_LINK_MKL
    fprintf(stderr, "[tkv] BLAS: MKL 2026.2 (linked static import lib, kernel runtime)\n");
    g_blas_state = 1;
    return 1;
#else
    /* BLAS mặc định bật (zero-config): GLAS_RUN_ENV thay qua opt-in
     * TKV_GEMM_BLAS=1; với env khác ('0') tách BLAS hoàn toàn.
     * Biên dịch thử nghiệm: .\bench_attn.exe tuỳ chọn TKV_GEMM_BLAS=0. */
    const char* env_blas = getenv("TKV_GEMM_BLAS");
    if (env_blas && env_blas[0] == '0') { g_blas_state = -1; return -1; }
    char path_buf[MAX_PATH] = {0};
    const char* env_path = getenv("TKV_GEMM_BLAS_PATH");
    g_blas_mod = NULL;
    if (env_path && env_path[0]) g_blas_mod = LoadLibraryA(env_path);
    if (!g_blas_mod) {
        DWORD len = GetModuleFileNameA(NULL, path_buf, MAX_PATH);
        if (len > 0 && len < MAX_PATH) {
            char* slash = strrchr(path_buf, '\\');
            if (slash) {
                strcpy(slash + 1, "libscipy_openblas64_.dll");
                g_blas_mod = LoadLibraryA(path_buf);
            }
        }
    }
    if (!g_blas_mod) g_blas_mod = LoadLibraryA("libscipy_openblas64_.dll");
    if (!g_blas_mod) { g_blas_state = -1; return -1; }
    p_cblas_sgemm = (void(*)(int, int, int, TKV_BLASINT, TKV_BLASINT, TKV_BLASINT,
                             float, const float*, TKV_BLASINT,
                             const float*, TKV_BLASINT, float, float*, TKV_BLASINT))
                    GetProcAddress(g_blas_mod, "cblas_sgemm");
    if (!p_cblas_sgemm)
        p_cblas_sgemm = (void(*)(int, int, int, TKV_BLASINT, TKV_BLASINT, TKV_BLASINT,
                                 float, const float*, TKV_BLASINT,
                                 const float*, TKV_BLASINT, float, float*, TKV_BLASINT))
                        GetProcAddress(g_blas_mod, "scipy_cblas_sgemm");
    p_openblas_set_num_threads = (void(*)(int))GetProcAddress(g_blas_mod, "openblas_set_num_threads");
    if (!p_openblas_set_num_threads)
        p_openblas_set_num_threads = (void(*)(int))GetProcAddress(g_blas_mod, "scipy_openblas_set_num_threads");
    if (!p_cblas_sgemm) { FreeLibrary(g_blas_mod); g_blas_mod = NULL; g_blas_state = -1; return -1; }
    fprintf(stderr, "[tkv] BLAS: scipy-openblas64_ loaded (cblas_sgemm)\n");
    g_blas_state = 1;
    return 1;
#endif
}

/* Return 1 = BLAS da dung thay kernel native, 0 = dung kernel native. */
static int tkv_try_blas(float* a, float* b, float* o, int n) {
    if (tkv_blas_load() != 1) return 0;
    int nt = tkv_nthreads(n);
#ifdef TKV_LINK_MKL
    tkv_mkl_set_threads(nt > 0 ? nt : 1);
    tkv_mkl_gemm(111 /*NoTrans*/, n, n, n, a, n, b, n, o, n);
    return 1;
#else
    if (p_openblas_set_num_threads) p_openblas_set_num_threads(nt > 0 ? nt : 1);
    p_cblas_sgemm(101 /*RowMajor*/, 111 /*NoTrans*/, 111 /*NoTrans*/,
        n, n, n, 1.0f, a, n, b, n, 0.0f, o, n);
    return 1;
#endif
}

/* BLAS cho chu nhat (rect mat-cheo / square). A/B theo RowMajor.
 * transA = 111 (NoTrans) hay 112 (Trans). Default giam bit-exact. */
static int tkv_try_blas_rect(float* a, int lda, float* b, int ldb, float* o, int ldc,
                              int m, int n, int k, int transA) {
    if (tkv_blas_load() != 1) return 0;
    int nt = tkv_nthreads(m > n ? m : n);
#ifdef TKV_LINK_MKL
    tkv_mkl_set_threads(nt > 0 ? nt : 1);
    tkv_mkl_gemm(transA, m, n, k, a, lda, b, ldb, o, ldc);
    return 1;
#else
    if (p_openblas_set_num_threads) p_openblas_set_num_threads(nt > 0 ? nt : 1);
    p_cblas_sgemm(101 /*RowMajor*/, transA, 111 /*NoTrans*/, m, n, k,
                  1.0f, a, lda, b, ldb, 0.0f, o, ldc);
    return 1;
#endif
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

/* 2026-11-06: co "dang chay trong 1 worker .tkv" (thread_spawn). Khi do 12 worker
 * da song song san (attention_bwd: 12 head x 6 GEMM) -> GEMM/pack chi CAN chay
 * DON LUONG, khong can pool chung (tranh g_gemm_lock + oversubscription).
 * Ghi chu DO LAI: production attention GEMMs deu roi nhanh SMALL (k = hd = 64
 * va n = 64 < TKV_MIN_N = 96) nen von da don luong; co nay KHONG doi toc do do
 * duoc (ATTENTION_BWD ~250 ms/layer truoc va sau). Giu lai nhu safeguard cho
 * shape lon hon; pack song song (pure copy) cung duoc tat trong nested.
 * Doi so luong luong KHONG doi ket qua (moi ptu van 1 job, cung pc-block + FMA)
 * -> van bit-exact. */
static __declspec(thread) int t_nested = 0;

/* mode 6 (2026-11-06): pack 1 ma tran f32 vao buffer padded, chia theo HANG
 * DICH [i0,i1). Thuan copy -> moi thu tu deu bit-giong (chi la di chuyen du
 * lieu). `trans=1` ghi dst[i*ld+j] = src[j*stride+i] theo tile 32x32 de moi
 * huong deu cache-friendly (truoc day vong j->i lam moi store lech 1 cot). */
static void pack_rows_f32(const float* src, float* dst, int stride, int rows,
                          int cols, int ld, int trans, int i0, int i1) {
    if (!trans) {
        for (int i = i0; i < i1; i++) {
            float* d = dst + (long long)i * ld;
            const float* s = src + (long long)i * stride;
            int j = 0;
            for (; j + 8 <= cols; j += 8)
                _mm256_storeu_ps(d + j, _mm256_loadu_ps(s + j));
            for (; j < cols; j++) d[j] = s[j];
        }
    } else {
        for (int jj = 0; jj < rows; jj += 32) {
            int je = jj + 32; if (je > rows) je = rows;
            for (int ii = i0; ii < i1; ii += 32) {
                int ie = ii + 32; if (ie > i1) ie = i1;
                for (int j = jj; j < je; j++) {
                    const float* s = src + (long long)j * stride;
                    for (int i = ii; i < ie; i++)
                        dst[(long long)i * ld + j] = s[i];
                }
            }
        }
    }
}

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
        else if (j->mode == 5)
            lmhead_add_rows((float*)j->o, (const float*)j->a, j->n, j->i0, j->i1);
        else if (j->mode == 6)
            pack_rows_f32((const float*)j->a, (float*)j->o, j->lda, j->m, j->n,
                          j->k, j->mc, j->i0, j->i1);
        else if (j->mode == 7)
            gemm_rect_ta_f32((const float*)j->a, j->lda, (const float*)j->b, j->ldb,
                             (float*)j->o, j->n, j->m, j->n, j->k, j->i0, j->i1, j->j0, j->j1,
                             j->mc, j->nc, j->bpl);
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
static void tkv_run_mt_rect(int nt, int mode, const float* a, int lda, const float* b, int ldb,
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
            g_job[used].mode = mode;
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
 * 5 = dwte += tmp. n = V (mode 3) hoac E (mode 5), alpha = scale (mode 3). */
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

/* Chay pack_rows_f32 tren pool (mode 6). Chia theo HANG DICH mtotal. */
static void tkv_run_pack(int nt, const float* src, float* dst, int stride,
                         int rows, int cols, int ld, int trans, int mtotal) {
    if (mtotal <= 0) return;
    AcquireSRWLockExclusive(&g_gemm_lock);
    InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL);
    if (nt > g_nw) nt = g_nw;
    if (nt < 1) nt = 1;
    if (nt > mtotal) nt = mtotal;
    int per = (mtotal + nt - 1) / nt;
    if (per < 1) per = 1;
    int used = 0;
    for (int t = 0; t < nt; t++) {
        int i0 = t * per;
        if (i0 >= mtotal) break;
        int i1 = i0 + per; if (i1 > mtotal) i1 = mtotal;
        g_job[used].a = src; g_job[used].o = dst;
        g_job[used].lda = stride; g_job[used].m = rows; g_job[used].n = cols;
        g_job[used].k = ld; g_job[used].mc = trans;
        g_job[used].mode = 6;
        g_job[used].i0 = i0; g_job[used].i1 = i1;
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
    static __declspec(thread) float bp[GEMM_KC * GEMM_BPL_MAX];
    /* bao ve buffer (M7): bpl trong [GEMM_BPL, GEMM_BPL_MAX], nc <= bpl - 4 */
    if (bpl < GEMM_BPL) bpl = GEMM_BPL;
    if (bpl > GEMM_BPL_MAX) bpl = GEMM_BPL_MAX;
    if (nc_b > bpl - 4) nc_b = bpl - 4;
    if (nc_b < 1) nc_b = 1;
    if (mc_b < 1) mc_b = 1;
    for (int jc = j0; jc < j1; jc += nc_b) {
        int nc = j1 - jc; if (nc > nc_b) nc = nc_b;
        /* MC2 (2026-11-06): gom `mc2` HANG vao 1 chunk de tile C (mc2 x nc
         * f32 ~ 128 KB) nam trong L2 -> C chi ra DRAM 1 lan thay vi
         * (k/GEMM_KC) lan. Truoc day voi m lon (lm-head dwte: 50257 x 768
         * @ k=1024) C bi doc+ghi lai 16 lan tren 154 MB -> 2.5 GB RMW va
         * kernel tut con 69 GFLOPS (vs 389 GFLOPS cung shape m=4096).
         * Thu tu cong theo k KHONG doi (pc tang dan, trong pc van la
         * micro_f32) -> ket qua BIT-GIONG duong cu. */
        int mc2 = 32768 / nc;                 /* ~128 KB C / chunk */
        mc2 = (mc2 / mc_b) * mc_b;
        if (mc2 < mc_b) mc2 = mc_b;
        for (int ic2 = i0; ic2 < i1; ic2 += mc2) {
            int ic2e = ic2 + mc2; if (ic2e > i1) ic2e = i1;
            for (int ii = ic2; ii < ic2e; ii++)
                memset(o + (long long)ii * ldc + jc, 0, (size_t)nc * sizeof(float));
            for (int pc = 0; pc < k; pc += GEMM_KC) {
                int kc = k - pc; if (kc > GEMM_KC) kc = GEMM_KC;
                pack_b_f32(b, bp, ldb, pc, kc, jc, nc, bpl);
                for (int ic = ic2; ic < ic2e; ic += mc_b) {
                    int mc = ic2e - ic; if (mc > mc_b) mc = mc_b;
                    micro_f32(a + (long long)ic * lda + pc, lda, bp,
                              o + (long long)ic * ldc + jc, ldc, mc, nc, kc, bpl);
                }
            }
        }
    }
    (void)m;
}

/* Micro 4x16 voi A luu kieu [k][m] (lda = so phan tu 1 hang k, tuc chieu m):
 * phan tu A[p][i] = a[p * lda + i]. Dung cho dwte = dl^T @ xf khi dl la
 * [T][V]: k = t, m = v. Voi p co dinh, 4 gia tri v = i..i+3 NAM LIEN TIEP
 * (cung cache line) nen thay 4 broadcast bang 4 lan doc sat nhau. Thu tu
 * cong k va FMA y nguyen micro_f32 -> ket qua BIT-GIONG duong dlT. */
static void micro_ta_f32(const float* a, int lda, const float* bp, float* c, int n,
                         int mc, int nc, int kc, int bpl) {
    int i = 0;
    for (; i + 4 <= mc; i += 4) {
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
                const float* ap = a + (long long)p * lda + i;
                __m256 va0 = _mm256_broadcast_ss(ap);
                __m256 va1 = _mm256_broadcast_ss(ap + 1);
                __m256 va2 = _mm256_broadcast_ss(ap + 2);
                __m256 va3 = _mm256_broadcast_ss(ap + 3);
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
                const float* ap = a + (long long)p * lda + i;
                s0 += ap[0] * bv;
                s1 += ap[1] * bv;
                s2 += ap[2] * bv;
                s3 += ap[3] * bv;
            }
            ci[j] += s0;
            ci[n + j] += s1;
            ci[2 * n + j] += s2;
            ci[3 * n + j] += s3;
        }
    }
    for (; i < mc; i++) {
        float* ci = c + (long long)i * n;
        for (int j = 0; j < nc; j++) {
            float s = 0.0f;
            for (int p = 0; p < kc; p++)
                s += a[(long long)p * lda + i] * bp[(long long)p * bpl + j];
            ci[j] += s;
        }
    }
}

/* Nhu gemm_rect_f32 nhung A la [k][m] (transposed A). C chi doc/ghi 1 lan
 * nho MC2; thu tu cong p tang dan trong tung pc -> bit-giong. */
static void gemm_rect_ta_f32(const float* a, int lda, const float* b, int ldb, float* o, int ldc,
                             int m, int n, int k, int i0, int i1, int j0, int j1,
                             int mc_b, int nc_b, int bpl) {
    if (i1 <= i0 || j1 <= j0) return;
    static __declspec(thread) float bp[GEMM_KC * GEMM_BPL_MAX];
    if (bpl < GEMM_BPL) bpl = GEMM_BPL;
    if (bpl > GEMM_BPL_MAX) bpl = GEMM_BPL_MAX;
    if (nc_b > bpl - 4) nc_b = bpl - 4;
    if (nc_b < 1) nc_b = 1;
    if (mc_b < 1) mc_b = 1;
    for (int jc = j0; jc < j1; jc += nc_b) {
        int nc = j1 - jc; if (nc > nc_b) nc = nc_b;
        int mc2 = 32768 / nc;
        mc2 = (mc2 / mc_b) * mc_b;
        if (mc2 < mc_b) mc2 = mc_b;
        for (int ic2 = i0; ic2 < i1; ic2 += mc2) {
            int ic2e = ic2 + mc2; if (ic2e > i1) ic2e = i1;
            for (int ii = ic2; ii < ic2e; ii++)
                memset(o + (long long)ii * ldc + jc, 0, (size_t)nc * sizeof(float));
            for (int pc = 0; pc < k; pc += GEMM_KC) {
                int kc = k - pc; if (kc > GEMM_KC) kc = GEMM_KC;
                pack_b_f32(b, bp, ldb, pc, kc, jc, nc, bpl);
                for (int ic = ic2; ic < ic2e; ic += mc_b) {
                    int mc = ic2e - ic; if (mc > mc_b) mc = mc_b;
                    micro_ta_f32(a + (long long)pc * lda + ic, lda, bp,
                                 o + (long long)ic * ldc + jc, ldc, mc, nc, kc, bpl);
                }
            }
        }
    }
    (void)m;
}

static int tkv_k_eff(const float* b, const float* a, int n) {
    if (n <= 0) return 0;
    for (int p = n - 1; p >= 0; p--) {
        const float* br = b + (long long)p * n;
        int j;
        for (j = 0; j < n; j++)
            if (br[j] != 0.0f) return p + 1;
        for (int r = 0; r < n; r++) {
            uint32_t bits;
            float av = a[(long long)r * n + p];
            memcpy(&bits, &av, sizeof bits);
            if ((bits & 0x7F800000u) == 0x7F800000u) return p + 1;   /* Inf/NaN */
        }
    }
    return 0;
}

EXPORT void SgemmF32(float* a, float* b, float* o, int n) {
    if (tkv_try_blas(a, b, o, n)) return;
    /* M7: lop VOCAB (n == 50257) chia cot manh + NC lon; con lai pattern cu.
     * nho (< MIN_N mac dinh 96) da tro thanh nt = 1 trong tkv_nthreads. */
    int nt = tkv_nthreads(n);
    int nc = GEMM_NC, bpl = GEMM_BPL, cols_req = -1;
    if (tkv_shape_on() && n == TKV_VOCAB) {
        nc = GEMM_NC_RG;
        bpl = GEMM_BPL_MAX;
        if (nt > 1) cols_req = tkv_ncols_vocab(nt, n);
    }
    /* M9: rut k xuong k_eff khi tile B bi zero-pad (xem tkv_k_eff) - BIT-EXACT.
     * k_eff == n (khong co hang 0 cuoi) -> khong vao nhay nay, di duong cu. */
    {
        int k_eff = tkv_k_eff(b, a, n);
        if (k_eff < n) {
            if (nt <= 1)
                gemm_rect_f32(a, n, b, n, o, n, n, n, k_eff, 0, n, 0, n,
                              GEMM_MC, nc, bpl);
            else
                tkv_run_mt_rect(nt, 2, a, n, b, n, o, n, n, n, k_eff,
                                (cols_req > 0) ? cols_req : tkv_ncols(nt, n),
                                GEMM_MC, nc, bpl);
            return;
        }
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
    if (!srcd && m > 0) {
        /* 2026-11-06: pack song song (truoc day 1 luong, chiem 50-60% thoi
         * gian 1 phep smm_dot: do bench_packed lin_bwd create=33.6ms vs
         * gemm=24.2ms). Thuan copy -> bit-giong. */
        int nt = t_nested ? 1 : tkv_nthreads(m);
        if (nt > 1 && (long long)m * (long long)n >= (1LL << 16))
            tkv_run_pack(nt, srcf, buf, stride, rows, cols, ld, trans, m);
        else
            pack_rows_f32(srcf, buf, stride, rows, cols, ld, trans, 0, m);
    } else if (!trans) {
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
 * bit-giong. Dung CHUNG cho packed (M4) va lmhead v2 (M6).
 * `mode` 2 = gemm_rect_f32 (A [m][k]), 7 = gemm_rect_ta_f32 (A [k][m]). */
/* Giữ kí tự ở metadata `rows` — phòng mách bạn. */
static void run_rect_shaped_m(int mode, const float* a, int lda, const float* b, int ldb,
                              float* c, int ldc, int m, int n, int k) {
    /* BLAS luôn được thử trước (zero-config). Set TKV_GEMM_BLAS=0 để
     * bật lại kernel native cho mọi shape. Layout BLAS = RowMajor. */
    if (tkv_blas_load() == 1) {
        int transA = (mode == 7) ? 112 : 111;
        if (tkv_try_blas_rect((float*)a, lda, (float*)b, ldb, c, ldc, m, n, k, transA) == 1)
            return;
    }
    int mc = GEMM_MC, nc = GEMM_NC, cols_req = 1, bpl = GEMM_BPL;
    int nt;
    if (tkv_shape_on()) {
        int cls = tkv_shape_class(m, n, k);
        if (cls == TKV_CLS_SMALL) {
            nt = 1;
        } else {
            nt = tkv_nthreads(m > n ? m : n);
            if (cls == TKV_CLS_VOCAB) {
                /* LUU Y (do 2026-11-07, bench_tile): doi cot sang boi 16
                 * (cols=4, NC=64) nhanh hon ~190 ms nhung LECH BIT - 7/55 cot
                 * bien cua strip cu tinh bang mul+add scalar, doi sang FMA
                 * lam mode-1 loss 13.442915 -> 13.442913. GIU nguyen tiling
                 * cu de bao toan bit-exact. */
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
    if (t_nested) nt = 1;
    if (nt <= 1) {
        if (mode == 7)
            gemm_rect_ta_f32(a, lda, b, ldb, c, ldc, m, n, k, 0, m, 0, n, mc, nc, bpl);
        else
            gemm_rect_f32(a, lda, b, ldb, c, ldc, m, n, k, 0, m, 0, n, mc, nc, bpl);
    } else
        tkv_run_mt_rect(nt, mode, a, lda, b, ldb, c, ldc, m, n, k, cols_req, mc, nc, bpl);
}

static void run_rect_shaped(const float* a, int lda, const float* b, int ldb,
                            float* c, int ldc, int m, int n, int k) {
    run_rect_shaped_m(2, a, lda, b, ldb, c, ldc, m, n, k);
}

/* Nhu run_rect_shaped nhung A la [k][m] (bo duoc buoc transpose A). */
static void run_rect_ta_shaped(const float* a, int lda, const float* b, int ldb,
                               float* c, int ldc, int m, int n, int k) {
    run_rect_shaped_m(7, a, lda, b, ldb, c, ldc, m, n, k);
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
 * v2 (2026-10-25, doi chieu so do v1 = 38.6s): 4 pha, dung thread pool +
 * GEMM blocked da co (run_rect_shaped):
 *   1. softmax-grad song song theo t -> scratch dl (T x V)   [pool mode 3]
 *   2. dxf = dl @ wte        -> run_rect_shaped (blocked/threaded, ghi de)
 *   3. tmp = dl^T @ xf       -> run_rect_ta_shaped (A [k][m], khong transpose)
 *   4. dwte += tmp           -> AVX2                          [pool mode 5]
 * v1 single-thread bi memory-bound: moi t re-read toan wte + RMW toan dwte
 * (~630 GB) -> 38.6s. v2 moi buffer chi doc/ghi 1 lan + GEMM blocked.
 * Scratch tam: dl (T*V*4) + tmp (V*E*4), free ngay trong loi
 * (peak dl+tmp ≈ 360 MB voi T=1024 V=50257; truoc 2026-11-07 co them dlT).
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

    /* pha 3+4: tmp = dlT @ xf. dl la [T][V] = [k][m] nen doc THANG bang
     * gemm_rect_ta_f32 (A [k][m]) - bo han buoc transpose 51,5M ptu (do
     * 2026-11-07 @seq1024: 110 ms) va bo buffer dlT 205 MB. Thu tu cong k (t)
     * va FMA y nguyen duong dlT -> bit-giong (loss EXACT 10.760399). */
    long long nwe = (long long)V * E;
    float* tmp = (float*)malloc((size_t)nwe * sizeof(float));
    if (!tmp) { free(dl); return -6; }
    run_rect_ta_shaped(dl, V, xf, E, tmp, E, V, E, T);
    free(dl);

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

/* LinearDxFused (YEU CAU #10 Ask B, 2026-11-01): dx = gy * w^T (trans_b=1).
 * Thay cho `dx = smm_dot(gy, w, m, n, k)` trong gpt2_linear_bwd.
 *
 * VI SAO NHANH: smm_dot -> _smm_core (k>=256, m<=256) -> _smm_full ->
 *   SgemmFull -> SgemmF32(At,Bt,Ct,T) tinh DAY DU T hang nhung chi r < ib = m
 *   duoc _acc_f cong vao dx. 248/256 hang thua = 32x phep nhan (12.69 ms dx1).
 *   O day goi TRUC TIEP gemm_rect_f32/gemm_rows_f32 voi i1 = m -> bo hang thua.
 *
 * BIT-EXACT (loss EXACT):
 *   - Goi dung static helper cua TU nay (full_tile_a/full_tile_b/tkv_k_eff/
 *     gemm_rect_f32/gemm_rows_f32) — khong copy code (tranh 2 nguon su that).
 *   - At/Bt xay DAY DU T x T (hang i >= m = 0) de tkv_k_eff doc dung -> k_eff GIONG.
 *   - j1 = T (KHONG jb) -> jc/nc/micro_f32 giong SgemmF32 -> cot 0..jb-1 cung bit.
 *   - m % 4 == 0 (guard -11): micro_f32 i-tail (scalar, khac FMA) chi xay ra khi
 *     mc % 4 != 0; reference (i1=T) luon mc=64 -> khong i-tail. m chia het 4 ->
 *     mc = min(64, m-ic) chia het 4 -> khong i-tail -> cung FMA.
 *   - k % 256 == 0 (guard -12): p-tile cuoi luon DAY (pw = T) -> tkv_k_eff = T
 *     -> di `gemm_rows_f32`. DO: p-tile LE (pw < T) khien tkv_k_eff < T ->
 *     `gemm_rect_f32`, va khi i1 = ib > GEMM_MC (nhieu block ic) no LECH BIT so
 *     voi reference i1 = T (do ai chet: probe _am6 `k300-both` m=200 n=96
 *     k=300 -> 1264 ptu lech; tach yeu to: `k300-onlyA` m=8 -> 0, `m200-onlyB`
 *     k=768 -> 0 — chi CA HAI cung nhau moi lech). San pham khong bi anh huong:
 *     out_d that luon {768, 2304, 3072} = boi cua 256 -> khong bao gio vao
 *     gemm_rect_f32. HOP DONG: khong du chung minh -> KHONG nhan, caller fallback.
 *   - Threading (tkv_run_mt*) chi chia [i0,i1)x[j0,j1) — moi ptu van 1 job cung
 *     pc-block (KC=64) + cung FMA -> single-thread CUNG BIT.
 *   - mode=0 + p0==0: memset +0.0f truoc khi cong (giu -0.0f), giong SgemmFull.
 *
 * TRA VE 0 = OK; am = loi (caller fallback smm_dot nguyen ven):
 *   -1 NULL, -2 shape <=0, -5 list qua ngan, -6 khong du bo nho tam,
 *   -9 k < 256 (khong di qua _smm_full), -10 m > 256 (-> _smm_pk),
 *   -11 m % 4 != 0 (micro_f32 i-tail -> khac FMA),
 *   -12 k % 256 != 0 (p-tile le + nhieu block ic -> khong chung minh duoc BIT). */
EXPORT int LinearDxFused(const float* gy, int gy_len,
                         const float* w, int w_len,
                         float* dx, int dx_len,
                         int m, int n, int k) {
    if (!gy || !w || !dx) return -1;
    if (m <= 0 || n <= 0 || k <= 0) return -2;
    int T = 256;          /* cung so voi _smm_full (hardcode 256) */
    int ndim = k;         /* smm_dot: trans_b=1, ndim = k */
    if (k < 256) return -9;
    if (m > T) return -10;
    if ((m & 3) != 0) return -11;
    if ((k & (T - 1)) != 0) return -12;
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

    /* Giong SgemmFull: i0 -> p0 -> j0. m <= T -> i0 chi chay 1 lan (i0=0, ib=m). */
    for (int i0 = 0; i0 < m; i0 += T) {
        int ib = m - i0; if (ib > T) ib = T;
        for (int p0 = 0; p0 < k; p0 += T) {
            int pw = k - p0; if (pw > T) pw = T;
            full_tile_a(At, gy, k, i0, ib, p0, pw, T);
            for (int j0 = 0; j0 < n; j0 += T) {
                int jb = n - j0; if (jb > T) jb = T;
                full_tile_b(Bt, w, ndim, p0, pw, j0, jb, T, 1 /* trans_b=1 */);
                if (ib >= T) {
                    /* m = T: khong cat hang duoc -> goi SgemmF32 (chinh reference,
                     * co thread) de KHONG regressed so voi smm_dot (do m=256 single-
                     * thread thua threaded reference ~2x - do test_dx do duoc). */
                    SgemmF32(At, Bt, Ct, T);
                } else {
                    /* Cat hang [ib, T): chi tinh hang that [0, ib). */
                    int k_eff = tkv_k_eff(Bt, At, T);
                    if (k_eff < T)
                        gemm_rect_f32(At, T, Bt, T, Ct, T, T, T, k_eff,
                                      0, ib, 0, T, GEMM_MC, GEMM_NC, GEMM_BPL);
                    else
                        gemm_rows_f32(At, Bt, Ct, T, 0, ib, 0, T,
                                      GEMM_MC, GEMM_NC, GEMM_BPL);
                }
                if (p0 == 0) {
                    /* mode=0 + p0==0: memset +0.0f truoc khi cong (giu -0.0f) */
                    for (int r = 0; r < ib; r++)
                        memset(dx + (long long)(i0 + r) * n + j0, 0,
                               (size_t)jb * sizeof(float));
                }
                /* _acc_f: cd[(i0+r)*n + (j0+c)] += Ct[r*T+c], tang dan p0. */
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

/* LinearDwFused (YEU CAU #10 Ask A) nam trong tkv_linear_dw.c — TU rieng
 * bien dich /fp:precise: /fp:fast cho phep tai lien ket nen ket qua phu thuoc
 * gia tri dich (do 01/11). Xem build.ps1. */

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

/* CountChar16(p, n, c) -> i64: dem so lan ma UTF-16 `c` xuat hien trong
 * [p, p+n) (n tinh bang KY TU, p tro toi ky tu dau cua String).
 * Khac CountByte: so sanh 16-bit nen dung duoc voi moi chuoi .NET, khong
 * chi ASCII, va khong phai copy chuoi sang BSTR truoc khi quet.
 * AVX2 pcmpeqw + movemask (moi lane khop = 2 bit) -> dem bit / 2. */
EXPORT long long CountChar16(const unsigned short* p, int n, int c) {
    long long cnt = 0;
    long long i = 0;
    unsigned short cc = (unsigned short)c;
    if (!p || n <= 0) return 0;
    __m256i vc = _mm256_set1_epi16((short)cc);
    for (; i + 16 <= n; i += 16) {
        __m256i d = _mm256_loadu_si256((const __m256i*)(const void*)(p + i));
        __m256i eq = _mm256_cmpeq_epi16(d, vc);
        unsigned int m = (unsigned int)_mm256_movemask_epi8(eq);
        m = m - ((m >> 1) & 0x55555555u);
        m = (m & 0x33333333u) + ((m >> 2) & 0x33333333u);
        m = (m + (m >> 4)) & 0x0F0F0F0Fu;
        cnt += (long long)((m * 0x01010101u) >> 24) / 2;
    }
    for (; i < n; i++) if (p[i] == cc) cnt++;
    return cnt;
}

/* ==== YEU CAU #14 (2026-11-06): attention_bwd FUSED per head ================
 * Gop 6 GEMM + softmax fwd/bwd + writeback CUA MOT HEAD thanh 1 lenh goi:
 *   Smat = smm_dot(gQ, gK, n, n, hd)  -> dispatch _smm_core (k>=64):
 *          m <= 256 -> SgemmFull(T=256, mode=0) | m > 256 -> packed T=256
 *   l13  = softmax_causal_fwd(Smat, n, inv)       (tkv_bwd_ops.c)
 *   gCtx = smm_fwd(Smat, gV, n, hd, n)            -> dispatch giong tren
 *   gDp  = smm_dot(gDc, gV, n, n, hd)             -> dispatch giong tren
 *   l12  = softmax_causal_bwd(gDp, Smat, gDc, gCtx, n, hd)   (tkv_bwd_ops.c)
 *   gDq  = smm_fwd(gDs, gK, n, hd, n)             -> dispatch giong tren (gDs = gDp in-place)
 *   gDkT = smm_fwd_at(gQ, gDs)   (_p58 trans_a, T=64)  -> port truc tiep tai day
 *   gDvT = smm_fwd_at(gDc, Smat) (_p58 trans_a, T=64)  -> port truc tiep tai day
 *   writeback packed per head: [t*3hd+d | +hd+d | +2hd+d], dq/dk * inv, dv raw
 *
 * BIT-EXACT:
 *   - 4 GEMM packed/full: GOI DUNG cac static/EXPORT trong file nay voi
 *     DUNG T=256 + mode=0 (SgemmFull tu memset vung truoc khi cong) => cung ma
 *     may, cung bits nhu duong .tkv.
 *   - 2 trans-A: port _tile_a_at_w/_tile_b_w + SgemmF32 + tich luy p0 TANG DAN
 *     (giong _p58_core_simple) => cung thu tu moi phep cong.
 *   - Softmax: goi dung entry da duoc kiem chung (_am7/_am8).
 *
 * TRA VE 0 = OK, <0 = loi ro -> caller (.tkv) fallback duong cu NGUYEN VAN.
 *   -1 NULL, -2 shape sai, -5 buffer qua ngan, -6 het bo nho, -13 n < 64
 *   hoac hd != 64, -20 xgemm, -30 trans-A. */
extern int SoftmaxCausalFwd(float* s, int s_len, int n, double inv);
extern int SoftmaxCausalBwd(float* dp, int dp_len, const float* P, int P_len,
                            const float* dctx, int dc_len, const float* ctx, int c_len,
                            int n, int hd);

/* Dispatch kieu _smm_core cho 2 truong hop:
 *   trans_b = 0: B luu [k x np] (ndim = np)   — C[m][np] = A[m][k] x B[k][np]
 *   trans_b = 1: B luu [np x k] (ndim = k)    — C[m][np] = A[m][k] x B^T
 * Tra ve 0 = OK, <0 = loi. */
static int attn_xgemm(float* c, const float* a, int m, int k,
                      const float* b, int b_rows, int b_cols, int b_stride, int trans_b) {
    int np = (trans_b == 0) ? b_cols : b_rows;
    long long a_len = (long long)m * k;
    long long b_len = (long long)b_rows * b_stride;
    long long c_len = (long long)m * np;
    if (k < 64) return -23;                        /* .tkv se di tiled — kernel khong dam bao */
    if (m <= 256) {
        int ndim = (trans_b == 0) ? np : k;
        return SgemmFull(a, b, c, (int)a_len, (int)b_len, (int)c_len,
                         m, np, k, ndim, trans_b, 64, 0);
    }
    long long hA = packed_create(a, NULL, (int)a_len, m, k, k, 64, 0);
    if (!hA) return -21;
    long long hB;
    if (trans_b == 0) hB = packed_create(b, NULL, (int)b_len, k, np, np, 64, 0);
    else              hB = packed_create(b, NULL, (int)b_len, np, k, k, 64, 1);
    if (!hB) { SgemmPackedFree(hA); return -22; }
    int rc = SgemmPacked(hA, hB, c, (int)c_len, 64);
    SgemmPackedFree(hA);
    SgemmPackedFree(hB);
    if (rc != 0) return -30 - rc;
    return 0;
}

/* Port _tile_a_at_w: At[r*T+t] = A_stored[(p0+t)*mdim + i0 + r], zero-fill T^2. */
static void attn_tile_a_at_w(float* out, const float* d, int mdim, int i0, int ib,
                             int p0, int pw, int T) {
    memset(out, 0, (size_t)T * (size_t)T * sizeof(float));
    for (int t = 0; t < pw; t++) {
        const float* src = d + (long long)(p0 + t) * (long long)mdim + i0;
        for (int r = 0; r < ib; r++) out[r * T + t] = src[r];
    }
}

/* Port _tile_b_w voi trans_b = 0: B luu [k x ndim], tile[i][j] = B[p0+i, r0+j]. */
static void attn_tile_b_w(float* out, const float* d, int ndim, int p0, int pw,
                          int r0, int br, int T) {
    memset(out, 0, (size_t)T * (size_t)T * sizeof(float));
    for (int i = 0; i < pw; i++) {
        const float* row = d + (long long)(p0 + i) * (long long)ndim + r0;
        memcpy(out + i * T, row, (size_t)br * sizeof(float));
    }
}

/* Port 1 GEMM trans-A cua _p58_core_simple (T=64, m=hd=64):
 * cd[hd x n] = A^T x B, A luu [k x hd], B luu [k x n]; cd PHAI duoc zero-fill
 * truoc boi caller. Tra ve 0 = OK, <0 = loi. */
static int attn_trans_a64(float* cd, const float* sa, const float* b, int hd, int n,
                          float* AtB, float* BtB, float* Ct) {
    const int T = 64;
    int k = n;                                     /* gDkT/gDvT: k = seq */
    for (int i0 = 0; i0 < hd; i0 += T) {
        int ib = hd - i0; if (ib > T) ib = T;
        for (int p0 = 0; p0 < k; p0 += T) {
            int pw = k - p0; if (pw > T) pw = T;
            attn_tile_a_at_w(AtB, sa, hd, i0, ib, p0, pw, T);
            for (int j0 = 0; j0 < n; j0 += T) {
                int jb = n - j0; if (jb > T) jb = T;
                attn_tile_b_w(BtB, b, n, p0, pw, j0, jb, T);
                SgemmF32(AtB, BtB, Ct, T);
                for (int r = 0; r < ib; r++) {
                    float* dst = cd + (long long)(i0 + r) * (long long)n + j0;
                    const float* ct = Ct + (long long)r * T;
                    for (int c = 0; c < jb; c++) dst[c] = dst[c] + ct[c];
                }
            }
        }
    }
    return 0;
}

/* flash kernel o tkv_flash_attn.c (link vao cung DLL) */
extern int FlashAttentionBwdFused(const float*, int, const float*, int, float*, int, float*, int, int, int, int, int, double);

EXPORT int AttentionBwdFused(const float* qkv, int qkv_len,
                             const float* dctx, int dctx_len,
                             float* ctxo, int ctxo_len,
                             float* dqo, int dqo_len,
                             int n, int h, int hd, int head, double inv) {
    /* Thu flash (poco online-softmax, fp32) truoc - nhanh hon duong cu
     * (khong materialize Smat n x n). rc != 0 -> duong cu NGUYEN VAN ben
     * duoi (soft-fail; loss EXACT nhu truoc). xem tkv_flash_attn.c.
     * TKV_FLASH_OFF=1 de tat dispatch nay (A/B + rollback). */
    {
        static __declspec(thread) int flash_off = -2;
        if (flash_off == -2) {
            char fb[8];
            flash_off = (GetEnvironmentVariableA("TKV_FLASH_OFF", fb, 8) > 0 && fb[0] == '1') ? 1 : 0;
        }
        if (!flash_off) {
            int rfc = FlashAttentionBwdFused(qkv, qkv_len, dctx, dctx_len,
                                             ctxo, ctxo_len, dqo, dqo_len,
                                             n, h, hd, head, inv);
            if (rfc == 0) return 0;
        }
    }
    if (!qkv || !dctx || !ctxo || !dqo) return -1;
    if (n < 64 || h <= 0 || hd != 64) return -13;               /* .tkv tiled / shape nho */
    if (head < 0 || head >= h / hd) return -2;
    long long nn = (long long)n * n;
    long long nd = (long long)n * hd;
    long long n3h = (long long)n * 3 * h;
    if ((long long)qkv_len < n3h) return -5;
    if ((long long)dctx_len < (long long)n * h) return -5;
    if ((long long)ctxo_len < nd) return -5;
    if ((long long)dqo_len < (long long)n * 3 * hd) return -5;

    float* gQ = NULL; float* gK = NULL; float* gV = NULL; float* gDc = NULL;
    float* Smat = NULL; float* gCtx = NULL; float* gDp = NULL; float* gDq = NULL;
    float* gDkT = NULL; float* gDvT = NULL;
    float* AtB = NULL; float* BtB = NULL; float* Ct = NULL;
    int rc = 0;
    int save_nested = t_nested;
    t_nested = 1;

#define ATTN_ALLOC(var, bytes)                                            \
    do { var = (float*)malloc((size_t)(bytes));                            \
         if (!var) { rc = -6; goto done; } } while (0)
    ATTN_ALLOC(gQ, nd * 4);   ATTN_ALLOC(gK, nd * 4);
    ATTN_ALLOC(gV, nd * 4);   ATTN_ALLOC(gDc, nd * 4);
    ATTN_ALLOC(Smat, nn * 4); ATTN_ALLOC(gCtx, nd * 4);
    ATTN_ALLOC(gDp, nn * 4);  ATTN_ALLOC(gDq, nd * 4);
    ATTN_ALLOC(gDkT, nd * 4); ATTN_ALLOC(gDvT, nd * 4);
    ATTN_ALLOC(AtB, 64 * 64 * 4); ATTN_ALLOC(BtB, 64 * 64 * 4); ATTN_ALLOC(Ct, 64 * 64 * 4);
#undef ATTN_ALLOC

    for (int t = 0; t < n; t++) {
        const float* qs = qkv + (long long)t * 3 * h + (long long)head * hd;
        const float* ds = dctx + (long long)t * h + (long long)head * hd;
        memcpy(gQ + (long long)t * hd, qs, hd * sizeof(float));
        memcpy(gK + (long long)t * hd, qs + h, hd * sizeof(float));
        memcpy(gV + (long long)t * hd, qs + 2 * h, hd * sizeof(float));
        memcpy(gDc + (long long)t * hd, ds, hd * sizeof(float));
    }

    /* 1) Smat = gQ x gK^T */
    rc = attn_xgemm(Smat, gQ, n, hd, gK, n, hd, hd, 1);
    if (rc != 0) goto done;
    /* 2) softmax causal fwd (in-place) */
    rc = SoftmaxCausalFwd(Smat, (int)nn, n, inv);
    if (rc != 0) goto done;
    /* 3) gCtx = Smat x gV */
    rc = attn_xgemm(gCtx, Smat, n, n, gV, n, hd, hd, 0);
    if (rc != 0) goto done;
    /* 4) gDp = gDc x gV^T */
    rc = attn_xgemm(gDp, gDc, n, hd, gV, n, hd, hd, 1);
    if (rc != 0) goto done;
    /* 5) softmax causal bwd (in-place on gDp; gDs = gDp) */
    rc = SoftmaxCausalBwd(gDp, (int)nn, Smat, (int)nn, gDc, (int)nd, gCtx, (int)nd, n, hd);
    if (rc != 0) goto done;
    /* 6) gDq = gDs x gK */
    rc = attn_xgemm(gDq, gDp, n, n, gK, n, hd, hd, 0);
    if (rc != 0) goto done;
    /* 7+8) gDkT = gQ^T x gDs | gDvT = gDc^T x Smat (trans-A, T=64) */
    memset(gDkT, 0, (size_t)nd * 4);
    rc = attn_trans_a64(gDkT, gQ, gDp, hd, n, AtB, BtB, Ct);
    if (rc != 0) goto done;
    memset(gDvT, 0, (size_t)nd * 4);
    rc = attn_trans_a64(gDvT, gDc, Smat, hd, n, AtB, BtB, Ct);
    if (rc != 0) goto done;
    /* 9) writeback packed per head (giong cac vong .tkv) */
    for (int t = 0; t < n; t++) {
        long long d0 = (long long)t * hd;
        long long p0 = (long long)t * 3 * hd;
        float* dst = dqo + p0;
        for (int d = 0; d < hd; d++) ctxo[d0 + d] = gCtx[d0 + d];
        for (int d = 0; d < hd; d++) {
            dst[d]          = (float)((double)gDq[d0 + d] * inv);
            dst[hd + d]     = (float)((double)gDkT[(long long)d * n + t] * inv);
            dst[2 * hd + d] = gDvT[(long long)d * n + t];
        }
    }
    rc = 0;

done:
    t_nested = save_nested;
    free(gQ); free(gK); free(gV); free(gDc);
    free(Smat); free(gCtx); free(gDp); free(gDq);
    free(gDkT); free(gDvT);
    free(AtB); free(BtB); free(Ct);
    return rc;
}

/* ==== YEU CAU #15 (2026-11-06): linear_dw fused (trans-A GEMM + gflat add) ====
 * gdw[gdw_off + i*out_d + c] += sum_p x[p*in_d + i] * gy[p*out_d + c]
 *   (tuong duong `dw = smm_fwd_at(x, gy, in_d, out_d, n)` roi
 *    `gflat[goff+k] = gflat[goff+k] + dw.data[k]`)
 *
 * Hai che do BIT-EXACT:
 *   mode 0 (P58): tai hien _p58_core_simple — T = min(min(roundup64(k), 1024),
 *     roundup64(min(m,n))) >= 64; SgemmF32 tren tile T; p0/i0/j0 TANG DAN;
 *     cd zero-fill dau nen dung thu tu cong cua duong cu.
 *   mode 1 (PACKED): tai hien smm_transpose + smm_fwd — pack x trans=1
 *     (packed_create, logical [in_d][n] — buffer GIONG pack tu ctxTt
 *     trans=0), pack gy trans=0, T=256; buoi cong gio giong y.
 *
 * Sau GEMM, kernel cong thang cd vao gdw (kng co vong interpreted) — moi ptu
 * 1 phep f32 add giong duong .tkv. TRA VE 0 = OK; <0 = fail -> caller
 * fallback duong cu nguyen van.
 *   -1 NULL, -2 shape <= 0, -3 mode khong ho tro, -5 buffer qua ngan,
 *   -6 gdw_off < 0 hoac het bo nho. */
static int dw_at_gemm_p58(float* cd, const float* sa, const float* b,
                          int m, int n, int k, float* AtB, float* BtB, float* Ct) {
    long long tk = (((long long)k + 63) / 64) * 64;
    if (tk > 1024) tk = 1024;
    long long rmin = (long long)(m < n ? m : n);
    long long t2 = ((rmin + 63) / 64) * 64;
    int T = (int)(tk < t2 ? tk : t2);
    if (T < 64) T = 64;
    for (int i0 = 0; i0 < m; i0 += T) {
        int ib = m - i0; if (ib > T) ib = T;
        for (int p0 = 0; p0 < k; p0 += T) {
            int pw = k - p0; if (pw > T) pw = T;
            attn_tile_a_at_w(AtB, sa, m, i0, ib, p0, pw, T);
            for (int j0 = 0; j0 < n; j0 += T) {
                int jb = n - j0; if (jb > T) jb = T;
                attn_tile_b_w(BtB, b, n, p0, pw, j0, jb, T);
                SgemmF32(AtB, BtB, Ct, T);
                for (int r = 0; r < ib; r++) {
                    float* dst = cd + (long long)(i0 + r) * (long long)n + j0;
                    const float* ct = Ct + (long long)r * T;
                    for (int c = 0; c < jb; c++) dst[c] = dst[c] + ct[c];
                }
            }
        }
    }
    return 0;
}

EXPORT int LinearDwAtFused(const float* x, int x_len, const float* gy, int gy_len,
                           float* gdw, int gdw_len, int gdw_off,
                           int n, int in_d, int out_d, int mode) {
    if (!x || !gy || !gdw) return -1;
    if (n <= 0 || in_d <= 0 || out_d <= 0) return -2;
    if (mode < 0 || mode > 1) return -3;
    if (gdw_off < 0) return -6;
    long long need_x = (long long)n * in_d;
    long long need_y = (long long)n * out_d;
    long long need_d = (long long)in_d * out_d;
    if ((long long)x_len < need_x || (long long)gy_len < need_y) return -5;
    if ((long long)gdw_len - gdw_off < need_d) return -5;

    float* cd = (float*)malloc((size_t)need_d * sizeof(float));
    if (!cd) return -6;
    memset(cd, 0, (size_t)need_d * sizeof(float));
    int rc = 0;

    if (mode == 0) {
        long long tk = (((long long)n + 63) / 64) * 64; if (tk > 1024) tk = 1024;
        long long rmin = (long long)(in_d < out_d ? in_d : out_d);
        long long t2 = ((rmin + 63) / 64) * 64;
        int T = (int)(tk < t2 ? tk : t2); if (T < 64) T = 64;
        float* AtB = (float*)malloc((size_t)T * T * sizeof(float));
        float* BtB = (float*)malloc((size_t)T * T * sizeof(float));
        float* Ct = (float*)malloc((size_t)T * T * sizeof(float));
        if (!AtB || !BtB || !Ct) { free(AtB); free(BtB); free(Ct); free(cd); return -6; }
        rc = dw_at_gemm_p58(cd, x, gy, in_d, out_d, n, AtB, BtB, Ct);
        free(AtB); free(BtB); free(Ct);
    } else {
        /* Reproduce smm_transpose + smm_fwd: materialize x^T [in_d x n] trong C
         * (pure copies - giong smm_transpose), roi CÙNG dispatch: k>=64 ->
         * m<=256 ? SgemmFull(T=256,mode=0) : packed(T=256). */
        if (n < 64) { free(cd); return -23; }
        float* xt = (float*)malloc((size_t)need_x * sizeof(float));
        if (!xt) { free(cd); return -6; }
        for (int i = 0; i < in_d; i++) {
            float* dst = xt + (long long)i * n;
            for (int j = 0; j < n; j++) dst[j] = x[(long long)j * in_d + i];
        }
        int m = in_d;
        if (m <= 256) {
            rc = SgemmFull(xt, gy, cd, (int)need_x, (int)need_y, (int)need_d,
                           m, out_d, n, out_d, 0, 256, 0);
        } else {
            long long hA = packed_create(xt, NULL, (int)need_x, m, n, n, 256, 0);
            if (hA) {
                long long hB = packed_create(gy, NULL, (int)need_y, n, out_d, out_d, 256, 0);
                if (hB) {
                    rc = SgemmPacked(hA, hB, cd, (int)need_d, 256);
                    SgemmPackedFree(hA);
                    SgemmPackedFree(hB);
                    if (rc != 0) rc = -30 - rc;
                } else { rc = -22; SgemmPackedFree(hA); }
            } else { rc = -21; }
        }
        free(xt);
    }

    if (rc == 0) {
        float* dst = gdw + gdw_off;
        for (long long i = 0; i < need_d; i++) dst[i] = dst[i] + cd[i];
    }
    free(cd);
    return rc;
}
/* ==== Tkv torch bridge: linear+bias+(gelu) fused via PyTorch ATen/oneDNN ====
 * TTkv_torch_fused.dll (wrapped ATen addmm+gelu); optional at runtime.
 * rc < 0 -> caller fallback duong cu NGUYEN VAN.
 * TKV_TORCH_PATH env = absolute path to tkv_torch_fused.dll; else search PATH.
 * TkvTorchLinearGeluFwd(x, w, bias, y, n, in_d, out_d) -> i32. */
typedef int (*tkv_lin_gelu_fn)(const float*, const float*, const float*, int64_t, int64_t, int64_t, float*);
typedef int (*tkv_lin_fn)     (const float*, const float*, const float*, int64_t, int64_t, int64_t, float*);
typedef int (*tkv_lin_bwd_fn) (const float*, const float*, const float*, float*, float*, float*, int64_t, int64_t, int64_t);
typedef int (*tkv_ln_fn)      (const float*, const float*, const float*, float*, int64_t, int64_t, double);
typedef int (*tkv_mm_t_fn)    (const float*, const float*, float*, int64_t, int64_t, int64_t);
typedef int (*tkv_sdpa_fn)    (const float*, float*, int64_t, int64_t, int64_t);
static HMODULE g_torch_fused = NULL;
static tkv_lin_gelu_fn p_lin_gelu = NULL;
static tkv_lin_fn p_lin = NULL;
static tkv_lin_bwd_fn p_lin_bwd = NULL;
static tkv_ln_fn p_ln = NULL;
static tkv_mm_t_fn p_mm_t = NULL;
static tkv_sdpa_fn p_sdpa = NULL;

static int tkv_torch_fused_load(void) {
    if (g_torch_fused) return 1;
    const char* env = getenv("TKV_TORCH_PATH");
    HMODULE h = NULL;
    HMODULE self = NULL;
    if (env && env[0]) {
        h = LoadLibraryA(env);
    } else {
        /* 1) tim tkv_torch_fused.dll canh module goi (tkv_simd_native.dll) */
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCTSTR)&tkv_torch_fused_load, &self) && self) {
            char dir[MAX_PATH] = {0};
            DWORD n = GetModuleFileNameA(self, dir, MAX_PATH);
            if (n > 0 && n < MAX_PATH) {
                char* slash = strrchr(dir, '\\');
                if (slash) {
                    strcpy(slash + 1, "tkv_torch_fused.dll");
                    /* LOAD_WITH_ALTERED_SEARCH_PATH -> dep resolve noi theo D:\\...\\out */
                    h = LoadLibraryExA(dir, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
                    if (!h) {}
                }
            }
        }
        /* 2) fallback: search PATH/CWD nhu cu */
        if (!h) h = LoadLibraryA("tkv_torch_fused.dll");
    }
    if (!h) return 0;
    p_lin_gelu = (tkv_lin_gelu_fn)GetProcAddress(h, "TkvTorchLinearGeluFwd");
    if (!p_lin_gelu) { FreeLibrary(h); return 0; }
    p_lin = (tkv_lin_fn)GetProcAddress(h, "TkvTorchLinearFwd");
    if (!p_lin) { FreeLibrary(h); return 0; }
    p_lin_bwd = (tkv_lin_bwd_fn)GetProcAddress(h, "TkvTorchLinearBwdFwd");
    if (!p_lin_bwd) { FreeLibrary(h); return 0; }
    /* optional new exports (LN/MM_T/SDPA) — older bridge without them: fallback -9 */
    p_ln = (tkv_ln_fn)GetProcAddress(h, "TkvTorchLayerNormFwd");
    p_mm_t = (tkv_mm_t_fn)GetProcAddress(h, "TkvTorchMmT");
    p_sdpa = (tkv_sdpa_fn)GetProcAddress(h, "TkvTorchSdpa");
    g_torch_fused = h;
    return 1;
}

EXPORT int TkvTorchLinearGeluFwd(const float* x, const float* w, const float* bias,
                                 float* y, int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !bias || !y) return -1;
    if (!tkv_torch_fused_load()) return -9;
    return p_lin_gelu(x, w, bias, n, in_d, out_d, y);
}

EXPORT int TkvTorchLinearFwd(const float* x, const float* w, const float* bias,
                             float* y, int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !bias || !y) return -1;
    if (!tkv_torch_fused_load()) return -9;
    return p_lin(x, w, bias, n, in_d, out_d, y);
}

EXPORT int TkvTorchLinearBwdFwd(const float* x, const float* gy, const float* w,
                                 float* dx, float* dw, float* db,
                                 int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !gy || !w || !dx || !dw || !db) return -1;
    if (!tkv_torch_fused_load()) return -9;
    return p_lin_bwd(x, gy, w, dx, dw, db, n, in_d, out_d);
}

/* ==== Tkv torch bridge: LN/SDPA/MmT (ATen same-kernel parity route §0.105) ====
 * Cung load lazy nhu tren; vang export (bridge cu) -> -9 -> caller fallback. */
EXPORT int TkvTorchLayerNormFwd(const float* x, const float* g, const float* b,
                                float* y, int64_t n, int64_t h, double eps) {
    if (!x || !g || !b || !y) return -1;
    if (!tkv_torch_fused_load()) return -9;
    if (!p_ln) return -9;
    return p_ln(x, g, b, y, n, h, eps);
}

EXPORT int TkvTorchMmT(const float* x, const float* w, float* y,
                       int64_t n, int64_t in_d, int64_t out_d) {
    if (!x || !w || !y) return -1;
    if (!tkv_torch_fused_load()) return -9;
    if (!p_mm_t) return -9;
    return p_mm_t(x, w, y, n, in_d, out_d);
}

EXPORT int TkvTorchSdpa(const float* qkv, float* y, int64_t n,
                        int64_t nheads, int64_t hd) {
    if (!qkv || !y) return -1;
    if (!tkv_torch_fused_load()) return -9;
    if (!p_sdpa) return -9;
    return p_sdpa(qkv, y, n, nheads, hd);
}
