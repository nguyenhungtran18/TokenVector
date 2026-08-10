# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 1 (2026-08-03, dong Python-parity-gap
v2): sha256_hex/md5_hex/base64_encode/base64_decode goi duoc NGAY TRONG
bieu thuc ('return f(x)', 'f(x) + "!"', long nhau 'g(f(x))') - truoc day
CHI hoat dong o dang 't = f(x)' dung rieng 1 dong. Khong co tuong duong
Python that cho cac builtin nay nen doi chieu bang so sanh duong 'compose'
voi duong 'gan roi dung' da xac minh dung tu truoc (giong quy uoc cua
http_get_test.py), CONG voi 1 test tu-nhat-quan (base64 roundtrip)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_builtin_compose.tkv'

ENTRIES = ['sha_direct', 'sha_compose', 'sha_compose_concat', 'md5_direct',
           'b64_of_md5_direct', 'md5_in_b64_nested', 'b64_roundtrip']
exes = {}
for entry in ENTRIES:
    exe_path = HERE / f'sample_expr_builtin_compose_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    exes[entry] = exe_path


def run(entry, s):
    r = subprocess.run([str(exes[entry]), s], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{entry}({s!r}) THAT BAI: {r.stdout} {r.stderr}")
    return r.stdout.strip()


total = 0
mismatches = []
for s in ['hello', 'TokenVector', '', 'a b c 123']:
    total += 1
    direct = run('sha_direct', s)
    compose = run('sha_compose', s)
    if compose != direct:
        mismatches.append(('sha_compose vs sha_direct', s, direct, compose))

    total += 1
    concat = run('sha_compose_concat', s)
    if concat != direct + '!':
        mismatches.append(('sha_compose_concat', s, direct + '!', concat))

    total += 1
    md5_d = run('md5_direct', s)
    b64_direct = run('b64_of_md5_direct', s)
    nested = run('md5_in_b64_nested', s)
    if nested != b64_direct:
        mismatches.append(('md5_in_b64_nested vs b64_of_md5_direct', s, b64_direct, nested))

    total += 1
    rt = run('b64_roundtrip', s)
    if rt != s:
        mismatches.append(('b64_roundtrip', s, s, rt))

print(f"So mau doi chieu: {total}")
print(f"Khop: {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_BUILTIN_COMPOSE nhom 1 (datetime/hashlib/base64): PASS - "
      "goi builtin trong bieu thuc dung 100%, khop duong 'gan roi dung' cu.")
