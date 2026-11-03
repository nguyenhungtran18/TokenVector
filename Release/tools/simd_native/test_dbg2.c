#include <stdio.h>
#include <stdlib.h>
#include <string.h>

__declspec(dllimport) int LinearDwFused(const float* x, int x_len, const float* gy,
                                        int gy_len, float* gdw, int gdw_len,
                                        int gdw_off, int n, int in_d, int out_d);

static unsigned int bits(float f) { unsigned int u; memcpy(&u, &f, 4); return u; }

int main(void) {
    int k = 200, in_d = 96, out_d = 64;
    long long nx = (long long)k * in_d, ny = (long long)k * out_d;
    long long nd = (long long)in_d * out_d;
    float* x = (float*)malloc((size_t)nx * 4);
    float* gy = (float*)malloc((size_t)ny * 4);
    for (long long i = 0; i < nx; i++) x[i] = (float)((i % 17) - 8) * 0.03f;
    for (long long i = 0; i < ny; i++) gy[i] = (float)((i % 13) - 6) * 0.02f;

    float t[4];
    int ti = 0;
    for (int p0 = 0; p0 < k; p0 += 64) {
        int pw = k - p0; if (pw > 64) pw = 64;
        float s = 0.0f;
        for (int q = 0; q < pw; q++) s = x[(long long)(p0 + q) * in_d] * gy[(long long)(p0 + q) * out_d] + s;
        t[ti++] = s;
    }
    float manual = (((0.0f + t[0]) + t[1]) + t[2]) + t[3];
    printf("t0..t3 = %.9g %.9g %.9g %.9g\n", t[0], t[1], t[2], t[3]);
    printf("manual block-adds = %.9g  bits=%08x\n", manual, bits(manual));

    float* d = (float*)calloc((size_t)nd, 4);
    LinearDwFused(x, (int)nx, gy, (int)ny, d, (int)nd, 0, k, in_d, out_d);
    float one = d[0];
    printf("call1 = %.9g bits=%08x\n", one, bits(one));
    printf("one + one = %.9g bits=%08x\n", one + one, bits(one + one));

    LinearDwFused(x, (int)nx, gy, (int)ny, d, (int)nd, 0, k, in_d, out_d);
    printf("call2 = %.9g bits=%08x   delta = %.9g\n", d[0], bits(d[0]), d[0] - one);

    /* prefill = 1.0f: neu dung phep cong thuong thi ket qua = 1.0f + one */
    float* e = (float*)malloc((size_t)nd * 4);
    for (long long i = 0; i < nd; i++) e[i] = 1.0f;
    LinearDwFused(x, (int)nx, gy, (int)ny, e, (int)nd, 0, k, in_d, out_d);
    printf("prefill1 = %.9g bits=%08x   (1.0f+one = %.9g bits=%08x)\n",
           e[0], bits(e[0]), 1.0f + one, bits(1.0f + one));
    free(d); free(e); free(x); free(gy);
    return 0;
}
