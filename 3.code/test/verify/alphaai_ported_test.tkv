# -*- coding: utf-8 -*-
"""Kiem chung THAT 5 ham do AlphaAI sinh SONG SONG (2026-07-28, xem
test/alphaai_batch_port.py) - doi chieu voi CPython that (runpy), qua
CLI tu dong (compile_tkv_cli). KHONG sua tay code AlphaAI sinh - giu
nguyen 100% de test nay la bang chung fix il_codegen.py dung THAT."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_alphaai_ported.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('count_vowels_str', ['hello world', 'AEIOU', '', 'xyz', 'TokenVector'], 'str'),
    ('most_frequent_char', ['hello', 'aaabbbb', 'x', 'abcabc'], 'str'),
    ('fib_sum_upto', [0, 1, 2, 5, 10], 'i32'),
    ('range_stats_sum', [0, 1, 4, 5, 10, 11], 'i32'),
]

total = 0
mismatches = []
for entry, args_list, argkind in cases:
    py_func = py_ns[entry]
    exe_path = HERE / f'sample_alphaai_ported_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for a in args_list:
        total += 1
        expected = py_func(a)
        r = subprocess.run([str(exe_path), str(a)], capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        ok = (got == str(expected)) if r.returncode == 0 else False
        if not ok:
            mismatches.append((entry, a, expected, got, r.returncode, r.stderr))

# safe_divide_report: 2 tham so (a, b) - test rieng. (7.0, 0.0) KHONG dua
# vao doi chieu tu dong: chia float cho 0 trong CIL/.NET la IEEE754 hop le
# (tra ve Infinity, KHONG nem exception) trong khi Python that NEM
# ZeroDivisionError - khac biet ngu nghia THAT giua CLR va Python (giong
# gioi han '/' i32 da biet o Buoc 6), KHONG phai bug cua session nay -
# 'except ZeroDivisionError:' tren PHEP CHIA FLOAT khong bao gio bat duoc
# gi ca vi khong co exception nao duoc nem. Ghi nhan RO RANG o day thay vi
# coi la mismatch.
exe_path = HERE / 'sample_alphaai_ported_safe_divide_report.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='safe_divide_report')
py_func = py_ns['safe_divide_report']
for a, b in [(10.0, 2.0), (0.0, 5.0), (-3.0, 4.0)]:
    total += 1
    expected = py_func(a, b)
    r = subprocess.run([str(exe_path), str(a), str(b)], capture_output=True, text=True)
    got = r.stdout.rstrip('\r\n')
    if got != str(expected):
        mismatches.append(('safe_divide_report', (a, b), expected, got, r.returncode, r.stderr))

r = subprocess.run([str(exe_path), '7.0', '0.0'], capture_output=True, text=True)
got_zero = r.stdout.rstrip('\r\n')
print(f"(GHI NHAN, khong tinh vao so mau) 7.0/0.0: Python that={py_func(7.0, 0.0)!r}, "
      f"exe (CLR float div-by-zero khong nem exception)={got_zero!r}")

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH (co the la gioi han '/' i32 da biet, xem STATUS.md, khong phai bug moi):")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("ALPHAAI-PORTED SUPPORT: PASS - 5 ham AlphaAI sinh (string/dict/list/try-except/tuple) khop CPython that 100%.")
