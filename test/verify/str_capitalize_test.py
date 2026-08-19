# -*- coding: utf-8 -*-
"""Kiem chung THAT s.capitalize() (Huong A stdlib mo rong, nhom rieng
string_methods_batch4.py, 2026-07-29) - doi chieu voi CPython that
(runpy). Test bao gom chuoi rong (gioi han da xu ly, tranh
ArgumentOutOfRangeException cua Substring(1) tren chuoi rong)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_str_capitalize.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_str_capitalize_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for s in ('hello WORLD', 'HELLO', 'x', '', 'hELLO wOrLD 123'):
    total += 1
    expected = py_ns['compute'](s)
    r = subprocess.run([str(exe_path), s], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((s, expected, None, r.stdout, r.stderr))
        continue
    got = r.stdout.strip()
    if got != expected:
        mismatches.append((s, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STR_CAPITALIZE (s.capitalize()): PASS - dung 100%.")
