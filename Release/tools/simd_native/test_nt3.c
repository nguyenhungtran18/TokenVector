#include <stdio.h>
#include <stdint.h>
#include <string.h>

static void pc(const char* name, float v) {
    uint32_t b;
    memcpy(&b, &v, 4);
    printf("%s=0x%08x\n", name, b);
}

int main(void) {
    int k;
    for (k = 0; k < 5; k++) {
        float a = (float)k * 0.04f - 20.0f;
        float b = (float)((double)k * 0.04 - 20.0);
        float c = (float)((double)k * (double)0.04f - 20.0);
        char tag[32];
        snprintf(tag, sizeof tag, "k=%d a", k); pc(tag, a);
        snprintf(tag, sizeof tag, "k=%d b", k); pc(tag, b);
        snprintf(tag, sizeof tag, "k=%d c", k); pc(tag, c);
    }
    return 0;
}
