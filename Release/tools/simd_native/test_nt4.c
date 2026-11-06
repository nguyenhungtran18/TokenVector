#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
int main(void) {
    uint32_t b = 0xc189a114u; /* gia tri tu NT2: -17.96? can xac nhan */
    float v; memcpy(&v, &b, 4);
    float e = (float)exp((double)v);
    uint32_t eb; memcpy(&eb, &e, 4);
    printf("v=%.9g vbits=0x%08x expbits=0x%08x\n", v, b, eb);
    return 0;
}
