# -*- coding: utf-8 -*-
"""Kiem chung THAT File I/O co ban (read_file/write_file/append_file/
file_exists) - dung CLI tu dong (compile_tkv_cli) de build, doi chieu voi
CPython that (qua _file_io_helpers.py, cung logic .NET File.* anh xa toi)."""
import runpy
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_file_io.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

entries = ['save_and_check', 'save_read_length', 'append_twice']
content = 'Hello TokenVector File IO'

total = 0
mismatches = []
with tempfile.TemporaryDirectory() as tmpdir:
    tmp = Path(tmpdir)
    for entry in entries:
        exe_path = HERE / f'sample_file_io_{entry}.exe'
        compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
        py_func = py_ns[entry]

        py_path = str(tmp / f'{entry}_py.txt')
        exe_path_file = str(tmp / f'{entry}_exe.txt')

        total += 1
        expected = py_func(py_path, content)
        r = subprocess.run([str(exe_path), exe_path_file, content],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        if got != expected:
            mismatches.append((entry, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("FILE I/O SUPPORT: PASS - read_file/write_file/append_file/file_exists "
      "bien dich THAT va dung 100%.")
