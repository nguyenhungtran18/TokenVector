#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int GeluErfBwd(float* x, int x_len, float* gy, int gy_len, float* out, int out_len, long long lo, long long hi) {
tkv_gelu_bv(x, gy, out, lo, hi);
return 0;
  return 0;
}
