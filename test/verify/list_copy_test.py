# -*- coding: utf-8 -*-
"""Kiem chung THAT lst.copy() (Huong A stdlib mo rong, nhom rieng
list_copy.py, 2026-07-29) - doi chieu voi CPython that (runpy). Kiem tra
CA doc lap that (mutate ban sao khong anh huong ban goc - lst2.append()
roi lst.reverse() phai khong lam xao tron nhau)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_list_copy.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_list_copy_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for n in (1, 3, 5, 8):
    total += 1
    expected = py_ns['compute'](n)
    r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((n, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((n, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("LIST_COPY (lst.copy(), doc lap that): PASS - dung 100%.")
