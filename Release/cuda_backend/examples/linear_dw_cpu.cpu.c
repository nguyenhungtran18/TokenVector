#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int LinearDwFused(float* x, float* gy, float* gdw, int n, int in_d, int out_d) {
for (int i = 0; i < (in_d); i++) {
  for (int c = 0; c < (out_d); c++) {
    float acc = 0.0;
    for (int p = 0; p < (n); p++) {
      acc = fmaf(x[p * in_d + i], gy[p * out_d + c], acc);
    }
    gdw[i * out_d + c] = gdw[i * out_d + c] + acc;
  }
}
  return 0;
}
