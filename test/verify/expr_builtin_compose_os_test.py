# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 2 (2026-08-03): os_getenv/os_mkdir
goi duoc NGAY TRONG bieu thuc. Trong tam: os_getenv co nhan IL rieng
('os_getenv_end') - PHAI sinh nhan DUY NHAT moi lan goi (dung
label_counter), khong thi ilasm bao loi 'label da khai bao' ngay khi 1
ham goi os_getenv() 2 LAN ('getenv_twice' la test THAT truong hop nay,
khong phai ly thuyet)."""
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_builtin_compose_os.tkv'

ENTRIES = ['getenv_direct', 'getenv_compose', 'getenv_compose_concat',
           'getenv_twice', 'mkdir_direct', 'mkdir_compose']
exes = {}
for entry in ENTRIES:
    exe_path = HERE / f'sample_expr_builtin_compose_os_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    exes[entry] = exe_path


def run(entry, args, env=None):
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    r = subprocess.run([str(exes[entry])] + list(args), capture_output=True, text=True, env=full_env)
    if r.returncode != 0:
        raise RuntimeError(f"{entry}{args} THAT BAI: {r.stdout} {r.stderr}")
    return r.stdout.strip()


total = 0
mismatches = []

VAR_A, VAL_A = 'TKV_TEST_VAR_A', 'gia-tri-A'
VAR_B, VAL_B = 'TKV_TEST_VAR_B', 'gia-tri-B'
VAR_MISSING = 'TKV_TEST_VAR_KHONG_TON_TAI_123'
env = {VAR_A: VAL_A, VAR_B: VAL_B}

for name, expected in [(VAR_A, VAL_A), (VAR_MISSING, '')]:
    total += 1
    direct = run('getenv_direct', [name], env=env)
    if direct != expected:
        mismatches.append(('getenv_direct', name, expected, direct))

    total += 1
    compose = run('getenv_compose', [name], env=env)
    if compose != direct:
        mismatches.append(('getenv_compose vs direct', name, direct, compose))

    total += 1
    concat = run('getenv_compose_concat', [name], env=env)
    if concat != direct + '!':
        mismatches.append(('getenv_compose_concat', name, direct + '!', concat))

total += 1
twice = run('getenv_twice', [VAR_A, VAR_B], env=env)
if twice != VAL_A + VAL_B:
    mismatches.append(('getenv_twice', (VAR_A, VAR_B), VAL_A + VAL_B, twice))

total += 1
twice_one_missing = run('getenv_twice', [VAR_A, VAR_MISSING], env=env)
if twice_one_missing != VAL_A + '':
    mismatches.append(('getenv_twice (1 missing)', (VAR_A, VAR_MISSING), VAL_A, twice_one_missing))

tmp_root = Path(tempfile.mkdtemp(prefix='tkv_os_mkdir_test_'))
try:
    for sub in ['direct_dir', 'compose_dir']:
        total += 1
        target = tmp_root / sub
        entry = 'mkdir_direct' if sub == 'direct_dir' else 'mkdir_compose'
        got = int(run(entry, [str(target)]))
        expected_val = 1 if sub == 'direct_dir' else 2
        if got != expected_val or not target.is_dir():
            mismatches.append((entry, str(target), expected_val, got, target.is_dir()))
finally:
    shutil.rmtree(tmp_root, ignore_errors=True)

print(f"So mau doi chieu: {total}")
print(f"Khop: {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_BUILTIN_COMPOSE nhom 2 (os_getenv/os_mkdir): PASS - "
      "goi builtin trong bieu thuc dung 100%, nhan IL rieng bung khong trung lap.")
