/* adamw_mt_check.c - kiem thu mode 8 (AdamW 8-thread trong tkv_simd_native.dll)
 * bit-exact vs scalar ref o n >= 65536, va do thoi gian. */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

__declspec(dllimport) int AdamwStepF32(float* p, float* m, float* v, const float* g, int n,
                                       float lr, float b1, float b2, float eps, float wd,
                                       float bc1s, float bc2s);

static float frand(void) { return ((float)rand() / (float)RAND_MAX - 0.5f) * 2.0f; }

static void ref_adamw(float* p, float* m, float* v, const float* g, long long n,
                      float lr, float b1, float b2, float eps, float wd,
                      float bc1s, float bc2s) {
    (void)bc1s;
    for (long long i = 0; i < n; i++) {
        float gi = g[i];
        float mi = b1 * m[i] + (1.0f - b1) * gi;
        float vi = b2 * v[i] + (1.0f - b2) * gi * gi;
        m[i] = mi; v[i] = vi;
        p[i] = p[i] - lr * (mi * bc2s) / (sqrtf(vi) + eps * bc2s) - lr * wd * p[i];
    }
}

static double maxdiff(const float* a, const float* b, long long n) {
    double mx = 0.0;
    for (long long i = 0; i < n; i++) { double d = fabs((double)a[i] - (double)b[i]); if (d > mx) mx = d; }
    return mx;
}

int main(void) {
    long long n = 124000000;
    float* p = (float*)malloc(n * 4);
    float* m = (float*)malloc(n * 4);
    float* v = (float*)malloc(n * 4);
    float* g = (float*)malloc(n * 4);
    float* p2 = (float*)malloc(n * 4);
    float* m2 = (float*)malloc(n * 4);
    float* v2 = (float*)malloc(n * 4);
    srand(12345);
    for (long long i = 0; i < n; i++) { p[i] = frand(); m[i] = frand() * 0.1f; v[i] = fabsf(frand()) + 0.1f; g[i] = frand() * 0.01f; }
    for (long long i = 0; i < n; i++) { p2[i] = p[i]; m2[i] = m[i]; v2[i] = v[i]; }
    float lr = 3e-4f, b1 = 0.9f, b2 = 0.999f, eps = 1e-8f, wd = 0.01f, bc1s = 0.1f, bc2s = 0.031f;
    printf("ref scalar...\n"); fflush(stdout);
    long long t0 = clock();
    ref_adamw(p2, m2, v2, g, n, lr, b1, b2, eps, wd, bc1s, bc2s);
    printf("scalar %.3f s\n", (double)(clock() - t0) / CLOCKS_PER_SEC); fflush(stdout);
    printf("adamw_step...\n"); fflush(stdout);
    t0 = clock();
    int st = AdamwStepF32(p, m, v, g, (int)n, lr, b1, b2, eps, wd, bc1s, bc2s);
    printf("mt rc=%d %.3f s\n", st, (double)(clock() - t0) / CLOCKS_PER_SEC);
    printf("p maxdiff=%.3e  m maxdiff=%.3e  v maxdiff=%.3e\n",
           maxdiff(p, p2, n), maxdiff(m, m2, n), maxdiff(v, v2, n));
    return 0;
}
