# -*- coding: utf-8 -*-
"""Kiem chung THAT tuple/nhieu gia tri tra ve - dung CLI tu dong
(compile_tkv_cli) cho 'use_pair' (goi ham tra ve tuple + giai nen) va
'swap_test' (gan song song / hoan doi) - CA HAI deu tra ve VO HUONG nen
dung duoc CLI truc tiep; 'make_pair' (return type tuple) duoc kiem chung
GIAN TIEP qua use_pair (khong the dung CLI cho ham tra ve tuple - CLI
tu dong hien CHI ho tro entry vo huong, dung nhu thiet ke)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_tuple.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('use_pair', py_ns['use_pair'], [(10, 2), (9, 3), (0, 5), (100, 10)]),
    ('swap_test', py_ns['swap_test'], [(10, 2), (0, 0), (-5, 3), (7, 7)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_tuple_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        if entry == 'use_pair':
            got = float(r.stdout.strip())
            ok = abs(got - float(expected)) < 1e-3
        else:
            got = int(r.stdout.strip())
            ok = got == int(expected)
        if not ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("TUPLE SUPPORT: PASS - return a,b / x,y=f(...) / x,y=y,x bien dich THAT va dung 100%.")
