/* tkv_cuda_native.c — GPU path for the hot kernel (SgemmF32) via cuBLAS.
 * Lazy-loads libcublas/cudart; does NOT link against CUDA at compile time
 * (works on a machine without CUDA toolkit installed; CPU fallback stays).
 *
 * Exports (same pattern as tkv_simd_native):
 *   TkvCUDA_Available() -> int  1 = GPU+cuBLAS ready, 0 = không có
 *   TkvCUDA_SgemmF32(a, b, o, n) -> int  1 = ran on GPU, 0 = không dùng được
 *
 * SgemmF32 itself checks TkvCUDA_SgemmF32 first; fallback = existing AVX2 path.
 */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

#ifdef _WIN32
  #include <windows.h>
  #include <winapifamily.h>
  #define EXPORT __declspec(dllexport)
  #define LOAD_LIB(name) LoadLibraryA(name)
  #define LOAD_SYM(mod, name) (void*)GetProcAddress((HMODULE)(mod), name)
  #define UNLOAD_LIB(mod) FreeLibrary((HMODULE)(mod))
#else
  #include <dlfcn.h>
  #define EXPORT __attribute__((visibility("default")))
  #define LOAD_LIB(name) dlopen(name, RTLD_LAZY | RTLD_LOCAL)
  #define LOAD_SYM(mod, name) dlsym(mod, name)
  #define UNLOAD_LIB(mod) dlclose(mod)
#endif

typedef int cublasStatus_t;
typedef void* cublasHandle_t;
typedef enum { CUBLAS_OP_N = 0, CUBLAS_OP_T = 1, CUBLAS_OP_C = 2 } cublasOperation_t;
typedef int cudaError_t;

typedef int (*PFN_cublasCreate)(cublasHandle_t*);
typedef int (*PFN_cublasSgemm)(cublasHandle_t, cublasOperation_t, cublasOperation_t,
                              int, int, int, const float*, const float*, int,
                              const float*, int, const float*, float*, int);
typedef int (*PFN_cublasDestroy)(cublasHandle_t);
typedef int (*PFN_cudaMalloc)(void**, size_t);
typedef int (*PFN_cudaFree)(void*);
typedef int (*PFN_cudaMemcpy)(void*, const void*, size_t, int);
typedef int (*PFN_cudaSetDevice)(int);

#define cudaMemcpyHostToDevice   1
#define cudaMemcpyDeviceToHost   2

static PFN_cublasCreate  p_create;
static PFN_cublasSgemm   p_sgemm;
static PFN_cublasDestroy p_destroy;
static PFN_cudaMalloc    p_cudamalloc;
static PFN_cudaFree      p_cudafree;
static PFN_cudaMemcpy    p_cudamemcpy;
static PFN_cudaSetDevice p_setdevice;

static cublasHandle_t g_handle = 0;
static int g_state = -1; /* -1: uninit | 0: không dùng được | 1: ready */

static const char* const cublas_names[] = {
#ifdef _WIN32
    "cublas64_12.dll", "cublas64_11.dll",
#else
    "libcublas.so.12", "libcublas.so.11", "libcublas.so.cu12", "libcublas.so",
#endif
    0
};
static const char* const cudart_names[] = {
#ifdef _WIN32
    "cudart64_120.dll", "cudart64_110.dll",
#else
    "libcudart.so.12", "libcudart.so.11", "libcudart.so.cu12", "libcudart.so",
#endif
    0
};

static void* load_first(const char* const* names) {
    for (int i = 0; names[i]; i++) {
        void* h = LOAD_LIB(names[i]);
        if (h) return h;
    }
    return 0;
}

static int cuda_init(void) {
    if (g_state != -1) return g_state;
    void* h_cublas = load_first(cublas_names);
    void* h_cudart = load_first(cudart_names);
    if (!h_cublas || !h_cudart) { g_state = 0; return 0; }

    p_create     = (PFN_cublasCreate)    (LOAD_SYM(h_cublas, "cublasCreate_v2") ? LOAD_SYM(h_cublas, "cublasCreate_v2") : LOAD_SYM(h_cublas, "cublasCreate"));
    p_sgemm      = (PFN_cublasSgemm)     LOAD_SYM(h_cublas, "cublasSgemm_v2");
    p_destroy    = (PFN_cublasDestroy)   (LOAD_SYM(h_cublas, "cublasDestroy_v2") ? LOAD_SYM(h_cublas, "cublasDestroy_v2") : LOAD_SYM(h_cublas, "cublasDestroy"));
    p_cudamalloc = (PFN_cudaMalloc)      LOAD_SYM(h_cudart, "cudaMalloc");
    p_cudafree   = (PFN_cudaFree)        LOAD_SYM(h_cudart, "cudaFree");
    p_cudamemcpy = (PFN_cudaMemcpy)      LOAD_SYM(h_cudart, "cudaMemcpy");
    p_setdevice  = (PFN_cudaSetDevice)   LOAD_SYM(h_cudart, "cudaSetDevice");

    if (!p_create || !p_sgemm || !p_destroy || !p_cudamalloc || !p_cudafree || !p_cudamemcpy) {
        g_state = 0;
        return 0;
    }
    if (p_setdevice) p_setdevice(0);
    if (p_create(&g_handle) != 0) { g_state = 0; return 0; }
    g_state = 1;
    return 1;
}

EXPORT int TkvCUDA_Available(void) {
    return cuda_init();
}

EXPORT int TkvCUDA_SgemmF32(const float* a, const float* b, float* o, int n) {
    if (cuda_init() != 1) return 0;
    if (n < 512) return 0; /* small: CPU AVX2 wins; also avoids PCIe overhead */

    const float alpha = 1.0f, beta = 0.0f;
    const size_t bytes = (size_t)n * (size_t)n * sizeof(float);
    float* d_a = 0, * d_b = 0, * d_o = 0;
    if (p_cudamalloc((void**)&d_a, bytes) != 0) return 0;
    if (p_cudamalloc((void**)&d_b, bytes) != 0) { p_cudafree(d_a); return 0; }
    if (p_cudamalloc((void**)&d_o, bytes) != 0) { p_cudafree(d_a); p_cudafree(d_b); return 0; }

    if (p_cudamemcpy(d_a, a, bytes, cudaMemcpyHostToDevice) != 0) goto fail;
    if (p_cudamemcpy(d_b, b, bytes, cudaMemcpyHostToDevice) != 0) goto fail;

    /* row-major C = A*B  <=>  col-major C' = B^T * A^T */
    if (p_sgemm(g_handle, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n,
                &alpha, d_b, n, d_a, n, &beta, d_o, n) != 0) goto fail;

    if (p_cudamemcpy(o, d_o, bytes, cudaMemcpyDeviceToHost) != 0) goto fail;

    p_cudafree(d_a); p_cudafree(d_b); p_cudafree(d_o);
    return 1;

fail:
    if (d_a) p_cudafree(d_a);
    if (d_b) p_cudafree(d_b);
    if (d_o) p_cudafree(d_o);
    return 0;
}

/* ---- P1 (2026-11-13): GEMM chu nhat ROW-MAJOR ti cuBLAS ------------------
 * Dung cho cac loi goi FULL GEMM (SgemmFull/SgemmPacked/LinearDxFused/
 * LinearDwAtFused), KHONG dung cho tile ben trong vong lap. Goi tu
 * tkv_simd_native.c khi TKV_GEMM_CUDA=1.
 *
 * Row-major C = opA(A)·opB(B)  <=>  col-major C^T = opB(B)·opA(A)^T
 * (1 hang cua buffer row-major chinh la 1 cot cua ma tran col-major tuong ung,
 * chi can truyen lda/ldb/ldc NGUYEN GIA TRI).
 *
 * transA/transB: 111 = NoTrans, 112 = Trans (cblas convention cua engine).
 * accumulate:    1 => beta = 1.0 (dW cong don vao C -> H2D copy C truoc);
 *                0 => beta = 0.0.
 * Tra ve 1 = da chay tren GPU, 0 = nen fallback (CUDA thieu / shape nho / loi).
 *
 * Cac call tu worker thread DIFFERENT matrices -> mutex quay quanh toan bo
 * lo goi; GEMM la nút co chai nen xep hang CPU con hon. */
static float *g_da_buf = 0, *g_db_buf = 0, *g_dc_buf = 0;
static size_t g_da_sz = 0, g_db_sz = 0, g_dc_sz = 0;
#if defined(_WIN32)
static CRITICAL_SECTION g_cuda_mu;
static volatile LONG g_cuda_mu_init = 0;
static void cuda_lock(void) {
    if (InterlockedCompareExchange(&g_cuda_mu_init, 1, 0) == 0) InitializeCriticalSection(&g_cuda_mu);
    EnterCriticalSection(&g_cuda_mu);
}
static void cuda_unlock(void) { LeaveCriticalSection(&g_cuda_mu); }
#else
#include <pthread.h>
static pthread_mutex_t g_cuda_mu = PTHREAD_MUTEX_INITIALIZER;
static void cuda_lock(void) { pthread_mutex_lock(&g_cuda_mu); }
static void cuda_unlock(void) { pthread_mutex_unlock(&g_cuda_mu); }
#endif

/* ---- P2-lite (2026-11-13): weight-B cache tren GPU -------------------------
 * Cac ma tran WEIGHT (khong doi giua 2 lan cap nhat) duoc upload 1 lan moi
 * "epoch" va giu tren GPU; epoch tang moi lan AdamW chay (weights bi cap nhat).
 *
 * DIEU KIEN AN TOAN (kiem o nhanh trong TkvCUDA_RectF32):
 *   transA == NoTrans (A la ACTIVATION) va accumulate == 0.
 *   Khi do B trong toan bo cac GEMM day cua engine la WEIGHT cua Linear/fc/
 *   lmhead. Cach cau hinh con lai deu dung transA=112 hoac beta=1 (dW).
 *   Neu suy doan SAI -> ket qua SAI; gate 1e-5 se bat (loss lenh ro). */
static unsigned long long g_wdirty = 1;
EXPORT void TkvCUDA_MarkWeightsDirty(void) { g_wdirty++; }
#define TKV_WCACHE_MAX 96
typedef struct { const float* ptr; float* dev; size_t bytes; unsigned long long epoch; } TkvWEntry;
static TkvWEntry g_wc[TKV_WCACHE_MAX];

static int wcache_get(const float* b, size_t bytes, float** dev) {
    for (int i = 0; i < TKV_WCACHE_MAX; i++)
        if (g_wc[i].dev && g_wc[i].epoch == g_wdirty && g_wc[i].ptr == b && g_wc[i].bytes == bytes) {
            *dev = g_wc[i].dev;
            return 1;
        }
    return 0;
}
/* Cache B len device. Tra ve 1 = da co/da nap xong, 0 = khong cache duoc
 * (day hoac loi alloc) -> caller dung duong copy thong thuong. */
static int wcache_put(const float* b, size_t bytes, const float* hostB, float** dev) {
    int idx = -1;
    for (int i = 0; i < TKV_WCACHE_MAX; i++)
        if (g_wc[i].dev == 0 || g_wc[i].epoch != g_wdirty) { idx = i; break; }
    if (idx < 0) return 0;
    if (g_wc[idx].dev) { p_cudafree(g_wc[idx].dev); g_wc[idx].dev = 0; }
    if (p_cudamalloc((void**)&g_wc[idx].dev, bytes) != 0) return 0;
    if (p_cudamemcpy(g_wc[idx].dev, hostB, bytes, cudaMemcpyHostToDevice) != 0) {
        p_cudafree(g_wc[idx].dev); g_wc[idx].dev = 0; return 0;
    }
    g_wc[idx].ptr = b; g_wc[idx].bytes = bytes; g_wc[idx].epoch = g_wdirty;
    *dev = g_wc[idx].dev;
    return 1;
}

static int buf_get(float** p, size_t* sz, size_t need) {
    if (*sz >= need) return 1;
    if (*p) p_cudafree(*p);
    *p = 0; *sz = 0;
    if (p_cudamalloc((void**)p, need) != 0) return 0;
    *sz = need;
    return 1;
}

EXPORT int TkvCUDA_RectF32(const float* a, int lda, const float* b, int ldb,
                           float* c, int ldc, int m, int n, int k,
                           int transA, int transB, int accumulate) {
    if (cuda_init() != 1) return 0;
    if (!a || !b || !c || m <= 0 || n <= 0 || k <= 0) return 0;
    /* Nho qua -> overhead PCIe > cai duoc GPU. */
    if ((long long)m * (long long)n < 65536) return 0;

    const int opA = (transA == 112) ? 1 /*CUBLAS_OP_T*/ : 0 /*CUBLAS_OP_N*/;
    const int opB = (transB == 112) ? 1 : 0;
    const size_t sz_a = (size_t)lda * (size_t)(opA ? k : m) * sizeof(float);
    const size_t sz_b = (size_t)ldb * (size_t)(opB ? n : k) * sizeof(float);
    const size_t sz_c = (size_t)ldc * (size_t)m * sizeof(float);
    const float alpha = 1.0f, beta = accumulate ? 1.0f : 0.0f;

    cuda_lock();
    int ok = 0;
    float* b_dev = 0;
    const int B_weight = (transA != 112 && !accumulate);   /* A=activation -> B=weight */
    int use_cached_B = 0;

    if (!buf_get(&g_da_buf, &g_da_sz, sz_a)) goto out;
    if (!buf_get(&g_dc_buf, &g_dc_sz, sz_c)) goto out;
    if (p_cudamemcpy(g_da_buf, a, sz_a, cudaMemcpyHostToDevice) != 0) goto out;
    if (accumulate && p_cudamemcpy(g_dc_buf, c, sz_c, cudaMemcpyHostToDevice) != 0) goto out;

    if (B_weight && (wcache_get(b, sz_b, &b_dev) || wcache_put(b, sz_b, b, &b_dev))) {
        use_cached_B = 1;
    } else if (!buf_get(&g_db_buf, &g_db_sz, sz_b)) goto out;
    if (!use_cached_B && p_cudamemcpy(g_db_buf, b, sz_b, cudaMemcpyHostToDevice) != 0) goto out;
    if (!use_cached_B) b_dev = g_db_buf;

    /* C^T = P·Q voi P = opB(B)·read(b), Q = opA(A)^T; dims n x m x k */
    if (p_sgemm(g_handle, (cublasOperation_t)opB, (cublasOperation_t)opA,
                n, m, k, &alpha, b_dev, ldb, g_da_buf, lda, &beta, g_dc_buf, ldc) != 0) goto out;

    if (p_cudamemcpy(c, g_dc_buf, sz_c, cudaMemcpyDeviceToHost) != 0) goto out;
    ok = 1;
out:
    cuda_unlock();
    return ok;
}

EXPORT void TkvCUDA_Shutdown(void) {
    if (g_handle && p_destroy) p_destroy(g_handle);
    g_handle = 0;
    g_state = -1;
}
