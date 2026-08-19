# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 3 (2026-08-03): 3 method chuoi CAN
VONG LAP + hidden local (.count()/.title()/.zfill()) goi duoc NGAY TRONG
bieu thuc ('return s.count(x) + 100', 's.title() + "!"', long trong dieu
kien if, 2 lan trong CUNG 1 bieu thuc). Doi chieu THANG voi CPython that
(runpy) vi 3 method nay co tuong duong Python 1:1.

Trong tam ky thuat: co che hidden-local moi (EXPR_METHOD_TEMPS trong
il_dispatch.py) - first-pass cap phat local AN theo id(node AST), pass 2
tra cuu lai qua CUNG khoa do. 'count_twice' la ca THAT kiem tra 2 node
method_call KHAC NHAU trong 1 bieu thuc nhan 2 BO local rieng (khong
dung chung/de len nhau) va nhan IL khong trung lap."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_method_compose.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('count_in_expr', [('banana', 'an'), ('aaa', 'a'), ('xyz', 'q')]),
    ('count_twice', [('banana', 'an', 'na'), ('hello world', 'l', 'o')]),
    ('count_in_cond', [('banana', 'an'), ('banana', 'ban'), ('xyz', 'q')]),
    ('title_in_expr', [('hello world',), ('apple42book',), ('',)]),
    ('zfill_in_expr', [('42', 5), ('-42', 5), ('12345', 3)]),
    ('title_and_zfill', [('ab cd', 4), ('x', 3)]),
    ('count_of_title', [('banana banana', 'Banana'), ('aa bb', 'A')]),
]

total = 0
mismatches = []
for entry, arg_sets in cases:
    exe_path = HERE / f'sample_expr_method_compose_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        got_ok = (int(got) == int(expected)) if isinstance(expected, int) else (got == expected)
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_METHOD_COMPOSE nhom 3 (.count()/.title()/.zfill() trong bieu thuc): "
      "PASS - dung 100% so voi CPython that.")
