# -*- coding: utf-8 -*-
"""Kiem chung tong hop '__tkv_extern_class__' (Task 5, 2026-08-18 - xem
docs/superpowers/plans/2026-08-18-extern-class.md, task-5-brief.md). Cau
truc theo mau extern_method_test.py/extern_pinvoke_test.py (compile_tkv_cli
+ subprocess + doi chieu Python/CPython that). File nay LA test TONG HOP,
KHONG lap lai case da co o 4 file Task 1-4:
  - extern_class_parse_test.py (Task 1: parse pragma)
  - extern_class_typesystem_test.py (Task 2: type-system)
  - extern_class_ctor_test.py (Task 3: newobj codegen)
  - extern_class_method_test.py (Task 4: callvirt codegen + chaining)

4 buoc rieng cua Task 5:
  1. Test tich cuc dung fixture sample_extern_class.tkv, doi chieu Python
     string concat that lam oracle.
  2. Test tuong thich: __tkv_extern_class__ TRON voi __tkv_extern_method__
     (Phase 1) VA __tkv_extern_pinvoke__ (Phase 2) trong CUNG 1 file.
  3. Test 2 extern-class KHAC NHAU cung khai method TRUNG TEN nhung KHAC
     chu ky (bo sung gap coverage docs/BUGS_TODO.md muc L).
  4. Test duck-typing tu choi handle type lam tham so 'inferred' (Step 1-4
     cua brief).
"""
import math
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli, TranspileError  # noqa: E402

HERE = Path(__file__).parent.parent
TKV = HERE / 'sample_extern_class.tkv'

fails = []


def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: THAT BAI' + (f' - {detail}' if detail else ''))


# ---------------------------------------------------------------------------
# Step A: test tich cuc - fixture sample_extern_class.tkv, doi chieu Python
# string concat that ('a' + 'b' == StringBuilder(a).Append(b).ToString()).
# ---------------------------------------------------------------------------
exe = compile_tkv_cli(str(TKV), out_exe=str(HERE / '_extern_class_sample.exe'),
                       entry_name='run_concat')
r = subprocess.run([str(exe), 'hello, ', 'world'], capture_output=True, text=True)
want = 'hello, ' + 'world'
check('StepA fixture tich cuc', r.returncode == 0 and r.stdout.strip() == want,
      f'exit={r.returncode} stdout={r.stdout!r} stderr={r.stderr[:300]!r} want={want!r}')


# ---------------------------------------------------------------------------
# Step B: tuong thich - __tkv_extern_class__ TRON voi __tkv_extern_method__
# (Phase 1) trong CUNG 1 file: goi net_pow (static method .NET) de tinh gia
# tri, roi dung ket qua lam doi so cho constructor cua Sb, ToString() in ra.
# ---------------------------------------------------------------------------
compat_src = '''
__tkv_extern_method__ = [
    {"name": "net_pow", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [{"name": "ToString", "params": [], "returns": "str"}],
    },
]


def main() -> "i32":
    p = net_pow(2.0, 10.0)
    s = Sb(str(p))
    print(s.ToString())
    return 0
'''
tmp_compat = HERE / '_extern_class_compat.tkv'
tmp_compat.write_text(compat_src, encoding='utf-8')
exe_compat = compile_tkv_cli(str(tmp_compat), out_exe=str(HERE / '_extern_class_compat.exe'),
                              entry_name='main')
r_compat = subprocess.run([str(exe_compat)], capture_output=True, text=True)
want_compat = str(math.pow(2.0, 10.0))
check('StepB tuong thich extern_method', r_compat.returncode == 0
      and r_compat.stdout.strip().splitlines()[0] == want_compat,
      f'exit={r_compat.returncode} stdout={r_compat.stdout!r} '
      f'stderr={r_compat.stderr[:300]!r} want={want_compat!r}')

# ---------------------------------------------------------------------------
# Step B2: tuong thich - TRON CA BA: __tkv_extern_class__ + __tkv_extern_method__
# (Phase 1) + __tkv_extern_pinvoke__ (Phase 2, msvcrt.dll::sqrt cdecl) trong
# CUNG 1 file.
# ---------------------------------------------------------------------------
compat3_src = '''
__tkv_extern_method__ = [
    {"name": "net_pow3", "assembly": "mscorlib",
     "class": "System.Math", "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]
__tkv_extern_pinvoke__ = [
    {"name": "c_sqrt3", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]
__tkv_extern_class__ = [
    {
        "name": "Sb3", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [{"name": "ToString", "params": [], "returns": "str"}],
    },
]


def main() -> "i32":
    p = net_pow3(2.0, 6.0)
    q = c_sqrt3(p)
    s = Sb3(str(q))
    print(s.ToString())
    return 0
'''
tmp_compat3 = HERE / '_extern_class_compat3.tkv'
tmp_compat3.write_text(compat3_src, encoding='utf-8')
try:
    exe_compat3 = compile_tkv_cli(str(tmp_compat3), out_exe=str(HERE / '_extern_class_compat3.exe'),
                                   entry_name='main')
    r_compat3 = subprocess.run([str(exe_compat3)], capture_output=True, text=True)
    want_compat3 = str(math.sqrt(math.pow(2.0, 6.0)))
    check('StepB2 tuong thich extern_method+pinvoke+extern_class',
          r_compat3.returncode == 0 and r_compat3.stdout.strip().splitlines()[0] == want_compat3,
          f'exit={r_compat3.returncode} stdout={r_compat3.stdout!r} '
          f'stderr={r_compat3.stderr[:300]!r} want={want_compat3!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'StepB2: build/chay THAT BAI khong mong doi: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Step C: 2 extern-class KHAC NHAU cung khai method TRUNG TEN ('Describe')
# nhung KHAC chu ky (arity/params/returns khac nhau) - bo sung gap coverage
# docs/BUGS_TODO.md muc L. Ca hai deu dung DUOC trong CUNG 1 compile (khoa
# EXPR_METHOD_CODEGEN la ('extern_class', 'Describe') dung dong, resolve
# THEO RECEIVER thuc te tai codegen-time - xem Task 4 report "Central
# finding").
# ---------------------------------------------------------------------------
diffsig_src = '''
__tkv_extern_class__ = [
    {
        "name": "SbD", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [{"name": "Describe", "params": [], "returns": "str"}],
    },
    {
        "name": "ObjD", "assembly": "mscorlib", "class": "System.Object",
        "ctor": [],
        "methods": [{"name": "Describe", "params": ["str"], "returns": "i32"}],
    },
]


def main() -> "i32":
    a = SbD("zzz")
    o = ObjD()
    print(a.Describe())
    print(o.Describe("x"))
    return 0
'''
tmp_diffsig = HERE / '_extern_class_diffsig.tkv'
tmp_diffsig.write_text(diffsig_src, encoding='utf-8')
try:
    exe_diffsig = compile_tkv_cli(str(tmp_diffsig), out_exe=str(HERE / '_extern_class_diffsig.exe'),
                                   entry_name='main')
    check('StepC 2 handle-type method trung ten khac chu ky - build OK', exe_diffsig is not None)
    # Kiem tra IL sinh dung 2 callvirt KHAC chu ky cho CUNG 1 ten method 'Describe'
    # (dispatch theo receiver THUC TE tai codegen-time, khong bi lan giua 2 lop -
    # xac nhan qua noi dung IL thay vi chay THAT vi 2 lop .NET that gia lap trong
    # fixture nay khong THUC SU co method 'Describe' - chi dung de kiem tra
    # HANH VI COMPILER, khong phai hanh vi runtime .NET that).
    il_diffsig = Path(str(exe_diffsig)).with_suffix('.il')
    if il_diffsig.exists():
        il_text = il_diffsig.read_text(encoding='utf-8', errors='replace')
        check('StepC IL callvirt SbD.Describe() dung chu ky',
              'callvirt instance string [mscorlib]System.Text.StringBuilder::Describe()' in il_text,
              il_text[:3000])
        check('StepC IL callvirt ObjD.Describe(string) dung chu ky',
              'callvirt instance int32 [mscorlib]System.Object::Describe(string)' in il_text,
              il_text[:3000])
    else:
        fails.append('StepC: khong tim thay .il de kiem chu ky')
except Exception as e:  # noqa: BLE001
    fails.append(f'StepC: build THAT BAI khong mong doi: {type(e).__name__}: {e}')
finally:
    from il_dispatch import EXPR_METHOD_CODEGEN
    check('StepC finally-pop Describe khong sot lai',
          ('extern_class', 'Describe') not in EXPR_METHOD_CODEGEN)


# ---------------------------------------------------------------------------
# Step D (Step 1-4 cua brief): duck-typing PHAI tu choi handle type lam
# tham so 'inferred' (khong annotation) - handle type khong tham gia co
# che suy kieu qua cach dung (Task 3/4 plan duck-typing-inference).
# ---------------------------------------------------------------------------
duck_src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]

def f(x) -> "str":
    return x.ToString()

def main() -> "i32":
    s = Sb()
    print(f(s))
    return 0
'''
tmp_duck = HERE / '_extern_class_ducktyping_reject.tkv'
tmp_duck.write_text(duck_src, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp_duck), out_exe=str(HERE / '_extern_class_ducktyping_reject.exe'),
                     entry_name='main')
    check('StepD ducktyping_reject_raises', False, 'khong raise - handle type LOT qua duck-typing!')
except TranspileError:
    check('StepD ducktyping_reject_raises', True)
except Exception as e:  # noqa: BLE001
    check('StepD ducktyping_reject_raises', False, f'raise sai loai: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Step E (Task 4, extern-class-property): duck-typing PHAI tu choi property
# cua handle type lam tham so 'inferred' (cung co che voi Step D nhung qua
# 'properties' key thay vi 'methods'), VA obj.Prop += x (compound-assign)
# PHAI hoat dong dung qua try_expand_compound_attr.
# ---------------------------------------------------------------------------
def test_duck_typing_rejects_handle_type_property():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": True}]},
]

def f(x) -> "i32":
    return x.Length

def main() -> "i32":
    s = Sb()
    return f(s)
'''
    tmp = HERE / '_extern_class_prop_ducktyping.tkv'
    tmp.write_text(src, encoding='utf-8')
    try:
        compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_ducktyping.exe'), entry_name='main')
        check('prop_ducktyping_reject_raises', False, 'khong raise - property handle type LOT qua duck-typing!')
    except TranspileError:
        check('prop_ducktyping_reject_raises', True)
    finally:
        tmp.unlink()


def test_compound_assign_on_property():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": ["str"], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": False}]},
]

def main() -> "i32":
    s = Sb("hello")
    s.Length += 1
    print(s.Length)
    return 0
'''
    tmp = HERE / '_extern_class_prop_compound.tkv'
    tmp.write_text(src, encoding='utf-8')
    exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_compound.exe'), entry_name='main')
    r = subprocess.run([str(exe)], capture_output=True, text=True)
    check('compound_returncode', r.returncode == 0, r.stderr)
    check('compound_output', r.stdout.splitlines()[0].strip() == '6', repr(r.stdout))
    tmp.unlink()


test_duck_typing_rejects_handle_type_property()
test_compound_assign_on_property()


# ---------------------------------------------------------------------------
# Step F (5th instance cua bug class - xem docs/BUGS_TODO.md muc O): duck-typing
# PHAI tu choi handle type lam tham so 'inferred' NGAY CA KHI tham so do KHONG
# duoc dung trong than ham (khong co rang buoc nao duoc collect - Task 3's
# collect_inferred_constraints() gan constraints[p.name] = [] cho truong hop
# nay, hop le). Truoc fix, resolve_call_site() chi kiem tra extern-class qua
# _check_constraint() GOI TRONG vong 'for c in constraints.get(p.name, [])' -
# tham so inferred KHONG dung trong body co [] rong nen vong lap khong chay
# lan nao, _check_constraint KHONG BAO GIO duoc goi, handle type lot qua
# resolve_call_site voi shape=None -> KeyError trong il_type_str() luc codegen
# than ham chua loi goi (chu KHONG phai luc goi ham dung tham so do).
# ---------------------------------------------------------------------------
def test_duck_typing_rejects_handle_type_unused_param():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": ["str"], "methods": []},
]

def unused_param(x, y: "i32") -> "i32":
    return y

def main() -> "i32":
    a = Sb("hello")
    return unused_param(a, 5)
'''
    tmp = HERE / '_extern_class_unused_param_ducktyping.tkv'
    tmp.write_text(src, encoding='utf-8')
    try:
        compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_unused_param_ducktyping.exe'),
                         entry_name='main')
        check('unused_param_ducktyping_reject_raises', False,
              'khong raise - handle type KHONG DUNG trong than ham LOT qua duck-typing '
              '(se crash KeyError o il_type_str luc codegen)!')
    except TranspileError:
        check('unused_param_ducktyping_reject_raises', True)
    except Exception as e:  # noqa: BLE001
        check('unused_param_ducktyping_reject_raises', False,
              f'raise sai loai: {type(e).__name__}: {e}')
    finally:
        if tmp.exists():
            tmp.unlink()


test_duck_typing_rejects_handle_type_unused_param()


# ---------------------------------------------------------------------------
# Don dep cac fixture .tkv/.exe/.il TAM sinh ra trong luc test - CHI xoa
# tien to '_extern_class_' TRU 'sample_extern_class.tkv' (file mau vinh vien).
# ---------------------------------------------------------------------------
for _p in HERE.glob('_extern_class_*'):
    try:
        _p.unlink()
    except OSError:
        pass

if fails:
    print('extern_class_test: TRUOT')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('extern_class_test: dat (4 buoc: tich cuc fixture, tuong thich '
      'extern_method+pinvoke, method trung ten khac chu ky tren 2 handle-type, '
      'duck-typing reject)')
sys.exit(0)
