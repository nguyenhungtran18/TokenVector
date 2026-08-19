# -*- coding: utf-8 -*-
"""Kiem chung THAT 'with open(...) as f:' (Wave 2, 2026-07-29) - dung CLI
tu dong (compile_tkv_cli), doi chieu voi CPython that (runpy) - file .tkv
van la Python that (open()/with chuan), chi khac o CACH BIEN DICH."""
import runpy
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_with_open.tkv'
py_ns = runpy.run_path(str(SRC_PATH))
py_write_n_lines = py_ns['write_n_lines']
py_append_then_read = py_ns['append_then_read']

total = 0
mismatches = []
with tempfile.TemporaryDirectory() as tmpdir:
    tmp = Path(tmpdir)

    exe_write = HERE / 'sample_with_open_write_n_lines.exe'
    compile_tkv_cli(SRC_PATH, exe_write, entry_name='write_n_lines')
    for n in (0, 1, 5, 20):
        total += 1
        py_path = str(tmp / f'wnl_py_{n}.txt')
        exe_path_file = str(tmp / f'wnl_exe_{n}.txt')
        expected = py_write_n_lines(py_path, n)
        r = subprocess.run([str(exe_write), exe_path_file, str(n)],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append(('write_n_lines', n, expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        if got != expected:
            mismatches.append(('write_n_lines', n, expected, got, r.stdout, r.stderr))

    exe_append = HERE / 'sample_with_open_append_then_read.exe'
    compile_tkv_cli(SRC_PATH, exe_append, entry_name='append_then_read')
    cases = [('Hello, ', 'World!'), ('', 'only-second'), ('only-first', '')]
    for i, (first, second) in enumerate(cases):
        total += 1
        py_path = str(tmp / f'atr_py_{i}.txt')
        exe_path_file = str(tmp / f'atr_exe_{i}.txt')
        expected = py_append_then_read(py_path, first, second)
        r = subprocess.run([str(exe_append), exe_path_file, first, second],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append(('append_then_read', (first, second), expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        if got != expected:
            mismatches.append(('append_then_read', (first, second), expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("WITH-OPEN SUPPORT: PASS - bien dich THAT va dung 100%.")
