# -*- coding: utf-8 -*-
"""Kiem chung THAT Giai doan 0.2 nhom 5 (2026-08-03): method tra ve
container voi kieu PHU THUOC DOI TUONG NHAN (d.keys()/d.values()/
lst.copy()) goi duoc NGAY TRONG bieu thuc. Doi chieu THANG CPython that
(runpy) - ca 3 method deu co tuong duong Python 1:1.

Trong tam ky thuat: EXPR_METHOD_SHAPE nay luu HAM PHAN GIAI fn(obj_ta)
-> TypeAnn thay vi cap (dtype, shape) TINH nhu nhom 4 - vi 'd.keys()'
tren dict[i32,str] cho list[i32] nhung tren dict khac lai cho kieu khac.
'copy_is_independent' kiem tra ban sao THAT SU doc lap (sua ban sao
khong dung vao nguon), khong chi 'chay khong loi'."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_expr_recv_dependent.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

ENTRIES = ['keys_assign', 'keys_in_call', 'values_in_call',
           'copy_in_call', 'copy_is_independent']

total = 0
mismatches = []
for entry in ENTRIES:
    exe_path = HERE / f'sample_expr_recv_dependent_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    py_func = py_ns[entry]
    for n in (0, 5):
        total += 1
        expected = py_func(n)
        r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, n, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        got_ok = (int(got) == int(expected)) if isinstance(expected, int) else (got == str(expected))
        if not got_ok:
            mismatches.append((entry, n, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("EXPR_RECV_DEPENDENT nhom 5 (d.keys()/d.values()/lst.copy() trong bieu "
      "thuc, kieu tra ve phu thuoc doi tuong nhan): PASS - dung 100%.")
