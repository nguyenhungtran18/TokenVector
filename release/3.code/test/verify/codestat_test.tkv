# -*- coding: utf-8 -*-
"""Cong cu THAT `tools/codestat.tkv` (~300 dong) - doi chieu .exe voi
CHINH file nguon chay duoi CPython, tren NHIEU file dau vao that."""
import subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
SRC = ROOT / 'tools' / 'codestat.tkv'

ns = {'read_file': lambda p: Path(p).read_text(encoding='utf-8')}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = ROOT / 'tools' / 'codestat.exe'
if exe.exists():
    exe.unlink()
compile_tkv_cli(SRC, exe, entry_name='main')

TARGETS = [
    SRC,                                   # tu soi guong
    ROOT / 'test' / 'sample_csv_report.tkv',
    ROOT / 'tkv_compile.py',
    ROOT / 'compiler' / 'il_features' / 'slicing.py',
    ROOT / 'compiler' / 'typed_dsl_parser.py',
]

bad = 0
for t in TARGETS:
    if not t.exists():
        print(f'  BO QUA (khong co): {t}')
        continue
    r = subprocess.run([str(exe), str(t)], capture_output=True, text=True,
                       encoding='utf-8')
    got = r.stdout.replace('\r\n', '\n').strip()
    want = ns['main'](str(t)).strip()
    if r.returncode != 0 or got != want:
        bad += 1
        print(f'SAI LECH tren {t.name} (rc={r.returncode})')
        gl, wl = got.split('\n'), want.split('\n')
        for i in range(max(len(gl), len(wl))):
            g = gl[i] if i < len(gl) else '<thieu>'
            w = wl[i] if i < len(wl) else '<thieu>'
            if g != w:
                print(f'  dong {i+1}: exe={g!r} | CPython={w!r}')
        if r.stderr:
            print('  stderr:', r.stderr[:300])
    else:
        print(f'  OK {t.name}: {len(want.splitlines())} dong bao cao khop')

if bad:
    sys.exit(1)
print('codestat (cong cu that ~300 dong): PASS - khop CPython tren tat ca file thu.')
