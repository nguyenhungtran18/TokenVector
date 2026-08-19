# -*- coding: utf-8 -*-
"""Kiem chung THAT assert (Wave 3, 2026-07-29) - dung CLI tu dong
(compile_tkv_cli), doi chieu voi CPython that (runpy): truong hop PASS
so ket qua tra ve; truong hop FAIL so exit-code (0 vs khac-0, giong
Python that AssertionError khong bat se crash script voi exit-code
khac-0)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_assert.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

pass_cases = [
    ('check_positive', py_ns['check_positive'], [(5,), (1,)]),
    ('check_positive_msg', py_ns['check_positive_msg'], [(5,)]),
    ('check_range', py_ns['check_range'], [(5, 0, 10)]),
]
fail_cases = [
    ('check_positive', [(-5,), (0,)]),
    ('check_positive_msg', [(-1,)]),
    ('check_range', [(50, 0, 10)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in pass_cases:
    exe_path = HERE / f'sample_assert_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, 'PASS-expected', 'CRASHED', r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        if got != expected:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

for entry, arg_sets in fail_cases:
    exe_path = HERE / f'sample_assert_{entry}.exe'
    for args in arg_sets:
        total += 1
        try:
            py_ns[entry](*args)
            py_raised = False
        except AssertionError:
            py_raised = True
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        exe_raised = (r.returncode != 0)
        if py_raised != exe_raised:
            mismatches.append((entry, args, f'py_raised={py_raised}', f'exe_raised={exe_raised}', r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("ASSERT SUPPORT: PASS - bien dich THAT va dung 100%.")
