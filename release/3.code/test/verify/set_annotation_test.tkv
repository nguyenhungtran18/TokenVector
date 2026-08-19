# -*- coding: utf-8 -*-
"""set[dtype] trong chu thich kieu + set.to_list() (2026-08-03).

Ky vong tinh TAY (khong doi chieu CPython duoc: .to_list() khong ton tai
trong Python that - da ghi ro trong file .tkv). Bao gom 1 ca AM: lay chi
so tren set phai bao loi RO RANG chu khong phai 'chi ho tro mang rank 1
hoac 2' nhu truoc."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_set_annot.tkv'
CASES = [
    ('sum_via_to_list', ['2', '3'], '5'),
    ('sum_via_to_list', ['4', '4'], '4'),          # trung lap bi loai
    ('count_after_roundtrip', ['7', '9'], '2'),    # set qua THAM SO
    ('count_after_roundtrip', ['7', '7'], '1'),
]
mismatches = []
built = {}
for entry, args, expected in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_set_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *args], capture_output=True, text=True)
    got = r.stdout.strip()
    print(f'  {entry}({", ".join(args)}) -> {got!r} (ky vong {expected!r})')
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

NEG = HERE / 'sample_set_annot_neg.tkv'
NEG.write_text('def f(n: "i32") -> "i32":\n    s = set()\n    s.add(2)\n    total = 0\n'
               '    for x in s:\n        total = total + x\n    return total\n', encoding='utf-8')
try:
    compile_tkv_cli(NEG, HERE / 'sample_set_annot_neg.exe', entry_name='f')
    mismatches.append(('ca am', 'for x in <set>', 'loi ro rang', 'bien dich thanh cong'))
    print('  FAIL ca am: bien dich thanh cong (dang le bao loi)')
except SyntaxError as e:
    if 'to_list' in str(e):
        print(f'  PASS ca am: {str(e)[:100]}...')
    else:
        mismatches.append(('ca am', 'thong bao chi cach dung to_list', str(e)[:200]))
        print(f'  FAIL ca am: thong bao khong huu ich: {str(e)[:150]}')

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('set[dtype] + set.to_list(): PASS - dung 100%.')
