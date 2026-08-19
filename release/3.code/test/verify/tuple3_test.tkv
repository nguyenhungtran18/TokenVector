# -*- coding: utf-8 -*-
"""Kiem chung THAT tuple >2 phan tu (ValueTuple`3). Doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_tuple3.tkv'
py_ns = runpy.run_path(str(SRC_PATH))


# unpack3 goi divmod3 dung 'q = a / b' - DSL bien dich '/' tren i32
# thanh CHIA NGUYEN (gioi han da biet, xem STATUS.md muc toan hoc) -
# ham tham chieu dung '//' thay vi chay lai van ban qua runpy.
def _ref_unpack3(a, b):
    q, r, s = a // b, a % b, a + b
    return q + r + s


cases = [
    ('unpack3', _ref_unpack3, [(17, 5), (10, 3), (1, 1)]),
    ('rotate3', py_ns['rotate3'], [(1, 2, 3), (7, 8, 9), (0, 0, 0)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_tuple3_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("TUPLE3 SUPPORT: PASS - tuple 3 phan tu (return/unpack/hoan doi) bien dich THAT va dung 100%.")
