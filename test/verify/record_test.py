# -*- coding: utf-8 -*-
"""Kiem chung THAT 'class dang record' (field-only struct that su) - dung
CLI tu dong (compile_tkv_cli) cho 2 ham vo huong dung Point NOI BO
(khoi tao/doc/GHI field) - doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_record.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('make_point', py_ns['make_point'], [(1.0, 2.0), (0.0, 0.0), (-3.5, 4.5), (10.0, -2.0)]),
    ('move_point', py_ns['move_point'], [(1.0, 2.0, 0.5, 0.5), (0.0, 0.0, 1.0, 1.0), (5.0, -5.0, -1.0, 2.0)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_record_{entry}.exe'
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
print("RECORD SUPPORT: PASS - class dang record (field-only): khoi tao/doc/ghi field bien dich THAT va dung 100%.")
