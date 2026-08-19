# -*- coding: utf-8 -*-
"""Kiem chung THAT s.count(sub) (Huong A stdlib mo rong, nhom rieng
stdlib_string_count.py, 2026-07-29) - dem KHONG chong lap, doi chieu voi
CPython that (runpy). Test bao gom truong hop chong lap tiem an
("aaaa".count("aa") == 2 KHONG PHAI 3, xac minh dung thuat toan
khong-chong-lap)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_string_count.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_string_count_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for s in ('aaaa', 'aaaaa', 'xyz', 'aa', 'axaa'):
    total += 1
    expected = py_ns['compute'](s)
    r = subprocess.run([str(exe_path), s], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((s, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((s, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STRING_COUNT (s.count(sub), khong chong lap): PASS - dung 100%.")
