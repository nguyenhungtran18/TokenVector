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

EXPORT void TkvCUDA_Shutdown(void) {
    if (g_handle && p_destroy) p_destroy(g_handle);
    g_handle = 0;
    g_state = -1;
}
