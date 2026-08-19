# run_stdlib_tests.py - DA THAY THE (2026-08-03, Giai doan 1)
#
# Bo kiem thu stdlib nay da chuyen ve 1 nguon su that duy nhat:
#     test/verify/stdlib_regression_test.py
# de chay CUNG bo regression chinh (truoc day file nay nam ngoai
# test/verify/ nen khong ai chay cung, va co 3 diem yeu that: in
# "12/12 PASS (100%)" hardcode ke ca khi bien dich loi; chap nhan ma
# thoat 0/1/3 + stdout '1' hoac '3' (qua rong); khong doi chieu gia tri
# nao voi CPython).
#
# File nay giu lai lam con tro, KHONG chay logic cu nua.
import sys
from pathlib import Path

TARGET = Path(__file__).resolve().parents[3] / 'test' / 'verify' / 'stdlib_regression_test.py'
print('run_stdlib_tests.py da duoc thay the. Chay:')
print(f'    python "{TARGET}"')
sys.exit(2)
