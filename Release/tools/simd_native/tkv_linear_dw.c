/* tkv_linear_dw.c — YEU CAU #10 ASK A (2026-11-01)
 * ================================================================
 * gdw[gdw_off + i*out_d + c] += sum_p x[p*in_d + i] * gy[p*out_d + c]
 *
 * Thay cho chuoi .tkv: `dw = smm_fwd_at(x, gy, in_d, out_d, n)` (build tile
 * T x T = 64 x 64 bang code interpreted, 3 vong ghi T^2) roi
 * `gflat[goff + k] += dw.data[k]`. Mot pass, khong Tensor dw, khong copy lan 2.
 *
 * VI SAO NHANH (do bang tv/tests/_am4.tkv, 01/11):
 *   dw la GEMM contraction k = n = 8, nhung duong .tkv van build tile 64 x 64
 *   cho TUNG o (dw2 = 576 o: 4096 A + 4096 B + 4096 ACC = 7.1M phep ghi
 *   INTERPRETED) roi moi goi simd_gemm. O day tile bien mat, vong p that
 *   (n = 8) nam trong C, 4 hang x 8 cot/lan (gy doc 1 lan cho 4 hang).
 *
 * BIT-EXACT (bat buoc — loss phai EXACT). Doi chieu voi wrapper .tkv:
 *   `dw = (((0 + Ct_0) + Ct_1) ...)` roi `gflat[k] = gflat[k] + dw[k]`.
 *   Voi n <= 64 chi co MOT p-tile => dw = 0 + Ct (0 + x la chinh x), roi dung
 *   MOT phep cong vao gflat. Vi vay n > 64 bi tu choi (rc = -8): nhieu p-tile
 *   thi phai cong don tung p-tile vao dw roi moi cong vao gflat, khong the
 *   gop lam mot phep cong ma giu nguyen bit.
 *   Chinh Ct: `micro_f32` (4x16) KHONG gom cot — moi lane = MOT cot, vong p
 *   tang dan FMA vao lane (`c0a = _mm256_fmadd_ps(va0, vb0, c0a)`), va
 *   `tkv_k_eff` rut k cua tile xuong dung n khi n < 64 (cac hang B con lai
 *   = 0). Nen moi phan tu = chuoi FMA tuan tu theo p bat dau tu 0 — tai hien
 *   chinh xac bang 8 lane AVX (8 cot) va vong p tuan tu.
 *   Khong co phep giam tong NGANG, khong tai lien ket.
 *
 * VI SAO TU RIENG + /fp:precise: build.ps1 bien dich TU nay bang /fp:precise.
 * Voi /fp:fast MSVC tai lien ket `a + b + c` (va gop ca load(gdw) vao cay),
 * lam ket qua phu thuoc gia tri dich — do duoc 01/11. Kernel cu giu /fp:fast
 * (chung dua vao intrinsics, khong doi bit).
 *
 * Tra ve 0 = OK; am = loi ro (caller .tkv fallback duong cu):
 *   -1 tham so NULL, -2 shape <= 0, -5 list qua ngan, -6 gdw_off am,
 *   -7 shape le (out_d % 16 != 0 hoac in_d % 4 != 0): duong scalar tail cua
 *      micro_f32 khong dam bao cung bit -> tu choi,
 *   -8 n > 64 (nhieu p-tile: khong gop duoc thanh mot phep cong).
 */
#include <immintrin.h>

#define EXPORT __declspec(dllexport)

EXPORT int LinearDwFused(const float* x, int x_len, const float* gy, int gy_len,
                         float* gdw, int gdw_len, int gdw_off,
                         int n, int in_d, int out_d) {
    if (!x || !gy || !gdw) return -1;
    if (n < 0 || in_d <= 0 || out_d <= 0) return -2;
    if (gdw_off < 0) return -6;
    if ((out_d & 15) != 0 || (in_d & 3) != 0) return -7;
    if (n > 64) return -8;
    long long need_x = (long long)n * in_d;
    long long need_y = (long long)n * out_d;
    long long need_d = (long long)in_d * out_d;
    if ((long long)x_len < need_x || (long long)gy_len < need_y) return -5;
    if ((long long)gdw_len - gdw_off < need_d) return -5;
    if (n == 0) return 0;

    int c = 0;
    for (int i0 = 0; i0 < in_d; i0 += 4) {
        int nr = in_d - i0; if (nr > 4) nr = 4;
        const float* x0 = x + (long long)i0;
        float* d0 = gdw + gdw_off + (long long)i0 * out_d;
        for (c = 0; c + 8 <= out_d; c += 8) {
            __m256 b0 = _mm256_setzero_ps(), b1 = b0, b2 = b0, b3 = b0;
            for (int q = 0; q < n; q++) {
                __m256 g = _mm256_loadu_ps(gy + (long long)q * out_d + c);
                float av = x0[(long long)q * in_d];
                b0 = _mm256_fmadd_ps(_mm256_set1_ps(av), g, b0);
                if (nr > 1) {
                    av = x0[(long long)q * in_d + 1];
                    b1 = _mm256_fmadd_ps(_mm256_set1_ps(av), g, b1);
                    if (nr > 2) {
                        av = x0[(long long)q * in_d + 2];
                        b2 = _mm256_fmadd_ps(_mm256_set1_ps(av), g, b2);
                        if (nr > 3) {
                            av = x0[(long long)q * in_d + 3];
                            b3 = _mm256_fmadd_ps(_mm256_set1_ps(av), g, b3);
                        }
                    }
                }
            }
            float* d = d0 + c;
            float* d1 = d + out_d, *d2 = d + 2 * out_d, *d3 = d + 3 * out_d;
            _mm256_storeu_ps(d, _mm256_add_ps(_mm256_loadu_ps(d), b0));
            if (nr > 1) {
                _mm256_storeu_ps(d1, _mm256_add_ps(_mm256_loadu_ps(d1), b1));
                if (nr > 2) {
                    _mm256_storeu_ps(d2, _mm256_add_ps(_mm256_loadu_ps(d2), b2));
                    if (nr > 3)
                        _mm256_storeu_ps(d3, _mm256_add_ps(_mm256_loadu_ps(d3), b3));
                }
            }
        }
        for (; c < out_d; c++) {   /* chi khi out_d % 16 != 0 — da tu choi o tren */
            for (int r = 0; r < nr; r++) {
                float s = 0.0f;
                for (int q = 0; q < n; q++)
                    s = x0[(long long)q * in_d + r] * gy[(long long)q * out_d + c] + s;
                d0[(long long)r * out_d + c] = d0[(long long)r * out_d + c] + s;
            }
        }
    }
    return 0;
}
