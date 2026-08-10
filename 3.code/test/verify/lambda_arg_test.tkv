# -*- coding: utf-8 -*-
"""Kiem chung THAT lambda-1-bieu-thuc lam tham so truc tiep (A2, 2026-07-29) -
dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy),
giong het pattern cua closure_arg_test.py/funcref_test.py. demo_lambda_arg()
truyen 'lambda x: x * 2 + 1' TRUC TIEP cho apply() - kieu tham so/tra ve
cua lambda suy HOAN TOAN tu chu ky 'func' cua apply's 'f', khong chu thich
kieu rieng."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_lambda_arg.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['demo_lambda_arg']()
exe_path = HERE / 'sample_lambda_arg_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='demo_lambda_arg')

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
print("LAMBDA LAM THAM SO TRUC TIEP (A2): PASS - dung 100%.")
