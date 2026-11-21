#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int GeluErfFwd(float* x, int x_len, float* out, int out_len, long long lo, long long hi) {
for (int i = 0; i < (hi); i++) {
  if (i >= lo) {
    out[i - lo] = tkv_gelu_f(x[i]);
  }
}
return 0;
  return 0;
}
