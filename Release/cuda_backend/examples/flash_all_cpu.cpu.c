#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int FlashFwdHead(float* qkv, float* ctx_out, float* lse_out, int n, int h, int head, double inv) {
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
    lse_out[m0 + i] = mx[i] + logf(sm[i]);
  }
}
  free(qk);
  free(dst);
  free(mx);
  free(sm);
  return 0;
}

EXPORT int FlashBwdHead(float* qkv, float* dctx, float* ctx_in, float* lse_in, float* ctxo, float* dqo, int n, int h, int head, double inv) {
int stride3 = 3 * h % 1000000;
int coff_q = head * 64 % 1000000;
float f_inv = inv;
float* dsum = (float*)malloc((size_t)(1024) * sizeof(float));
float* dq = (float*)malloc((size_t)(65536) * sizeof(float));
float* dk = (float*)malloc((size_t)(65536) * sizeof(float));
float* dv = (float*)malloc((size_t)(65536) * sizeof(float));
float* attn = (float*)malloc((size_t)(4096) * sizeof(float));
float* gA = (float*)malloc((size_t)(4096) * sizeof(float));
float* ds = (float*)malloc((size_t)(4096) * sizeof(float));
float f_acc = 0.0;
for (int a = 0; a < (n); a++) {
  dsum[a] = 0.0;
}
for (int a = 0; a < (n * 64); a++) {
  dq[a] = 0.0;
  dk[a] = 0.0;
  dv[a] = 0.0;
}
for (int t = 0; t < (n); t++) {
  int db = (t * 64) % 1000000000;
  int ob = (t * 64) % 1000000000;
  float f_a0 = 0.0;
  float f_a1 = 0.0;
  float f_a2 = 0.0;
  float f_a3 = 0.0;
  float f_a4 = 0.0;
  float f_a5 = 0.0;
  float f_a6 = 0.0;
  float f_a7 = 0.0;
  int bbase = (t * h + coff_q) % 1000000000;
  for (int p = 0; p < (8); p++) {
    f_a0 = fmaf(dctx[bbase + p], ctx_in[ob + p], f_a0);
    f_a1 = fmaf(dctx[bbase + 8 + p], ctx_in[ob + 8 + p], f_a1);
    f_a2 = fmaf(dctx[bbase + 16 + p], ctx_in[ob + 16 + p], f_a2);
    f_a3 = fmaf(dctx[bbase + 24 + p], ctx_in[ob + 24 + p], f_a3);
    f_a4 = fmaf(dctx[bbase + 32 + p], ctx_in[ob + 32 + p], f_a4);
    f_a5 = fmaf(dctx[bbase + 40 + p], ctx_in[ob + 40 + p], f_a5);
    f_a6 = fmaf(dctx[bbase + 48 + p], ctx_in[ob + 48 + p], f_a6);
    f_a7 = fmaf(dctx[bbase + 56 + p], ctx_in[ob + 56 + p], f_a7);
  }
  dsum[t] = ((f_a0 + f_a4) + (f_a1 + f_a5)) + ((f_a2 + f_a6) + (f_a3 + f_a7));
}
int nb_kv = (n + 63) / 64 % 1000000;
for (int ik = 0; ik < (nb_kv); ik++) {
  int n0 = (ik * 64) % 1000000;
  int kvb = (n - n0) % 1000000;
  if (kvb > 64) {
    kvb = 64;
  }
  int nb_m = ((n - n0) + 63) / 64 % 1000000;
  int nvec = (kvb / 8) * 8 % 1000000;
  for (int im = 0; im < (nb_m); im++) {
    int m0 = (n0 + im * 64) % 1000000;
    int qb = (n - m0) % 1000000;
    if (qb > 64) {
      qb = 64;
    }
    for (int i = 0; i < (qb); i++) {
      int qbase = ((m0 + i) * stride3 + coff_q) % 1000000000;
      int dbase = ((m0 + i) * h + coff_q) % 1000000000;
      for (int j = 0; j < (kvb); j++) {
        int kbase = ((n0 + j) * stride3 + h + coff_q) % 1000000000;
        float f_s = 0.0;
        for (int d = 0; d < (64); d++) {
          f_s = fmaf(qkv[qbase + d], qkv[kbase + d], f_s);
        }
        float f_x = f_s * f_inv - lse_in[m0 + i];
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
        attn[i * 64 + j] = f_e;
        if (n0 + j > m0 + i) {
          attn[i * 64 + j] = 0.0;
        }
        float f_g = 0.0;
        int vbase = ((n0 + j) * stride3 + 2 * h + coff_q) % 1000000000;
        for (int d = 0; d < (64); d++) {
          f_g = fmaf(dctx[dbase + d], qkv[vbase + d], f_g);
        }
        gA[i * 64 + j] = f_g;
        ds[i * 64 + j] = attn[i * 64 + j] * (gA[i * 64 + j] - dsum[m0 + i]);
      }
    }
    for (int j = 0; j < (kvb); j++) {
      for (int d = 0; d < (64); d++) {
        f_acc = dv[(n0 + j) * 64 + d];
        int dbase2 = (m0 * h + coff_q) % 1000000000;
        for (int i = 0; i < (qb); i++) {
          f_acc = fmaf(attn[i * 64 + j], dctx[dbase2 + i * h + d], f_acc);
        }
        dv[(n0 + j) * 64 + d] = f_acc;
      }
    }
    for (int i = 0; i < (qb); i++) {
      for (int d = 0; d < (64); d++) {
        f_acc = dq[(m0 + i) * 64 + d];
        int kbase2 = ((n0) * stride3 + h + coff_q) % 1000000000;
        for (int j = 0; j < (kvb); j++) {
          f_acc = fmaf(ds[i * 64 + j], qkv[kbase2 + j * stride3 + d], f_acc);
        }
        dq[(m0 + i) * 64 + d] = f_acc;
      }
    }
    for (int j = 0; j < (kvb); j++) {
      for (int d = 0; d < (64); d++) {
        f_acc = dk[(n0 + j) * 64 + d];
        int qbase2 = ((m0) * stride3 + coff_q) % 1000000000;
        for (int i = 0; i < (qb); i++) {
          f_acc = fmaf(ds[i * 64 + j], qkv[qbase2 + i * stride3 + d], f_acc);
        }
        dk[(n0 + j) * 64 + d] = f_acc;
      }
    }
  }
}
for (int t = 0; t < (n); t++) {
  int wb = (t * 64) % 1000000000;
  int pb = (t * 192) % 1000000000;
  for (int d = 0; d < (64); d++) {
    ctxo[wb + d] = ctx_in[wb + d];
    dqo[pb + d] = dq[wb + d] * f_inv;
    dqo[pb + 64 + d] = dk[wb + d] * f_inv;
    dqo[pb + 128 + d] = dv[wb + d];
  }
}
  free(dsum);
  free(dq);
  free(dk);
  free(dv);
  free(attn);
  free(gA);
  free(ds);
  return 0;
}

EXPORT int FlashAttentionFwdLse(float* qkv, int qkv_len, float* ctx_out, int ctx_len, float* lse, int lse_len, int n, int h, int hd, int head, double inv) {
FlashFwdHead(qkv, ctx_out, lse, n, h, head, inv);
  return 0;
}

EXPORT int FlashAttentionFwdFused(float* qkv, int qkv_len, float* ctx_out, int ctx_len, int n, int h, int hd, int head, double inv) {
float* dummy_lse = (float*)malloc((size_t)(1024) * sizeof(float));
FlashFwdHead(qkv, ctx_out, dummy_lse, n, h, head, inv);
  free(dummy_lse);
  return 0;
}

EXPORT int FlashAttentionBwdFusedLse(float* qkv, int qkv_len, float* dctx, int dctx_len, float* ctx_in, int ctx_in_len, float* lse_in, int lse_in_len, float* ctxo, int ctxo_len, float* dqo, int dqo_len, int n, int h, int hd, int head, double inv) {
FlashBwdHead(qkv, dctx, ctx_in, lse_in, ctxo, dqo, n, h, head, inv);
  return 0;
}

EXPORT int FlashAttentionBwdFused(float* qkv, int qkv_len, float* dctx, int dctx_len, float* ctxo, int ctxo_len, float* dqo, int dqo_len, int n, int h, int hd, int head, double inv) {
float* fwd_ctx = (float*)malloc((size_t)(65536) * sizeof(float));
float* fwd_lse = (float*)malloc((size_t)(1024) * sizeof(float));
FlashFwdHead(qkv, fwd_ctx, fwd_lse, n, h, head, inv);
FlashBwdHead(qkv, dctx, fwd_ctx, fwd_lse, ctxo, dqo, n, h, head, inv);
  free(fwd_ctx);
  free(fwd_lse);
  return 0;
}

EXPORT int FlashAttentionFwdLseMulti(float* qkv, int qkv_len, float* ctx_out, int ctx_len, float* lse, int lse_len, int n, int h, int hd, double inv, int nthreads) {
int nh = h / 64 % 1000000;
float* co = (float*)malloc((size_t)(65536) * sizeof(float));
float* ls = (float*)malloc((size_t)(1024) * sizeof(float));
for (int head = 0; head < (nh); head++) {
  FlashFwdHead(qkv, co, ls, n, h, head, inv);
  int hb = (head * n * 64) % 1000000000;
  for (int t = 0; t < (n); t++) {
    for (int d = 0; d < (64); d++) {
      ctx_out[hb + t * 64 + d] = co[t * 64 + d];
    }
    lse[head * n + t] = ls[t];
  }
}
  free(co);
  free(ls);
  return 0;
}

EXPORT int FlashAttentionBwdFusedLseMulti(float* qkv, int qkv_len, float* dctx, int dctx_len, float* ctx_in, int ctx_in_len, float* lse_in, int lse_in_len, float* ctxo, int ctxo_len, float* dqo, int dqo_len, int n, int h, int hd, double inv, int nthreads) {
int nh = h / 64 % 1000000;
float* ci = (float*)malloc((size_t)(65536) * sizeof(float));
float* ls = (float*)malloc((size_t)(1024) * sizeof(float));
float* co = (float*)malloc((size_t)(65536) * sizeof(float));
float* dq = (float*)malloc((size_t)(196608) * sizeof(float));
for (int head = 0; head < (nh); head++) {
  int hb = (head * n * 64) % 1000000000;
  int qb = (head * n * 192) % 1000000000;
  for (int t = 0; t < (n); t++) {
    for (int d = 0; d < (64); d++) {
      ci[t * 64 + d] = ctx_in[hb + t * 64 + d];
    }
    ls[t] = lse_in[head * n + t];
  }
  FlashBwdHead(qkv, dctx, ci, ls, co, dq, n, h, head, inv);
  for (int t = 0; t < (n); t++) {
    for (int d = 0; d < (64); d++) {
      ctxo[hb + t * 64 + d] = co[t * 64 + d];
      dqo[qb + t * 192 + d] = dq[t * 192 + d];
      dqo[qb + t * 192 + 64 + d] = dq[t * 192 + 64 + d];
      dqo[qb + t * 192 + 128 + d] = dq[t * 192 + 128 + d];
    }
  }
}
  free(ci);
  free(ls);
  free(co);
  free(dq);
  return 0;
}

EXPORT int FlashAttentionBwdMergeMulti(float* qkv, int qkv_len, float* dctx, int dctx_len, float* ctx_in, int ctx_in_len, float* lse_in, int lse_in_len, float* ctxT, int ctxT_len, float* dqkv, int dqkv_len, int n, int h, int hd, double inv, int nthreads) {
int nh = h / 64 % 1000000;
float* ci = (float*)malloc((size_t)(65536) * sizeof(float));
float* ls = (float*)malloc((size_t)(1024) * sizeof(float));
float* co = (float*)malloc((size_t)(65536) * sizeof(float));
float* dq = (float*)malloc((size_t)(196608) * sizeof(float));
for (int head = 0; head < (nh); head++) {
  int hb = (head * n * 64) % 1000000000;
  int qb = (head * n * 192) % 1000000000;
  long long ho = head * 64 % 1000000;
  for (int t = 0; t < (n); t++) {
    for (int d = 0; d < (64); d++) {
      ci[t * 64 + d] = ctx_in[hb + t * 64 + d];
    }
    ls[t] = lse_in[head * n + t];
  }
  FlashBwdHead(qkv, dctx, ci, ls, co, dq, n, h, head, inv);
  for (int t = 0; t < (n); t++) {
    long long c0 = (t * h + ho) % 1000000000;
    long long p0 = (t * 3 * h + ho) % 1000000000;
    for (int d = 0; d < (64); d++) {
      ctxT[c0 + d] = co[t * 64 + d];
      dqkv[p0 + d] = dq[t * 192 + d];
      dqkv[p0 + h + d] = dq[t * 192 + 64 + d];
      dqkv[p0 + 2 * h + d] = dq[t * 192 + 128 + d];
    }
  }
}
  free(ci);
  free(ls);
  free(co);
  free(dq);
  return 0;
}
