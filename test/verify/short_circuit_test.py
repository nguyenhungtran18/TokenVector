# -*- coding: utf-8 -*-
"""Kiem chung THAT 'and'/'or' short-circuit dung ngu nghia Python.

Loi that da xay ra (2026-08-02): compile_boolop sinh thang 'and'/'or' bitwise
cua CIL, tuc TINH CA HAI VE. 'i < len(lst) and lst[i] == x' nem
ArgumentOutOfRangeException khi i == len(lst) du ve trai da sai - trong khi
CPython tra ve False binh thuong. Test nay khoa lai hanh vi dung.

Luu y ve or_short: chi goi voi n > 0. Voi n <= 0 thi CHINH CPython cung nem
IndexError (ve trai sai thi 'or' PHAI tinh ve phai) - do la ngu nghia dung,
khong phai loi.
"""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sc_probe2.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('and_true', [(1,), (0,), (2,)]),
    ('or_short', [(1,), (5,)]),
    ('chain', [(1, 2, 3), (3, 2, 1), (1, 1, 2)]),
    ('mixed', [(1, 1), (-5, 0), (1, -1), (0, 0)]),
]

total = 0
mismatches = []
for entry, arg_sets in cases:
    exe_path = HERE / f'sc2_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_ns[entry](*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                           capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
