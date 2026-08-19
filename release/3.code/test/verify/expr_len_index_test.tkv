# -*- coding: utf-8 -*-
"""len(<bieu thuc>) + <bieu thuc>[i] (2026-08-03).

Trong tai la CHINH CPython: sample_expr_len_index.tkv la Python hop le
nen bo test chay no bang CPython roi so voi stdout cua .exe da bien dich.
Khong tu tuyen bo ky vong."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_expr_len_index.tkv'
ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

CASES = [
    ('count_fields', ['a,b,c']),
    ('count_fields', ['solo']),
    ('first_field', ['a,b,c']),
    ('nth_field', ['x,y,z', 1]),
    ('len_of_nth', ['a,bcd,e', 1]),
    ('fields_plus_ten', ['a,b']),
    ('len_of_concat', ['ab', 'cde']),
]
mismatches = []
built = {}
for entry, args in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_expr_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *[str(a) for a in args]],
                       capture_output=True, text=True)
    expected = str(ns[entry](*args))
    got = r.stdout.strip()
    print(f'  {entry}({", ".join(map(repr, args))}) -> exe={got!r} CPython={expected!r}')
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('len(<bieu thuc>) + <bieu thuc>[i] (doi chieu CPython): PASS - dung 100%.')
