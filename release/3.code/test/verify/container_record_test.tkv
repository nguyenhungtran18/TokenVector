# -*- coding: utf-8 -*-
"""Kiem chung THAT khoang trong ngon ngu #2 - container long nhau chua
record: List<Point> (append/index/for-in) va Dictionary<i32,Point>
(gan/doc/'in') - dung CLI tu dong, doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_container_record.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('sum_of_points_list', py_ns['sum_of_points_list'],
     [(1.0, 2.0, 3.0, 4.0), (0.0, 0.0, 0.0, 0.0), (-1.0, 2.5, 3.0, -4.0)]),
    ('point_at_index', py_ns['point_at_index'],
     [(1.0, 2.0, 3.0, 4.0, 0), (1.0, 2.0, 3.0, 4.0, 1), (5.0, -1.0, 2.0, 2.0, 1)]),
    ('dict_of_points_sum', py_ns['dict_of_points_sum'],
     [(1.0, 2.0), (0.0, 0.0), (-3.0, 4.5)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_container_record_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = float(r.stdout.strip())
        if abs(got - float(expected)) > 1e-3:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("CONTAINER-RECORD SUPPORT: PASS - List<Point>/Dictionary<i32,Point> bien dich THAT va dung 100%.")
