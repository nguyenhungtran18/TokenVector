# -*- coding: utf-8 -*-
"""Kiem chung THAT set.remove()/discard()/union()/intersection()/
difference() (Huong A stdlib mo rong, nhom rieng set_methods_batch2.py,
2026-07-29) - doi chieu voi CPython that (runpy). Test cung kiem tra
list.remove() KHONG bi anh huong (regression cua chinh sua doi trong
list_type.py's known_shapes guard) qua bo test rieng list_batch3_test.py
da co san chay lai trong full regression."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_set_batch2.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

exe_path = HERE / 'sample_set_batch2_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='compute')

total = 0
mismatches = []
for n in (1, 3, 5, 8):
    total += 1
    expected = py_ns['compute'](n)
    r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((n, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((n, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("SET_BATCH2 (remove/discard/union/intersection/difference): PASS - dung 100%.")
