# -*- coding: utf-8 -*-
"""Parity test for str.isdigit().

Ledger P036/P041 found that TokenVector could not compile s.isdigit().
This test keeps the contract explicit: variable receiver, expression
receiver, empty string, and str()/print formatting must match CPython.
"""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'tmp_string_isdigit.tkv'
EXE = HERE / 'tmp_string_isdigit.exe'

SRC.write_text(
    '''
def mk() -> "str":
    return "42"


def run() -> "str":
    xs = ["", "123", "12a", "007"]
    out = []
    for s in xs:
        out.append(str(s.isdigit()))
    out.append(str(mk().isdigit()))
    out.append(str("abc".isdigit()))
    return "|".join(out)
'''.lstrip(),
    encoding='utf-8',
)

py_ns = runpy.run_path(str(SRC))
expected = py_ns['run']()

compile_tkv_cli(str(SRC), str(EXE), entry_name='run', class_name='StringIsDigitProgram')
r = subprocess.run([str(EXE)], capture_output=True, text=True)
got = r.stdout.strip()

print(f"expected={expected!r}")
print(f"got={got!r}")
if r.returncode != 0 or got != expected:
    print(r.stderr)
    sys.exit(1)
print("string_isdigit_test: PASS")
