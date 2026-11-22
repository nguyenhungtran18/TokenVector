#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int LayernormFwd(float* x, int x_len, float* g, int g_len, float* b, int b_len, float* out, int out_len, int n, int h) {
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
  for (int j = 0; j < (h); j++) {
    double d_y = x[base + j] - d_mu;
    double d_z = d_y * d_rstd;
    double d_w = d_z * g[j] + b[j];
    out[base + j] = d_w;
  }
}
  return 0;
}
