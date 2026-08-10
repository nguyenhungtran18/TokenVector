# -*- coding: utf-8 -*-
"""Kiem chung THAT container long nhau (Wave 2, 2026-07-29):
List<List<T>> (append 1 bien list khac, ghi lai qua chi so, doc qua bien
trung gian) va Dictionary<K, List<T>> (gia tri la 1 list khac) - dung CLI
tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_nested_container.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = ['sum_nested_list', 'sum_dict_of_list']

total = 0
mismatches = []
for entry in cases:
    exe_path = HERE / f'sample_nested_container_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    total += 1
    expected = py_ns[entry]()
    r = subprocess.run([str(exe_path)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((entry, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((entry, expected, got, r.stdout, r.stderr))

print(f"So ham doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("NESTED CONTAINER SUPPORT: PASS - List<List<T>>/Dictionary<K,List<T>> bien dich THAT va dung 100%.")
