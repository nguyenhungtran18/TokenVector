# -*- coding: utf-8 -*-
"""Kiem chung THAT stdlib mo rong (Huong A - bang du lieu _MATH_FUNCS,
2026-07-29): tan/asin/acos/atan/sinh/cosh/log10/trunc them vao bang co
san, khong code moi - doi chieu voi CPython that (runpy)."""
import math
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_math_ext.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_math_ext_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for x in (0.5, 0.3, 0.9, 1.0):
    total += 1
    expected = (math.tan(x) + math.asin(x) + math.acos(x) + math.atan(x) +
                math.sinh(x) + math.cosh(x) + math.log10(x) + math.trunc(x))
    r = subprocess.run([str(exe_path), str(x)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((x, expected, None, r.stdout, r.stderr))
        continue
    got = float(r.stdout.strip())
    if abs(got - expected) > 1e-3:
        mismatches.append((x, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("MATH_EXT (tan/asin/acos/atan/sinh/cosh/log10/trunc): PASS - dung 100%.")
