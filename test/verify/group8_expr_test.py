# -*- coding: utf-8 -*-
"""Giai doan 0.2 nhom 8 (2026-08-03): db_open/db_exec/db_query_text/
db_query_int/db_close, zip_create/zip_extract, json_get_str, http_post goi
duoc o MOI vi tri bieu thuc (khong chi RHS 1 phep gan don le).

Kiem chung THAT: chay exe, doi chieu stdout voi ky vong tinh tay, VA doc
lai file .db + thu muc giai nen bang chinh Python (khong chi 'exe khong
crash'). http_post CHI kiem tra bien dich duoc (khong co endpoint that)."""
import sqlite3
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_group8_expr.tkv'
exe_path = HERE / 'sample_group8_expr.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='run_g8')
# http_post o vi tri bieu thuc: bien dich RIENG (entry khac) - qua duoc
# ilasm nghia la IL sinh ra hop le.
compile_tkv_cli(SRC_PATH, HERE / 'sample_group8_post.exe', entry_name='post_json')

dbpath = HERE / 'g8_expr.db'
zipsrc = HERE / 'g8_zipsrc'
zipout = HERE / 'g8_out.zip'
zipdest = HERE / 'g8_zipsrc_out'


def _rm(p: Path):
    if p.is_dir():
        for child in sorted(p.iterdir(), reverse=True):
            _rm(child)
        p.rmdir()
    elif p.exists():
        p.unlink()


for p in (dbpath, zipsrc, zipout, zipdest):
    _rm(p)
zipsrc.mkdir()
(zipsrc / 'hello.txt').write_text('xin chao', encoding='utf-8')

r = subprocess.run([str(exe_path), str(dbpath), str(zipsrc), str(zipout)],
                   capture_output=True, text=True, cwd=str(HERE))
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = r.stdout.strip()

# zip_create duoc goi HAI lan tren CUNG file .zip (z0 roi z) - kiem chung
# sua 2026-08-03: truoc day lan 2 nem IOException 'file da ton tai'.
# s = "A,B!" ; total = 1 + 10 = 11 ; z = 1 + 1 = 2 ; k = "" + "-" = "-"
# db_close tra ve 0 (SQLITE_OK).
expected = "A,B!_11_2_-0"
mismatches = []
if got != expected:
    mismatches.append(('exe stdout', expected, got))

conn = sqlite3.connect(str(dbpath))
rows = conn.execute('SELECT id, name FROM t ORDER BY id').fetchall()
conn.close()
if rows != [(1, 'A,B')]:
    mismatches.append(('db rows', [(1, 'A,B')], rows))

if not zipout.exists() or not zipfile.is_zipfile(str(zipout)):
    mismatches.append(('zip_create', 'file zip hop le', f'ton tai={zipout.exists()}'))
else:
    names = sorted(zipfile.ZipFile(str(zipout)).namelist())
    if names != ['hello.txt']:
        mismatches.append(('zip noi dung', ['hello.txt'], names))

extracted = zipdest / 'hello.txt'
if not extracted.exists() or extracted.read_text(encoding='utf-8') != 'xin chao':
    mismatches.append(('zip_extract', 'xin chao', extracted.read_text(encoding='utf-8')
                       if extracted.exists() else 'KHONG TON TAI'))

print(f"exe stdout: {got!r} (ky vong {expected!r})")
print(f"db rows (doc lai qua Python sqlite3 that): {rows!r}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("Nhom 8 (db_*/zip_*/json_get_str/http_post trong BIEU THUC): PASS - dung 100%.")
