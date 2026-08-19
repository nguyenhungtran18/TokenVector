# -*- coding: utf-8 -*-
"""Kiem chung THAT min(a,b)/max(a,b) + sum(lst)/min(lst)/max(lst)/
sorted(lst) (Wave 3 quick-win, 2026-07-29) - dung CLI tu dong
(compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_aggregates.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('clip_val', py_ns['clip_val'], [(5, 0, 10), (-5, 0, 10), (50, 0, 10), (7, 0, 10)]),
    ('sum_list_i32', py_ns['sum_list_i32'], [()]),
    ('min_list_i32', py_ns['min_list_i32'], [()]),
    ('max_list_f32', py_ns['max_list_f32'], [()]),
    ('sorted_first_last', py_ns['sorted_first_last'], [()]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_aggregates_{entry}.exe'
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
        got_ok = (abs(float(got) - float(expected)) < 1e-4) if isinstance(expected, float) else (int(got) == int(expected))
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("AGGREGATES SUPPORT: PASS - min/max/sum/sorted bien dich THAT va dung 100%.")
