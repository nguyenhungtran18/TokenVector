# -*- coding: utf-8 -*-
"""Kiem chung THAT closure (Buoc 4, slice dau tien, 2026-07-29) - dung CLI
tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy) - giong het
pattern cua funcref_test.py (Buoc 2). make_counter_demo() tao 1 closure
NOI BO ('inc'), goi 3 lan, tra ve tong (a+b+c) - kiem chung mutation +
song sot cua bien bi bat qua nhieu lan goi TACH BIET."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_closure.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['make_counter_demo']()
exe_path = HERE / 'sample_closure_make_counter_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='make_counter_demo')

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
print("CLOSURE SUPPORT (slice dau tien): PASS - mutation + song sot qua 3 lan goi dung 100%.")
