/* test_tkv_step124.c - probe the D5-2 trampoline: load tkv_step124.dll,
 * call TkvStep124Probe on [2,2] @ [2,2], print rc + y values. */
#include <stdio.h>
#include <stdint.h>
#include <windows.h>

typedef int (*step124_fn)(const float*, const float*, const float*, float*,
                          int64_t, int64_t, int64_t);

int main(void) {
    HMODULE h = LoadLibraryA("tkv_step124.dll");
    if (!h) { printf("load fail\n"); return 2; }
    step124_fn f = (step124_fn)GetProcAddress(h, "TkvStep124Probe");
    if (!f) { printf("sym fail\n"); return 2; }

    float x[4]  = { 1, 2, 3, 4 };
    float w[4]  = { 5, 6, 7, 8 };
    float b[2]  = { 10, 20 };
    float y[4]  = { 0, 0, 0, 0 };
    int rc = f(x, w, b, y, 2, 2, 2);
    printf("rc=%d y=", rc);
    for (int i = 0; i < 4; i++) printf("%.2f ", y[i]);
    printf("\n");
    /* expected: x@w = [19, 22, 43, 50]; +b = [29, 42, 53, 70] */
    if (rc != 0) return 3;
    if (y[0] != 29.0f || y[1] != 42.0f || y[2] != 53.0f || y[3] != 70.0f) {
        printf("MISMATCH\n"); return 4;
    }
    printf("OK\n");
    return 0;
}
