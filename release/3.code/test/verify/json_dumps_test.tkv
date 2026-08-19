# -*- coding: utf-8 -*-
"""json_dumps: thoat ky tu dac biet + dict (2026-08-03).

Trong tai la json.dumps cua CPython voi separators=(',',':') (json_dumps
cua DSL khong chen khoang trang). Khong doi chieu bang cach chay file
.tkv duoi CPython duoc: 'json_dumps' khong phai builtin cua Python."""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_json_dumps.tkv'
BS = chr(92)


def pyjson(obj):
    return json.dumps(obj, separators=(',', ':'), ensure_ascii=False)


CASES = [
    ('dump_str', ['xin chao'], lambda a: pyjson(a[0])),
    ('dump_str', ['co "nhay kep"'], lambda a: pyjson(a[0])),
    ('dump_str', ['co' + BS + 'backslash'], lambda a: pyjson(a[0])),
    ('dump_str', ['dong1\ndong2'], lambda a: pyjson(a[0])),
    ('dump_str', ['tab\there'], lambda a: pyjson(a[0])),
    ('dump_list', ['a"b', 'c' + BS + 'd'], lambda a: pyjson([a[0], a[1]])),
    ('dump_dict_str', ['k1', 'v"1', 'k2', 'dong\n2'],
     lambda a: pyjson({a[0]: a[1], a[2]: a[3]})),
    ('dump_dict_int', ['a', '1', 'b', '-2'],
     lambda a: pyjson({a[0]: int(a[1]), a[2]: int(a[3])})),
    ('dump_in_expr', ['x"y'], lambda a: '[' + pyjson(a[0]) + ']'),
]

mismatches = []
built = {}
for entry, args, expect_fn in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_json_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *args], capture_output=True, text=True)
    expected = expect_fn(args)
    got = r.stdout.strip()
    print(f'  {entry}({args!r})\n     got={got!r}\n     py ={expected!r}')
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('json_dumps (thoat ky tu + dict, doi chieu json.dumps cua CPython): PASS - dung 100%.')
