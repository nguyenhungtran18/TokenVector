# -*- coding: utf-8 -*-
"""Kiem chung THAT khoang trong ngon ngu #1 - method that tren record
(khong chi field): method KHONG mutate (total, chi doc), method MUTATE
(scale, ghi field qua self trong than method), va method nhan 1 record
KHAC lam tham so (combined_with, goi method tren CA self LAN tham so) -
dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_record_method.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('make_and_scale', py_ns['make_and_scale'],
     [(1.0, 2.0, 3.0), (0.0, 0.0, 5.0), (-1.5, 4.0, 2.0), (10.0, -3.0, 0.5)]),
    ('two_points_sum', py_ns['two_points_sum'],
     [(1.0, 2.0, 3.0, 4.0), (0.0, 0.0, 0.0, 0.0), (-1.0, 2.5, 3.0, -4.0)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_record_method_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = float(r.stdout.strip())
        if abs(got - float(expected)) > 1e-3:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("RECORD-METHOD SUPPORT: PASS - method khong mutate/mutate/nhan record khac lam tham so bien dich THAT va dung 100%.")
