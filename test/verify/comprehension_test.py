# -*- coding: utf-8 -*-
"""Kiem chung THAT list/dict comprehension. Doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_comprehension.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('sum_of_squares_comp', py_ns['sum_of_squares_comp'], [(5,), (0,), (1,), (10,)]),
    ('filtered_sum_comp', py_ns['filtered_sum_comp'], [(5,), (0,), (10,)]),
    ('doubled_from_list_comp', py_ns['doubled_from_list_comp'], [(5,), (0,), (3,)]),
    ('dict_comp_squares', py_ns['dict_comp_squares'], [(5,), (0,), (1,)]),
    ('dict_comp_from_items', py_ns['dict_comp_from_items'], [(5,), (0,), (3,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_comprehension_{entry}.exe'
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
print("COMPREHENSION SUPPORT: PASS - list/dict comprehension bien dich THAT va dung 100%.")
