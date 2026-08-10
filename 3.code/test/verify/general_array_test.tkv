# -*- coding: utf-8 -*-
"""Kiem chung THAT phep toan mang tong quat qua list runtime-size (muc
tieu #3). Doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_general_array.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('elementwise_add_runtime', py_ns['elementwise_add_runtime'], [(5,), (1,), (10,)]),
    ('elementwise_mul_runtime', py_ns['elementwise_mul_runtime'], [(5,), (1,), (8,)]),
    ('dot_product_runtime', py_ns['dot_product_runtime'], [(5,), (1,), (8,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_general_array_{entry}.exe'
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
print("GENERAL-ARRAY SUPPORT: PASS - cong/nhan/dot-product tren list runtime-size khop CPython that 100%.")
