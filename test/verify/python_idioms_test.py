# -*- coding: utf-8 -*-
"""Cac cach viet Python thuong ngay (2026-08-03) - doi chieu CHINH CPython.

sample_python_idioms.tkv la Python HOP LE nen bo test chay no bang CPython
roi so tung ky tu voi stdout cua .exe. Trong tam: '//' va '%' voi SO AM -
lop loi SAI AM THAM (bien dich duoc, chay duoc, ket qua khac Python)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_python_idioms.tkv'
ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

CASES = []
for a, b in [(7, 2), (-7, 2), (7, -2), (-7, -2), (-9, 3), (0, 5), (1, 7), (-1, 7)]:
    CASES += [('floor_div', [a, b]), ('modulo', [a, b]), ('div_and_mod', [a, b])]
CASES += [('grade', [20]), ('grade', [7]), ('grade', [3]), ('grade', [-1]),
          ('flags', [42]),
          ('has_sub', ['abxyc']), ('has_sub', ['abc']),
          ('has_field', ['a,b,c']), ('has_field', ['a,c']),
          ('bar', [5]), ('bar', [0]),
          ('joined', ['a,b,c']), ('joined', ['solo']),
          ('with_consts', [5]),
          # 'def' long khong bat bien -> nang len top-level (2026-08-03)
          ('uses_helper', [4]),
          # ham tra tuple lam entry CLI: in ra dang '(a, b)' giong Python
          ('pair_of', [3]),
          # tham so co GIA TRI MAC DINH khi lam entry CLI: thieu doi so
          # thi dung mac dinh (truoc day nem IndexOutOfRangeException)
          ('with_default', [4]),
          ('with_default', [4, 10])]

mismatches = []
built = {}
for entry, args in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_idiom_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *[str(a) for a in args]],
                       capture_output=True, text=True)
    expected = str(ns[entry](*args))
    got = r.stdout.strip()
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:150]))
        print(f'  SAI  {entry}{tuple(args)} exe={got!r} CPython={expected!r}')

print(f'Da doi chieu {len(CASES)} ca voi CPython, sai lech: {len(mismatches)}')
if mismatches:
    sys.exit(1)
print('Cach viet Python thuong ngay (// % am, elif, True/False, in, *, join, '
      'hang so module, def long, tuple entry, tham so mac dinh): PASS - dung 100%.')
