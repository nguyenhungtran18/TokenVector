# -*- coding: utf-8 -*-
"""Kiem chung THAT chi so am cho mang co dinh (np.zeros) + slice voi bien
am hang so (Wave 3, 2026-07-29) - dung CLI tu dong (compile_tkv_cli),
doi chieu voi CPython/numpy that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_neg_slice_array.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('arr_last', py_ns['arr_last'], [()]),
    ('arr_second_last', py_ns['arr_second_last'], [()]),
    ('slice_list_last2', py_ns['slice_list_last2'], [()]),
    ('slice_str_all_but_last', py_ns['slice_str_all_but_last'], [('hello',), ('ab',)]),
    ('slice_str_last2', py_ns['slice_str_last2'], [('hello',), ('ab',)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_neg_slice_array_{entry}.exe'
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
        if entry in ('arr_last', 'arr_second_last'):
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
print("NEG-SLICE/ARRAY SUPPORT: PASS - bien dich THAT va dung 100%.")
