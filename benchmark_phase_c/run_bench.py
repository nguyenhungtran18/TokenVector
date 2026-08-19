import subprocess
import time
import os

BASE = os.path.dirname(os.path.abspath(__file__))
N = '2000000'
cases = ['bench_b3', 'bench_nested', 'bench_property', 'bench_multi']


def timeit(cmd):
    t0 = time.perf_counter()
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=BASE)
    t1 = time.perf_counter()
    if r.returncode != 0:
        return None, f'FAIL: {r.stderr[:200]}'
    return t1 - t0, r.stdout.strip()


print(f'{"category":<16} {"TokenVector":>14} {"Python3":>14} {"C#":>14}')
for name in cases:
    tvk_t, tvk_out = timeit([os.path.join(BASE, f'{name}_tkv.exe'), N])
    py_t, py_out = timeit(['py', os.path.join(BASE, f'{name}.py'), N])
    cs_t, cs_out = timeit([os.path.join(BASE, f'{name}_cs.exe'), N])
    tvk_s = f'{tvk_t:.3f}s' if tvk_t is not None else tvk_out
    py_s = f'{py_t:.3f}s' if py_t is not None else py_out
    cs_s = f'{cs_t:.3f}s' if cs_t is not None else cs_out
    print(f'{name:<16} {tvk_s:>14} {py_s:>14} {cs_s:>14}   (out: tvk={tvk_out} py={py_out} cs={cs_out})')
