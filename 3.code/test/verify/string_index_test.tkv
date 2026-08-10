# -*- coding: utf-8 -*-
"""Kiem chung THAT string index s[i] + len(s) vua them - dung LUON CLI
tu dong (compile_tkv_cli, xem tkv_compile.py) thay vi tu tay viet IL
Main() - vua kiem chung tinh nang moi vua kiem chung CLI hoat dong dung
voi dtype 'str' tron lan tham so i32."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_string_index.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('first_char', [('hello',), ('A',), ('TokenVector',)]),
    ('last_char', [('hello',), ('A',), ('TokenVector',)]),
    ('str_length', [('hello',), ('',), ('TokenVector',), ('a',)]),
    ('char_at', [('hello', 0), ('hello', 4), ('TokenVector', 5)]),
]

total = 0
mismatches = []
for entry, arg_sets in cases:
    exe_path = HERE / f'sample_string_index_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.rstrip('\r\n')
        if isinstance(expected, str):
            ok = got == expected
        else:
            ok = int(got) == expected
        if not ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STRING INDEX/LEN SUPPORT: PASS - s[i] va len(s) bien dich THAT va dung 100%.")
