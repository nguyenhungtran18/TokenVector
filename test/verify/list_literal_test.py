# -*- coding: utf-8 -*-
"""Kiem chung THAT list literal CO PHAN TU (Giai doan 0.1, 2026-08-03,
dong Python-parity-gap v2): 'xs = [3, 1, 2]' - truoc day chi '[]' roi
'.append()' moi hoat dong, biên dich SyntaxError neu co phan tu ngay
trong '[]'. Dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython
that (runpy) cho ca int/float/str."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_list_literal.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('int_list_sum', py_ns['int_list_sum'], [0, 1, 5]),
    ('float_list_sum', py_ns['float_list_sum'], [0, 1, 5]),
    ('str_list_pick', py_ns['str_list_pick'], [0, 1, 2, 5]),
]

total = 0
mismatches = []
for entry, py_func, ns in cases:
    exe_path = HERE / f'sample_list_literal_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for n in ns:
        total += 1
        expected = py_func(n)
        r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, n, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        if isinstance(expected, float):
            got_ok = abs(float(got) - float(expected)) < 1e-4
        elif isinstance(expected, int):
            got_ok = int(got) == int(expected)
        else:
            got_ok = got == str(expected)
        if not got_ok:
            mismatches.append((entry, n, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("LIST_LITERAL SUPPORT: PASS - '[3,1,2]' co phan tu bien dich THAT va dung 100% (int/float/str).")
