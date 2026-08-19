# -*- coding: utf-8 -*-
"""Kiem chung THAT set/frozenset dong (HashSet<T>). Doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_set.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('count_unique_mod', py_ns['count_unique_mod'], [(10, 3), (5, 1), (1, 5)]),
    ('contains_test', py_ns['contains_test'], [(5, 3), (5, 10), (0, 0)]),
    ('set_comp_evens', py_ns['set_comp_evens'], [(10,), (0,), (1,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_set_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("SET SUPPORT: PASS - set() dong (add/in/len/comprehension) bien dich THAT va dung 100%.")
