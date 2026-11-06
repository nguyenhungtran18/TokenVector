/* test_nt5b.c - doi bit erf/dgelu cua .NET (file _nt5.tkv) voi 2 kieu:
 *   A: ep f32 truoc khi tinh erf  (JIT truncate f64 -> f32 cho call)
 *   B: giu f64 trong erf
 * Neu kieu A khop 100% -> GeluErfBwd native dung doan doan IL.
 * Build: cl /nologo /O2 /fp:precise test_nt5b.c /Fe:test_nt5b.exe
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

static float erf_f32(float x) {          /* IL: erf(float32) */
    double sg = 1.0;
    if (x < 0.0f) sg = -1.0;
    float ax = fabsf(x);
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

static float dgelu_a(float v, float gy) { /* A: erf(arg f32) */
    double s = 1.4142135623730951;
    float ef = erf_f32((float)((double)v / s));
    double d = 0.5 * (1.0 + (double)ef)
             + (double)v * 0.3989422804014327 * exp(((-0.5) * (double)v) * (double)v);
    return (float)((double)gy * d);
}

static uint32_t parse_bits(char** pp) {
    char* p = *pp;
    long long sv = strtoll(p, NULL, 16);
    char* sp = strchr(p, ' ');
    *pp = sp ? sp + 1 : p + strlen(p);
    return (uint32_t)sv;
}

int main(int argc, char** argv) {
    FILE* f = fopen(argc > 1 ? argv[1] : "out/nt5_tkv.txt", "r");
    char line[256];
    long tot = 0, bad_e = 0, bad_g = 0, shown = 0;
    if (!f) { printf("khong mo duoc file\n"); return 2; }
    while (fgets(line, sizeof line, f)) {
        char* p = strstr(line, "v=");
        char* q;
        uint32_t vb, eb, gb, cb, cg;
        float v;
        if (!p) continue;
        p += 2;
        vb = parse_bits(&p);
        p = strstr(p, "e="); if (!p) continue; p += 2; eb = parse_bits(&p);
        p = strstr(p, "g="); if (!p) continue; p += 2; gb = parse_bits(&p);
        memcpy(&v, &vb, 4);
        { float t = erf_f32((float)((double)v / 1.4142135623730951)); memcpy(&cb, &t, 4); }
        cg = 0; { float t = dgelu_a(v, 0.75f); memcpy(&cg, &t, 4); }
        tot++;
        if (cb != eb) { bad_e++; if (shown < 5) { printf("ERF LECH v=%.9g tkv=0x%08x c=0x%08x\n", (double)v, eb, cb); shown++; } }
        if (cg != gb) { bad_g++; if (shown < 10) { printf("GEL LECH v=%.9g tkv=0x%08x c=0x%08x\n", (double)v, gb, cg); shown++; } }
    }
    fclose(f);
    printf("TOTAL=%ld BAD_ERF=%ld BAD_GELU=%ld\n", tot, bad_e, bad_g);
    return (bad_e || bad_g) ? 1 : 0;
}
