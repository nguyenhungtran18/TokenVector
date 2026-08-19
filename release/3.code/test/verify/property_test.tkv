# -*- coding: utf-8 -*-
"""Kiem chung THAT @property (Phase C.3, 2026-07-29) - dung CLI tu dong
(compile_tkv_cli), doi chieu voi CPython that (runpy)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_property.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['demo_property']()
exe_path = HERE / 'sample_property_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='demo_property')

r = subprocess.run([str(exe_path)], capture_output=True, text=True)
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = float(r.stdout.strip())

print(f"CPython that: {expected}")
print(f"exe bien dich: {got}")
if abs(got - expected) > 1e-3:
    print("SAI LECH!")
    sys.exit(1)
print("@property (Phase C.3): PASS - dung 100%.")
