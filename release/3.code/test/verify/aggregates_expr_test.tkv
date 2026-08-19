# -*- coding: utf-8 -*-
"""sum/min/max/sorted/any/all trong BIEU THUC + nhan ca SET (2026-08-03).

Trong tai la CHINH CPython: sample_aggregates_expr.tkv la Python hop le
(sum/min/max/sorted/any/all/set deu la builtin that cua Python) nen bo
test chay no bang CPython roi so voi stdout cua .exe."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_aggregates_expr.tkv'
ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

CASES = [
    ('sum_plus', [1, 2, 3]),
    ('max_gate', [4, 9, 2]),
    ('max_gate', [1, 2, 3]),
    ('span', [4, 9, 2]),
    ('sorted_first', [3, 1, 2]),
    ('sorted_keeps_source', [3, 1, 2]),     # sorted() KHONG duoc sua list nguon
    ('any_all_combo', [0, 1]),
    ('any_all_combo', [1, 1]),
    ('any_all_combo', [0, 0]),
    ('sum_of_set', [2, 3, 2]),              # trung lap bi loai
    ('sorted_set_first', [5, 1, 5]),
]
mismatches = []
built = {}
for entry, args in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_agg_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *[str(a) for a in args]],
                       capture_output=True, text=True)
    expected = str(ns[entry](*args))
    got = r.stdout.strip()
    print(f'  {entry}{tuple(args)} -> exe={got!r} CPython={expected!r}')
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('sum/min/max/sorted/any/all trong bieu thuc + set (doi chieu CPython): PASS - dung 100%.')
