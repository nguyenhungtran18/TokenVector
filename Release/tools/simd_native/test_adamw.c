/* test_adamw.c - kiem thu M5: buffer f32 native + fused AdamW/elementwise (§M5).
 * Xay: cl /O2 /arch:AVX2 /fp:fast test_adamw.c tkv_simd_native.lib /Fe:test_adamw.exe
 * (can tkv_simd_native.lib cung thu muc - sinh boi build.ps1).
 *
 * AdamW so voi cong thuc SCALAR DUNG SPEC (GĐ10 §M5) - chung minh SIMD khong
 * lech (vector == scalar cung cong thuc, TOL 1e-5). Dung thi/sai cua cong thuc
 * vs torch la cua so confirm (team Inference doi chieu GĐ10).
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

__declspec(dllimport) long long F32Zero(float* p, int n);
__declspec(dllimport) long long F32CopyTo(const float* src, int src_len, float* p, int n);
__declspec(dllimport) long long F32CopyFrom(const float* p, int n, float* dst, int dst_len);
__declspec(dllimport) int F32Addcmul(float* dst, const float* x, const float* y, float scale, int n);
__declspec(dllimport) int AdamwStepF32(float* p, float* m, float* v, const float* g, int n,
                                       float lr, float b1, float b2, float eps, float wd,
                                       float bc1s, float bc2s);

static int fails = 0;
static void ck(const char* name, double got, double want, double tol) {
    if (fabs(got - want) <= tol) printf("PASS %s\n", name);
    else { printf("FAIL %s got=%.9f want=%.9f\n", name, got, want); fails++; }
}

/* Cong thuc AdamW scalar DUNG SPEC (GĐ10 §M5), thu tu co dinh: */
static void ref_adamw(float* p, float* m, float* v, const float* g, int n,
                      float lr, float b1, float b2, float eps, float wd,
                      float bc1s, float bc2s) {
    (void)bc1s;
    for (int i = 0; i < n; i++) {
        float gi = g[i];
        float mi = b1 * m[i] + (1.0f - b1) * gi;
        float vi = b2 * v[i] + (1.0f - b2) * gi * gi;
        m[i] = mi;
        v[i] = vi;
        p[i] = p[i] - lr * (mi * bc2s) / (sqrtf(vi) + eps * bc2s) - lr * wd * p[i];
    }
}

/* max |a-b| qua mot mang */
static double maxdiff(const float* a, const float* b, int n) {
    double mx = 0.0;
    for (int i = 0; i < n; i++) { double d = fabs((double)a[i] - (double)b[i]); if (d > mx) mx = d; }
    return mx;
}

static void fill(float* a, int n, int seed) {
    unsigned s = (unsigned)seed;
    for (int i = 0; i < n; i++) { s = s * 1664525u + 1013904223u; a[i] = ((float)(s >> 8) / 16777216.0f) * 2.0f - 1.0f; }
}

/* --- M5.1: F32Zero --- */
static void test_zero(void) {
    int n = 37;
    float* p = (float*)malloc(n * 4);
    for (int i = 0; i < n; i++) p[i] = 123.0f;
    F32Zero(p, n);
    double bad = 0.0;
    for (int i = 0; i < n; i++) if (p[i] != 0.0f) bad += 1.0;
    ck("f32_zero_all_zero", bad, 0.0, 0.0);
    free(p);
}

/* --- M5.2: copy to/from --- */
static void test_copy(void) {
    int n = 20;
    float* src = (float*)malloc(n * 4);
    float* buf = (float*)malloc(n * 4);
    float* back = (float*)malloc(n * 4);
    fill(src, n, 7);
    for (int i = 0; i < n; i++) buf[i] = -999.0f;
    long long r = F32CopyTo(src, n, buf, n);
    ck("copy_to_count", (double)r, (double)n, 0.0);
    ck("copy_to_exact", maxdiff(src, buf, n), 0.0, 0.0);
    for (int i = 0; i < n; i++) back[i] = -999.0f;
    r = F32CopyFrom(buf, n, back, n);
    ck("copy_from_count", (double)r, (double)n, 0.0);
    ck("copy_from_exact", maxdiff(buf, back, n), 0.0, 0.0);
    /* bounds: src qua ngan -> -1 */
    ck("copy_to_short_src", (double)F32CopyTo(src, n - 1, buf, n), -1.0, 0.0);
    ck("copy_from_short_dst", (double)F32CopyFrom(buf, n, back, n - 1), -1.0, 0.0);
    free(src); free(buf); free(back);
}

/* --- M5.3: addcmul dst += scale*x*y --- */
static void test_addcmul(void) {
    int n = 41;   /* 41 % 8 != 0 -> co scalar tail */
    float* dst = (float*)malloc(n * 4);
    float* dst2 = (float*)malloc(n * 4);
    float* x = (float*)malloc(n * 4);
    float* y = (float*)malloc(n * 4);
    fill(dst, n, 1); fill(dst2, n, 1); fill(x, n, 2); fill(y, n, 3);
    float scale = 0.37f;
    /* reference scalar */
    for (int i = 0; i < n; i++) dst2[i] += scale * x[i] * y[i];
    int st = F32Addcmul(dst, x, y, scale, n);
    ck("addcmul_status", (double)st, 0.0, 0.0);
    ck("addcmul_vs_scalar", maxdiff(dst, dst2, n), 0.0, 1e-6);
    ck("addcmul_bad_arg", (double)F32Addcmul(NULL, x, y, scale, n), -1.0, 0.0);
    free(dst); free(dst2); free(x); free(y);
}

/* --- M5.4: AdamwStepF32 vs scalar spec (2 kich thuoc: chia het 8 + du 8) --- */
static void test_adamw_case(int n, int seed) {
    float* p = (float*)malloc(n * 4);
    float* m = (float*)malloc(n * 4);
    float* v = (float*)malloc(n * 4);
    float* g = (float*)malloc(n * 4);
    float* p2 = (float*)malloc(n * 4);
    float* m2 = (float*)malloc(n * 4);
    float* v2 = (float*)malloc(n * 4);
    fill(p, n, seed); fill(m, n, seed + 1); fill(v, n, seed + 2); fill(g, n, seed + 3);
    for (int i = 0; i < n; i++) { v[i] = fabs(v[i]) + 0.1f; }   /* v > 0 nhu torch */
    for (int i = 0; i < n; i++) { v2[i] = v[i]; }
    for (int i = 0; i < n; i++) { p2[i] = p[i]; m2[i] = m[i]; }
    float lr = 3e-4f, b1 = 0.9f, b2 = 0.999f, eps = 1e-8f, wd = 0.01f;
    float bc1s = 0.1f, bc2s = 0.031f;

    int st = AdamwStepF32(p, m, v, g, n, lr, b1, b2, eps, wd, bc1s, bc2s);
    ck("adamw_status", (double)st, 0.0, 0.0);
    ref_adamw(p2, m2, v2, g, n, lr, b1, b2, eps, wd, bc1s, bc2s);

    char nm[64];
    double dp = maxdiff(p, p2, n), dm = maxdiff(m, m2, n), dv = maxdiff(v, v2, n);
    sprintf(nm, "adamw_p_vs_scalar_n%d", n); ck(nm, dp, 0.0, 1e-5);
    sprintf(nm, "adamw_m_vs_scalar_n%d", n); ck(nm, dm, 0.0, 1e-6);
    sprintf(nm, "adamw_v_vs_scalar_n%d", n); ck(nm, dv, 0.0, 1e-6);
    free(p); free(m); free(v); free(g); free(p2); free(m2); free(v2);
}

static void test_adamw(void) {
    test_adamw_case(64, 10);    /* chia het 8 (SIMD full) */
    test_adamw_case(37, 50);    /* du 8 (scalar tail) */
    ck("adamw_bad_arg", (double)AdamwStepF32(NULL, NULL, NULL, NULL, 4, 1e-3f, 0.9f, 0.999f, 1e-8f, 0.0f, 0.1f, 0.03f), -1.0, 0.0);
}

int main(void) {
    test_zero();
    test_copy();
    test_addcmul();
    test_adamw();
    printf("SUMMARY fails=%d\n", fails);
    return fails ? 1 : 0;
}
