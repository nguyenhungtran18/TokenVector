#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int BiasAddRows(float* y, float* b, long long rows, long long cols) {
for (int i = 0; i < (rows); i++) {
  long long base = i * cols;
  for (int j = 0; j < (cols); j++) {
    y[base + j] = y[base + j] + b[j];
  }
}
  return 0;
}
