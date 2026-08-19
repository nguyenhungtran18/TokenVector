# -*- coding: utf-8 -*-
"""Kiem chung THAT 12 ham domain toan hoc/so hoc do Gemini sinh thu cong
qua chat (khong qua Groq) 2026-07-28 - bien dich qua tkv_compile that +
doi chieu CPython that."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_manual_chat_math12.tkv'
py_ns = runpy.run_path(str(SRC_PATH))


# 5 ham GOC (do Gemini viet) dung 'temp = temp / 10' de tach chu so -
# DSL bien dich '/' tren i32 thanh CHIA NGUYEN (dung y dinh thuat toan),
# nhung chay CHINH van ban do bang CPython THAT thi '/' la chia noi ->
# vong lap KHONG BAO GIO ve dung 0 (phan ky, xem STATUS.md muc "Mục tiêu
# #1 — Domain toán học"). Day la gioi han DA BIET tu Buoc 6 ("'/' tren
# i32 lam tron ve 0"), KHONG PHAI bug moi - dung ham tham chieu voi '//'
# (chia nguyen THAT cua Python, dung ngu nghia thuat toan) thay vi chay
# lai chinh van ban qua runpy cho 5 ham nay.
def _ref_lcm_via_gcd(a, b):
    if a == 0 or b == 0:
        return 0
    x, y = a, b
    while y != 0:
        x, y = y, x % y
    return a * b // x


def _ref_sum_of_digits(n):
    s, t = 0, n
    while t > 0:
        s += t % 10
        t //= 10
    return s


def _ref_reverse_number(n):
    rev, t = 0, n
    while t > 0:
        rev = rev * 10 + t % 10
        t //= 10
    return rev


def _ref_is_palindrome_number(n):
    return 1 if _ref_reverse_number(n) == n else 0


def _ref_digital_root(n):
    t = n
    while t > 9:
        t = _ref_sum_of_digits(t)
    return t


cases = [
    ('is_prime', py_ns['is_prime'], [(2,), (17,), (18,), (1,), (0,), (97,)]),
    ('count_primes_upto', py_ns['count_primes_upto'], [(10,), (2,), (30,), (1,)]),
    ('gcd_euclid', py_ns['gcd_euclid'], [(48, 18), (17, 5), (100, 25)]),
    ('lcm_via_gcd', _ref_lcm_via_gcd, [(4, 6), (21, 6), (5, 0)]),
    ('is_perfect_square', py_ns['is_perfect_square'], [(16,), (17,), (0,), (1,), (-4,)]),
    ('sum_of_digits', _ref_sum_of_digits, [(12345,), (0,), (9,), (100,)]),
    ('reverse_number', _ref_reverse_number, [(123,), (100,), (0,), (7,)]),
    ('is_palindrome_number', _ref_is_palindrome_number, [(121,), (123,), (7,), (0,)]),
    ('power_int', py_ns['power_int'], [(2, 10), (3, 0), (5, 3)]),
    ('fibonacci_nth', py_ns['fibonacci_nth'], [(0,), (1,), (10,), (2,)]),
    ('collatz_steps', py_ns['collatz_steps'], [(27,), (1,), (6,)]),
    ('digital_root', _ref_digital_root, [(9875,), (0,), (9,), (12345,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_manual_chat_math12_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(expected):
            mismatches.append((entry, args, expected, got, r.returncode, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("MANUAL-CHAT-MATH12 SUPPORT: PASS - 12 ham toan hoc Gemini sinh thu cong bien dich THAT va dung 100%.")
