#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int SoftmaxCausalBwd(float* dp, int dp_len, float* P, int P_len, float* dctx, int dc_len, float* ctx, int c_len, int n, int hd) {
tkv_softmax_cb(dp, P, dctx, ctx, n, hd);
return 0;
  return 0;
}
