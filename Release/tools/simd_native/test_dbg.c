#include <stdio.h>
#include <stdlib.h>
#include <string.h>

__declspec(dllimport) int SgemmFull(const float* a, const float* b, float* c,
                                    int a_len, int b_len, int c_len,
                                    int m, int n, int k, int ndim, int trans_b,
                                    int T, int mode);
__declspec(dllimport) int LinearDwFused(const float* x, int x_len, const float* gy,
                                        int gy_len, float* gdw, int gdw_len,
                                        int gdw_off, int n, int in_d, int out_d);

int main(void) {
    int k = 200, in_d = 96, out_d = 64;
    long long nx = (long long)k * in_d, ny = (long long)k * out_d;
    long long nd = (long long)in_d * out_d;
    float* x = (float*)malloc((size_t)nx * 4);
    float* gy = (float*)malloc((size_t)ny * 4);
    float* xT = (float*)malloc((size_t)nx * 4);
    float* ref = (float*)calloc((size_t)nd, 4);
    float* got = (float*)calloc((size_t)nd, 4);
    for (long long i = 0; i < nx; i++) x[i] = (float)((i % 17) - 8) * 0.03f;
    for (long long i = 0; i < ny; i++) gy[i] = (float)((i % 13) - 6) * 0.02f;
    for (int p = 0; p < k; p++)
        for (int i = 0; i < in_d; i++) xT[(long long)i * k + p] = x[(long long)p * in_d + i];

    SgemmFull(xT, gy, ref, (int)nx, (int)ny, (int)nd, in_d, out_d, k, out_d, 0, 64, 1);
    printf("ref[0]=%.9g ref[1]=%.9g\n", ref[0], ref[1]);
    LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);
    printf("call1 [0]=%.9g [1]=%.9g  same=%d\n", got[0], got[1], memcmp(&ref[0], &got[0], 4) == 0);
    LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);
    printf("call2 [0]=%.9g [1]=%.9g\n", got[0], got[1]);
    LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);
    printf("call3 [0]=%.9g\n", got[0]);
    LinearDwFused(x, (int)nx, gy, (int)ny, got, (int)nd, 0, k, in_d, out_d);
    printf("call4 [0]=%.9g\n", got[0]);
    {
        float* g2 = (float*)calloc((size_t)nd, 4);
        LinearDwFused(x, (int)nx, gy, (int)ny, g2, (int)nd, 0, k, in_d, out_d);
        printf("fresh call [0]=%.9g same_as_call1=%d\n", g2[0], memcmp(&g2[0], &ref[0], 4) == 0);
        free(g2);
    }
    /* tinh tay tung p-tile cho phan tu (0,0) */
    float t[4];
    int pc = 0, ti = 0;
    for (int p0 = 0; p0 < k; p0 += 64) {
        int pw = k - p0; if (pw > 64) pw = 64;
        float s = 0.0f;
        for (int q = 0; q < pw; q++) s = x[(long long)(p0 + q) * in_d + 0] * gy[(long long)(p0 + q) * out_d + 0] + s;
        t[ti++] = s;
        pc += pw;
    }
    printf("tiles: %.9g %.9g %.9g %.9g  sum=%.9g  sum+sum=%.9g\n", t[0], t[1], t[2], t[3],
           ((t[0] + t[1]) + t[2]) + t[3], 2.0f * (((t[0] + t[1]) + t[2]) + t[3]));
    return 0;
}
