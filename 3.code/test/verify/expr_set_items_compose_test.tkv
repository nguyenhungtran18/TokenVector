# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 6 (2026-08-03): d.items() va
set.union()/intersection()/difference() chuyen sang duong bieu thuc
THONG NHAT. Doi chieu THANG CPython that (runpy) - ca 4 deu co tuong
duong Python 1:1.

Trong tam ky thuat:
- 4 method nay KHONG con duong ASSIGN_RHS_PARSERS rieng; phep gan di qua
  nhanh assign_scalar CHUNG, kieu tra ve suy tu ham phan giai (co che
  nhom 5), rieng set.* con dung 1 BIEN AN (co che nhom 3) vi ban cu ghi
  thang vao bien dich roi nap lai - dang do khong the la bieu thuc.
- 'union_twice': 2 loi goi set.union() trong CUNG 1 ham -> 2 bien an
  rieng theo id(node); neu khoa bi de len nhau, ket qua se sai.
- 'union_leaves_sources_intact': ban sao THAT SU (2 set nguon khong bi
  sua), khong chi 'chay khong loi'."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_set_items_compose.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

ENTRIES = ['items_assign', 'union_assign', 'intersection_assign',
           'difference_assign', 'union_twice', 'union_leaves_sources_intact',
           'ks_sum_of_copy']
# BUG THAT (2026-08-03) - 3 ham 'ks_*' la HOI QUY cho 1 loi da lot vao 2
# commit: bo duong ASSIGN_RHS cu (nhom 3-6) lam mat kenh parser
# 'known_shapes[bien_dich]' ma cac parser KHAC tra cuu -> 'ys = xs.copy()'
# roi 'sum(ys)' bao "ham 'sum' khong ton tai". Ca dung chuoi (sorted/
# count) kiem RIENG ben duoi vi tra ve str/i32 khac nhau.
STR_ARG_ENTRIES = [('ks_sorted_of_split', ['b,a,c'], str),
                   ('ks_count_on_split', ['a,b,a'], int)]

total = 0
mismatches = []
for entry in ENTRIES:
    exe_path = HERE / f'sample_expr_set_items_compose_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for n in (0, 7):
        total += 1
        expected = py_func(n)
        r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, n, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        if int(got) != int(expected):
            mismatches.append((entry, n, expected, got, r.stdout, r.stderr))

for entry, args, cast in STR_ARG_ENTRIES:
    exe_path = HERE / f'sample_expr_set_items_compose_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    total += 1
    expected = py_ns[entry](*args)
    r = subprocess.run([str(exe_path)] + args, capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
        continue
    got = r.stdout.strip()
    if cast(got) != cast(expected):
        mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_SET_ITEMS nhom 6 (d.items() + set.union/intersection/difference "
      "qua duong bieu thuc thong nhat): PASS - dung 100%.")
