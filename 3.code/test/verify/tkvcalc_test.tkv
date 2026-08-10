# -*- coding: utf-8 -*-
"""Chuong trinh THAT >1000 dong CO CLASS (tools/tkvcalc.tkv: 13 class,
ke thua 2 tang, dispatch ao, phan cap exception) - doi chieu .exe voi
CHINH file nguon chay duoi CPython tren ~70 bieu thuc that."""
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC = ROOT / 'tools' / 'tkvcalc.tkv'

# Cac ham toan hoc la BUILTIN cua TokenVector nhung KHONG phai cua Python -
# shim de chinh file .tkv chay duoc duoi CPython lam trong tai.
ns = {'floor': math.floor, 'ceil': math.ceil, 'sqrt': math.sqrt}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = ROOT / 'tools' / 'tkvcalc.exe'
if exe.exists():
    exe.unlink()
compile_tkv_cli(SRC, exe, entry_name='main')

CASES = [
    # so hoc co ban
    ('1 + 2', ''), ('2 * 3 + 4', ''), ('2 + 3 * 4', ''), ('(2 + 3) * 4', ''),
    ('10 - 4 - 3', ''), ('100 / 8', ''), ('7 / 2', ''), ('1 - 2 - 3 - 4', ''),
    # uu tien va ket hop
    ('2 ^ 3 ^ 2', ''), ('(2 ^ 3) ^ 2', ''), ('2 ^ -1', ''), ('-2 ^ 2', ''),
    ('2 * 3 ^ 2', ''), ('1 + 2 * 3 - 4 / 2', ''),
    # dau am / duong 1 ngoi
    ('-5', ''), ('--5', ''), ('+7', ''), ('-(3 + 4)', ''), ('3 * -2', ''),
    ('-3 * -2', ''), ('- -  - 4', ''),
    # chia nguyen / du (ke ca so am - dung ngu nghia Python)
    ('7 // 2', ''), ('-7 // 2', ''), ('7 // -2', ''), ('-7 // -2', ''),
    ('7 % 3', ''), ('-7 % 3', ''), ('7 % -3', ''), ('8 % 4', ''),
    ('7.5 // 2', ''), ('7.5 % 2', ''),
    # so thuc
    ('1.5 + 2.25', ''), ('0.1 + 0.2', ''), ('3.0 * 2', ''), ('10 / 4', ''),
    ('.5 + 1', ''), ('2.', ''),
    # so sanh
    ('1 < 2', ''), ('2 < 1', ''), ('3 <= 3', ''), ('3 >= 4', ''),
    ('2 == 2', ''), ('2 != 2', ''), ('1 + 1 == 2', ''), ('2 * 3 > 5', ''),
    # ham
    ('abs(-5)', ''), ('abs(5)', ''), ('sqrt(16)', ''), ('sqrt(2)', ''),
    ('floor(3.7)', ''), ('ceil(3.2)', ''), ('round(2.5)', ''), ('round(3.5)', ''),
    ('sign(-9)', ''), ('sign(0)', ''), ('min(3, 7)', ''), ('max(3, 7)', ''),
    ('pow(2, 10)', ''), ('hypot(3, 4)', ''), ('min(2 * 3, 7 - 2)', ''),
    ('abs(min(-3, -9))', ''), ('max(sqrt(9), floor(2.9))', ''),
    # bien va nhieu cau lenh
    ('x = 3; x * 2', ''), ('x = 3; y = x ^ 2; y + 1', ''),
    ('a = 1; b = 2; c = a + b; c * c', ''), ('x = 1; x = x + 1; x = x + 1; x', ''),
    ('n = 10; n / 4', ''), ('x = 2; y = 3; max(x, y) ^ 2', ''),
    # khoang trang / chu thich
    ('  1   +   2  ', ''), ('1 + 2 # cong hai so', ''), ('# chi chu thich\n3 * 3', ''),
    ('1 +\t2', ''),
    # loi (moi loai)
    ('1 +', ''), ('(1 + 2', ''), ('1 + 2)', ''), ('1 / 0', ''), ('7 // 0', ''),
    ('z + 1', ''), ('1 $ 2', ''), ('1.2.3', ''), ('', ''), ('   ', ''),
    ('sqrt(-1)', ''), ('1 2', ''), ('min(1)', ''), ('!', ''), ('1e5', ''),
    # che do khac
    ('2 + 3 * 4', 'stats'), ('x = 2; x + 1', 'stats'),
    ('2 + 3 * 4', 'tokens'), ('x = 1; y', 'tokens'),
    ('2 + 3 * 4', 'postfix'), ('x = 1 + 2', 'postfix'),
    ('-3 + max(1, 2)', 'postfix'), ('2 ^ 3 ^ 2', 'postfix'),
]

bad = 0
for src, mode in CASES:
    r = subprocess.run([str(exe), src, mode], capture_output=True, text=True,
                       encoding='utf-8')
    got = r.stdout.replace('\r\n', '\n').strip()
    try:
        want = str(ns['main'](src, mode)).strip()
    except Exception as e:                       # pragma: no cover
        want = 'PYTHON-RAISE ' + type(e).__name__ + ': ' + str(e)
    if r.returncode != 0 or got != want:
        bad += 1
        print(f'SAI LECH src={src!r} mode={mode!r} (rc={r.returncode})')
        print(f'  exe    : {got!r}')
        print(f'  CPython: {want!r}')
        if r.stderr:
            print('  stderr:', r.stderr[:200])

print(f'{len(CASES) - bad}/{len(CASES)} truong hop khop CPython')
if bad:
    sys.exit(1)
print('tkvcalc (chuong trinh THAT >1000 dong, 13 class): PASS - khop CPython 100%.')
