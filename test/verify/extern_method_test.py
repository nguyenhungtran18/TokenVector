# -*- coding: utf-8 -*-
"""Kiem chung '__tkv_extern_method__' (Task 4, 2026-08-17 - xem docs/
superpowers/plans/2026-08-14-extern-method.md, Task 3 report doi chieu
loai exception THAT tung buoc validate). Cau truc theo mau ipow_test.py/
db_test.py (compile_tkv_cli + subprocess + doi chieu CPython that).

9 buoc dung theo dung task-4-brief.md:
  1. Test tich cuc (net_pow qua System.Math::Pow).
  2. Test dtype khac nhau THEO VI TRI (net_round: f64,i32 -> f64).
  3. Test loi validate (moi case 1 ham rieng, doi chieu dung loai exception
     THAT - xem Task 3 report: trung ten builtin la ValueError (tu
     register_expr_builtin), CON LAI la TranspileError).
  4. Test isolation (QUAN TRONG NHAT) - goi compile_tkv_cli 2 LAN LIEN TIEP
     trong CUNG process, 2 file KHAC nhau CUNG ten builtin 'net_pow'.
  5. Test tuong thich P/Invoke (sqlite3.dll dung DONG THOI voi
     __tkv_extern_method__ trong CUNG 1 file).
  6. Regression duoc chay RIENG qua pytest/tkv_test_runner (xem report),
     khong lap lai o day.
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli, TranspileError  # noqa: E402
from il_dispatch import EXPR_BUILTIN_CODEGEN, EXPR_BUILTIN_DTYPE  # noqa: E402

HERE = Path(__file__).parent.parent
TKV = HERE / 'sample_extern_method.tkv'

fails = []


def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: THAT BAI' + (f' - {detail}' if detail else ''))


# ---------------------------------------------------------------------------
# Step 1: test tich cuc - net_pow qua System.Math::Pow, doi chieu CPython that.
# ---------------------------------------------------------------------------
exe_pow = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_method_pow.exe'),
                           entry_name='run_pow')
r = subprocess.run([str(exe_pow), '2.0', '10.0'], capture_output=True, text=True)
want = str(math.pow(2.0, 10.0))
check('Step1 net_pow(2,10)', r.returncode == 0 and r.stdout.strip() == want,
      f'exit={r.returncode} stdout={r.stdout!r} stderr={r.stderr[:200]!r} want={want!r}')
check('Step1 gia tri dung 1024.0', want == '1024.0', want)

# ---------------------------------------------------------------------------
# Step 2: dtype khac nhau THEO VI TRI - net_round(f64, i32) -> f64. Vi tri 0
# la f64, vi tri 1 la i32 - ep DUNG THEO KHAI BAO (khong theo bieu thuc
# nguon, run_round() trong sample_extern_method.tkv tu convert x=float(a),
# n=int(b) TRUOC khi goi net_round - dtype cua chinh net_round() phai khop
# dung vi tri khai bao trong pragma, khac danh minh boi dtype 2 tham so
# GIONG NHAU nhu net_pow o Step 1).
# ---------------------------------------------------------------------------
exe_round = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_method_round.exe'),
                             entry_name='run_round')
r2 = subprocess.run([str(exe_round), '3.14159', '2'], capture_output=True, text=True)
want2 = str(round(3.14159, 2))
check('Step2 net_round(3.14159,2)', r2.returncode == 0 and r2.stdout.strip() == want2,
      f'exit={r2.returncode} stdout={r2.stdout!r} stderr={r2.stderr[:200]!r} want={want2!r}')

# Xac nhan IL sinh ra dung ep THEO VI TRI: tham so 0 la float64 (khong phai
# int32), tham so 1 la int32 (khong phai float64) - doc lai .il vua sinh.
il_path = HERE / '_extern_method_round.il'
if il_path.exists():
    il_text = il_path.read_text(encoding='utf-8', errors='replace')
    check('Step2 IL goi dung chu ky Round(float64, int32)',
          'Round(float64, int32)' in il_text, il_text[:4000])
else:
    fails.append('Step2: khong tim thay .il de kiem chu ky (co the compile_tkv_cli khong giu lai .il)')


# ---------------------------------------------------------------------------
# Step 3: test loi validate - moi case build FAIL, dung loai exception.
# ---------------------------------------------------------------------------
def _build_tmp(src_text, name):
    tmp = HERE / f'_extern_method_err_{name}.tkv'
    tmp.write_text(src_text, encoding='utf-8')
    exe = HERE / f'_extern_method_err_{name}.exe'
    return tmp, exe


def expect_raise(label, src_text, name, exc_type):
    tmp, exe = _build_tmp(src_text, name)
    try:
        compile_tkv_cli(str(tmp), str(exe), entry_name='run')
        fails.append(f'{label}: LE RA PHAI RAISE {exc_type.__name__} nhung build THANH CONG')
    except exc_type:
        pass  # dung loai mong doi
    except Exception as e:  # noqa: BLE001
        fails.append(f'{label}: raise SAI LOAI - duoc {type(e).__name__} ({e}), '
                      f'mong doi {exc_type.__name__}')


# 3a. assembly chua khai qua __tkv_extern_assembly__ (ten bia, khong nam
# trong 3 mac dinh mscorlib/System/System.Core).
expect_raise(
    'Step3a assembly chua khai bao', '''
__tkv_extern_method__ = [
    {"name": "bad_asm_method", "assembly": "Bia.Khong.Ton.Tai",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_asm_method(1.0, 2.0))
''', 'assembly', TranspileError)

# 3b. dtype khong ho tro trong params.
expect_raise(
    'Step3b dtype khong ho tro trong params', '''
__tkv_extern_method__ = [
    {"name": "bad_param_dtype", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["list", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_param_dtype(1.0, 2.0))
''', 'param_dtype', TranspileError)

# 3c. dtype khong ho tro trong returns.
expect_raise(
    'Step3c dtype khong ho tro trong returns', '''
__tkv_extern_method__ = [
    {"name": "bad_return_dtype", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "complex"},
]


def run(a: "str") -> "str":
    return str(bad_return_dtype(1.0, 2.0))
''', 'return_dtype', TranspileError)

# 3d. name trung 1 builtin co san ('pow') - phai la ValueError tu guard
# co san cua register_expr_builtin (Task 3 report muc 1), KHONG phai
# TranspileError.
expect_raise(
    'Step3d name trung builtin co san (pow)', '''
__tkv_extern_method__ = [
    {"name": "pow", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(pow(1.0, 2.0))
''', 'dup_name', ValueError)

# 3e. class sai regex (ky tu la).
expect_raise(
    'Step3e class sai regex', '''
__tkv_extern_method__ = [
    {"name": "bad_class_name", "assembly": "mscorlib",
     "class": "System.Math!!!", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_class_name(1.0, 2.0))
''', 'bad_class', TranspileError)

# 3f. method sai regex (chua dau cham).
expect_raise(
    'Step3f method sai regex', '''
__tkv_extern_method__ = [
    {"name": "bad_method_name", "assembly": "mscorlib",
     "class": "System.Math", "method": "Po.w", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_method_name(1.0, 2.0))
''', 'bad_method', TranspileError)

# 3g. returns "void" - CHAN o Phase 1 (fix review finding I1: truoc day
# 'void' validate/dang ky duoc nhung KHONG THE GOI THAT o dang lenh doc lap,
# vi codegen_call_stmt (file_io.py) khong tra EXPR_BUILTIN_CODEGEN).
expect_raise(
    'Step3g returns "void" bi chan (Phase 1 chua ho tro)', '''
__tkv_extern_method__ = [
    {"name": "bad_void_return", "assembly": "mscorlib",
     "class": "System.Console", "method": "Beep", "params": [], "returns": "void"},
]


def run(a: "str") -> "str":
    bad_void_return()
    return a
''', 'void_return', TranspileError)

# Xac nhan sau MOI case loi, builtin KHONG bi dang ky sot lai (finally chay
# ca khi validate fail giua chung - vd 3d fail o buoc 7 SAU KHI qua het cac
# buoc 1-6, nhung guard cua register_expr_builtin tu no khong dang ky duoc
# nen khong co gi de pop; cac case 3a/3b/3c/3e/3f fail SOM hon, truoc khi
# goi register_expr_builtin - cung khong dang ky sot).
check('Step3 khong builtin loi nao sot lai trong EXPR_BUILTIN_CODEGEN',
      not any(n in EXPR_BUILTIN_CODEGEN for n in
              ('bad_asm_method', 'bad_param_dtype', 'bad_return_dtype',
               'bad_class_name', 'bad_method_name', 'bad_void_return')),
      sorted(EXPR_BUILTIN_CODEGEN.keys() & {'bad_asm_method', 'bad_param_dtype',
             'bad_return_dtype', 'bad_class_name', 'bad_method_name', 'bad_void_return'}))


# ---------------------------------------------------------------------------
# Step 4 (QUAN TRONG NHAT): isolation - goi compile_tkv_cli 2 LAN LIEN TIEP
# trong CUNG process, 2 file KHAC nhau nhung CA HAI cung khai
# __tkv_extern_method__ voi CUNG ten 'net_pow' - lan 2 phai build THANH
# CONG, khong bao loi trung ten gia (finally-pop cua Task 3).
# ---------------------------------------------------------------------------
iso_src_a = '''
__tkv_extern_method__ = [
    {"name": "net_pow", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str", b: "str") -> "str":
    return str(net_pow(float(a), float(b)))
'''
iso_src_b = '''
__tkv_extern_method__ = [
    {"name": "net_pow", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str", b: "str") -> "str":
    doubled = net_pow(float(a), float(b))
    return str(doubled)
'''
tmp_a = HERE / '_extern_method_iso_a.tkv'
tmp_b = HERE / '_extern_method_iso_b.tkv'
tmp_a.write_text(iso_src_a, encoding='utf-8')
tmp_b.write_text(iso_src_b, encoding='utf-8')
exe_a = HERE / '_extern_method_iso_a.exe'
exe_b = HERE / '_extern_method_iso_b.exe'

check('Step4 truoc khi compile: net_pow chua dang ky', 'net_pow' not in EXPR_BUILTIN_CODEGEN)
try:
    compile_tkv_cli(str(tmp_a), str(exe_a), entry_name='run')
    step4_first_ok = True
except Exception as e:  # noqa: BLE001
    step4_first_ok = False
    fails.append(f'Step4 lan compile THU NHAT (file A) THAT BAI khong mong doi: {e}')
check('Step4 sau lan 1: net_pow da duoc pop khoi EXPR_BUILTIN_CODEGEN',
      'net_pow' not in EXPR_BUILTIN_CODEGEN)

if step4_first_ok:
    try:
        compile_tkv_cli(str(tmp_b), str(exe_b), entry_name='run')
        step4_second_ok = True
    except Exception as e:  # noqa: BLE001
        step4_second_ok = False
        fails.append(f'Step4 lan compile THU HAI (file B, CUNG ten net_pow) '
                      f'THAT BAI - finally-pop KHONG hoat dong: {type(e).__name__}: {e}')
    check('Step4 lan 2 build THANH CONG (finally-pop dung)', step4_second_ok)
    if step4_second_ok:
        r4 = subprocess.run([str(exe_b), '3.0', '4.0'], capture_output=True, text=True)
        want4 = str(math.pow(3.0, 4.0))
        check('Step4 file B chay dung ket qua', r4.stdout.strip() == want4,
              f'got={r4.stdout!r} want={want4!r}')
else:
    fails.append('Step4: bo qua lan compile thu 2 vi lan 1 da that bai')

check('Step4 cuoi cung: net_pow khong con dang ky', 'net_pow' not in EXPR_BUILTIN_CODEGEN)


# ---------------------------------------------------------------------------
# Step 5: tuong thich P/Invoke - dung DONG THOI cjson/sqlite (co san) VA
# __tkv_extern_method__ (moi) trong CUNG 1 file, build+chay PASS.
# ---------------------------------------------------------------------------
pinvoke_src = '''# -*- coding: utf-8 -*-
"""Test tuong thich: sqlite3.dll (P/Invoke co san, tu dong phat hien qua
uses_sqlite() quet body_lines) DUNG DONG THOI voi __tkv_extern_method__
(moi, Task 2-3) trong CUNG 1 ham - xac nhan khong xung dot extern_lines."""
__tkv_extern_method__ = [
    {"name": "net_pow2", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]


def run(dbpath: "str") -> "str":
    h = db_open(dbpath)
    rc1 = db_exec(h, "DROP TABLE IF EXISTS nums")
    rc2 = db_exec(h, "CREATE TABLE nums (id INTEGER, val TEXT)")
    p = net_pow2(2.0, 8.0)
    rc3 = db_exec(h, "INSERT INTO nums VALUES (1, '" + str(p) + "')")
    got = db_query_text(h, "SELECT val FROM nums WHERE id = 1")
    rc4 = db_close(h)
    return got
'''
tmp_pi = HERE / '_extern_method_pinvoke.tkv'
tmp_pi.write_text(pinvoke_src, encoding='utf-8')
exe_pi = HERE / '_extern_method_pinvoke.exe'
try:
    compile_tkv_cli(str(tmp_pi), str(exe_pi), entry_name='run')
    dbfile = HERE / '_extern_method_pinvoke.db'
    if dbfile.exists():
        dbfile.unlink()
    r5 = subprocess.run([str(exe_pi), str(dbfile)], capture_output=True, text=True,
                         cwd=str(HERE))
    want5 = str(math.pow(2.0, 8.0))
    check('Step5 P/Invoke sqlite + extern_method dong thoi',
          r5.returncode == 0 and r5.stdout.strip() == want5,
          f'exit={r5.returncode} stdout={r5.stdout!r} stderr={r5.stderr[:300]!r} want={want5!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step5: build/chay THAT BAI khong mong doi: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Don dep cac fixture .tkv/.exe/.il/.db TAM sinh ra trong luc test (khong
# nam trong .gitignore vi *.tkv khong bi ignore, khac *.exe/*.il) - CHI xoa
# tien to '_extern_method_' TRU 'sample_extern_method.tkv' (file mau vinh
# vien, xem Step 1/2 o tren).
for _p in HERE.glob('_extern_method_*'):
    try:
        _p.unlink()
    except OSError:
        pass

if fails:
    print('extern_method_test: TRUOT')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('extern_method_test: dat (5 buoc: tich cuc, dtype theo vi tri, '
      '7 case loi validate, isolation 2-lan-cung-process, P/Invoke dong thoi)')
sys.exit(0)
