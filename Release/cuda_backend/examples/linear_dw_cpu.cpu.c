#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int tkv_cpu_linear_dw_cpu(float* x, float* gy, float* gdw, int n, int in_d, int out_d) {
for (int i = 0; i < (in_d); i++) {
  for (int c = 0; c < (out_d); c++) {
    float s = gdw[i * out_d + c];
    for (int p = 0; p < (n); p++) {
      s = fmaf(x[p * in_d + i], gy[p * out_d + c], s);
    }
    gdw[i * out_d + c] = s;
  }
}
  return 0;
}
