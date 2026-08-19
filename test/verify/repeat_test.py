# -*- coding: utf-8 -*-
"""Kiem chung THAT 'lst * n' + 'repeat_str(s, n)' (Wave 3, 2026-07-29) -
dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_repeat.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('repeat_list_sum', py_ns['repeat_list_sum'], [(3,), (0,), (1,)]),
    ('repeat_str_len', py_ns['repeat_str_len'], [('ab', 3), ('x', 5)]),
    ('repeat_str_value', py_ns['repeat_str_value'], [()]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_repeat_{entry}.exe'
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
        got_ok = (got == expected) if isinstance(expected, str) else (int(got) == int(expected))
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("REPEAT SUPPORT: PASS - lst*n/repeat_str(s,n) bien dich THAT va dung 100%.")
