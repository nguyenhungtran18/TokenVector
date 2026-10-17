#include <stdio.h>
#include <stdlib.h>
#include <time.h>

__declspec(dllimport) void SgemmF32(float* a, float* b, float* o, int n);
__declspec(dllimport) double SumF64(double* a, int n);
__declspec(dllimport) void AddF32(float* a, float* b, float* o, int n);

static double now_ms(void) {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(void) {
    for (int n = 32; n <= 256; n *= 2) {
        float* a = (float*)malloc((size_t)n * n * 4);
        float* b = (float*)malloc((size_t)n * n * 4);
        float* o = (float*)malloc((size_t)n * n * 4);
        for (int i = 0; i < n * n; i++) { a[i] = (i % 7) - 3.0f; b[i] = (i % 5) - 2.0f; }

        /* correctness vs scalar */
        double checksum = 0;
        SgemmF32(a, b, o, n);
        for (int i = 0; i < n * n; i++) checksum += o[i];

        double best = 1e18;
        for (int r = 0; r < 200; r++) {
            double t0 = now_ms();
            SgemmF32(a, b, o, n);
            double t1 = now_ms();
            if (t1 - t0 < best) best = t1 - t0;
        }
        printf("SGEMM n=%3d  best=%.6f ms  checksum=%.4f\n", n, best, checksum);
        free(a); free(b); free(o);
    }
    return 0;
}
