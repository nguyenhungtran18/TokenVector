import sys


def bm_add(reps, n):
    half = n // 2
    a = [0.0] * n
    b = [0.0] * half
    r = [0.0] * half
    for i in range(n):
        a[i] = (i % 97) * 0.1
    for i in range(half):
        b[i] = (i % 4) + 1.0
    cs = csq = 0.0
    for _ in range(reps):
        for i in range(half):
            r[i] = a[i] + b[i]
        for i in range(half):
            r[i] = a[half + i] + b[i]
        cs = csq = 0.0
        for i in range(half):
            cs += r[i]
            csq += r[i] * r[i]
    print(f"sum={cs} sumsq={csq}")



def _mm(a, b, r, n):
    for i in range(n):
        for j in range(n):
            s = 0.0
            for kk in range(n):
                s += a[i * n + kk] * b[kk * n + j]
            r[i * n + j] = s

def bm_matmul(reps, n):
    m = n * n
    a = [((i % 7) - 3.0) for i in range(m)]
    b = [((i % 5) - 2.0) for i in range(m)]
    r = [0.0] * m
    cs = 0.0
    for _ in range(reps):
        _mm(a, b, r, n)
        cs = 0.0
        for i in range(m):
            cs += r[i]
    print(f"sum={cs}")



def _fib(n):
    if n < 2:
        return n
    return _fib(n - 1) + _fib(n - 2)

def bm_fib(n):
    print(f"fib={_fib(n)}")



def _sort(xs, lo, hi, tmp):
    if hi - lo < 2:
        return
    mid = (lo + hi) // 2
    _sort(xs, lo, mid, tmp)
    _sort(xs, mid, hi, tmp)
    # Merge qua buffer tam. Merge tai cho loi khi k == i: ghi vao phan tu
    # chua doc xong nen MAT phan tu - dau ra co thu tu nhung khong phai hoan vi.
    tmp[lo:hi] = xs[lo:hi]
    i, j, k = 0, mid - lo, lo
    while i < mid - lo and j < hi - lo:
        if tmp[lo + i] <= tmp[lo + j]:
            xs[k] = tmp[lo + i]; i += 1
        else:
            xs[k] = tmp[lo + j]; j += 1
        k += 1
    while i < mid - lo:
        xs[k] = tmp[lo + i]; i += 1; k += 1
    while j < hi - lo:
        xs[k] = tmp[lo + j]; j += 1; k += 1

def bm_sort(reps, n):
    src = [(i * 1103515245 + 12345) % 65536 for i in range(n)]
    tmp = [0] * n  # buffer dung chung, tao mot lan ngoai vong lap
    cs = 0
    for _ in range(reps):
        work = list(src)
        _sort(work, 0, n, tmp)
        cs = work[0] + work[n - 1] + work[n // 2]
    print(f"cs={cs}")



def bm_str(reps, n):
    cs = 0
    chunk = "abcdefgh"
    for _ in range(reps):
        buf = [chunk] * n
        s = "".join(buf)
        # Phai quet DUNG range(n) nhu phia TokenVector (s[i:i+1] == "e"),
        # KHONG dung s.count("e") - count quet ca chuoi nen lam 2 ben
        # khong con cung so luong cong viec va checksum lech nhau.
        cnt = 0
        for i in range(n):
            if s[i:i + 1] == "e":
                cnt += 1
        cs = len(s) + cnt
    print(f"cs={cs}")


# ---- NumPy: cung khoi viec. Do theo 3 quy tac cua run_benchmark.tkv:
# best-of-N, do BEN trong vong lap, khoi tao + checksum ngoai vong do.
# fib bo qua: de quy, NumPy khong lam duoc ma khong doi thuat toan.
import time as _time

def npbm_add(reps, n):
    import numpy as np
    half = n // 2
    a = (np.arange(n) % 97) * 0.1
    b = (np.arange(half) % 4) + 1.0
    r = np.empty(half)
    best = 1.0e9
    cs = csq = 0.0
    for _ in range(reps):
        t0 = _time.perf_counter()
        r[:] = a[:half] + b
        r[:] = a[half:] + b
        d = (_time.perf_counter() - t0) * 1000.0
        if d < best:
            best = d
        cs = float(r.sum())
        csq = float((r * r).sum())
    print(f"sum={cs} sumsq={csq}  best={best}")


def npbm_matmul(reps, n):
    import numpy as np
    m = n * n
    a = np.array([((i % 7) - 3.0) for i in range(m)]).reshape(n, n)
    b = np.array([((i % 5) - 2.0) for i in range(m)]).reshape(n, n)
    r = np.zeros((n, n))
    best = 1.0e9
    cs = 0.0
    for _ in range(reps):
        t0 = _time.perf_counter()
        np.dot(a, b, out=r)
        d = (_time.perf_counter() - t0) * 1000.0
        if d < best:
            best = d
        cs = float(r.sum())
    print(f"sum={cs}  best={best}")


def npbm_sort(reps, n):
    import numpy as np
    src = np.array([(i * 1103515245 + 12345) % 65536 for i in range(n)], dtype=np.int64)
    work = np.empty_like(src)
    best = 1.0e9
    cs = 0
    for _ in range(reps):
        work[:] = src  # copy ngoai vong do ( nhu tkv )
        t0 = _time.perf_counter()
        work.sort()
        d = (_time.perf_counter() - t0) * 1000.0
        if d < best:
            best = d
        cs = int(work[0]) + int(work[n - 1]) + int(work[n // 2])
    print(f"cs={cs}  best={best}")


def npbm_str(reps, n):
    import numpy as np
    chunk = "abcdefgh"
    best = 1.0e9
    cs = 0
    for _ in range(reps):
        t0 = _time.perf_counter()
        buf = [chunk] * n
        s = "".join(buf)
        # Quet DUNG range(n) dau tien nhu Python/TokenVector (khong quet het 8n)
        b = np.frombuffer(s.encode("ascii"), dtype=np.uint8)
        cnt = int((b[:n] == 101).sum())
        cs = len(s) + cnt
        d = (_time.perf_counter() - t0) * 1000.0
        if d < best:
            best = d
    print(f"cs={cs}  best={best}")


_DISPATCH = {'add': 'bm_add', 'matmul32': 'bm_matmul', 'fib': 'bm_fib', 'sort': 'bm_sort', 'string': 'bm_str',
             'np_add': 'npbm_add', 'np_matmul32': 'npbm_matmul', 'np_sort': 'npbm_sort', 'np_string': 'npbm_str'}
_CALLS = {'add': 'bm_add(20, 262144)', 'matmul32': 'bm_matmul(20, 32)', 'fib': 'bm_fib(32)', 'sort': 'bm_sort(20, 200000)', 'string': 'bm_str(3, 200000)',
          'np_add': 'npbm_add(20, 262144)', 'np_matmul32': 'npbm_matmul(20, 32)', 'np_sort': 'npbm_sort(20, 200000)', 'np_string': 'npbm_str(3, 200000)'}
if __name__ == "__main__":
    k = sys.argv[1]
    exec(_CALLS[k])
