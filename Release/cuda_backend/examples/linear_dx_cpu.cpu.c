#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int LinearDxFused(float* gy, int gy_len, float* w, int w_len, float* dx, int dx_len, int m, int n, int k, int ndim, int T) {
int nb_m = (m + T - 1) / T % 1000000;
for (int im = 0; im < (nb_m); im++) {
  int i0 = (im * T) % 1000000;
  int ib = (m - i0) % 1000000;
  if (ib > T) {
    ib = T;
  }
  int nb_p = (k + T - 1) / T % 1000000;
  for (int ip = 0; ip < (nb_p); ip++) {
    long long p0 = (ip * T) % 1000000;
    int pw = (k - p0) % 1000000;
    if (pw > T) {
      pw = T;
    }
    int nb_j = (n + T - 1) / T % 1000000;
    for (int ij = 0; ij < (nb_j); ij++) {
      int j0 = (ij * T) % 1000000;
      int jb = (n - j0) % 1000000;
      if (jb > T) {
        jb = T;
      }
      int k_eff = 0 % 1;
      for (int p = 0; p < (pw); p++) {
        float f_has = 0.0;
        for (int c = 0; c < (jb); c++) {
          float f_wv = w[(j0 + c) * ndim + p0 + p];
          if (f_wv != 0.0) {
            f_has = 1.0;
          }
        }
        for (int r = 0; r < (ib); r++) {
          float f_gv = gy[(i0 + r) * k + p0 + p];
          if (!isfinite(f_gv)) {
            f_has = 1.0;
          }
        }
        if (f_has == 1.0) {
          k_eff = p + 1;
        }
      }
      if (p0 == 0) {
        for (int r = 0; r < (ib); r++) {
          for (int c = 0; c < (jb); c++) {
            dx[(i0 + r) * n + j0 + c] = 0.0;
          }
        }
      }
      int nchunks = (k_eff + 63) / 64 % 1000000;
      for (int r = 0; r < (ib); r++) {
        for (int c = 0; c < (jb); c++) {
          float f_ct = 0.0;
          for (int pc_i = 0; pc_i < (nchunks); pc_i++) {
            int pc = (pc_i * 64) % 1000000;
            int kc = (k_eff - pc) % 1000000;
            if (kc > 64) {
              kc = 64;
            }
            float f_s = 0.0;
            for (int p = 0; p < (kc); p++) {
              float f_av = 0.0;
              float f_bv = 0.0;
              if (pc + p < pw) {
                f_av = gy[(i0 + r) * k + p0 + pc + p];
                f_bv = w[(j0 + c) * ndim + p0 + pc + p];
              }
              f_s = fmaf(f_av, f_bv, f_s);
            }
            f_ct = f_ct + f_s;
          }
          dx[(i0 + r) * n + j0 + c] = dx[(i0 + r) * n + j0 + c] + f_ct;
        }
      }
    }
  }
}
  return 0;
}
