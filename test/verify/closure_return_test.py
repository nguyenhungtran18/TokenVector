# -*- coding: utf-8 -*-
"""Kiem chung THAT closure-tra-ve-gia-tri (Buoc 4, pham vi (b1) return-value,
2026-07-29) - dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that
(runpy), giong het pattern cua closure_test.py (Buoc 4 slice dau tien) va
funcref_test.py (Buoc 2). demo_closure_return() nhan 'counter' tu
make_counter() (closure tra RA NGOAI), goi 3 lan TU BEN NGOAI ham da tao no -
kiem chung ca (a) codegen dung cho 'return inc' (tra Func`N delegate lam gia
tri, khong Invoke) lan (b) suy kieu dung cho 'counter = make_counter()' (giu
duoc shape='func', khong rot ve scalar thuong)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_closure_return.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['demo_closure_return']()
exe_path = HERE / 'sample_closure_return_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='demo_closure_return')

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
print("CLOSURE TRA VE GIA TRI (b1): PASS - goi tu NGOAI ham tao ra no, mutation + song sot dung 100%.")
