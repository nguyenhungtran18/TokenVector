# -*- coding: utf-8 -*-
"""Bay suy kieu (2026-08-03, dot 3) - moi ham trong sample TRA VE 'str',
ngu canh da lam lo ra ca 5 bug 'suy kieu roi ve body_dtype' trong 1 phien.
Doi chieu .exe voi CHINH file nguon chay duoi CPython."""
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC = ROOT / 'test' / 'sample_infer_dtype.tkv'

ns = {'floor': math.floor, 'ceil': math.ceil, 'sqrt': math.sqrt}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = ROOT / 'test' / 'sample_infer_dtype.exe'
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
        for i, (g, w) in enumerate(zip(got.split('|'), want.split('|'))):
            if g != w:
                print(f'  phan {i}: exe={g!r} | CPython={w!r}')
        print(f'  exe    : {got!r}')
        print(f'  CPython: {want!r}')
        if r.stderr:
            print('  stderr:', r.stderr[:300])
    else:
        print(f'  OK n={n}: {got}')

if bad:
    sys.exit(1)
print('Bay suy kieu (builtin/method/list-cua-method/word-count/so sanh): PASS - khop CPython.')
