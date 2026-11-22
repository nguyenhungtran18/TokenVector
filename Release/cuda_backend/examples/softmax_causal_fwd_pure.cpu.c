#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int SoftmaxCausalFwd(float* s, int s_len, int n, double inv) {
for (int t = 0; t < (n); t++) {
  double d_mxv = s[t * n] * inv;
  s[t * n] = d_mxv;
  for (int u = 0; u < (t + 1); u++) {
    if (u > 0) {
      double d_m0 = s[t * n + u] * inv;
      s[t * n + u] = d_m0;
      if (d_m0 > d_mxv) {
        d_mxv = d_m0;
      }
    }
  }
  double d_totv = 0.0;
  for (int u = 0; u < (t + 1); u++) {
    double d_e = exp(s[t * n + u] - d_mxv);
    s[t * n + u] = d_e;
    d_totv = d_totv + d_e;
  }
  double d_ivv = 1.0 / d_totv;
  for (int u = 0; u < (t + 1); u++) {
    s[t * n + u] = s[t * n + u] * d_ivv;
  }
  for (int u = 0; u < (n); u++) {
    if (u > t) {
      s[t * n + u] = 0.0;
    }
  }
}
  return 0;
}
