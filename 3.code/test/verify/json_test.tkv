# -*- coding: utf-8 -*-
"""Kiem chung THAT json_dumps() (Wave 2, 2026-07-29) - dung CLI tu dong
(compile_tkv_cli), doi chieu voi json module That cua CPython (qua
_json_helpers.py, separators=(',', ':') de khop dinh dang gon cua DSL)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_json.tkv'
py_ns = runpy.run_path(str(SRC_PATH))

cases = [
    ('dumps_int', py_ns['dumps_int'], [(0,), (42,), (-7,)]),
    ('dumps_float', py_ns['dumps_float'], [(0.0,), (3.5,), (-2.0,)]),
    ('dumps_str', py_ns['dumps_str'], [('hello',), ('',)]),
    ('dumps_int_list', py_ns['dumps_int_list'], [()]),
    ('dumps_str_list', py_ns['dumps_str_list'], [()]),
    ('dumps_empty_list', py_ns['dumps_empty_list'], [()]),
    # Giai doan 0.2 nhom 7 (2026-08-03): json_dumps() goi duoc NGAY TRONG
    # bieu thuc, khong chi o RHS 1 phep gan don le. 'dumps_list_twice' la
    # ca de vo nhat: 2 loi goi trong CUNG 1 bieu thuc -> 2 bo bien cuc bo
    # an rieng (khoa theo id(danh sach tham so)) + nhan IL khong trung.
    ('dumps_int_in_expr', py_ns['dumps_int_in_expr'], [(0,), (42,), (-7,)]),
    ('dumps_list_in_expr', py_ns['dumps_list_in_expr'], [()]),
    ('dumps_list_twice', py_ns['dumps_list_twice'], [()]),
    ('dumps_len_of_result', py_ns['dumps_len_of_result'], [(42,), (-7,)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_json_{entry}.exe'
    compile_tkv_cli(SRC_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = r.stdout.strip()
        # 'dumps_len_of_result' tra i32, cac ham con lai tra str.
        got_ok = (int(got) == int(expected)) if isinstance(expected, int) else (got == expected)
        if not got_ok:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == json module CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("JSON_DUMPS SUPPORT: PASS - bien dich THAT va dung 100%.")
