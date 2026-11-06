#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

int main(void) {
    int k;
    for (k = 0; k < 1001; k++) {
        float v = (float)((double)k * 0.04 - 20.0);
        float e = (float)exp((double)v);
        uint32_t b;
        memcpy(&b, &e, 4);
        printf("NT2 bits=0x%08x\n", b);
    }
    return 0;
}
