import numpy as np, time

def bench(n, runs):
    a = ((np.arange(n*n) % 7) - 3).astype(np.float32).reshape(n, n)
    b = ((np.arange(n*n) % 5) - 2).astype(np.float32).reshape(n, n)
    c = a @ b
    cs = float(c.sum())
    best = 1e18
    for _ in range(runs):
        t0 = time.perf_counter()
        c = a @ b
        t1 = time.perf_counter()
        best = min(best, (t1 - t0) * 1000.0)
    print(f"numpy f32 n={n:3d}  best={best:.6f} ms  checksum={cs:.2f}")

for n in (32, 128, 192, 256, 384, 512):
    bench(n, 100 if n <= 128 else 30)
