# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 4 (2026-08-03): builtin/method tra
ve CONTAINER goi duoc NGAY TRONG bieu thuc.

- 's.split(sep)' co tuong duong Python 1:1 -> doi chieu THANG CPython (runpy).
- 'os_list_files(p)' khong co tuong duong Python -> doi chieu duong
  'compose' voi duong 'gan roi dung' (da xac minh dung tu truoc) tren
  CUNG 1 thu muc that, CONG voi so file THAT dem bang os.listdir (bang
  chung doc lap, khong tu-tham-chieu).

Trong tam ky thuat: hinh dang tra ve (list[str]) lay tu EXPR_*_SHAPE qua
_shaped_return_ta_of_call - CUNG nhanh da dung cho ham nguoi dung tra ve
container, KHONG phai duong khai bao thu 2."""
import os
import runpy
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_container_compose.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

ENTRIES = ['split_assign', 'split_in_call', 'split_in_call_join',
           'list_files_assign', 'list_files_in_call']
exes = {}
for entry in ENTRIES:
    exe_path = HERE / f'sample_expr_container_compose_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    exes[entry] = exe_path


def run(entry, args):
    r = subprocess.run([str(exes[entry])] + [str(a) for a in args],
                        capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{entry}{tuple(args)} THAT BAI: {r.stdout} {r.stderr}")
    return r.stdout.strip()


total = 0
mismatches = []

# --- s.split(sep): doi chieu THANG CPython that ---
for s, sep in [('a,b,c', ','), ('mot|hai', '|'), ('khongcodauphancach', ','),
               ('x,,y', ','), ('', ',')]:
    for entry in ('split_assign', 'split_in_call', 'split_in_call_join'):
        total += 1
        expected = py_ns[entry](s, sep)
        got = run(entry, [s, sep])
        got_ok = (int(got) == int(expected)) if isinstance(expected, int) else (got == str(expected))
        if not got_ok:
            mismatches.append((entry, (s, sep), expected, got))

# --- os_list_files(p): doi chieu 2 duong + so file THAT ---
tmp_root = Path(tempfile.mkdtemp(prefix='tkv_listfiles_test_'))
try:
    for i in range(3):
        (tmp_root / f'file{i}.txt').write_text('x', encoding='utf-8')
    (tmp_root / 'thu_muc_con').mkdir()  # GetFiles chi dem FILE, khong dem thu muc
    real_count = len([e for e in os.listdir(tmp_root) if (tmp_root / e).is_file()])

    total += 1
    direct = int(run('list_files_assign', [str(tmp_root)]))
    if direct != real_count:
        mismatches.append(('list_files_assign vs os.listdir that', str(tmp_root), real_count, direct))

    total += 1
    compose = int(run('list_files_in_call', [str(tmp_root)]))
    if compose != direct:
        mismatches.append(('list_files_in_call vs list_files_assign', str(tmp_root), direct, compose))
finally:
    shutil.rmtree(tmp_root, ignore_errors=True)

print(f"So mau doi chieu: {total}")
print(f"Khop: {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_CONTAINER_COMPOSE nhom 4 (s.split()/os_list_files() tra ve list "
      "trong bieu thuc): PASS - dung 100%.")
