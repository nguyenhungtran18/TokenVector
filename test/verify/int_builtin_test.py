# -*- coding: utf-8 -*-
"""int(x) - chieu nguoc lai cua str(x) (them 2026-08-03, Giai doan 1).
Doi chieu THAT voi CPython: cung bieu thuc tinh bang Python, so tung ky tu
voi stdout cua .exe. Bao gom so AM (kiem tra 'conv.i4' cat huong ve 0 dung
nhu int(-3.7) == -3 cua Python, KHONG lam tron xuong -4)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
exe_path = HERE / 'sample_int_builtin.exe'
compile_tkv_cli(HERE / 'sample_int_builtin.tkv', exe_path, entry_name='parse_all')

CASES = [("42", "3.7", "5"), ("-7", "-3.7", "100"), ("0", "0.9", "-1")]
mismatches = []
for s, f, big in CASES:
    r = subprocess.run([str(exe_path), s, f, big], capture_output=True, text=True)
    # parse_all: int(s) + int(f) + int(big) + (int(s) + 1)
    expected = int(s) + int(float(f)) + int(big) + int(s) + 1
    got = r.stdout.strip()
    print(f"int('{s}'), int({f}), int({big}) -> {got!r} (CPython: {expected})")
    if r.returncode != 0 or got != str(expected):
        mismatches.append((s, f, big, expected, got, r.returncode, r.stderr[:200]))

if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("int() (str/f64/i64 -> i32, doi chieu CPython): PASS - dung 100%.")
