#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int DslProbe(float* out, float* x, int n) {
float f_has = 0.0;
for (int i = 0; i < (n); i++) {
  float f_v = x[i];
  if (!isfinite(f_v)) {
    f_has = 1.0;
  }
  if (f_v > 0.0) {
    out[i] = f_v;
  }
}
out[0] = f_has;
  return 0;
}
