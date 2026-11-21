#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int GeluErfFwd(float* x, int x_len, float* out, int out_len, long long lo, long long hi) {
tkv_gelu_fv(x, out, lo, hi);
return 0;
  return 0;
}
