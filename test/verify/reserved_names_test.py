# -*- coding: utf-8 -*-
"""Ten trung tu khoa ILASM (2026-08-03, dot 4) - class/ham/method/field/
bien deu dat ten trung tu khoa, va chuoi HANG chua tu khoa. Doi chieu voi
CHINH file nguon chay duoi CPython."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC = ROOT / 'test' / 'sample_reserved_names.tkv'

ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = ROOT / 'test' / 'sample_reserved_names.exe'
if exe.exists():
    exe.unlink()
compile_tkv_cli(SRC, exe, entry_name='main')

bad = 0
for n in ('0', '7'):
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
        print(f'  OK n={n}: {got}')

if bad:
    sys.exit(1)
print('Ten trung tu khoa ILASM (class/ham/method/field/bien + chuoi hang): PASS.')
