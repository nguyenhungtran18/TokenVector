#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int LayernormBwdFused(float* x, int x_len, float* gy, int gy_len, float* g, int g_len, float* dx, int dx_len, float* gflat, int gflat_len, int n, int h, long long o_dg, long long o_db) {
for (int i = 0; i < (n); i++) {
  long long base = i * h;
  double d_mu = 0.0;
  for (int j = 0; j < (h); j++) {
    d_mu = d_mu + x[base + j];
  }
  d_mu = d_mu / h;
  double d_var = 0.0;
  for (int j = 0; j < (h); j++) {
    double d_d = x[base + j] - d_mu;
    d_var = d_var + d_d * d_d;
  }
  d_var = d_var / h;
  double d_rstd = 1.0 / sqrt(d_var + 1e-6);
  double d_xh = 0.0;
  float f_gg = 0.0;
  double d_s1 = 0.0;
  double d_s2 = 0.0;
  for (int j = 0; j < (h); j++) {
    d_xh = (x[base + j] - d_mu) * d_rstd;
    f_gg = gy[base + j] * g[j];
    d_s1 = d_s1 + f_gg;
    d_s2 = d_s2 + f_gg * d_xh;
  }
  double d_m1 = d_s1 / h;
  double d_m2 = d_s2 / h;
  for (int j = 0; j < (h); j++) {
    d_xh = (x[base + j] - d_mu) * d_rstd;
    double d_gyv = gy[base + j];
    f_gg = gy[base + j] * g[j];
    double d_tmp = d_rstd * (f_gg - d_m1 - d_xh * d_m2);
    dx[base + j] = d_tmp;
    double d_pdg = gflat[o_dg + j];
    gflat[o_dg + j] = d_pdg + d_gyv * d_xh;
    gflat[o_db + j] = gflat[o_db + j] + gy[base + j];
  }
}
  return 0;
}
