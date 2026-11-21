#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int BiasGrad(float* gy, float* gflat, long long off, int n, int cols) {
for (int c = 0; c < (cols); c++) {
  float acc = gflat[off + c];
  for (int i = 0; i < (n); i++) {
    acc = acc + gy[i * cols + c];
  }
  gflat[off + c] = acc;
}
return 0;
  return 0;
}
