/* test_nt4b.c - doi bit exp() MSVC vs .NET tren input v TRUNG NHAU.
 * Doc file ket qua cua _nt4.tkv (dong "NT4 v=0x.. e=0x.."), tinh lai
 * (float)exp((double)v), so voi bit e cua .NET. Chi khop 100% moi
 * co the di native GeluErfBwd.
 * Build: cl /nologo /O2 test_nt4b.c /Fe:test_nt4b.exe
 * Run:   test_nt4b.exe D:\TokenVector.Inference\out\nt4_tkv.txt
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char** argv) {
    FILE* f = fopen(argc > 1 ? argv[1] : "out/nt4_tkv.txt", "r");
    char line[256];
    long total = 0, bad = 0, shown = 0;
    if (!f) { printf("khong mo duoc file\n"); return 2; }
    while (fgets(line, sizeof line, f)) {
        unsigned long long vb, eb, nb;
        float v, en;
        uint32_t b;
        char* p = strstr(line, "v=");
        char* q;
        long long sv;
        if (!p) continue;
        p += 2;
        q = strchr(p, ' ');
        if (!q) continue;
        *q = 0;
        sv = strtoll(p, NULL, 16);          /* "-0x..." -> so am da truoc '-' */
        vb = (unsigned long long)(uint32_t)sv;
        p = strstr(q + 1, "e=");
        if (!p) continue;
        p += 2;
        sv = strtoll(p, NULL, 16);
        eb = (unsigned long long)(uint32_t)sv;

        b = (uint32_t)vb; memcpy(&v, &b, 4);
        en = (float)exp((double)v);
        memcpy(&b, &en, 4); nb = b;
        total++;
        if (nb != eb) {
            bad++;
            if (shown < 10) {
                printf("LECH #%ld v=%.9g tkv=0x%08x native=0x%08x\n",
                       total - 1, (double)v, (unsigned)(uint32_t)eb, (unsigned)(uint32_t)nb);
                shown++;
            }
        }
    }
    fclose(f);
    printf("TOTAL=%ld BAD=%ld\n", total, bad);
    return bad ? 1 : 0;
}
