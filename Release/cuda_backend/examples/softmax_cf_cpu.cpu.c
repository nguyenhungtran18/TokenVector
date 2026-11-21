#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int SoftmaxCausalFwd(float* s, int s_len, int n, double inv) {
tkv_softmax_cf(s, n, inv);
return 0;
  return 0;
}
