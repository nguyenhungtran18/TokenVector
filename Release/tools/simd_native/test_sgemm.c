#include <stdio.h>
#include <stdlib.h>
#include <time.h>

__declspec(dllimport) void SgemmF32(float* a, float* b, float* o, int n);

static double now_ms(void) {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(void) {
    int sizes[] = {32, 64, 128, 192, 256, 384, 512};
    for (int s = 0; s < 7; s++) {
        int n = sizes[s];
        float* a = (float*)malloc((size_t)n * n * 4);
        float* b = (float*)malloc((size_t)n * n * 4);
        float* o = (float*)malloc((size_t)n * n * 4);
        for (long long i = 0; i < (long long)n * n; i++) { a[i] = (float)(i % 7) - 3.0f; b[i] = (float)(i % 5) - 2.0f; }
        double checksum = 0;
        SgemmF32(a, b, o, n);
        for (long long i = 0; i < (long long)n * n; i++) checksum += o[i];
        double best = 1e18;
        int runs = n <= 128 ? 100 : 30;
        for (int r = 0; r < runs; r++) {
            double t0 = now_ms();
            SgemmF32(a, b, o, n);
            double t1 = now_ms();
            if (t1 - t0 < best) best = t1 - t0;
        }
        printf("SGEMM f32 n=%3d  best=%.6f ms  checksum=%.2f\n", n, best, checksum);
        free(a); free(b); free(o);
    }
    return 0;
}
