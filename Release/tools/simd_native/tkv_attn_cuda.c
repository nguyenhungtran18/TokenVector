/* tkv_attn_cuda.c — GLOBAL causal attention qua cuBLAS + softmax fp32 (CPU)
 * cho TokenVector.Inference. TKV_ATTN_CUDA=1 (mac dinh 0) -> fwd/bwd cua moi head
 * chay: Sgemm (S=QK^T, O=PV, dV, dP, dQ, dK) tren GPU + scale/mask/softmax tren CPU
 * AVX2. Giai thuat: full attention (khong flash-tiled) — n <= 1024.
 *
 * Fallback: tra 0 (fallback flash AVX2 trong tkv_flash_attn.c / tkv_simd_native.c).
 *
 * Layout (row-major):
 *   qkv  [n][3*h]   Q tai [*, 0  .. h), K tai [*, h  .. 2h), V tai [*, 2h .. 3h),
 *                     head h_i nam tai offset head*hd trong moi phan.
 *   ctx_out [n][h]  moi head ghi tai  offset head*hd, pitch h.
 *   dctx (dO) [n][h]  giong ctx_out (gradient cua output).
 *   dqo  [n][3*hd]   moi head ghi packed [dQ | dK | dV] tai offset 3*hd*head.
 *   dp  [n][n]       intermediate (device).
 *   dot [n]          per-row sum es rowsum(P*dP) — intermediate.
 *
 * Cum device buffers giu cho tung thread (__thread) -> 12 worker song song khong
 * tranh. head_mask: n >= 1.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#ifdef _WIN32
  #include <windows.h>
  #define EXPORT __declspec(dllexport)
#else
  #include <dlfcn.h>
  #include <immintrin.h>
  #include "tkv_gelu_avx2.h"   /* tkv_exp_ps: vector exp fp32 */
  #define EXPORT __attribute__((visibility("default")))
#endif

#define TKV_MAX_N 1024
#define FL_HD     64

typedef int cublasStatus_t;
typedef void* cublasHandle_t;
typedef enum { CUBLAS_OP_N = 0, CUBLAS_OP_T = 1 } cublasOperation_t;

typedef int (*PFN_cublasCreate)(cublasHandle_t*);
typedef int (*PFN_cublasSgemm)(cublasHandle_t, cublasOperation_t, cublasOperation_t,
                              int, int, int, const float*, const float*, int,
                              const float*, int, const float*, float*, int);
typedef int (*PFN_cublasDestroy)(cublasHandle_t);
typedef int (*PFN_cudaMalloc)(void**, size_t);
typedef int (*PFN_cudaFree)(void*);
typedef int (*PFN_cudaMemcpy)(void*, const void*, size_t, int);
typedef int (*PFN_cudaMemcpy2D)(void*, size_t, const void*, size_t, size_t, size_t, int);
typedef int (*PFN_cudaSetDevice)(int);

#define cudaMemcpyHostToDevice   1
#define cudaMemcpyDeviceToHost   2

static PFN_cublasCreate  p_create;
static PFN_cublasSgemm   p_sgemm;
static PFN_cublasDestroy p_destroy;
static PFN_cudaMalloc    p_cudamalloc;
static PFN_cudaFree      p_cudafree;
static PFN_cudaMemcpy    p_cudamemcpy;
static PFN_cudaMemcpy2D  p_cudamemcpy2d;
static PFN_cudaSetDevice p_setdevice;
static cublasHandle_t g_handle_attn = 0;

static int cuda_init_attn(void) {
    static int st = -1;
    if (st != -1) return st;
#ifdef _WIN32
    void* hb = LoadLibraryA("cublas64_12.dll");
    if (!hb) hb = LoadLibraryA("cublas64_11.dll");
    void* hd = LoadLibraryA("cudart64_120.dll");
    if (!hd) hd = LoadLibraryA("cudart64_110.dll");
    if (!hb || !hd) { st = 0; return 0; }
    p_create     = (PFN_cublasCreate)  GetProcAddress((HMODULE)hb, "cublasCreate_v2");
    p_sgemm      = (PFN_cublasSgemm)   GetProcAddress((HMODULE)hb, "cublasSgemm_v2");
    p_destroy    = (PFN_cublasDestroy) GetProcAddress((HMODULE)hb, "cublasDestroy_v2");
    p_cudamalloc = (PFN_cudaMalloc)    GetProcAddress((HMODULE)hd, "cudaMalloc");
    p_cudafree   = (PFN_cudaFree)      GetProcAddress((HMODULE)hd, "cudaFree");
    p_cudamemcpy = (PFN_cudaMemcpy)    GetProcAddress((HMODULE)hd, "cudaMemcpy");
    p_cudamemcpy2d = (PFN_cudaMemcpy2D) GetProcAddress((HMODULE)hd, "cudaMemcpy2D");
    p_setdevice  = (PFN_cudaSetDevice) GetProcAddress((HMODULE)hd, "cudaSetDevice");
#else
    void* hb = dlopen("libcublas.so.12", RTLD_LAZY | RTLD_LOCAL);
    if (!hb) hb = dlopen("libcublas.so.11", RTLD_LAZY | RTLD_LOCAL);
    void* hd = dlopen("libcudart.so.12", RTLD_LAZY | RTLD_LOCAL);
    if (!hd) hd = dlopen("libcudart.so.11", RTLD_LAZY | RTLD_LOCAL);
    if (!hb || !hd) { st = 0; return 0; }
    p_create     = (PFN_cublasCreate)  dlsym(hb, "cublasCreate_v2");
    p_sgemm      = (PFN_cublasSgemm)   dlsym(hb, "cublasSgemm_v2");
    p_destroy    = (PFN_cublasDestroy) dlsym(hb, "cublasDestroy_v2");
    p_cudamalloc = (PFN_cudaMalloc)    dlsym(hd, "cudaMalloc");
    p_cudafree   = (PFN_cudaFree)      dlsym(hd, "cudaFree");
    p_cudamemcpy = (PFN_cudaMemcpy)    dlsym(hd, "cudaMemcpy");
    p_cudamemcpy2d = (PFN_cudaMemcpy2D) dlsym(hd, "cudaMemcpy2D");
    p_setdevice  = (PFN_cudaSetDevice) dlsym(hd, "cudaSetDevice");
#endif
    if (!p_create || !p_sgemm || !p_cudamalloc || !p_cudamemcpy || !p_cudamemcpy2d) { st = 0; return 0; }
    if (p_setdevice) p_setdevice(0);
    cublasHandle_t h = 0;
    if (p_create(&h) != 0) { st = 0; return 0; }
    (void)p_destroy;
    g_handle_attn = h;
    st = 1;
    return 1;
}

static int attn_on(void) {
    static int on = -1;
    if (on < 0) {
        const char* s = getenv("TKV_ATTN_CUDA");
        on = (s && s[0] && s[0] != '0') ? 1 : 0;
    }
    return on == 1 && cuda_init_attn() == 1;
}

/* 12 head chay trong 12 worker; cublasHandle_t DUNG CHUNG pick khong an toan
 * -> mutex serialize toan bo attention CUDA (GEMMs ~µs, khong mat hieu qua). */
#ifdef _WIN32
static CRITICAL_SECTION g_attn_mu;
static volatile LONG g_attn_mu_init = 0;
static void attn_lock(void) {
    if (InterlockedCompareExchange(&g_attn_mu_init, 1, 0) == 0) InitializeCriticalSection(&g_attn_mu);
    EnterCriticalSection(&g_attn_mu);
}
static void attn_unlock(void) { LeaveCriticalSection(&g_attn_mu); }
#else
#include <pthread.h>
static pthread_mutex_t g_attn_mu = PTHREAD_MUTEX_INITIALIZER;
static void attn_lock(void) { pthread_mutex_lock(&g_attn_mu); }
static void attn_unlock(void) { pthread_mutex_unlock(&g_attn_mu); }
#endif

/* Per-thread buffer set */
typedef struct {
    float *d_q, *d_k, *d_v, *d_s, *d_p, *d_do, *d_dp, *d_o, *d_tmp, *d_tmp2;
} TkvAttnBuf;
static __thread TkvAttnBuf* g_buf = NULL;
static inline TkvAttnBuf* attn_buf(void) {
    if (!g_buf) {
        g_buf = (TkvAttnBuf*)calloc(1, sizeof(TkvAttnBuf));
        if (!g_buf) return NULL;
        TkvAttnBuf* b = g_buf;
        size_t qb = (size_t)TKV_MAX_N * FL_HD * sizeof(float);
        size_t sb = (size_t)TKV_MAX_N * TKV_MAX_N * sizeof(float);
        if (p_cudamalloc((void**)&b->d_q, qb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_k, qb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_v, qb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_s, sb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_p, sb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_do, qb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_dp, sb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_o, qb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_tmp, sb) != 0) goto fail;
        if (p_cudamalloc((void**)&b->d_tmp2, sb) != 0) goto fail;
    }
    return g_buf;
fail:
    return NULL;
}

/* Row-major C = A*B with optional transposes via double-transpose to col-major.
 * C is filled row-major into dest (ldc*m floats). */
static int attn_gemm(cublasHandle_t hdl, float* a, int lda, float* b, int ldb, float* c, int ldc,
                     int m, int n, int k, int tA, int tB) {
    const float alpha = 1.0f, beta = 0.0f;
    int opA = (tA == 112) ? CUBLAS_OP_T : CUBLAS_OP_N;
    int opB = (tB == 112) ? CUBLAS_OP_T : CUBLAS_OP_N;
    /* C^T = opB(B).opA(A)^T ; dims col-major (n x m x k) */
    return p_sgemm(hdl, (cublasOperation_t)opB, (cublasOperation_t)opA, n, m, k,
                   &alpha, b, ldb, a, lda, &beta, c, ldc);
}

/* striding qkv slice [n x OO] at offset off: co? one 2D memcpy */
static int copy_slice(void* dst, size_t dpitch_bytes,
                      const float* src, size_t spitch_elems, int offset_elems, int n) {
    size_t width = FL_HD * sizeof(float);
    const unsigned char* p = (const unsigned char*)src + (size_t)offset_elems * sizeof(float);
    return p_cudamemcpy2d(dst, dpitch_bytes, p, spitch_elems * sizeof(float), width, (size_t)n, cudaMemcpyHostToDevice);
}

static void cpu_smax_rows(float* a, int n) {
    /* a: [n][n] row-major, causal: row i uses cols 0..i; cols > i are -inf (set 0 here) */
    for (int i = 0; i < n; i++) {
        float* row = a + (size_t)i * n;
        int lim = i;
        float mx = row[0];
        for (int j = 1; j <= lim; j++) if (row[j] > mx) mx = row[j];
        float sum = 0.0f;
        int j = 0;
        for (; j + 8 <= lim + 1; j += 8) {
#ifdef _WIN32
            for (int k = 0; k < 8; k++) { float e = expf(row[j + k] - mx); row[j + k] = e; sum += e; }
#else
            __m256 v = _mm256_loadu_ps(row + j);
            __m256 e = tkv_exp_ps(_mm256_sub_ps(v, _mm256_set1_ps(mx)));
            _mm256_storeu_ps(row + j, e);
            __m128 lo4 = _mm256_castps256_ps128(e);
            __m128 hi4 = _mm256_extractf128_ps(e, 1);
            __m128 s4 = _mm_add_ps(lo4, hi4);
            s4 = _mm_hadd_ps(s4, s4);
            s4 = _mm_hadd_ps(s4, s4);
            sum += _mm_cvtss_f32(s4);
#endif
        }
        for (; j <= lim; j++) { float e = expf(row[j] - mx); row[j] = e; sum += e; }
        for (j = lim + 1; j < n; j++) row[j] = 0.0f;
        float inv = 1.0f / sum;
        for (j = 0; j < n; j++) row[j] *= inv;
    }
}

static void cpu_ds_rows(float* P, float* dP, float* dot, int n) {
    /* dS = P * (dP - dot[i]); dot[i] = sum_u P[i,u]*dP[i,u] */
    for (int i = 0; i < n; i++) {
        float* p = P + (size_t)i * n;
        float* dp = dP + (size_t)i * n;
        float s = 0.0f;
        for (int j = 0; j <= i; j++) s += p[j] * dp[j];
        dot[i] = s;
        for (int j = 0; j <= i; j++) dp[j] = p[j] * (dp[j] - s);
        for (int j = i + 1; j < n; j++) dp[j] = 0.0f;
    }
}

/* fwd: out head=ctx_out + head*hd (strided write). */
static int attn_fwd_head_impl(const float* qkv, float* ctx_out, int n, int h, int hd, int head, double inv) {
    TkvAttnBuf* b = attn_buf();
    if (!b) return -2;
    const int stride3 = 3 * h;
    float* dqkv = (float*)qkv;
    cublasHandle_t hdl = g_handle_attn;
    (void)hd;
    /* copy Q,K,V slices (device) */
    if (copy_slice(b->d_q, FL_HD * 4, dqkv, stride3, head * FL_HD, n) != 0) return -3;
    if (copy_slice(b->d_k, FL_HD * 4, dqkv, stride3, h + head * FL_HD, n) != 0) return -3;
    if (copy_slice(b->d_v, FL_HD * 4, dqkv, stride3, 2 * h + head * FL_HD, n) != 0) return -3;

    /* S = Q K^T * inv — do scale here on host to keep cuBLAS simple: scale on host later */
    if (attn_gemm(hdl, b->d_q, FL_HD, b->d_k, FL_HD, b->d_s, n, n, n, FL_HD, 111, 112) != 0) return -4;
    /* D2H S -> scale/mask/softmax -> H2D */
    float* hbuf = (float*)malloc((size_t)n * n * sizeof(float));
    if (!hbuf) return -5;
    if (p_cudamemcpy(hbuf, b->d_s, (size_t)n * n * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(hbuf); return -6; }
    /* scale by inv */
    {
        float invf = (float)inv;
        int i = 0;
        for (; i + 8 <= n * n; i += 8) {
            __m256 v = _mm256_loadu_ps(hbuf + i);
            _mm256_storeu_ps(hbuf + i, _mm256_mul_ps(v, _mm256_set1_ps(invf)));
        }
        for (; i < n * n; i++) hbuf[i] *= invf;
    }
    cpu_smax_rows(hbuf, n);
    if (p_cudamemcpy(b->d_p, hbuf, (size_t)n * n * sizeof(float), cudaMemcpyHostToDevice) != 0) { free(hbuf); return -7; }
    free(hbuf);
    /* O = P V */
    if (attn_gemm(hdl, b->d_p, n, b->d_v, FL_HD, b->d_o, FL_HD, n, n, FL_HD, 111, 111) != 0) return -8;
    /* D2H O -> write strided */
    float* oh = (float*)malloc((size_t)n * FL_HD * sizeof(float));
    if (!oh) return -9;
    if (p_cudamemcpy(oh, b->d_o, (size_t)n * FL_HD * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(oh); return -10; }
    for (int t = 0; t < n; t++) memcpy(ctx_out + (size_t)t * FL_HD, oh + (size_t)t * FL_HD, FL_HD * sizeof(float));
    free(oh);
    return 0;
}

static int attn_bwd_head_impl(const float* qkv, const float* dctx, const float* /*ctx_in*/,
                              float* ctxo, float* dqo, int n, int h, int hd, int head, double inv) {
    TkvAttnBuf* b = attn_buf();
    if (!b) return -2;
    const int stride3 = 3 * h;
    const float* dqkv = qkv;
    cublasHandle_t hdl = g_handle_attn;
    float invf = (float)inv;
    if (copy_slice(b->d_q, FL_HD * 4, dqkv, stride3, head * FL_HD, n) != 0) return -3;
    if (copy_slice(b->d_k, FL_HD * 4, dqkv, stride3, h + head * FL_HD, n) != 0) return -3;
    if (copy_slice(b->d_v, FL_HD * 4, dqkv, stride3, 2 * h + head * FL_HD, n) != 0) return -3;
    if (copy_slice(b->d_do, FL_HD * 4, dctx, h, head * FL_HD, n) != 0) return -3;

    /* Recompute P = softmax(Q K^T * inv) */
    if (attn_gemm(hdl, b->d_q, FL_HD, b->d_k, FL_HD, b->d_s, n, n, n, FL_HD, 111, 112) != 0) return -4;
    float* hbuf = (float*)malloc((size_t)n * n * sizeof(float));
    if (!hbuf) return -5;
    if (p_cudamemcpy(hbuf, b->d_s, (size_t)n * n * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(hbuf); return -6; }
    {
        int i = 0;
        for (; i + 8 <= n * n; i += 8) {
            __m256 v = _mm256_loadu_ps(hbuf + i);
            _mm256_storeu_ps(hbuf + i, _mm256_mul_ps(v, _mm256_set1_ps(invf)));
        }
        for (; i < n * n; i++) hbuf[i] *= invf;
    }
    cpu_smax_rows(hbuf, n);   /* hbuf holds P (lower-tri) */
    float* P = hbuf;
    if (p_cudamemcpy(b->d_p, P, (size_t)n * n * sizeof(float), cudaMemcpyHostToDevice) != 0) { free(P); return -7; }

    /* dV = P^T @ dO */
    if (attn_gemm(hdl, b->d_p, n, b->d_do, FL_HD, b->d_o, FL_HD, hd, n, hd, 112, 111) != 0) { free(P); return -8; }
    float* dv = (float*)malloc((size_t)n * FL_HD * sizeof(float));
    if (!dv) { free(P); return -9; }
    if (p_cudamemcpy(dv, b->d_o, (size_t)n * FL_HD * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(dv); free(P); return -10; }

    /* dP = dO @ V^T */
    if (attn_gemm(hdl, b->d_do, FL_HD, b->d_v, FL_HD, b->d_dp, n, n, n, FL_HD, 111, 112) != 0) { free(dv); free(P); return -11; }
    float* dP = (float*)malloc((size_t)n * n * sizeof(float));
    if (!dP) { free(dv); free(P); return -12; }
    if (p_cudamemcpy(dP, b->d_dp, (size_t)n * n * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(dv); free(P); free(dP); return -13; }

    /* dS = P ∘ (dP - dot) with dot = rowsum(P∘dP); dP ← dS (in-place semantics) */
    float* dot = (float*)malloc((size_t)n * sizeof(float));
    if (!dot) { free(dv); free(P); free(dP); return -14; }
    cpu_ds_rows(P, dP, dot, n);

    /* scale dS by inv (fold into dQ/dK) */
    float* dS = dP;
    if (p_cudamemcpy(b->d_dp, dS, (size_t)n * n * sizeof(float), cudaMemcpyHostToDevice) != 0) { free(dv); free(P); free(dS); free(dot); return -15; }

    /* dQ = dS @ K * inv */
    if (attn_gemm(hdl, b->d_dp, n, b->d_k, FL_HD, b->d_o, FL_HD, n, FL_HD, n, 111, 111) != 0) { free(dv); free(P); free(dS); free(dot); return -16; }
    float* dq = (float*)malloc((size_t)n * FL_HD * sizeof(float));
    if (!dq) { free(dv); free(P); free(dS); free(dot); return -17; }
    if (p_cudamemcpy(dq, b->d_o, (size_t)n * FL_HD * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(dv); free(P); free(dS); free(dot); free(dq); return -18; }
    {   /* scale by inv */
        int i = 0;
        for (; i + 8 <= n * FL_HD; i += 8) {
            __m256 v = _mm256_loadu_ps(dq + i);
            _mm256_storeu_ps(dq + i, _mm256_mul_ps(v, _mm256_set1_ps(invf)));
        }
        for (; i < n * FL_HD; i++) dq[i] *= invf;
    }

    /* dK = dS^T @ Q * inv */
    if (attn_gemm(hdl, b->d_dp, n, b->d_q, FL_HD, b->d_tmp2, FL_HD, n, FL_HD, n, 112, 111) != 0) { free(dv); free(P); free(dS); free(dot); free(dq); return -19; }
    float* dk = (float*)malloc((size_t)n * FL_HD * sizeof(float));
    if (!dk) { free(dv); free(P); free(dS); free(dot); free(dq); return -20; }
    if (p_cudamemcpy(dk, b->d_tmp2, (size_t)n * FL_HD * sizeof(float), cudaMemcpyDeviceToHost) != 0) { free(dv); free(P); free(dS); free(dot); free(dq); free(dk); return -21; }
    {
        int i = 0;
        for (; i + 8 <= n * FL_HD; i += 8) {
            __m256 v = _mm256_loadu_ps(dk + i);
            _mm256_storeu_ps(dk + i, _mm256_mul_ps(v, _mm256_set1_ps(invf)));
        }
        for (; i < n * FL_HD; i++) dk[i] *= invf;
    }
    /* O = P @ V — can cho IL merge ctxT (dw_proj = ctx^T @ gout de tao dw_proj) */
    if (attn_gemm(hdl, b->d_p, n, b->d_v, FL_HD, b->d_o, FL_HD, n, n, FL_HD, 111, 111) != 0) {
        free(dv); free(P); free(dS); free(dot); free(dq); free(dk); return -22;
    }
    float* ouh = (float*)malloc((size_t)n * FL_HD * sizeof(float));
    if (!ouh) { free(dv); free(P); free(dS); free(dot); free(dq); free(dk); return -23; }
    if (p_cudamemcpy(ouh, b->d_o, (size_t)n * FL_HD * sizeof(float), cudaMemcpyDeviceToHost) != 0) {
        free(dv); free(P); free(dS); free(dot); free(dq); free(dk); free(ouh); return -24;
    }
    for (int t = 0; t < n; t++) memcpy(ctxo + (size_t)t * FL_HD, ouh + (size_t)t * FL_HD, FL_HD * sizeof(float));
    free(ouh);

    free(dot); free(P); free(dS);

    /* write dQ,dK,dV packed vào dqo (head-range [n][3*hd]) */
    for (int t = 0; t < n; t++) {
        float* dst = dqo + (size_t)t * 3 * FL_HD;
        memcpy(dst,                 dq + (size_t)t * FL_HD, FL_HD * sizeof(float));
        memcpy(dst + FL_HD,         dk + (size_t)t * FL_HD, FL_HD * sizeof(float));
        memcpy(dst + 2 * FL_HD,     dv + (size_t)t * FL_HD, FL_HD * sizeof(float));
    }
    free(dq); free(dk); free(dv);
    return 0;
}

EXPORT int TkvCudaAttnFwd(const float* qkv, int n, int h, int hd, int head, double inv, float* ctx_out) {
    if (!attn_on()) return 0;
    if (hd != FL_HD || n > TKV_MAX_N || inv == 0.0) return 0;
    const int stride3 = 3 * h;
    float* dqkv = (float*)qkv;
    (void)stride3;
    attn_lock();
    int rc = attn_fwd_head_impl(dqkv, ctx_out, n, h, hd, head, inv);
    attn_unlock();
    return rc == 0 ? 1 : 0;
}

EXPORT int TkvCudaAttnBwd(const float* qkv, const float* dctx, const float* ctx_in,
                          float* ctxo, float* dqo, int n, int h, int hd, int head, double inv) {
    if (!attn_on()) return 0;
    if (hd != FL_HD || n > TKV_MAX_N || inv == 0.0) return 0;
    attn_lock();
    int rc = attn_bwd_head_impl(qkv, dctx, ctx_in, ctxo, dqo, n, h, hd, head, inv);
    attn_unlock();
    return rc == 0 ? 1 : 0;
}
