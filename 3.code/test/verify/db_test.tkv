# -*- coding: utf-8 -*-
"""Kiem chung THAT DB qua P/Invoke sqlite3.dll (Wave 3, 2026-07-29 - xem
project-tokenvector-wave2-status memory) - db_open/db_exec/db_query_text/
db_query_int/db_close. Doi chieu voi Python's sqlite3 module THAT (doc
lai CHINH file .db do exe vua tao ra, xac nhan noi dung dung THAT su
duoc ghi vao dia, khong chi 'exe khong crash')."""
import sqlite3
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_db.tkv'
exe_path = HERE / 'sample_db_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='run_db')

dbpath = HERE / 'db_test_real.db'
if dbpath.exists():
    dbpath.unlink()

r = subprocess.run([str(exe_path), str(dbpath)], capture_output=True, text=True, cwd=str(HERE))
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = r.stdout.strip()

expected = "Bob_2"
mismatches = []
if got != expected:
    mismatches.append(('exe stdout', expected, got))

conn = sqlite3.connect(str(dbpath))
cur = conn.cursor()
cur.execute('SELECT id, name FROM people ORDER BY id')
rows = cur.fetchall()
conn.close()
expected_rows = [(1, 'Alice'), (2, 'Bob')]
if rows != expected_rows:
    mismatches.append(('db rows', expected_rows, rows))

print(f"exe stdout: {got!r} (ky vong {expected!r})")
print(f"db rows (doc lai qua Python sqlite3 that): {rows!r}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("DB (db_open/db_exec/db_query_text/db_query_int/db_close qua sqlite3.dll THAT): PASS - dung 100%.")
