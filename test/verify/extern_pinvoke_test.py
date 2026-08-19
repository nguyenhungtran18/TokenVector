# -*- coding: utf-8 -*-
"""Kiem chung '__tkv_extern_pinvoke__' (Task 4/4, 2026-08-17 - xem docs/
superpowers/plans/2026-08-17-extern-pinvoke.md, task-4-brief.md). Cau truc
theo mau extern_method_test.py (compile_tkv_cli + subprocess + doi chieu
CPython/Windows API that).

9 buoc dung theo task-4-brief.md:
  1. Test tich cuc cdecl (msvcrt.dll::sqrt, doi chieu math.sqrt CPython).
  2. Test tich cuc stdcall (kernel32.dll::GetCurrentProcessId, xac nhan
     PID la so duong hop ly).
  3. Test returns:"void" goi dang lenh doc lap (msvcrt.dll::srand).
  4. Test loi validate (moi case 1 ham rieng, dung loai exception THAT).
  5. Test isolation (goi compile_tkv_cli 2 LAN LIEN TIEP cung process, 2
     file khac nhau CUNG ten builtin 'extern_pinvoke').
  6. Test tuong thich __tkv_extern_method__ (Phase 1) + P/Invoke viet tay
     (db_*) + __tkv_extern_pinvoke__ (Phase 2) DONG THOI trong CUNG 1 file.
  7. Regression duoc chay RIENG qua cac file test khac (xem report), khong
     lap lai toan bo o day - chi xac nhan khong builtin nao sot lai.
  8/9. Docs + commit - lam ngoai file nay.
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli, TranspileError  # noqa: E402
from il_dispatch import EXPR_BUILTIN_CODEGEN, EXPR_BUILTIN_DTYPE  # noqa: E402
from tkv_compile import EXTERN_VOID_BUILTIN_NAMES  # noqa: E402

HERE = Path(__file__).parent.parent
TKV = HERE / 'sample_extern_pinvoke.tkv'

fails = []


def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: THAT BAI' + (f' - {detail}' if detail else ''))


def _run(exe, args):
    return subprocess.run([str(exe)] + list(args), capture_output=True, text=True)


# ---------------------------------------------------------------------------
# Step 1: test tich cuc cdecl - msvcrt.dll::sqrt(double)->double, doi chieu
# math.sqrt CPython that.
# ---------------------------------------------------------------------------
exe_sqrt = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_pinvoke_sqrt.exe'),
                            entry_name='run_sqrt')
r1 = _run(exe_sqrt, ['144.0'])
want1 = str(math.sqrt(144.0))
check('Step1 c_sqrt(144.0) cdecl', r1.returncode == 0 and r1.stdout.strip() == want1,
      f'exit={r1.returncode} stdout={r1.stdout!r} stderr={r1.stderr[:200]!r} want={want1!r}')
check('Step1 gia tri dung 12.0', want1 == '12.0', want1)

# ---------------------------------------------------------------------------
# Step 2: test tich cuc stdcall - kernel32.dll::GetCurrentProcessId(void)
# ->i32, khong tham so. Xac nhan KET QUA HOP LY (so duong, khac 0, khac gia
# tri rac lon bat thuong - neu convention SAI, Windows thuong tra gia tri
# rac hoac crash).
# ---------------------------------------------------------------------------
exe_getpid = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_pinvoke_getpid.exe'),
                              entry_name='run_getpid')
r2 = _run(exe_getpid, ['x'])
pid_ok = False
pid_val = None
if r2.returncode == 0:
    try:
        pid_val = int(r2.stdout.strip())
        # PID that tren Windows: so duong, thuong < 100000 (khong phai gia
        # tri rac 32-bit ngau nhien nhu 3762504530 tung thay o spike truoc
        # khi truyen dung tham so).
        pid_ok = 0 < pid_val < 1_000_000
    except ValueError:
        pid_ok = False
check('Step2 c_getpid() stdcall exit=0', r2.returncode == 0,
      f'exit={r2.returncode} stdout={r2.stdout!r} stderr={r2.stderr[:200]!r}')
check('Step2 c_getpid() tra ve PID hop ly (0 < pid < 1000000)', pid_ok, pid_val)

# ---------------------------------------------------------------------------
# Step 3: test returns:"void" goi dang lenh doc lap - msvcrt.dll::srand
# (int)->void. Neu logic pop/khong-pop sai, ilasm.exe se FAIL luc assemble
# (mat can bang ngan xep) - compile_tkv_cli o day da assemble THANH CONG
# (khong raise), tuc IL sinh ra can bang dung.
# ---------------------------------------------------------------------------
exe_srand = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_pinvoke_srand.exe'),
                             entry_name='run_srand')
r3 = _run(exe_srand, ['42'])
check('Step3 c_srand(42) void, dang lenh doc lap', r3.returncode == 0 and r3.stdout.strip() == 'ok',
      f'exit={r3.returncode} stdout={r3.stdout!r} stderr={r3.stderr[:200]!r}')


# ---------------------------------------------------------------------------
# Step 4: test loi validate - moi case build FAIL, dung loai exception.
# ---------------------------------------------------------------------------
def _build_tmp(src_text, name):
    tmp = HERE / f'_extern_pinvoke_err_{name}.tkv'
    tmp.write_text(src_text, encoding='utf-8')
    exe = HERE / f'_extern_pinvoke_err_{name}.exe'
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


# 4a. dll sai dinh dang (chua ket thuc '.dll').
expect_raise(
    'Step4a dll sai dinh dang', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_dll_ext", "dll": "msvcrt.exe", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_dll_ext(1.0))
''', 'dll_ext', TranspileError)

# 4b. dll path traversal.
expect_raise(
    'Step4b dll path traversal', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_dll_path", "dll": "../../evil.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_dll_path(1.0))
''', 'dll_path', TranspileError)

# 4c. symbol sai regex (bat dau bang so).
expect_raise(
    'Step4c symbol sai regex', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_symbol", "dll": "msvcrt.dll", "symbol": "1sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_symbol(1.0))
''', 'bad_symbol', TranspileError)

# 4d. convention khong phai cdecl/stdcall.
expect_raise(
    'Step4d convention sai', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_conv", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "thiscall", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_conv(1.0))
''', 'bad_conv', TranspileError)

# 4e. dtype khong ho tro trong params.
expect_raise(
    'Step4e dtype khong ho tro trong params', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_param_dtype", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["list"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(bad_param_dtype(1.0))
''', 'param_dtype', TranspileError)

# 4f. dtype khong ho tro trong returns (khac 'void').
expect_raise(
    'Step4f dtype khong ho tro trong returns', '''
__tkv_extern_pinvoke__ = [
    {"name": "bad_return_dtype", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "complex"},
]


def run(a: "str") -> "str":
    return str(bad_return_dtype(1.0))
''', 'return_dtype', TranspileError)

# 4g. name trung 1 builtin co san ('pow') - phai la ValueError tu guard
# co san cua register_expr_builtin (dung nhu Task 3's xac nhan cho Phase 1).
expect_raise(
    'Step4g name trung builtin co san (pow)', '''
__tkv_extern_pinvoke__ = [
    {"name": "pow", "dll": "msvcrt.dll", "symbol": "pow",
     "convention": "cdecl", "params": ["f64", "f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(pow(1.0, 2.0))
''', 'dup_name', ValueError)

check('Step4 khong builtin loi nao sot lai trong EXPR_BUILTIN_CODEGEN',
      not any(n in EXPR_BUILTIN_CODEGEN for n in
              ('bad_dll_ext', 'bad_dll_path', 'bad_symbol', 'bad_conv',
               'bad_param_dtype', 'bad_return_dtype')),
      sorted(EXPR_BUILTIN_CODEGEN.keys() & {'bad_dll_ext', 'bad_dll_path',
             'bad_symbol', 'bad_conv', 'bad_param_dtype', 'bad_return_dtype'}))


# ---------------------------------------------------------------------------
# Step 5 (QUAN TRONG NHAT): isolation - goi compile_tkv_cli 2 LAN LIEN TIEP
# trong CUNG process, 2 file KHAC nhau nhung CA HAI cung khai
# __tkv_extern_pinvoke__ voi CUNG ten 'c_iso' - lan 2 phai build THANH
# CONG, khong bao loi trung ten gia (finally-pop). Mo rong cho ca case
# non-void (khac void da test o Task 3's fix report).
# ---------------------------------------------------------------------------
iso_src_a = '''
__tkv_extern_pinvoke__ = [
    {"name": "c_iso", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    return str(c_iso(float(a)))
'''
iso_src_b = '''
__tkv_extern_pinvoke__ = [
    {"name": "c_iso", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(a: "str") -> "str":
    x = c_iso(float(a))
    return str(x)
'''
tmp_a = HERE / '_extern_pinvoke_iso_a.tkv'
tmp_b = HERE / '_extern_pinvoke_iso_b.tkv'
tmp_a.write_text(iso_src_a, encoding='utf-8')
tmp_b.write_text(iso_src_b, encoding='utf-8')
exe_a = HERE / '_extern_pinvoke_iso_a.exe'
exe_b = HERE / '_extern_pinvoke_iso_b.exe'

check('Step5 truoc khi compile: c_iso chua dang ky', 'c_iso' not in EXPR_BUILTIN_CODEGEN)
try:
    compile_tkv_cli(str(tmp_a), str(exe_a), entry_name='run')
    step5_first_ok = True
except Exception as e:  # noqa: BLE001
    step5_first_ok = False
    fails.append(f'Step5 lan compile THU NHAT (file A) THAT BAI khong mong doi: {e}')
check('Step5 sau lan 1: c_iso da duoc pop khoi EXPR_BUILTIN_CODEGEN',
      'c_iso' not in EXPR_BUILTIN_CODEGEN)

if step5_first_ok:
    try:
        compile_tkv_cli(str(tmp_b), str(exe_b), entry_name='run')
        step5_second_ok = True
    except Exception as e:  # noqa: BLE001
        step5_second_ok = False
        fails.append(f'Step5 lan compile THU HAI (file B, CUNG ten c_iso) '
                      f'THAT BAI - finally-pop KHONG hoat dong: {type(e).__name__}: {e}')
    check('Step5 lan 2 build THANH CONG (finally-pop dung)', step5_second_ok)
    if step5_second_ok:
        r5b = _run(exe_b, ['16.0'])
        want5b = str(math.sqrt(16.0))
        check('Step5 file B chay dung ket qua', r5b.stdout.strip() == want5b,
              f'got={r5b.stdout!r} want={want5b!r}')
else:
    fails.append('Step5: bo qua lan compile thu 2 vi lan 1 da that bai')

check('Step5 cuoi cung: c_iso khong con dang ky', 'c_iso' not in EXPR_BUILTIN_CODEGEN)
check('Step5 EXTERN_VOID_BUILTIN_NAMES khong con sot ten nao tu test nay',
      not ({'c_iso'} & EXTERN_VOID_BUILTIN_NAMES))


# ---------------------------------------------------------------------------
# Step 6: tuong thich __tkv_extern_method__ (Phase 1) + P/Invoke viet tay
# (db_*, sqlite3.dll) + __tkv_extern_pinvoke__ (Phase 2) DONG THOI trong
# CUNG 1 file - xac nhan khong xung dot extern_lines/cjson_decl_lines/
# sqlite_decl_lines/pinvoke_decl_lines.
# ---------------------------------------------------------------------------
combo_src = '''# -*- coding: utf-8 -*-
"""Test tuong thich: __tkv_extern_method__ (Phase 1, .NET managed) +
db_* (P/Invoke sqlite3.dll viet tay san) + __tkv_extern_pinvoke__ (Phase 2,
P/Invoke DLL native tong quat) DONG THOI trong CUNG 1 file."""
__tkv_extern_method__ = [
    {"name": "net_pow3", "assembly": "mscorlib", "class": "System.Math",
     "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]
__tkv_extern_pinvoke__ = [
    {"name": "c_sqrt3", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]


def run(dbpath: "str") -> "str":
    h = db_open(dbpath)
    rc1 = db_exec(h, "DROP TABLE IF EXISTS nums3")
    rc2 = db_exec(h, "CREATE TABLE nums3 (id INTEGER, val TEXT)")
    p = net_pow3(2.0, 6.0)
    s = c_sqrt3(p)
    rc3 = db_exec(h, "INSERT INTO nums3 VALUES (1, '" + str(s) + "')")
    got = db_query_text(h, "SELECT val FROM nums3 WHERE id = 1")
    rc4 = db_close(h)
    return got
'''
tmp_combo = HERE / '_extern_pinvoke_combo.tkv'
tmp_combo.write_text(combo_src, encoding='utf-8')
exe_combo = HERE / '_extern_pinvoke_combo.exe'
try:
    compile_tkv_cli(str(tmp_combo), str(exe_combo), entry_name='run')
    dbfile = HERE / '_extern_pinvoke_combo.db'
    if dbfile.exists():
        dbfile.unlink()
    r6 = subprocess.run([str(exe_combo), str(dbfile)], capture_output=True, text=True,
                         cwd=str(HERE))
    # net_pow3(2.0, 6.0) = 64.0, sqrt(64.0) = 8.0
    want6 = str(math.sqrt(math.pow(2.0, 6.0)))
    check('Step6 extern_method + db_* + extern_pinvoke dong thoi',
          r6.returncode == 0 and r6.stdout.strip() == want6,
          f'exit={r6.returncode} stdout={r6.stdout!r} stderr={r6.stderr[:300]!r} want={want6!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step6: build/chay THAT BAI khong mong doi: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Don dep cac fixture .tkv/.exe/.il/.db TAM sinh ra trong luc test - CHI xoa
# tien to '_extern_pinvoke_' TRU 'sample_extern_pinvoke.tkv' (file mau vinh
# vien, xem Step 1-3 o tren).
# ---------------------------------------------------------------------------
for _p in HERE.glob('_extern_pinvoke_*'):
    try:
        _p.unlink()
    except OSError:
        pass

if fails:
    print('extern_pinvoke_test: TRUOT')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('extern_pinvoke_test: dat (6 buoc: cdecl tich cuc, stdcall tich cuc, '
      'void doc lap, 6 case loi validate, isolation 2-lan-cung-process, '
      'tuong thich extern_method+db_*+extern_pinvoke dong thoi)')
sys.exit(0)
