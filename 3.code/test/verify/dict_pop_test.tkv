# -*- coding: utf-8 -*-
"""Kiem chung THAT d.pop(k, default) (Huong A stdlib mo rong, nhom rieng
dict_pop.py, 2026-07-29) - mo phong kien truc d.get() da co, dung ky
thuat 'dup+pop' de tranh can hidden local. Doi chieu voi CPython that
(runpy). Test ca truong hop key TON TAI (pop lan 1 ra gia tri that, xoa
khoi dict - len() giam) VA key KHONG con (pop lan 2 tra ve default)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_dict_pop.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_dict_pop_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for k in (1, 2, 3, 99):
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
print("DICT_POP (d.pop(k, default)): PASS - dung 100%.")
