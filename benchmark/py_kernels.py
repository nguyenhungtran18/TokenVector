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



def _sort(xs, lo, hi):
    if hi - lo < 2:
        return
    mid = (lo + hi) // 2
    _sort(xs, lo, mid)
    _sort(xs, mid, hi)
    i, j, k = lo, mid, lo
    while i < mid and j < hi:
        if xs[i] <= xs[j]:
            xs[k] = xs[i]; i += 1
        else:
            xs[k] = xs[j]; j += 1
        k += 1
    while i < mid:
        xs[k] = xs[i]; i += 1; k += 1
    while j < hi:
        xs[k] = xs[j]; j += 1; k += 1

def bm_sort(reps, n):
    src = [(i * 1103515245 + 12345) % 65536 for i in range(n)]
    cs = 0
    for _ in range(reps):
        work = list(src)
        _sort(work, 0, n)
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


_DISPATCH = {'add': 'bm_add', 'matmul32': 'bm_matmul', 'fib': 'bm_fib', 'sort': 'bm_sort', 'string': 'bm_str'}
_CALLS = {'add': 'bm_add(20, 262144)', 'matmul32': 'bm_matmul(20, 32)', 'fib': 'bm_fib(32)', 'sort': 'bm_sort(20, 200000)', 'string': 'bm_str(3, 200000)'}
if __name__ == "__main__":
    k = sys.argv[1]
    exec(_CALLS[k])
