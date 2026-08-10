# -*- coding: utf-8 -*-
"""Kiem chung THAT dict.items()-as-assign ('items_list = d.items()' +
'for k, v in items_list:', Huong A stdlib mo rong, nhom cuoi cung
2026-07-29) - doi chieu voi CPython that (runpy). Dung tong k*v (khong
phu thuoc THU TU duyet - tranh rui ro thu tu enumeration cua .NET
Dictionary khac CPython dict that, du ca hai deu la insertion-order
trong thuc te)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_dict_items_list.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_dict_items_list_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for n in (0, 1, 5, 10):
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
print("DICT_ITEMS_LIST (items_list = d.items(); for k,v in items_list): PASS - dung 100%.")
