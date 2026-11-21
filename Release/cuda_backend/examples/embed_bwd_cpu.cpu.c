#include <immintrin.h>

#include <math.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int EmbedBwdFused(long long* idx, int idx_len, int rows, int d, float* gy, int gy_len, float* gw, int gw_len) {
tkv_embed_bwd(idx, gy, gw, rows, d, idx_len);
return 0;
  return 0;
}
