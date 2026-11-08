/* test_tkv_step124.c - probe D5-3 (embed) + D5-2 (linear probe). */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <windows.h>

typedef int (*embed_fn)(const int64_t*, const int64_t*, const float*, const float*,
                        float*, int64_t, int64_t);

int main(void) {
    HMODULE h = LoadLibraryA("tkv_step124.dll");
    if (!h) { printf("load fail\n"); return 2; }
    embed_fn f = (embed_fn)GetProcAddress(h, "TkvStep124Embed");
    if (!f) { printf("sym fail\n"); return 2; }

    /* vocab 4, h 8; ids/pos length 3 */
    int64_t ids[3]  = { 2, 0, 3 };
    int64_t pos[3]  = { 0, 1, 2 };
    float wte[32]   = { /* 4 rows of 8 */
        0.0f, 0.1f, 0.2f, 0.3f, 0.4f, 0.5f, 0.6f, 0.7f,
        1.0f, 1.1f, 1.2f, 1.3f, 1.4f, 1.5f, 1.6f, 1.7f,
        2.0f, 2.1f, 2.2f, 2.3f, 2.4f, 2.5f, 2.6f, 2.7f,
        3.0f, 3.1f, 3.2f, 3.3f, 3.4f, 3.5f, 3.6f, 3.7f
    };
    float wpe[24]   = { /* 3 rows of 8 (need pos 0..2) */
        0.00f, 0.01f, 0.02f, 0.03f, 0.04f, 0.05f, 0.06f, 0.07f,
        0.10f, 0.11f, 0.12f, 0.13f, 0.14f, 0.15f, 0.16f, 0.17f,
        0.20f, 0.21f, 0.22f, 0.23f, 0.24f, 0.25f, 0.26f, 0.27f
    };
    float out[24];
    memset(out, 0xAA, sizeof(out));
    int64_t n = 3, hh = 8;
    int rc = f(ids, pos, wte, wpe, out, n, hh);
    printf("rc=%d\n", rc);
    for (int64_t t = 0; t < n; t++) {
        printf("row %lld: ", (long long)t);
        for (int64_t j = 0; j < hh; j++) printf("%.2f ", out[t * hh + j]);
        printf("\n");
    }
    if (rc != 0) return 3;
    /* compute expected = wte + wpe (same f32 add rounding as kernel) */
    int64_t ids_local[3] = { 2, 0, 3 };
    int64_t pos_local[3] = { 0, 1, 2 };
    for (int64_t t = 0; t < n; t++) {
        for (int64_t j = 0; j < hh; j++) {
            float exp = wte[ids_local[t] * hh + j] + wpe[pos_local[t] * hh + j];
            if (out[t * hh + j] != exp) { printf("MISMATCH t=%lld j=%lld\n", (long long)t, (long long)j); return 4; }
        }
    }
    printf("OK\n");
    return 0;
}
