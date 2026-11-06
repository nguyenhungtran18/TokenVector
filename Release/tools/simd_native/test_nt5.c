#include <stdio.h>
#include <stdint.h>
#include <string.h>
static void pc(const char* name, float v) { uint32_t b; memcpy(&b, &v, 4); printf("%s=0x%08x\n", name, b); }
int main(void) {
    int k;
    for (k = 51; k <= 52; k++) {
        float a = (float)k * 0.04f - 20.0f;
        float b = (float)((double)k * (double)0.04f - 20.0f);
        float c = (float)((double)k * 0.04 - 20.0);
        char t[32];
        snprintf(t,32,"k%d a",k); pc(t,a); snprintf(t,32,"k%d b",k); pc(t,b); snprintf(t,32,"k%d c",k); pc(t,c);
    }
    return 0;
}
