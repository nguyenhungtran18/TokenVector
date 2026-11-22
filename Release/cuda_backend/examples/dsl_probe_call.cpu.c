#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int AddOne(float* a, int n) {
for (int i = 0; i < (n); i++) {
  a[i] = a[i] + 1.0;
}
  return 0;
}

EXPORT int Caller(float* a, int n) {
AddOne(a, n);
for (int i = 0; i < (n); i++) {
  a[i] = a[i] * 2.0;
}
  return 0;
}
