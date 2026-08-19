# -*- coding: utf-8 -*-
"""Kiem chung THAT khoang trong ngon ngu #3 - import module TokenVector
khac ('__tkv_import__'): sample_import_main.tkv dung Rect/double_it dinh
nghia trong sample_import_shapes.tkv - dung CLI tu dong (compile_tkv_cli,
tu dong gop 2 file qua extract_program_file), doi chieu voi CPython that.

CPython that KHONG co co che import '.tkv' (chi TokenVector compiler moi
hieu '__tkv_import__') - de doi chieu dung, GHEP THU CONG namespace cua
2 file (runpy.run_path tra ve CHINH globals dict duoc ham dung, gan them
Rect/double_it vao do TRUOC khi goi ham cua main la du, vi Python tra cuu
free-variable LUC GOI HAM, khong phai luc dinh nghia)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SHAPES_PATH = HERE / 'sample_import_shapes.tkv'
MAIN_PATH = HERE / 'sample_import_main.tkv'

shapes_ns = runpy.run_path(str(SHAPES_PATH))
main_ns = runpy.run_path(str(MAIN_PATH))
# runpy.run_path() tra ve 1 BAN SAO cua namespace (KHONG phai chinh
# __globals__ ma ham dung de tra cuu free-variable luc goi - da xac minh
# THAT: 'ns is ns["f"].__globals__' la False) - phai cap nhat TRUC TIEP
# vao __globals__ cua ham (2 ham trong main_ns cung 1 module nen dung
# CHUNG 1 __globals__ dict, chi can cap nhat 1 lan).
main_ns['main'].__globals__.update({k: v for k, v in shapes_ns.items() if not k.startswith('_')})

cases = [
    ('scaled_rect_area', main_ns['scaled_rect_area'],
     [(2.0, 3.0, 1.0), (0.0, 5.0, 2.0), (4.0, 4.0, 0.5), (1.5, 2.0, 3.0)]),
    ('main', main_ns['main'],
     [(2.0, 3.0), (0.0, 5.0), (10.0, -1.0)]),
]

total = 0
mismatches = []
for entry, py_func, arg_sets in cases:
    exe_path = HERE / f'sample_import_main_{entry}.exe'
    compile_tkv_cli(MAIN_PATH, exe_path, entry_name=entry)
    for args in arg_sets:
        total += 1
        expected = py_func(*args)
        r = subprocess.run([str(exe_path)] + [str(a) for a in args],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((entry, args, expected, None, r.stdout, r.stderr))
            continue
        got = float(r.stdout.strip())
        if abs(got - float(expected)) > 1e-3:
            mismatches.append((entry, args, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("IMPORT SUPPORT: PASS - '__tkv_import__' gop 2 file .tkv (record + ham) bien dich THAT va dung 100%.")
