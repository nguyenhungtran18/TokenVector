#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int SoftmaxCausalBwd(float* dp, int dp_len, float* P, int P_len, float* dctx, int dc_len, float* ctx, int c_len, int n, int hd) {
for (int t = 0; t < (n); t++) {
  double d_dotv = 0.0;
  for (int u = 0; u < (hd); u++) {
    float f_prod = dctx[t * hd + u] * ctx[t * hd + u];
    d_dotv = d_dotv + f_prod;
  }
  for (int u = 0; u < (t + 1); u++) {
    double d_pu = P[t * n + u];
    double d_dsu = dp[t * n + u];
    dp[t * n + u] = d_pu * (d_dsu - d_dotv);
  }
  for (int u = 0; u < (n); u++) {
    if (u > t) {
      dp[t * n + u] = 0.0;
    }
  }
}
  return 0;
}
