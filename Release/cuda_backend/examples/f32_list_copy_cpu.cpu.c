#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int F32ListCopy(float* dst, int dst_len, float* src, int src_len, int n) {
for (int i = 0; i < (n); i++) {
  dst[i] = src[i];
}
  return 0;
}
