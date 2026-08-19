# -*- coding: utf-8 -*-
"""Kiem chung THAT stdlib string mo rong (Huong A, 2026-07-29):
startswith/endswith/find/lstrip/rstrip them vao nhom rieng
string_methods_batch3.py - doi chieu voi CPython that (runpy). Kiem tra
ca dtype suy dung (a/b la bool-nhu-i32, c la vi tri i32) qua duong gan
vao bien roi dung trong 'if' - day la phan sua _infer_dtype quan trong
nhat cua tang nay."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_str_ext.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_str_ext_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for s in ('  hello  ', 'hello world', 'xyz', 'hello'):
    total += 1
    expected = py_ns['compute'](s)
    r = subprocess.run([str(exe_path), s], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((s, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((s, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STR_EXT (startswith/endswith/find/lstrip/rstrip): PASS - dung 100%.")
