# -*- coding: utf-8 -*-
"""Kiem chung THAT d.setdefault(k, default) (Huong A stdlib mo rong, nhom
rieng dict_setdefault.py, 2026-07-29) - doi chieu voi CPython that
(runpy). Test ca key TON TAI (khong doi gi) VA key MOI (chen 1 LAN duy
nhat - goi setdefault LAN 2 voi cung key phai thay key DA CO, khong tang
len(d) them nua)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_dict_setdefault.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_dict_setdefault_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for k in (1, 2, 99):
    total += 1
    expected = py_ns['compute'](k)
    r = subprocess.run([str(exe_path), str(k)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((k, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((k, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("DICT_SETDEFAULT (d.setdefault(k, default)): PASS - dung 100%.")
