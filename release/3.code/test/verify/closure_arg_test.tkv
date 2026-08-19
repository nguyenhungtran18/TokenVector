# -*- coding: utf-8 -*-
"""Kiem chung THAT closure-lam-tham-so (Buoc 4, pham vi A1, 2026-07-29) -
dung CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy),
giong het pattern cua closure_return_test.py/funcref_test.py.
make_adder_demo() truyen TEN ham long TRUC TIEP lam tham so cho apply()
(khong qua bien trung gian, ben trong chinh ham tao no) - truong hop MOI;
demo_closure_var_as_arg() truyen 1 bien da nhan closure tra ve (b1) - kiem
chung khong hoi quy."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_closure_arg.tkv'
py_ns = runpy.run_path(str(SRC_PATH))


def _check(entry_name):
    expected = py_ns[entry_name]()
    exe_path = HERE / f'sample_closure_arg_{entry_name}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry_name)
    r = subprocess.run([str(exe_path)], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"{entry_name}: exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
        sys.exit(1)
    got = int(r.stdout.strip())
    print(f"{entry_name}: CPython that={expected}, exe bien dich={got}")
    if got != expected:
        print(f"{entry_name}: SAI LECH!")
        sys.exit(1)


_check('make_adder_demo')
_check('demo_closure_var_as_arg')
print("CLOSURE LAM THAM SO (A1): PASS - ca 2 truong hop (ten truc tiep + bien trung gian) dung 100%.")
