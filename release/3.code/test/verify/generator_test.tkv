# -*- coding: utf-8 -*-
"""Kiem chung THAT generator LAZY THAT (Wave 3, 2026-07-29 - thay the
hoan toan B2(c)'s eager-list; class rieng cai IEnumerator<T>, field-
hoisted locals, switch tren state - xem project-tokenvector-wave2-status
memory) - dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that
(runpy). sample_generator.tkv bao gom gen_nested() co 'yield' LONG TRONG
if/for (khong phai 1 vong lap don) - kiem chung dung "Ho tro tong quat"
da chon, khong chi truong hop don gian."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_generator.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['demo_generator']()
exe_path = HERE / 'sample_generator_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='demo_generator')

r = subprocess.run([str(exe_path)], capture_output=True, text=True)
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = int(r.stdout.strip())

print(f"CPython that: {expected}")
print(f"exe bien dich: {got}")
if got != expected:
    print("SAI LECH!")
    sys.exit(1)
print("GENERATOR LAZY THAT (yield long trong if/for): PASS - dung 100%.")
