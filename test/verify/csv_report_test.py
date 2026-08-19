# -*- coding: utf-8 -*-
"""Cong cu THAT (sample_csv_report.tkv) - doi chieu voi CHINH no chay
duoi CPython tren cung file du lieu."""
import subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_csv_report.tkv'
DATA = HERE / 'csv_report_data.csv'
DATA.write_text('a,10\nb,-4\nc,7\nd,25\ne,-1\n', encoding='utf-8')

ns = {'read_file': lambda p: Path(p).read_text(encoding='utf-8')}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

exe = HERE / 'sample_csv_report.exe'
if exe.exists():
    exe.unlink()
compile_tkv_cli(SRC, exe, entry_name='report')
r = subprocess.run([str(exe), str(DATA), '1'], capture_output=True, text=True)
got, expected = r.stdout.strip(), ns['report'](str(DATA), 1)
print(f'  exe    : {got}')
print(f'  CPython: {expected}')
if r.returncode != 0 or got != expected:
    print(f'SAI LECH (rc={r.returncode}) {r.stderr[:200]}')
    sys.exit(1)
print('Cong cu CSV that viet bang TokenVector: PASS - khop CPython 100%.')
