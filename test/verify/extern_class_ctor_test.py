# -*- coding: utf-8 -*-
"""Kiem chung 'newobj' codegen cho __tkv_extern_class__ (Task 3, 2026-08-18 -
xem docs/superpowers/plans/... extern-class). RESCOPED theo controller
approval (option 1): CHI kiem tra constructor/newobj - KHONG goi method
(.callvirt la Task 4, ngoai pham vi Task 3). Cu phap annotation theo dung
mau DA CHAY o extern_class_typesystem_test.py (string-literal type,
return type != None) - vi 'None' lam return annotation khong duoc DSL nay
ho tro dung nhu bai Task 2 da ghi chu.

Do khong the goi .ToString() (thuoc Task 4/callvirt), viec xac nhan
constructor THANH CONG dua vao:
  1. Test tich cuc, ctor KHONG tham so: compile + chay chuong trinh tao 1
     doi tuong handle-type roi in 1 chuoi marker CO DINH ngay sau do - neu
     newobj sai/crash thi khong bao gio toi duoc dong print.
  2. Test tich cuc, ctor CO 1 tham so scalar (str): dung dung ctor that
     cua System.Text.StringBuilder(string) - kiem duong dan compile
     tham so + ep kieu (widening) trong nhanh newobj, khong chi nhanh
     0-tham-so.
  3. Doc truc tiep noi dung .il vua sinh (theo dung tien le
     extern_method_test.py Step2 doc lai .il de kiem chu ky IL) de xac
     nhan dong 'newobj instance void [mscorlib]System.Text.StringBuilder
     ::.ctor(...)' dung dang sinh ra - tin hieu CHINH XAC HON la "khong
     crash".
  4. Test loi: sai so luong tham so ctor -> phai raise (khong can doi
     tuong hoat dong, chi can construct bi TU CHOI dung).
"""
import subprocess
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError  # noqa: E402

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

# ---------------------------------------------------------------------------
# Test 1 (POSITIVE): ctor KHONG tham so - construct + marker print, khong
# goi method nao tren doi tuong.
# ---------------------------------------------------------------------------
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [],
    },
]

def main() -> "i32":
    s = Sb()
    print("ok")
    return 0
'''
tmp = HERE / '_extern_class_ctor_pos.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_ctor_pos.exe'), entry_name='main')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('ctor_noarg_returncode', r.returncode == 0, r.stderr)
# entrypoint wrapper cua tkv in ca gia tri tra ve (i32) sau marker - CHI
# can dong dau tien la marker (chung to thoat qua khoi 'newobj' khong
# crash) la du, khong quan tam dong sau.
check('ctor_noarg_output', r.stdout.strip().splitlines()[:1] == ['ok'], repr(r.stdout))

# Kiem tra IL sinh dung newobj 0-tham-so cho StringBuilder.
il_path_pos = HERE / '_extern_class_ctor_pos.il'
if il_path_pos.exists():
    il_text_pos = il_path_pos.read_text(encoding='utf-8', errors='replace')
    check('ctor_noarg_il_newobj',
          'newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()' in il_text_pos,
          il_text_pos[:2000])
else:
    fails.append('ctor_noarg_il: khong tim thay .il de kiem newobj')

# ---------------------------------------------------------------------------
# Test 2 (POSITIVE): ctor CO 1 tham so scalar (str) - dung ctor that
# StringBuilder(string), exercise duong dan compile-arg + widening.
# ---------------------------------------------------------------------------
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [],
    },
]

def main() -> "i32":
    s = Sb("hello")
    print("ok2")
    return 0
'''
tmp2 = HERE / '_extern_class_ctor_arg.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_ctor_arg.exe'), entry_name='main')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('ctor_arg_returncode', r2.returncode == 0, r2.stderr)
check('ctor_arg_output', r2.stdout.strip().splitlines()[:1] == ['ok2'], repr(r2.stdout))

il_path_arg = HERE / '_extern_class_ctor_arg.il'
if il_path_arg.exists():
    il_text_arg = il_path_arg.read_text(encoding='utf-8', errors='replace')
    check('ctor_arg_il_newobj',
          'newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(string)' in il_text_arg,
          il_text_arg[:2000])
else:
    fails.append('ctor_arg_il: khong tim thay .il de kiem newobj')

# ---------------------------------------------------------------------------
# Test 3 (NEGATIVE): sai so luong tham so ctor -> phai raise.
# ---------------------------------------------------------------------------
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
    },
]

def main() -> "i32":
    s = Sb()
    return 0
'''
tmp3 = HERE / '_extern_class_ctor_arity_err.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_ctor_arity_err.exe'), entry_name='main')
    check('ctor_arity_err_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('ctor_arity_err_raises', True)

# ---------------------------------------------------------------------------
# Test 4 (NEGATIVE): 'name' khong phai Python identifier hop le -> phai raise
# TranspileError (kiem tra o dau vong lap validate Task 3, tkv_compile.py).
# ---------------------------------------------------------------------------
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "123bad", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
    },
]

def main() -> "i32":
    return 0
'''
tmp4 = HERE / '_extern_class_ctor_name_err.tkv'
tmp4.write_text(src4, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_ctor_name_err.exe'), entry_name='main')
    check('ctor_name_identifier_err_raises', False, 'khong raise')
except TranspileError:
    check('ctor_name_identifier_err_raises', True)
except Exception as e:
    check('ctor_name_identifier_err_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Test 5 (NEGATIVE): 'name' trung voi builtin co san ('pow') -> phai raise
# ValueError.
# ---------------------------------------------------------------------------
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "pow", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
    },
]

def main() -> "i32":
    return 0
'''
tmp5 = HERE / '_extern_class_ctor_collision_err.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_ctor_collision_err.exe'), entry_name='main')
    check('ctor_name_collision_err_raises', False, 'khong raise')
except ValueError:
    check('ctor_name_collision_err_raises', True)
except Exception as e:
    check('ctor_name_collision_err_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Test 6 (NEGATIVE): 'assembly' chua duoc khai qua __tkv_extern_assembly__
# (khong phai 1 trong 3 GAC mac dinh) -> phai raise TranspileError.
# ---------------------------------------------------------------------------
src6 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "NotDeclared.Assembly", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
    },
]

def main() -> "i32":
    return 0
'''
tmp6 = HERE / '_extern_class_ctor_assembly_err.tkv'
tmp6.write_text(src6, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp6), out_exe=str(HERE / '_extern_class_ctor_assembly_err.exe'), entry_name='main')
    check('ctor_assembly_undeclared_err_raises', False, 'khong raise')
except TranspileError:
    check('ctor_assembly_undeclared_err_raises', True)
except Exception as e:
    check('ctor_assembly_undeclared_err_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Test 7 (NEGATIVE): 'class' khong dung dinh dang ten class .NET hop le
# (chua khoang trang) -> phai raise TranspileError.
# ---------------------------------------------------------------------------
src7 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System Text StringBuilder",
        "ctor": [], "methods": [],
    },
]

def main() -> "i32":
    return 0
'''
tmp7 = HERE / '_extern_class_ctor_classname_err.tkv'
tmp7.write_text(src7, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp7), out_exe=str(HERE / '_extern_class_ctor_classname_err.exe'), entry_name='main')
    check('ctor_classname_regex_err_raises', False, 'khong raise')
except TranspileError:
    check('ctor_classname_regex_err_raises', True)
except Exception as e:
    check('ctor_classname_regex_err_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Test 8 (NEGATIVE): 'ctor' dung dtype khong phai scalar ho tro
# (i32/i64/f32/f64/str) va cung khong phai handle-type da khai bao trong
# CUNG pragma -> phai raise TranspileError.
# ---------------------------------------------------------------------------
src8 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["bignum"], "methods": [],
    },
]

def main() -> "i32":
    return 0
'''
tmp8 = HERE / '_extern_class_ctor_dtype_err.tkv'
tmp8.write_text(src8, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp8), out_exe=str(HERE / '_extern_class_ctor_dtype_err.exe'), entry_name='main')
    check('ctor_dtype_unsupported_err_raises', False, 'khong raise')
except TranspileError:
    check('ctor_dtype_unsupported_err_raises', True)
except Exception as e:
    check('ctor_dtype_unsupported_err_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

for p in HERE.glob('_extern_class_ctor_*'):
    try:
        p.unlink()
    except OSError:
        pass

if fails:
    print(f'FAILED {len(fails)}/11:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 11/11')
