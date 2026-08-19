# -*- coding: utf-8 -*-
"""Regression cho thu vien chuan .tkv (examples/stdlib) - THAY
'examples/stdlib/run_stdlib_tests.py' (2026-08-03, Giai doan 1), gop ve
1 nguon su that duy nhat trong test/verify/ de chay cung bo regression
chinh.

3 diem yeu THAT cua ban cu da sua o day:
1. Ban cu in cung 1 dong ket "12/12 MODULES PASS (100%)" du bien 'passed'
   la bao nhieu - loi bien dich chi 'continue' roi van ra 100%. Nay:
   sys.exit(1) khi co bat ky module nao truot, khong co dong tong ket
   hardcode.
2. Ban cu chap nhan ma thoat 0/1/3 VA stdout '1' hoac '3' - qua rong.
   Nay: doi DUNG stdout '1' (moi test_*.tkv tra 1 CHI KHI tu kiem tra
   xong), ma thoat khong quan trong nhung stdout thi phai dung.
3. Ban cu KHONG co bat ky doi chieu nao voi CPython - moi khang dinh
   dung/sai deu do chinh file .tkv tu tuyen bo. Nay them phan B: bien
   dich cac driver IN RA GIA TRI THAT (hash/base64) roi so tung ky tu
   voi thu vien chuan Python.

Exe cu luon bi xoa truoc khi bien dich (bug binary-cache cu, commit
eb13d04)."""
import base64 as py_base64
import csv
import functools
import hashlib as py_hashlib
import io
import operator
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

ROOT = Path(__file__).parent.parent.parent
STDLIB = ROOT / 'TokenVector - Only' / 'examples' / 'stdlib'

# Cac module tu kiem tra ben trong .tkv (tra 1 = dat). Danh sach giu
# nguyen tu run_stdlib_tests.py + test_buffer (bug hardcode 1024 da sua
# 2026-08-03) + test_office_db (da bo 2 ham gia).
SELF_CHECK_MODULES = [
    'test_collections.tkv', 'test_csv.tkv', 'test_eval.tkv', 'test_functools.tkv',
    'test_datetime.tkv', 'test_os.tkv', 'test_hashlib.tkv', 'test_exception.tkv',
    'test_base64.tkv', 'test_shutil.tkv', 'test_zipfile.tkv', 'test_http_server.tkv',
    'test_buffer.tkv', 'test_office_db.tkv',
]

failures = []


def _rm(p: Path):
    if p.is_dir():
        for child in sorted(p.iterdir(), reverse=True):
            _rm(child)
        p.rmdir()
    elif p.exists():
        p.unlink()


# CO Y KHONG don 'doc_output.docx'/'docx_dir' truoc khi chay: chinh bo
# test nay phat hien zip_create nem IOException khi file .zip dich da ton
# tai (khac Python's zipfile, von ghi de). Da sua trong stdlib_zipfile.py
# ngay 2026-08-03 - de nguyen file cu lai chinh la phep kiem chung ban
# sua do, chay lan thu 2 tro di moi co y nghia.


def build_and_run(tkv_name, entry='main', args=()):
    tkv_path = STDLIB / tkv_name
    exe_path = STDLIB / (tkv_path.stem + '.exe')
    if exe_path.exists():
        exe_path.unlink()          # KHONG dung lai binary cache
    compile_tkv_cli(tkv_path, exe_path, entry_name=entry)
    r = subprocess.run([str(exe_path), *args], capture_output=True, text=True,
                       cwd=str(STDLIB), timeout=120)
    return r


print('--- A) Module tu kiem tra (stdout phai DUNG bang "1") ---')
for name in SELF_CHECK_MODULES:
    try:
        r = build_and_run(name)
    except Exception as e:                       # loi bien dich = TRUOT, khong bo qua
        failures.append((name, 'loi bien dich', repr(e)[:200]))
        print(f'  FAIL {name}: loi bien dich: {e}')
        continue
    got = r.stdout.strip()
    if got == '1':
        print(f'  PASS {name}')
    else:
        failures.append((name, '1', f'stdout={got!r} rc={r.returncode} err={r.stderr[:200]}'))
        print(f'  FAIL {name}: stdout={got!r} rc={r.returncode}')

print('--- B) Doi chieu GIA TRI THAT voi thu vien chuan CPython ---')
GROUND_TRUTH_SRC = STDLIB / 'sample_stdlib_ground_truth.tkv'
PROBE = 'TokenVector 2026'
CASES = [
    ('gt_sha256', py_hashlib.sha256(PROBE.encode()).hexdigest()),
    ('gt_md5', py_hashlib.md5(PROBE.encode()).hexdigest()),
    ('gt_b64', py_base64.b64encode(PROBE.encode()).decode()),
    ('gt_b64_roundtrip', PROBE),
]
for entry, expected in CASES:
    exe_path = STDLIB / f'sample_stdlib_{entry}.exe'
    if exe_path.exists():
        exe_path.unlink()
    compile_tkv_cli(GROUND_TRUTH_SRC, exe_path, entry_name=entry)
    r = subprocess.run([str(exe_path), PROBE], capture_output=True, text=True, timeout=120)
    got = r.stdout.strip()
    if got == expected:
        print(f'  PASS {entry}: {got}')
    else:
        failures.append((entry, expected, got))
        print(f'  FAIL {entry}: got={got!r} exp={expected!r}')

print('--- D) csv / functools / eval doi chieu CPython (Giai doan 2) ---')
P2_SRC = STDLIB / 'sample_phase2_ground_truth.tkv'


def run_p2(entry, args):
    exe_path = STDLIB / f'sample_p2_{entry}.exe'
    if exe_path.exists():
        exe_path.unlink()
    compile_tkv_cli(P2_SRC, exe_path, entry_name=entry)
    return subprocess.run([str(exe_path), *[str(a) for a in args]],
                          capture_output=True, text=True, timeout=120).stdout.strip()


def check(label, got, expected):
    if got == str(expected):
        print(f'  PASS {label}: {got!r}')
    else:
        failures.append((label, str(expected), got))
        print(f'  FAIL {label}: got={got!r} exp={str(expected)!r}')


# csv: dung CHINH module csv cua Python lam trong tai
CSV_LINES = ['a,"x,y",b', 'a,,b', '"he said ""hi""",2', 'plain', '"chi mot truong, co phay"']
for line in CSV_LINES:
    py_fields = next(csv.reader([line]))
    check(f'csv_field_count({line!r})', run_p2('csv_field_count', [line]), len(py_fields))
    check(f'csv_nth_field({line!r}, 0)', run_p2('csv_nth_field', [line, 0]), py_fields[0])
    buf = io.StringIO()
    csv.writer(buf, lineterminator='').writerow(py_fields)
    check(f'csv_roundtrip({line!r})', run_p2('csv_roundtrip', [line]), buf.getvalue())

# functools.reduce: trong tai la chinh functools.reduce cua Python
for n, init in [(4, 10), (1, 0), (6, -3)]:
    check(f'reduce_i32(1..{n}, add, {init})', run_p2('reduce_sum', [n, init]),
          functools.reduce(operator.add, range(1, n + 1), init))
for n in [5, 1, 3]:
    check(f'reduce_i32_nostart(1..{n}, mul)', run_p2('reduce_product', [n]),
          functools.reduce(operator.mul, range(1, n + 1)))

# eval: bieu thuc HANG do chinh file nay viet ra, trong tai la eval cua Python
for expr in ['7/2', '(10 + 20) * 3', '100 - 25 * 2 + 10', '-3 + 1.5', '10 % 3']:
    check(f'eval_str({expr!r})', run_p2('eval_value', [expr]), float(eval(expr)))

print('--- C) File .docx do office_db_suite tao ra co MO duoc khong ---')
docx = STDLIB / 'doc_output.docx'
if not docx.exists() or not zipfile.is_zipfile(str(docx)):
    failures.append(('doc_output.docx', 'file zip hop le', f'ton tai={docx.exists()}'))
    print('  FAIL doc_output.docx khong phai file zip hop le')
else:
    names = zipfile.ZipFile(str(docx)).namelist()
    if 'document.xml' not in names:
        failures.append(('doc_output.docx', 'co document.xml', str(names)))
        print(f'  FAIL doc_output.docx thieu document.xml: {names}')
    else:
        print(f'  PASS doc_output.docx mo duoc, chua {names}')

if failures:
    print(f'\nTRUOT {len(failures)} muc:')
    for f in failures:
        print(' ', f)
    sys.exit(1)
print(f'\nstdlib regression: PASS toan bo ({len(SELF_CHECK_MODULES)} module tu kiem tra '
      f'+ {len(CASES)} gia tri doi chieu CPython + 1 file .docx doc lai duoc).')
