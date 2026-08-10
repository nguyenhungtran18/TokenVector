# -*- coding: utf-8 -*-
"""Ban AST cua may tinh (tools/tkvcalc_ast.tkv, ~910 dong) - CAY CU PHAP
bang doi tuong THAT (field 'a'/'b' kieu CHINH class do).

2 phep thu:
  1. Doi chieu voi CHINH file nguon chay duoi CPython (trong tai ngoai).
  2. TUONG DUONG voi ban RPN (tools/tkvcalc.tkv) tren cung bo bieu thuc -
     2 kien truc hoan toan khac nhau phai cho CUNG ket qua.
"""
import math
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC_AST = ROOT / 'tools' / 'tkvcalc_ast.tkv'
SRC_RPN = ROOT / 'tools' / 'tkvcalc.tkv'

ns = {'floor': math.floor, 'ceil': math.ceil, 'sqrt': math.sqrt}
exec(compile(SRC_AST.read_text(encoding='utf-8'), str(SRC_AST), 'exec'), ns)

exe_ast = ROOT / 'tools' / 'tkvcalc_ast.exe'
exe_rpn = ROOT / 'tools' / 'tkvcalc.exe'
for exe in (exe_ast, exe_rpn):
    if exe.exists():
        exe.unlink()
compile_tkv_cli(SRC_AST, exe_ast, entry_name='main')
compile_tkv_cli(SRC_RPN, exe_rpn, entry_name='main')

# Lay CHINH bo bieu thuc cua tkvcalc_test.py (che do gia tri) - khong
# chep tay de 2 bo test khong the troi nhau.
CASES_SRC = (ROOT / 'test' / 'verify' / 'tkvcalc_test.py').read_text(encoding='utf-8')
CASES = [m.group(1).encode().decode('unicode_escape')
         for m in re.finditer(r"\('((?:[^'\\]|\\.)*)', ''\)", CASES_SRC)]
assert len(CASES) > 70, f'chi lay duoc {len(CASES)} bieu thuc tu tkvcalc_test.py'


def run(exe, src):
    r = subprocess.run([str(exe), src, ''], capture_output=True, text=True, encoding='utf-8')
    return r.returncode, r.stdout.replace('\r\n', '\n').strip()


bad_py = 0
bad_eq = 0
for src in CASES:
    rc, got = run(exe_ast, src)
    want = str(ns['main'](src, '')).strip()
    if rc != 0 or got != want:
        bad_py += 1
        print(f'SAI LECH (vs CPython) src={src!r}: exe={got!r} CPython={want!r}')
    rc_rpn, got_rpn = run(exe_rpn, src)
    if got.startswith('loi') and got_rpn.startswith('loi'):
        continue          # ca 2 deu bao loi - thong diep khac nhau la binh thuong
    if got != got_rpn:
        bad_eq += 1
        print(f'KHAC BAN RPN src={src!r}: AST={got!r} RPN={got_rpn!r}')

print(f'{len(CASES)} bieu thuc | lech CPython: {bad_py} | lech ban RPN: {bad_eq}')
if bad_py or bad_eq:
    sys.exit(1)
print('tkvcalc_ast (cay cu phap bang doi tuong that): PASS - khop CPython VA '
      'tuong duong ban RPN.')
