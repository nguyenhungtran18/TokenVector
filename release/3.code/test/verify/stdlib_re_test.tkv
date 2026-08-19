# -*- coding: utf-8 -*-
"""Kiem chung THAT re_match(pattern, s)/re_sub(pattern, repl, s) (Wave 2,
2026-07-29, soan boi Gemini, verify boi Claude qua ilasm.exe that) - dung
CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy, qua
_re_helpers.py bao real re.match/re.sub)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_stdlib_re.tkv'
py_ns = runpy.run_path(str(SRC_PATH))
py_has_digit, py_mask_digits = py_ns['has_digit'], py_ns['mask_digits']

cases = [
    ('has_digit', py_has_digit, ['abc123', 'abcdef', '999', '']),
    ('mask_digits', py_mask_digits, ['abc123def456', 'no-digits-here', '007']),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_stdlib_re_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for s in arg_sets:
        total += 1
        expected = py_func(s)
        r = subprocess.run([str(exe_path), s], capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, s, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        if entry == 'has_digit':
            got_ok = int(got) == int(expected)
        else:
            got_ok = got == expected
        if not got_ok:
            mismatches.append((entry, s, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STDLIB RE SUPPORT: PASS - re_match/re_sub bien dich THAT va dung 100%.")
