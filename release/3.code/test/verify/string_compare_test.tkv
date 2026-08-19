# -*- coding: utf-8 -*-
"""Kiem chung THAT so sanh thu tu chuoi (>,<,>=,<=), moi them 2026-07-28
sau khi lo hong nay lam that bai 1 ham that trong batch AI-port. Doi
chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_string_compare.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('count_digits', py_ns['count_digits'], [('a1b22c333',), ('hello',), ('12345',), ('',)]),
    ('is_lower_alpha', py_ns['is_lower_alpha'], [('a',), ('z',), ('A',), ('5',)]),
    ('str_less_than', py_ns['str_less_than'], [('apple', 'banana'), ('z', 'a'), ('cat', 'cat')]),
    ('str_ge', py_ns['str_ge'], [('zoo', 'apple'), ('a', 'z'), ('same', 'same')]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_string_compare_{entry}.exe'
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
print("STRING-COMPARE SUPPORT: PASS - >,<,>=,<= tren chuoi bien dich THAT va dung 100%.")
