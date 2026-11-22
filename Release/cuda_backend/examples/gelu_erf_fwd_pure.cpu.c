#include <immintrin.h>

#include <math.h>

#include <stdlib.h>

#define EXPORT __attribute__((visibility("default")))


EXPORT int GeluErfFwd(float* x, int x_len, float* out, int out_len, long long lo, long long hi) {
int n8 = (hi - lo) / 8 % 1000000;
for (int k = 0; k < (n8); k++) {
  long long base = lo + k * 8;
  for (int lane = 0; lane < (8); lane++) {
    float f_v = x[base + lane];
    float f_arg = f_v * 0.70710678118654752f;
    float f_sg = 1.0f;
    if (f_arg < 0.0f) {
      f_sg = -1.0f;
    }
    float f_ax = fabsf(f_arg);
    f_ax = fmaxf(f_ax, 0.0f);
    float f_t = 1.0f / fmaf(0.3275911f, f_ax, 1.0f);
    float f_p = 1.061405429f;
    f_p = fmaf(f_p, f_t, -1.453152027f);
    f_p = fmaf(f_p, f_t, 1.421413741f);
    f_p = fmaf(f_p, f_t, -0.284496736f);
    f_p = fmaf(f_p, f_t, 0.254829592f);
    f_p = fmaf(f_p, f_t, 0.0f);
    float f_ax2 = f_ax * f_ax;
    float f_neg2 = f_ax2 * -1.0f;
    f_neg2 = fmaxf(f_neg2, -90.0f);
    float f_kf = rintf(f_neg2 * 1.4426950408889634f);
    float f_r = fmaf(-f_kf, 0.6931471805599453f, f_neg2);
    float f_ep = 2.48015873e-05f;
    f_ep = fmaf(f_ep, f_r, 1.98412698e-04f);
    f_ep = fmaf(f_ep, f_r, 1.38888889e-03f);
    f_ep = fmaf(f_ep, f_r, 8.33333333e-03f);
    f_ep = fmaf(f_ep, f_r, 4.16666667e-02f);
    f_ep = fmaf(f_ep, f_r, 1.66666667e-01f);
    f_ep = fmaf(f_ep, f_r, 5.00000000e-01f);
    f_ep = fmaf(f_ep, f_r, 1.00000000e+00f);
    f_ep = fmaf(f_ep, f_r, 1.00000000e+00f);
    float f_pow = ldexpf(1.0f, f_kf);
    float f_e = f_ep * f_pow;
    float f_erf = fmaf(-f_e, f_p, 1.0f);
    f_erf = f_sg * f_erf;
    float f_op = 1.0f + f_erf;
    out[base + lane - lo] = (0.5f * f_v) * f_op;
  }
}
int nt = (hi - lo - n8 * 8) % 1000000;
for (int j = 0; j < (nt); j++) {
  int i = (lo + n8 * 8 + j) % 1000000000;
  float t_v = x[i];
  float t_arg = t_v / 1.4142135623730951f;
  double d_sg = 1.0;
  if (t_arg < 0.0f) {
    d_sg = -1.0;
  }
  float t_ax = fabsf(t_arg);
  double d_t = 1.0 / (1.0 + 0.3275911 * t_ax);
  double d_p = 1.061405429;
  d_p = d_p * d_t + -1.453152027;
  d_p = d_p * d_t + 1.421413741;
  d_p = d_p * d_t + -0.284496736;
  d_p = d_p * d_t + 0.254829592;
  d_p = d_p * d_t;
  float t_nax2 = (-t_ax) * t_ax;
  float t_e = exp(t_nax2);
  double d_r = d_sg * (1.0 - t_e * d_p);
  float t_r = d_r;
  float t_op = 1.0f + t_r;
  out[i - lo] = (0.5f * t_v) * t_op;
}
  return 0;
}
