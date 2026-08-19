# -*- coding: utf-8 -*-
"""Kiem chung THAT bug tim thay tu AI-port quy mo lon (2026-07-28): chi so
LONG ngoac vuong ('d[lst[i]] = x' / 'd[lst[i]] += x') truoc do bi tu choi
vi _INDEXED_ASSIGN_RE / _COMPOUND_INDEX_RE dung '[^\\]]+' (khong khop chi
so chua ']' ben trong). Da sua thanh '.+' (greedy). Doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_nested_index.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('unique_char_count', py_ns['unique_char_count'], [('hello world',), ('aaaa',), ('',), ('abcabc',)]),
    ('sum_at_nested_index', py_ns['sum_at_nested_index'], [(3,), (5,), (1,), (0,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_nested_index_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("NESTED-INDEX SUPPORT: PASS - 'd[lst[i]] = x' / 'd[lst[i]] += x' bien dich THAT va dung 100%.")
