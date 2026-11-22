#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int BufProbe(float* out, int n) {
float* tmp = (float*)malloc((size_t)(n) * sizeof(float));
for (int i = 0; i < (n); i++) {
  tmp[i] = out[i] * 2.0;
}
for (int i = 0; i < (n); i++) {
  out[i] = tmp[i] + 1.0;
}
  free(tmp);
  return 0;
}
