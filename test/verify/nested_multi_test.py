# -*- coding: utf-8 -*-
"""Kiem chung THAT nhieu def long song song trong 1 ham (Phase C.2,
2026-07-29) - dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython
that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_nested_multi.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['make_pair'](100)
exe_path = HERE / 'sample_nested_multi_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='make_pair')

r = subprocess.run([str(exe_path), '100'], capture_output=True, text=True)
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = int(r.stdout.strip())

print(f"CPython that: {expected}")
print(f"exe bien dich: {got}")
if got != expected:
    print("SAI LECH!")
    sys.exit(1)
print("Nhieu def long song song (Phase C.2): PASS - dung 100%.")
