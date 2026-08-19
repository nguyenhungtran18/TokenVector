# -*- coding: utf-8 -*-
"""Kiem chung THAT s.zfill(width) (Huong A stdlib mo rong, nhom rieng
stdlib_string_zfill.py, 2026-07-29) - doi chieu voi CPython that (runpy).
Test bao gom dau am ('-42'.zfill(6) -> '-00042', KHONG phai '000-42'),
dau duong ('+42'), khong dau, va width <= len(s) (khong doi)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_string_zfill.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_string_zfill_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
cases = [('42', 5), ('-42', 6), ('+42', 6), ('42', 2), ('42', 1), ('hello', 8)]
for s, width in cases:
    total += 1
    expected = py_ns['compute'](s, width)
    r = subprocess.run([str(exe_path), s, str(width)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((s, width, expected, None, r.stdout, r.stderr))
        continue
    got = r.stdout.strip()
    if got != expected:
        mismatches.append((s, width, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STRING_ZFILL (s.zfill(width)): PASS - dung 100%.")
