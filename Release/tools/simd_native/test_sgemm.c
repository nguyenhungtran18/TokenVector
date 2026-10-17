#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

__declspec(dllimport) void SgemmF32(float* a, float* b, float* o, int n);
__declspec(dllimport) void SgemmF64(double* a, double* b, double* o, int n);

static double now_ms(void) {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(void) {
    int sizes[] = {32, 64, 128, 192, 256, 384, 512, 768, 1024};
    for (int s = 0; s < 9; s++) {
        int n = sizes[s];
        long long m = (long long)n * n;
        float*  a  = (float*)malloc((size_t)m * 4);
        float*  b  = (float*)malloc((size_t)m * 4);
        float*  o  = (float*)malloc((size_t)m * 4);
        float*  orf= (float*)malloc((size_t)m * 4);
        double* d  = (double*)malloc((size_t)m * 8);
        double* e  = (double*)malloc((size_t)m * 8);
        double* f  = (double*)malloc((size_t)m * 8);
        double* frf= (double*)malloc((size_t)m * 8);
        for (long long i = 0; i < m; i++) {
            a[i] = (float)(i % 7) - 3.0f;  b[i] = (float)(i % 5) - 2.0f;
            d[i] = (double)(i % 7) - 3.0; e[i] = (double)(i % 5) - 2.0;
        }

        SgemmF32(a, b, o, n);
        SgemmF64(d, e, f, n);

        /* tham chieu naive (chi khi n nho) */
        double err32 = 0, err64 = 0;
        if (n <= 128) {
            for (int i = 0; i < n; i++)
                for (int j = 0; j < n; j++) {
                    float s = 0; double t = 0;
                    for (int k = 0; k < n; k++) { s += a[(long long)i*n+k] * b[(long long)k*n+j];
                                                  t += d[(long long)i*n+k] * e[(long long)k*n+j]; }
                    orf[(long long)i*n+j] = s; frf[(long long)i*n+j] = t;
                }
            for (long long i = 0; i < m; i++) {
                double da = fabs((double)o[i] - orf[i]); if (da > err32) err32 = da;
                double db = fabs((double)f[i] - frf[i]); if (db > err64) err64 = db;
            }
        }

        double cs32 = 0, cs64 = 0;
        for (long long i = 0; i < m; i++) { cs32 += o[i]; cs64 += f[i]; }
        double best32 = 1e18, best64 = 1e18;
        int runs = n <= 128 ? 100 : 30;
        for (int r = 0; r < runs; r++) {
            double t0 = now_ms(); SgemmF32(a, b, o, n); double t1 = now_ms();
            if (t1 - t0 < best32) best32 = t1 - t0;
            t0 = now_ms(); SgemmF64(d, e, f, n); t1 = now_ms();
            if (t1 - t0 < best64) best64 = t1 - t0;
        }
        printf("n=%3d  f32 best=%.6f ms err=%.1e cs=%.2f | f64 best=%.6f ms err=%.1e cs=%.2f\n",
               n, best32, err32, cs32, best64, err64, cs64);
        free(a); free(b); free(o); free(orf); free(d); free(e); free(f); free(frf);
    }
    return 0;
}
