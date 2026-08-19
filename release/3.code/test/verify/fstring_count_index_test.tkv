# -*- coding: utf-8 -*-
"""Kiem chung THAT f-string + list.count()/list.index() (Wave 2,
2026-07-29) - dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython
that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_fstring_count_index.tkv'
py_ns = runpy.run_path(str(SRC_PATH))
py_greet, py_count_and_find = py_ns['greet'], py_ns['count_and_find']

cases = [
    ('greet', py_greet, [('Hung', 25), ('An', 7), ('', 0)]),
    ('count_and_find', py_count_and_find, [(3,), (9,), (100,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_fstring_count_index_{entry}.exe'
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
        got_ok = (got == str(expected)) if entry == 'greet' else (int(got) == int(expected))
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("F-STRING + LIST.COUNT/INDEX SUPPORT: PASS - bien dich THAT va dung 100%.")
