# -*- coding: utf-8 -*-
"""Kiem chung THAT 4 toan tu/cu phap nho moi them (2026-07-28): % (chia
lay du), gan rut gon (+=/-=/*= tren bien/field-record/chi-so-list), not,
raise <Loai>("msg") - dung CLI tu dong, doi chieu voi CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_operators.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

int_cases = [
    ('mod_test', py_ns['mod_test'], [(7, 3), (10, 5), (1, 7), (100, 9)]),
    ('compound_var_test', py_ns['compound_var_test'], [(5, 3), (0, 0), (10, -2), (7, 7)]),
    ('counter_test', py_ns['counter_test'], [(10, 5), (0, 0), (100, -20)]),
    ('list_compound_test', py_ns['list_compound_test'], [(1, 2, 3), (0, 0, 0), (-5, 10, 2)]),
    ('not_test', py_ns['not_test'], [(5, 3), (3, 5), (5, 5)]),
]
str_cases = [
    ('raise_and_catch', py_ns['raise_and_catch'], [(5,), (-1,), (0,), (-100,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in int_cases:
    exe_path = HERE / f'sample_operators_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

for entry, py_func, arg_sets in str_cases:
    exe_path = HERE / f'sample_operators_{entry}.exe'
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
print("OPERATORS SUPPORT: PASS - %, +=/-=/*=, not, raise<Loai>(msg) bien dich THAT va dung 100%.")
