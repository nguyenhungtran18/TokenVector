# -*- coding: utf-8 -*-
"""Exception TU DINH NGHIA (Giai doan 3, 2026-08-03).

Trong tai la CHINH CPython: file sample_user_exception.tkv la Python HOP
LE ('class MyError(Exception):' chay duoc that), nen bo test chay no
BANG CPython roi so voi stdout cua .exe da bien dich. Khong tu tuyen bo
ky vong - hai ben doc lap phai ra cung ket qua.

Bao gom 1 ca AM: 'raise' 1 record KHONG ke thua Exception phai bao loi
LUC BIEN DICH (neu de lot, CLR se nem InvalidProgramException luc chay)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_user_exception.tkv'

# 1) Chay file .tkv bang CHINH CPython de lay ket qua chuan
ns = {}
exec(compile(SRC.read_text(encoding='utf-8'), str(SRC), 'exec'), ns)

CASES = [-1, 30, 500]
mismatches = []
for entry in ['check_age', 'uncaught_goes_to_generic']:
    exe_path = HERE / f'sample_user_exception_{entry}.exe'
    if exe_path.exists():
        exe_path.unlink()
    compile_tkv_cli(SRC, exe_path, entry_name=entry)
    for arg in CASES:
        r = subprocess.run([str(exe_path), str(arg)], capture_output=True, text=True)
        expected = ns[entry](arg)
        got = r.stdout.strip()
        print(f'  {entry}({arg}) -> exe={got!r} CPython={expected!r}')
        if r.returncode != 0 or got != expected:
            mismatches.append((entry, arg, expected, got, r.returncode, r.stderr[:200]))

# 2) Ca AM: record thuong (khong ke thua Exception) KHONG duoc phep 'raise'
NEG_SRC = HERE / 'sample_user_exception_neg.tkv'
NEG_SRC.write_text(
    '# Ca AM: Point KHONG ke thua Exception -> "raise Point(1)" phai bi\n'
    '# TU CHOI luc bien dich (khong duoc de den luc chay moi vo).\n'
    'class Point:\n    x: "i32"\n\n\ndef bad() -> "i32":\n    raise Point(1)\n    return 0\n',
    encoding='utf-8')
try:
    compile_tkv_cli(NEG_SRC, HERE / 'sample_user_exception_neg.exe', entry_name='bad')
    mismatches.append(('ca am', 'raise Point(1)', 'SyntaxError luc bien dich', 'bien dich THANH CONG'))
    print('  FAIL ca am: bien dich thanh cong (dang le phai bao loi)')
except SyntaxError as e:
    if 'Point' in str(e):
        print(f'  PASS ca am: bao loi dung -> {str(e)[:90]}...')
    else:
        mismatches.append(('ca am', 'thong bao co ten Point', str(e)[:200]))

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('Exception tu dinh nghia (raise/except theo LOAI, doi chieu CPython): PASS - dung 100%.')
