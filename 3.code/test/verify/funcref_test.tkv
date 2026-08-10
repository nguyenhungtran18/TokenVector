# -*- coding: utf-8 -*-
"""Kiem chung THAT 'function reference' hep (Wave 3, 2026-07-29) - dung CLI
tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy). Vi CPython
khong hieu cu phap annotation 'func(i32)->i32' (chi la 1 STRING, khong ep
kieu), py_ns['apply'](double_it, x) van chay dung nhu Python binh thuong -
doi chieu 1-1 voi ket qua .exe bien dich that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_funcref.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('apply_double', py_ns['apply_double'], [(5,), (0,), (-3,)]),
    ('apply_square', py_ns['apply_square'], [(5,), (0,), (-3,)]),
    ('apply_twice_double', py_ns['apply_twice_double'], [(3,), (0,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_funcref_{entry}.exe'
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
print("FUNCREF SUPPORT: PASS - function reference hep bien dich THAT va dung 100%.")
