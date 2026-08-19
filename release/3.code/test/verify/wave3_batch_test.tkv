# -*- coding: utf-8 -*-
"""Kiem chung THAT batch Wave 3 (range step, **, //, chained compare,
any/all, f-string format spec, list.remove() fix) - dung CLI tu dong
(compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_wave3_batch.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('sum_range_step', py_ns['sum_range_step'], [()]),
    ('sum_range_neg_step', py_ns['sum_range_neg_step'], [()]),
    ('power', py_ns['power'], [(2, 10), (3, 3), (5, 0)]),
    ('floor_div', py_ns['floor_div'], [(7, 2), (10, 5), (9, 3)]),
    ('in_range_chain', py_ns['in_range_chain'], [(5, 0, 10), (-5, 0, 10), (15, 0, 10)]),
    ('any_positive', py_ns['any_positive'], [()]),
    ('all_positive', py_ns['all_positive'], [()]),
    ('format_price', py_ns['format_price'], [(3.5,), (10.0,), (2.567,)]),
    ('remove_from_list', py_ns['remove_from_list'], [()]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_wave3_batch_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        if entry == 'power':
            got_ok = abs(float(got) - float(expected)) < 1e-4
        elif isinstance(expected, str):
            got_ok = (got == expected)
        else:
            got_ok = (int(got) == int(expected))
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("WAVE3-BATCH SUPPORT: PASS - bien dich THAT va dung 100%.")
