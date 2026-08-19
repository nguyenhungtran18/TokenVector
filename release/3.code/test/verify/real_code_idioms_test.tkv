# -*- coding: utf-8 -*-
"""Hoi quy cho 6 khoang trong tim duoc khi viet cong cu THAT
`tools/codestat.tkv` (2026-08-03): docstring trong than ham, method goi
tren bieu thuc, str(bieu thuc), str(hang so module), dong noi tiep trong
ngoac, va tu khoa ILASM nam trong CHUOI HANG (loi nay SAI AM THAM).
Trong tai: chinh file .tkv chay duoi CPython."""
import subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC = ROOT / 'test' / 'sample_real_idioms.tkv'

ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = ROOT / 'test' / 'sample_real_idioms.exe'
if exe.exists():
    exe.unlink()
compile_tkv_cli(SRC, exe, entry_name='main')

bad = 0
for n in ('5', '1', '12'):
    r = subprocess.run([str(exe), n], capture_output=True, text=True, encoding='utf-8')
    got = r.stdout.replace('\r\n', '\n').strip()
    want = ns['main'](int(n)).strip()
    if r.returncode != 0 or got != want:
        bad += 1
        print(f'SAI LECH n={n} (rc={r.returncode})')
        print(f'  exe    : {got!r}')
        print(f'  CPython: {want!r}')
        if r.stderr:
            print('  stderr:', r.stderr[:300])
    else:
        print(f'  OK n={n}')

if bad:
    sys.exit(1)
print('Cach viet code THAT (6 nhom): PASS - khop CPython.')
