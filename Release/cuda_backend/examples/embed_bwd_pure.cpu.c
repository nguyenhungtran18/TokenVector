#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int EmbedBwdFused(long long* idx, int idx_len, int rows, int d, float* gy, int gy_len, float* gw, int gw_len) {
for (int j = 0; j < (rows * d); j++) {
  gw[j] = 0.0;
}
for (int t = 0; t < (idx_len); t++) {
  int r = idx[t] % 1000000000;
  long long base = r * d;
  int gybase = (t * d) % 1000000000;
  for (int j = 0; j < (d); j++) {
    gw[base + j] = gw[base + j] + gy[gybase + j];
  }
}
  return 0;
}
