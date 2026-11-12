/* tkv_bwd_ops.c - YEU CAU #12 ASK A (2026-11-05)
 * Kernel non-GEMM trong backward: layernorm_bwd_fused, bias_grad,
 * softmax_causal_bwd.
 *
 * BIT-EXACT voi duong .tkv interpreted (IL trong bseq_p10.il):
 *   - moi phep hon loai f32/f64 -> JIT mo rong len f64 (probe _nt.tkv NT3);
 *   - tich luy v/mu/s1/s2/dotv la f64, thu tu TUAN TU tang dan;
 *   - store f32 ep ve f32 (conv.r4) nhu set_Item;
 *   - gflat cong: f32 + f32 (o_db, db) hoac f64 cong roi ep f32 (o_dg).
 *
 * TU rieng, bien dich /fp:precise (giong tkv_linear_dw.c) - /fp:fast cho phep
 * MSVC tai lien ket `a + b*c` (dis thanh FMA) lam lech bit.
 *
 * GeluErfBwd: da co (probe _nt4/_nt5: exp 3001/3001, erf+dgelu 401/401 khop
 * MSVC voi input trung bit; JIT ep f64->f32 khi goi erf(float32)).
 */
#include <immintrin.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif
#else
#define EXPORT __attribute__((visibility("default")))
#endif

/* ---- LN: .tkv gpt2_layernorm_bwd (md5 9473DB7D... cho gflat path) ---- */
EXPORT int LayernormBwdFused(const float* x, int x_len, const float* gy, int gy_len,
                             const float* g,  int g_len,
                             float* dx, int dx_len,
                             float* gflat, int gflat_len,
                             int n, int h, long long o_dg, long long o_db) {
    if (!x || !gy || !g || !dx || !gflat) return -1;
    if (n <= 0 || h <= 0 || o_dg < 0 || o_db < 0) return -2;

    long long nxh = (long long)n * h;
    if (x_len < nxh || gy_len < nxh || g_len < h || dx_len < nxh) return -5;
    if ((long long)gflat_len - o_dg < h || (long long)gflat_len - o_db < h) return -5;

    /* §0.106 b (2026-11-08): uu tien ATen `at::layer_norm` + autograd.backward
     * (TkvTorchLayerNormBwd) — cung kernel HF gpt2 backward -> BIT-IDENTICAL.
     * gflat offsets chi ghi 1 lan moi backward (gflat khoi tao zero) nen
     * gan thang dg/db = ket qua ATen, khong con drift f64-Welford vs f32-Welford. */
    {
        extern int TkvTorchLayerNormBwd(const float* x, const float* g, const float* b,
                                        const float* gy, float* dx, float* dg, float* db,
                                        long long n, long long h, double eps);
        float* dgbuf = (float*)malloc((size_t)h * sizeof(float));
        float* dbbuf = (float*)malloc((size_t)h * sizeof(float));
        float* bzer  = (float*)calloc((size_t)h, sizeof(float)); /* LN bwd khong dung bias value — zero buffer doc lap */
        if (dgbuf && dbbuf && bzer) {
            int rc_at = TkvTorchLayerNormBwd(x, g, bzer, gy, dx, dgbuf, dbbuf,
                                             (long long)n, (long long)h, 1e-6);
            if (rc_at == 0) {
                for (int j = 0; j < h; j++) {
                    gflat[o_dg + j] = dgbuf[j];
                    gflat[o_db + j] = dbbuf[j];
                }
                free(dgbuf); free(dbbuf); free(bzer);
                return 0;
            }
        }
        if (dgbuf) free(dgbuf);
        if (dbbuf) free(dbbuf);
        if (bzer)  free(bzer);
    }

    for (int i = 0; i < n; i++) {
        const float* xr  = x  + (long long)i * h;
        const float* gyr = gy + (long long)i * h;
        float*       dxr = dx + (long long)i * h;

        /* mu = sum(x) / h — tich luy f64, f32 duoc widen */
        double mu = 0.0;
        for (int j = 0; j < h; j++) mu = mu + (double)xr[j];
        mu = mu / (double)h;

        /* v = sum(d^2) / h — d tinh f64 */
        double v = 0.0;
        for (int j = 0; j < h; j++) {
            double d = (double)xr[j] - mu;
            v = v + d * d;
        }
        v = v / (double)h;

        /* rstd = 1/sqrt(v + EPS): f64, sqrt IEEE (giong Math.Sqrt) */
        double rstd = 1.0 / sqrt(v + 1e-6);

        /* s1/s2: gg la F32 (gy*g), ep f64 truoc khi cong */
        double s1 = 0.0, s2 = 0.0;
        for (int j = 0; j < h; j++) {
            double xh   = ((double)xr[j] - mu) * rstd;
            float gg    = gyr[j] * g[j];          /* f32 mul, round f32 */
            s1 = s1 + (double)gg;
            s2 = s2 + (double)gg * xh;
        }
        double m1 = s1 / (double)h;
        double m2 = s2 / (double)h;

        /* dx + dg/db ghi thang gflat */
        for (int j = 0; j < h; j++) {
            double xh = ((double)xr[j] - mu) * rstd;
            float gyv = gyr[j];
            float gg  = gyv * g[j];               /* f32 mul */
            dxr[j] = (float)(rstd * ((double)gg - m1 - xh * m2));

            /* dg += gy*xh: (f32) + f64 -> f64 -> f32 */
            float* pdg = gflat + o_dg + j;
            *pdg = (float)((double)(*pdg) + (double)gyv * xh);

            /* db += gy: f32 + f32 (o_db) */
            float* pdb = gflat + o_db + j;
            *pdb = *pdb + gyv;
        }
    }
    return 0;
}

/* ---- GELU erf BWD: op_gelu_erf_bwd (sequential + _ogb_one) ----
 * IL bseq_p10.il: dgelu = 0.5*(1.0+erf(v/s)) + (v*0.3989422804014327)*Exp((-0.5*v)*v)
 *   - erf(v/s): div tinh f64, JIT ep f32 truoc khi goi erf(float32)
 *     (probe _nt5.tkv: 401/401 khop voi kieu A);
 *   - erf: t = 1.0/(1.0+0.3275911*ax) f64, Horner f64, exp((-ax)*ax) f32;
 *   - out[i-lo] = (float)((double)gy[i] * dgelu).
 * Elementwise -> thu tu khong anh huong bit; /fp:precise khong FMA.
 */
/* erf(v / s): f64 div -> ep f32 (giong JIT) - dung cho BWD (gelu_b_one).
 * va
 * erf(arg): f32 chia (giong JIT IL `gelu_erf`) - dung cho FWD (gelu_f_one).
 * Cong thuc poly/Horner GIONG nhau, chi khac buoc chia. */
static inline float gelu_erf_b(float v) {
    float arg = (float)((double)v / 1.4142135623730951);
    double sg = 1.0;
    if (arg < 0.0f) sg = -1.0;
    float ax = fabsf(arg);
    double t = 1.0 / (1.0 + 0.3275911 * (double)ax);
    double poly = 1.061405429;
    poly = poly * t + -1.453152027;
    poly = poly * t + 1.421413741;
    poly = poly * t + -0.284496736;
    poly = poly * t + 0.254829592;
    poly = poly * t;
    float e = (float)exp((double)((-ax) * ax));
    return (float)(sg * (1.0 - (double)e * poly));
}
static inline float gelu_erf_f(float v) {
    float arg = v / (float)1.4142135623730951;
    double sg = 1.0;
    if (arg < 0.0f) sg = -1.0;
    float ax = fabsf(arg);
    double t = 1.0 / (1.0 + 0.3275911 * (double)ax);
    double poly = 1.061405429;
    poly = poly * t + -1.453152027;
    poly = poly * t + 1.421413741;
    poly = poly * t + -0.284496736;
    poly = poly * t + 0.254829592;
    poly = poly * t;
    float e = (float)exp((double)((-ax) * ax));
    return (float)(sg * (1.0 - (double)e * poly));
}
static inline float gelu_f_one(float v) {
    float e = gelu_erf_f(v);
    float hf = 0.5f * v;
    float op = 1.0f + e;
    return hf * op;
}
static inline float gelu_b_one(float v) {
    float ef = gelu_erf_b(v);
    double d = 0.5 * (1.0 + (double)ef)
             + ((double)v * 0.3989422804014327) * exp(((-0.5) * (double)v) * (double)v);
    return (float)d;
}

EXPORT int GeluErfBwd(const float* x, int x_len, const float* gy, int gy_len,
                      float* out, int out_len, long long lo, long long hi) {
    if (!x || !gy || !out) return -1;
    if (lo < 0 || hi < lo) return -2;
    if (x_len < hi || gy_len < hi || out_len < hi - lo) return -5;
    if (lo == hi) return 0;

    long long i = lo;
    for (; i + 3 < hi; i += 4) {
        float v0 = x[i], v1 = x[i + 1], v2 = x[i + 2], v3 = x[i + 3];
        float g0 = gy[i], g1 = gy[i + 1], g2 = gy[i + 2], g3 = gy[i + 3];
        out[i - lo]     = (float)((double)g0 * gelu_b_one(v0));
        out[i + 1 - lo] = (float)((double)g1 * gelu_b_one(v1));
        out[i + 2 - lo] = (float)((double)g2 * gelu_b_one(v2));
        out[i + 3 - lo] = (float)((double)g3 * gelu_b_one(v3));
    }
    for (; i < hi; i++) {
        out[i - lo] = (float)((double)gy[i] * gelu_b_one(x[i]));
    }
    return 0;
}

/* ---- GELU ERF FWD: y = 0.5*v*(1 + erf(v/s)) -------------------------------
 * Cong thuc:  y = (0.5f * v) * (1.0f + erf(v/sqrt(2)))  — doi chieu TF
 * 401/401 (probe _nt5) voi duong interpreted. rc < 0 -> caller fallback. */
EXPORT int GeluErfFwd(const float* x, int x_len, float* out, int out_len, long long lo, long long hi) {
    if (!x || !out) return -1;
    if (lo < 0 || hi < lo) return -2;
    if (x_len < hi || out_len < hi - lo) return -5;
    if (lo == hi) return 0;
    long long i = lo;
    for (; i + 3 < hi; i += 4) {
        out[i - lo]     = gelu_f_one(x[i]);
        out[i + 1 - lo] = gelu_f_one(x[i + 1]);
        out[i + 2 - lo] = gelu_f_one(x[i + 2]);
        out[i + 3 - lo] = gelu_f_one(x[i + 3]);
    }
    for (; i < hi; i++) {
        out[i - lo] = gelu_f_one(x[i]);
    }
    return 0;
}

/* ---- BIAS ADD ROWS: y[i, c] += b[c] (broadcast bias) ----------------------
 * Elementwise f32 add theo hang; thu tu cong GIONG vong interpreted .tkv
 * (i tang, o tang) -> BIT-EXACT. AVX2 8 cot/lan; /fp:precise (khong reorder). */
EXPORT int BiasAddRows(float* y, const float* b, long long rows, long long cols) {
    if (!y || !b) return -1;
    if (rows < 0 || cols < 0) return -2;
    long long full = (cols / 8) * 8;
    for (long long i = 0; i < rows; i++) {
        float* row = y + i * cols;
        long long j = 0;
        for (; j < full; j += 8) {
            __m256 yr = _mm256_loadu_ps(row + j);
            __m256 bb = _mm256_loadu_ps(b + j);
            _mm256_storeu_ps(row + j, _mm256_add_ps(yr, bb));
        }
        for (; j < cols; j++) row[j] = row[j] + b[j];
    }
    return 0;
}

/* ---- BIAS GRAD: .tkv vòng i-outer/o-inner, i64 off vao gflat ---- */
EXPORT int BiasGrad(const float* gy, int gy_len, float* gflat, int gflat_len,
                    long long off, int n, int cols) {
    if (!gy || !gflat) return -1;
    if (n < 0 || cols <= 0 || off < 0) return -2;

    long long need = (long long)n * cols;
    if (gy_len < need) return -5;
    if ((long long)gflat_len - off < cols) return -5;
    if (n == 0) return 0;

    /* AVX2 8 lanes, thu tu cong tung cot y nguyen (1 ptu = 1 lane) */
    int c = 0;
    for (; c + 8 <= cols; c += 8) {
        __m256 acc = _mm256_loadu_ps(gflat + off + c);
        for (int i = 0; i < n; i++)
            acc = _mm256_add_ps(acc, _mm256_loadu_ps(gy + (long long)i * cols + c));
        _mm256_storeu_ps(gflat + off + c, acc);
    }
    for (; c < cols; c++) {
        float acc = gflat[off + c];
        for (int i = 0; i < n; i++) acc = acc + gy[(long long)i * cols + c];
        gflat[off + c] = acc;
    }
    return 0;
}

/* ---- SOFTMAX CAUSAL FWD: P = softmax(inv*Q.K^T), mask nhan qua ----
 * _attn_hb_one + nhan n<128 (IL bseq_p10.il) — gop 4 vong cua duong .tkv:
 *   m0 = s[t*n+u] * inv   -> f32*f64 = f64, store f32, mxv giu f64 CHUA ROUND
 *   e  = exp(s - mxv)     -> s doc lai f32, exp f64, store f32, totv f64 chua round
 *   ivv = 1.0/totv; s = s * ivv (f32*f64 -> f64 -> f32)
 *   u > t -> 0
 * exp: MSVC == .NET Math.Exp (probe _nt4: 3001/3001, dai -100..+20; o day
 * doi so <= 0 nen nam trong dai da kiem).
 */
EXPORT int SoftmaxCausalFwd(float* s, int s_len, int n, double inv) {
    if (!s) return -1;
    if (n <= 0) return -2;
    if ((long long)s_len < (long long)n * n) return -5;

    for (int t = 0; t < n; t++) {
        float* row = s + (long long)t * n;

        /* scale + max: mxv la f64 TRUOC khi lam tron f32 */
        double mxv = (double)row[0] * inv;
        row[0] = (float)mxv;
        for (int u = 1; u <= t; u++) {
            double m0 = (double)row[u] * inv;
            row[u] = (float)m0;
            if (m0 > mxv) mxv = m0;
        }

        /* exp + tong: doc lai f32, cong don f64 (chua lam tron) */
        double totv = 0.0;
        for (int u = 0; u <= t; u++) {
            double e = exp((double)row[u] - mxv);
            row[u] = (float)e;
            totv = totv + e;
        }

        double ivv = 1.0 / totv;
        for (int u = 0; u <= t; u++) row[u] = (float)((double)row[u] * ivv);
        for (int u = t + 1; u < n; u++) row[u] = 0.0f;
    }
    return 0;
}

/* ---- SOFTMAX CAUSAL BWD: dp in-place, P=softmax causal ---- */
EXPORT int SoftmaxCausalBwd(float* dp, int dp_len, const float* P, int P_len,
                            const float* dctx, int dc_len, const float* ctx, int c_len,
                            int n, int hd) {
    if (!dp || !P || !dctx || !ctx) return -1;
    if (n <= 0 || hd <= 0) return -2;

    long long nn = (long long)n * n;
    long long nd = (long long)n * hd;
    if (dp_len < nn || P_len < nn || dc_len < nd || c_len < nd) return -5;

    for (int t = 0; t < n; t++) {
        const float* d  = dctx + (long long)t * hd;
        const float* ct = ctx  + (long long)t * hd;
        const float* p  = P    + (long long)t * n;
        float*       ds = dp   + (long long)t * n;

        /* dotv: tich f32, tich luy f64 tuan tu hd */
        double dotv = 0.0;
        for (int u = 0; u < hd; u++) {
            float prod = d[u] * ct[u];
            dotv = dotv + (double)prod;
        }

        /* u <= t: ds = p * (dp - dotv) (f64), u > t: 0 */
        for (int u = 0; u <= t; u++) ds[u] = (float)((double)p[u] * ((double)ds[u] - dotv));
        for (int u = t + 1; u < n; u++) ds[u] = 0.0f;
    }
    return 0;
}
/* ---- MEMORY-CRAM: _attn_hb_merge native (1 head) --------------
 * Gop 1 head output rieng (PACKED) vao ctxT/dqkv theo vi tri (t, head, d).
 * Tra lai 0 = OK; <0 = loi -> caller fallback duong interpreted cu. */
EXPORT int MergeHbHead(const float* co, const float* dq, float* ctxT, float* dqkv,
                       int n, int h, int hd, int hlo, int hhi) {
    if (!co || !dq || !ctxT || !dqkv) return -1;
    if (n <= 0 || h <= 0 || hd != 64) return -13;
    if (hlo < 0 || hhi > h / hd || hlo >= hhi) return -2;
    for (int head = hlo; head < hhi; head++) {
        int ho = head * hd;
        for (int t2 = 0; t2 < n; t2++) {
            long long c0 = (long long)t2 * h + ho;
            long long p0 = (long long)t2 * 3 * hd;
            long long r0 = (long long)t2 * 3 * h + ho;
            const float* src_dq = dq + p0;
            for (int d = 0; d < hd; d++) {
                ctxT[c0 + d]              = co[(long long)t2 * hd + d];
                dqkv[r0 + d]              = src_dq[d];
                dqkv[r0 + h + d]          = src_dq[hd + d];
                dqkv[r0 + 2 * h + d]      = src_dq[2 * hd + d];
            }
        }
    }
    return 0;
}

/* ---- EMBED BWD (op_embed_bwd): gw = scatter-add gy theo idx ---------------
 * gw[r*d + j] += sum_{t: idx[t]=r} gy[t*d + j], voi thu tu .tkv:
 *   counts[r] = so lan r xuat hien (tang dan t)
 *   starts[r] = prefix sum (cumulative)
 *   pos[cursor[r]] = t; cursor[r]++
 *   for q in 0..n-1: t = pos[q]; r = idx[t]; for j in 0..d-1: gw[r*d+j] += gy[t*d+j]
 *   (thu tu cong theo q TANG DAN — bit-exact).
 * giu nguyen bit: moi ptu cong don doc lap, thu tu phep cong giong .tkv.
 * rc < 0 -> caller fallback duong interpreted cu. */
EXPORT int EmbedBwdFused(const long long* idx, int idx_len, int rows, int d,
                        const float* gy, int gy_len, float* gw, int gw_len) {
    if (!idx || !gy || !gw) return -1;
    if (rows <= 0 || d <= 0 || idx_len < 0) return -2;
    long long n = idx_len;
    long long need_gy = n * d;
    long long need_gw = (long long)rows * d;
    if (gy_len < need_gy) return -5;
    if (gw_len < need_gw) return -5;
    /* zero-fill gw (giong t_zeros -> +0.0f) */
    memset(gw, 0, (size_t)need_gw * sizeof(float));

    if (n == 0) return 0;

    /* counts + starts */
    int* counts = (int*)calloc((size_t)rows, sizeof(int));
    int* starts = (int*)malloc((size_t)rows * sizeof(int));
    int* cursor = (int*)malloc((size_t)rows * sizeof(int));
    int* pos = (int*)malloc((size_t)n * sizeof(int));
    if (!counts || !starts || !cursor || !pos) {
        free(counts); free(starts); free(cursor); free(pos);
        return -6;
    }
    for (int r = 0; r < rows; r++) counts[r] = 0;
    for (long long t = 0; t < n; t++) {
        int r = (int)idx[t];
        if (r < 0 || r >= rows) { /* out of range -> fallback */
            free(counts); free(starts); free(cursor); free(pos);
            return -7;
        }
        counts[r] = counts[r] + 1;
    }
    int s = 0;
    for (int r = 0; r < rows; r++) { starts[r] = s; s = s + counts[r]; }
    for (int r = 0; r < rows; r++) cursor[r] = starts[r];
    for (long long t = 0; t < n; t++) {
        int r = (int)idx[t];
        pos[cursor[r]] = (int)t;
        cursor[r] = cursor[r] + 1;
    }
    /* main loop: q in 0..n-1, t = pos[q], r = idx[t] */
    for (long long q = 0; q < n; q++) {
        int t = pos[q];
        int r = (int)idx[t];
        const float* gyrow = gy + (long long)t * d;
        float* gwrow = gw + (long long)r * d;
        for (int j = 0; j < d; j++) gwrow[j] = gwrow[j] + gyrow[j];
    }
    free(counts); free(starts); free(cursor); free(pos);
    return 0;
}


/* ---- LAYERNORM FWD: out = (x - mu) * rstd * g + b -------------------------
 * BIT-EXACT voi duong .tkv interpreted (gpt2_layernorm):
 *   3 pass: mu (f64 acc, /h f32), v (f64 acc), scale (f32).
 *   EPS = 1e-5 (hard-code, khop _EPS cua .tkv).
 * rc < 0 -> caller fallback duong .tkv cu.
 *
 * §0.105 (2026-11-08): uu tien ATen `at::layer_norm` qua bridge
 * (TkvTorchLayerNormFwd) — cung kernel HF GPT-2 -> BIT-IDENTICAL voi PyTorch.
 * rc != 0 (bridge cu/VANG export) -> quay lai duong f64 nguyen van. */
/* forward decl: wrapper o tkv_simd_native.c (cung DLL); ABI: int64_t == long long (win64) */
extern int TkvTorchLayerNormFwd(const float* x, const float* g, const float* b,
                                float* y, long long n, long long h, double eps);
EXPORT int LayernormFwd(const float* x, int x_len, const float* g, int g_len,
                        const float* b, int b_len, float* out, int out_len,
                        int n, int h) {
    if (!x || !g || !b || !out) return -1;
    if (n <= 0 || h <= 0) return -2;
    long long need = (long long)n * h;
    long long need_g = h;
    if (x_len < need || out_len < need || g_len < need_g || b_len < need_g) return -5;
    {
        int rc_at = TkvTorchLayerNormFwd(x, g, b, out, (long long)n, (long long)h, 1e-6);
        if (rc_at == 0) return 0;
    }
    const double EPS = 1e-6;
    for (int i = 0; i < n; i++) {
        const float* row = x + (long long)i * h;
        float* orow = out + (long long)i * h;
        double mu = 0.0;
        for (int j = 0; j < h; j++) mu += (double)row[j];
        mu = mu / (double)h;
        double v = 0.0;
        for (int j = 0; j < h; j++) {
            double d = (double)row[j] - mu;
            v += d * d;
        }
        v = v / (double)h;
        double rstd = 1.0 / sqrt(v + EPS);
        for (int j = 0; j < h; j++) {
            orow[j] = (float)((((double)row[j] - mu) * rstd) * (double)g[j] + (double)b[j]);
        }
    }
    return 0;
}
