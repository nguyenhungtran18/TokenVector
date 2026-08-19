# -*- coding: utf-8 -*-
"""Kiem chung THAT ke thua + da hinh tren record (B1, 2026-07-29) - dung
CLI tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy). record
gio la REFERENCE TYPE (class, khong con struct) - .ctor chaining qua
'super().__init__()' (CPython that) tuong ung 'call instance void
Base::.ctor(...)' (CIL, xem gen_record_types); method override dispatch
qua callvirt (virtual/newslot virtual, xem record_overrides)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_inheritance.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

expected = py_ns['demo_inheritance']()
exe_path = HERE / 'sample_inheritance_demo.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='demo_inheritance')

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
print("KE THUA + DA HINH (B1): PASS - dung 100%.")
