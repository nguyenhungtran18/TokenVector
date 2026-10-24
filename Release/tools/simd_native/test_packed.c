/* test_packed.c - kiem thu M4: packed GEMM + fix re-entrancy (§3.1).
 * Xay: cl /O2 /arch:AVX2 /fp:fast test_packed.c tkv_simd_native.lib /Fe:test_packed.exe
 * (can tkv_simd_native.lib cung thu muc - sinh boi build.ps1).
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <windows.h>

__declspec(dllimport) long long SgemmPackedCreate(const float* src, int src_len, int rows, int cols,
                                                   int stride, int T, int trans);
__declspec(dllimport) int SgemmPacked(long long hA, long long hB, float* c, int c_len, int T);
__declspec(dllimport) long long SgemmPackedFree(long long h);
__declspec(dllimport) void SgemmF32(float* a, float* b, float* o, int n);

static int fails = 0;
static void ck(const char* name, double got, double want, double tol) {
    if (fabs(got - want) <= tol) printf("PASS %s (%.6f)\n", name, got);
    else { printf("FAIL %s got=%.6f want=%.6f\n", name, got, want); fails++; }
}

/* reference: C = A(m x k) * B(k x n), row-major, dense. */
static void ref_gemm(const float* A, const float* B, float* C, int m, int n, int k) {
    for (int i = 0; i < m; i++)
        for (int j = 0; j < n; j++) {
            float s = 0.0f;
            for (int p = 0; p < k; p++) s += A[i*k+p] * B[p*n+j];
            C[i*n+j] = 1.0f * s;   /* dung 1.0f* de tranh warning */
        }
}

/* --- M4.1: packed square vs simd_gemm (BIT-exact mong doi) --- */
static void test_square_vs_simd(void) {
    int n = 128;
    long long m = (long long)n * n;
    float* a = (float*)malloc(m * 4);
    float* b = (float*)malloc(m * 4);
    float* r1 = (float*)malloc(m * 4);
    float* r2 = (float*)malloc(m * 4);
    for (long long i = 0; i < m; i++) { a[i] = (float)(i % 7) - 3.0f; b[i] = (float)(i % 5) - 2.0f; }
    long long hA = SgemmPackedCreate(a, (int)m, n, n, n, n, 0);
    long long hB = SgemmPackedCreate(b, (int)m, n, n, n, n, 0);
    ck("square create handle", hA > 0 && hB > 0 ? 1 : 0, 1, 0);
    int st = SgemmPacked(hA, hB, r1, (int)m, n);
    ck("square run status", st, 0, 0);
    SgemmF32(a, b, r2, n);
    double maxd = 0;
    for (long long i = 0; i < m; i++) { double d = fabs((double)r1[i] - (double)r2[i]); if (d > maxd) maxd = d; }
    ck("square packed vs simd_gemm maxdiff", maxd, 0.0, 1e-4);
    SgemmPackedFree(hA); SgemmPackedFree(hB);
    free(a); free(b); free(r1); free(r2);
}

/* --- M4.2: rectangular + padding (rows/cols khong boi T) vs reference --- */
static void test_rect_pad(void) {
    int m = 5, k = 7, n = 3, T = 4;   /* 5,7,3 deu KHONG boi 4 -> pad */
    float A[5*7], B[7*3], C[5*3], Cref[5*3];
    for (int i = 0; i < m*k; i++) A[i] = (float)(i % 6) - 2.0f;
    for (int i = 0; i < k*n; i++) B[i] = (float)(i % 5) - 1.0f;
    ref_gemm(A, B, Cref, m, n, k);
    long long hA = SgemmPackedCreate(A, m*k, m, k, k, T, 0);
    long long hB = SgemmPackedCreate(B, k*n, k, n, n, T, 0);
    int st = SgemmPacked(hA, hB, C, m*n, T);
    ck("rect pad status", st, 0, 0);
    double maxd = 0;
    for (int i = 0; i < m*n; i++) { double d = fabs((double)C[i] - (double)Cref[i]); if (d > maxd) maxd = d; }
    ck("rect pad maxdiff", maxd, 0.0, 1e-4);
    SgemmPackedFree(hA); SgemmPackedFree(hB);
}

/* --- M4.3: trans=1 (luu ban transpose) vs reference --- */
static void test_trans(void) {
    int rows = 4, cols = 6, T = 4;
    /* src la rows x cols = 4 x 6; pack transpose -> handle 6 x 4 */
    float src[4*6];
    for (int i = 0; i < rows*cols; i++) src[i] = (float)(i % 5) - 1.0f;
    /* B dich = cols x n = 6 x 2, inner dim = 6 = cols (sau trans A la 6 x 4... ) */
    int n = 2;
    float B[6*2], C[6*4], Cref[6*4];
    for (int i = 0; i < cols*n; i++) B[i] = (float)(i % 4) - 1.0f;
    /* A_trans = src^T = cols x rows = 6 x 4; C = A_trans(6x4) * ??? inner=4 */
    /* Dung reference tren A_trans: A_trans 6 x 4, can B' 4 x n. */
    float Atrans[6*4];
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            Atrans[j*rows + i] = src[i*cols + j];   /* Atrans la cols x rows */
    /* Sua: inner dim cua A_trans la rows=4. Tao B2 4 x n. */
    float B2[4*2];
    for (int i = 0; i < 4*n; i++) B2[i] = (float)(i % 3) - 1.0f;
    ref_gemm(Atrans, B2, Cref, cols, n, rows);   /* 6x4 * 4x2 -> 6x2 */
    long long hA = SgemmPackedCreate(src, rows*cols, rows, cols, cols, T, 1); /* -> 6 x 4 */
    long long hB = SgemmPackedCreate(B2, 4*n, 4, n, n, T, 0);                 /* -> 4 x 2 */
    int st = SgemmPacked(hA, hB, C, cols*n, T);
    ck("trans status", st, 0, 0);
    double maxd = 0;
    for (int i = 0; i < cols*n; i++) { double d = fabs((double)C[i] - (double)Cref[i]); if (d > maxd) maxd = d; }
    ck("trans maxdiff", maxd, 0.0, 1e-4);
    SgemmPackedFree(hA); SgemmPackedFree(hB);
    (void)B;
}

/* --- M4.4: loi ro (khong im lang) --- */
static void test_errors(void) {
    float a[16], b[16], c[16];
    for (int i = 0; i < 16; i++) { a[i] = 1.0f; b[i] = 1.0f; }
    long long hA = SgemmPackedCreate(a, 16, 4, 4, 4, 4, 0);
    long long hB = SgemmPackedCreate(b, 16, 4, 4, 4, 4, 0);
    ck("err T mismatch", SgemmPacked(hA, hB, c, 16, 8), -2, 0);      /* T=8 khac handle T=4 */
    ck("err C qua ngan", SgemmPacked(hA, hB, c, 3, 4), -5, 0);       /* c_len 3 < 16 */
    ck("err handle 0", SgemmPacked(0, hB, c, 16, 4), -1, 0);
    /* inner dim khong khop: B co shape 4x4 -> A.n=4 == B.m=4 thi khop; tao B 2x4 */
    long long hB2 = SgemmPackedCreate(b, 8, 2, 4, 4, 4, 0);          /* 2 x 4 */
    ck("err inner mismatch", SgemmPacked(hA, hB2, c, 16, 4), -3, 0); /* A.n=4 != B.m=2 */
    ck("err create param", SgemmPackedCreate(a, 16, 4, 4, 3, 4, 0) > 0 ? 1 : 0, 0, 0); /* stride 3 < cols 4 */
    SgemmPackedFree(hA); SgemmPackedFree(hB); SgemmPackedFree(hB2);
}

/* --- M4.5: re-entrancy - 2 thread goi dong thoi khong duoc hang (§3.1) --- */
static DWORD WINAPI thr_sgemm(LPVOID p) {
    int n = 512;
    long long m = (long long)n * n;
    float* a = (float*)malloc(m * 4);
    float* b = (float*)malloc(m * 4);
    float* o = (float*)malloc(m * 4);
    for (long long i = 0; i < m; i++) { a[i] = 1.0f; b[i] = 2.0f; }
    for (int r = 0; r < 5; r++) SgemmF32(a, b, o, n);
    free(a); free(b); free(o);
    (void)p;
    return 0;
}
static void test_reentrancy(void) {
    HANDLE t1, t2;
    t1 = CreateThread(NULL, 0, thr_sgemm, NULL, 0, NULL);
    t2 = CreateThread(NULL, 0, thr_sgemm, NULL, 0, NULL);
    DWORD w1 = WaitForSingleObject(t1, 30000);   /* gioi han 30s: neu hang = bug quay lai */
    DWORD w2 = WaitForSingleObject(t2, 30000);
    ck("reentrancy t1 finished", w1 == WAIT_OBJECT_0 ? 1 : 0, 1, 0);
    ck("reentrancy t2 finished", w2 == WAIT_OBJECT_0 ? 1 : 0, 1, 0);
    CloseHandle(t1); CloseHandle(t2);
}

int main(void) {
    test_square_vs_simd();
    test_rect_pad();
    test_trans();
    test_errors();
    test_reentrancy();
    printf("\n=== PACKED: %s ===\n", fails == 0 ? "ALL PASS" : "FAIL");
    return fails == 0 ? 0 : 1;
}
