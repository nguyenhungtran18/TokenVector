#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int FlashAttentionFwdLse(float* qkv, int qkv_len, float* ctx_out, int ctx_len, float* lse, int lse_len, int n, int h, int hd, int head, double inv) {
int stride3 = 3 * h % 1000000;
int coff_q = head * 64 % 1000000;
float f_inv = inv;
int nb_m = (n + 63) / 64 % 1000000;
float* qk = (float*)malloc((size_t)(4096) * sizeof(float));
float* dst = (float*)malloc((size_t)(4096) * sizeof(float));
float* mx = (float*)malloc((size_t)(64) * sizeof(float));
float* sm = (float*)malloc((size_t)(64) * sizeof(float));
for (int im = 0; im < (nb_m); im++) {
  int m0 = (im * 64) % 1000000;
  int qb = (n - m0) % 1000000;
  if (qb > 64) {
    qb = 64;
  }
  int num_keys = (m0 + qb) % 1000000;
  if (num_keys > n) {
    num_keys = n;
  }
  int nb_kv = (num_keys + 63) / 64 % 1000000;
  for (int a = 0; a < (64); a++) {
    mx[a] = -3.4028234663852886e38;
    sm[a] = 0.0;
  }
  for (int a = 0; a < (4096); a++) {
    dst[a] = 0.0;
  }
  for (int ik = 0; ik < (nb_kv); ik++) {
    int n0 = (ik * 64) % 1000000;
    int kvb = (num_keys - n0) % 1000000;
    if (kvb > 64) {
      kvb = 64;
    }
    int nvec = (kvb / 8) * 8 % 1000000;
    for (int i = 0; i < (qb); i++) {
      int qbase = ((m0 + i) * stride3 + coff_q) % 1000000000;
      for (int j = 0; j < (kvb); j++) {
        float f_s = 0.0;
        int kbase = ((n0 + j) * stride3 + h + coff_q) % 1000000000;
        for (int d = 0; d < (64); d++) {
          f_s = fmaf(qkv[qbase + d], qkv[kbase + d], f_s);
        }
        qk[i * 64 + j] = f_s * f_inv;
        if (n0 + j > m0 + i) {
          qk[i * 64 + j] = -3.4028234663852886e38;
        }
      }
      float f_rmax = -3.4028234663852886e38;
      for (int j = 0; j < (kvb); j++) {
        if (qk[i * 64 + j] > f_rmax) {
          f_rmax = qk[i * 64 + j];
        }
      }
      float f_newmax = f_rmax;
      if (mx[i] > f_newmax) {
        f_newmax = mx[i];
      }
      float f_ok = 1.0;
      if (f_newmax == -3.4028234663852886e38) {
        f_ok = 0.0;
      }
      if (f_ok == 1.0) {
        float f_exptmp = 1.0;
        if (n0 > 0) {
          f_exptmp = expf(mx[i] - f_newmax);
        }
        if (mx[i] == -3.4028234663852886e38) {
          f_exptmp = 0.0;
        }
        float f_bsum = 0.0;
        for (int j = 0; j < (kvb); j++) {
          float f_x = qk[i * 64 + j] - f_newmax;
          float f_e = 0.0;
          if (j < nvec) {
            if (f_x < -87.3) {
              f_x = -87.3;
            }
            if (f_x > 88.7) {
              f_x = 88.7;
            }
            float f_t = f_x * 1.4426950408889634f;
            float f_n = rintf(f_t);
            float f_f = f_t - f_n;
            f_f = f_f * 0.6931471805599453f;
            float f_r = 1.388888654e-04f;
            f_r = fmaf(f_r, f_f, 8.333333e-03f);
            f_r = fmaf(f_r, f_f, 4.1666665e-02f);
            f_r = fmaf(f_r, f_f, 1.6666666e-01f);
            f_r = fmaf(f_r, f_f, 5.0000000e-01f);
            f_r = fmaf(f_r, f_f, 1.00000000e+00f);
            f_r = fmaf(f_r, f_f, 1.00000000e+00f);
            f_e = f_r * ldexpf(1.0f, f_n);
          }
          if (j >= nvec) {
            f_e = expf(f_x);
          }
          qk[i * 64 + j] = f_e;
          f_bsum = f_bsum + f_e;
        }
        if (n0 > 0) {
          for (int d = 0; d < (64); d++) {
            dst[i * 64 + d] = dst[i * 64 + d] * f_exptmp;
          }
        }
        sm[i] = f_bsum + f_exptmp * sm[i];
        mx[i] = f_newmax;
      }
      if (f_ok == 0.0) {
        for (int j = 0; j < (kvb); j++) {
          qk[i * 64 + j] = 0.0;
        }
        for (int d = 0; d < (64); d++) {
          dst[i * 64 + d] = 0.0;
        }
        mx[i] = f_newmax;
      }
    }
    for (int i = 0; i < (qb); i++) {
      int vbase = (n0 * stride3 + 2 * h + coff_q) % 1000000000;
      for (int d = 0; d < (64); d++) {
        float f_acc = dst[i * 64 + d];
        for (int j = 0; j < (kvb); j++) {
          f_acc = fmaf(qk[i * 64 + j], qkv[vbase + j * stride3 + d], f_acc);
        }
        dst[i * 64 + d] = f_acc;
      }
    }
  }
  for (int i = 0; i < (qb); i++) {
    float f_sinv = 1.0 / sm[i];
    int obase = ((m0 + i) * 64) % 1000000000;
    for (int d = 0; d < (64); d++) {
      ctx_out[obase + d] = dst[i * 64 + d] * f_sinv;
    }
    lse[m0 + i] = mx[i] + logf(sm[i]);
  }
}
  free(qk);
  free(dst);
  free(mx);
  free(sm);
  return 0;
}
