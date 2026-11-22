#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int TkvCudaAttnFwd(float* qkv, int n, int h, int hd, int head, double inv, float* ctx_out) {
float f_rc = 0.0;
  return 0;
}

EXPORT int TkvCudaAttnBwd(float* qkv, float* dctx, float* ctx_in, float* ctxo, float* dqo, int n, int h, int hd, int head, double inv) {
float f_rc = 0.0;
  return 0;
}
