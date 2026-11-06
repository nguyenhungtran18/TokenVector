/* test_nt.c - ground truth so hoc NATIVE cho YEU CAU #12.
 *   NT2: exp() cua MSVC CRT co bit-giong (float)Math.Exp((double)x) cua .NET
 *        tren cung mot gia tri f32 khong? -> chot gelu_erf_bwd di native duoc.
 * Chay (tu thu muc nay, sau vcvars64):
 *   cl /nologo /O2 /arch:AVX2 test_nt.c /Fe:test_nt.exe && test_nt.exe > out\nt_native.txt
 * Gia tri v lay dung danh sach da in boi out\nt_tkv.txt (doc lai qua strtof).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

int main(void) {
    static const char* vs[] = {
        "-8.0","-7.2","-6.4","-5.6","-4.8","-4.0","-3.1999998","-2.3999999",
        "-1.5999999","-0.7999999","1.1920929e-07","0.80000013","1.6000001",
        "2.4","3.2000003","4.0","4.8","5.6000004","6.4","7.2000003","8.0"
    };
    int k;
    for (k = 0; k < 21; k++) {
        float v = strtof(vs[k], NULL);
        float r = (float)exp((double)v);
        uint32_t b;
        memcpy(&b, &r, 4);
        printf("NT2 v=%s bits=0x%08x\n", vs[k], b);
    }
    /* NT1: tich luy f64 giong IL (f32 widen) */
    {
        double s = 0.0;
        int i;
        float xs[3];
        for (i = 0; i < 3; i++) xs[i] = 0.1f;
        for (i = 0; i < 3; i++) s = s + (double)xs[i];
        printf("NT1 acc_prod=%.17g\n", s);
    }
    return 0;
}
