# -*- coding: utf-8 -*-
"""Kiem chung THAT default args (goi ham thieu tham so cuoi) +
enumerate()/zip() trong for-loop (Wave 2, 2026-07-29) - dung CLI tu
dong (compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_default_args_itertools.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('call_add_omit', py_ns['call_add_omit'], [(5,), (0,), (-3,)]),
    ('call_add_full', py_ns['call_add_full'], [(5, 2), (0, 0)]),
    ('call_greet_omit', py_ns['call_greet_omit'], [('Hung',), ('An',)]),
    ('sum_enumerate', py_ns['sum_enumerate'], [()]),
    ('sum_zip_shorter_first', py_ns['sum_zip_shorter_first'], [()]),
    ('sum_zip_shorter_second', py_ns['sum_zip_shorter_second'], [()]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_default_args_itertools_{entry}.exe'
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
        got_ok = (got == str(expected)) if isinstance(expected, str) else (int(got) == int(expected))
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("DEFAULT-ARGS + ENUMERATE/ZIP SUPPORT: PASS - bien dich THAT va dung 100%.")
