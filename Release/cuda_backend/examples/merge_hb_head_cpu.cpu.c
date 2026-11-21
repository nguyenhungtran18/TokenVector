#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int MergeHbHead(float* co, float* dq, float* ctxT, float* dqkv, int n, int h, int hd, int hlo, int hhi) {
for (int head = 0; head < (hhi); head++) {
  if (head >= hlo) {
    float ho = head * hd;
    for (int t2 = 0; t2 < (n); t2++) {
      long long base = t2 * h;
      long long p0 = t2 * 3 * hd;
      long long r0 = t2 * 3 * h;
      for (int d = 0; d < (hd); d++) {
        ctxT[base + ho + d] = co[t2 * hd + d];
        dqkv[r0 + ho + d] = dq[p0 + d];
        dqkv[r0 + h + ho + d] = dq[p0 + hd + d];
        dqkv[r0 + 2 * h + ho + d] = dq[p0 + 2 * hd + d];
      }
    }
  }
}
return 0;
  return 0;
}
