# -*- coding: utf-8 -*-
"""Kiem chung duck-typing qua type-inference tinh (Task 5/5, xem docs/
superpowers/plans/2026-08-17-duck-typing-inference.md + specs/2026-08-17-
duck-typing-inference-design.md). Tai dung NGUYEN VEN cac case da xac nhan
hoat dong THAT qua Task 4 report + task4-critical-fix-report (build+chay
that qua compile_tkv_cli + subprocess, doi chieu ket qua tinh tay - KHONG
mo phong bang CPython vi ngon ngu DSL khong phai Python that; "kich ban
Python thuan tuong duong" duoc tinh tay va ghi ro trong comment tung buoc).

Cau truc theo mau extern_method_test.py (compile_tkv_cli + subprocess +
check() gom fail, khong dung pytest). 10 buoc dung task-5-brief.md:
  1. Field (2 record khac nhau khong ke thua chung, cung field).
  2. Method.
  3. Toan tu - CUNG 1 dinh nghia nguon cho ca scalar VA record co dunder.
  4. Ke thua (field/method o lop cha).
  5. Loi rang buoc (thieu field/method/toan tu).
  6. Gioi han "khong lan truyen" (tham so inferred truyen tiep vao ham khac).
  7. Cache (dem '.method' trong .il, khong sinh trung).
  8. Fixpoint 2 tang (monomorphize long nhau qua 2 vong pending).
  9. Generator goi ham inferred (regression Critical 1 da fix).
  10. Mangle khong dam va (regression Critical 2 da fix).
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli, TranspileError  # noqa: E402

HERE = Path(__file__).parent.parent
SAMPLE = HERE / 'sample_duck_typing.tkv'

fails = []
_tmp_files = []


def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: THAT BAI' + (f' - {detail}' if detail else ''))


def _build_tmp(src_text, name):
    tmp = HERE / f'_dtinfer_{name}.tkv'
    tmp.write_text(src_text, encoding='utf-8')
    exe = HERE / f'_dtinfer_{name}.exe'
    _tmp_files.append(tmp)
    return tmp, exe


def _run(exe):
    r = subprocess.run([str(exe)], capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr


def expect_raise(label, src_text, name, exc_type, must_contain=None):
    tmp, exe = _build_tmp(src_text, name)
    try:
        compile_tkv_cli(str(tmp), str(exe), entry_name='main')
        fails.append(f'{label}: LE RA PHAI RAISE {exc_type.__name__} nhung build THANH CONG')
    except exc_type as e:
        if must_contain and must_contain not in str(e):
            fails.append(f"{label}: raise dung loai nhung THIEU noi dung '{must_contain}' "
                          f'trong message: {e}')
    except Exception as e:  # noqa: BLE001
        fails.append(f'{label}: raise SAI LOAI - duoc {type(e).__name__} ({e}), '
                      f'mong doi {exc_type.__name__}')


# ---------------------------------------------------------------------------
# Step 1-4: file mau sample_duck_typing.tkv gom CA field/method/toan tu/
# ke thua trong 1 main() duy nhat (tai dung dung case da xac nhan trong
# Task 4 report - Point.x cho field, Animal/Dog cho ke thua field+method,
# Vec2.__add__ cho toan tu qua CUNG 1 dinh nghia nguon 'add_them').
#
# Kich ban Python thuan tuong duong (tinh tay):
#   field_sum  = get_x(Point(10,20))          = 10
#   method_sum = Dog(4).speak() (ke thua tu Animal, legs*10) = 40
#   scalar_sum = add_them(3, 4)               = 7
#   vec_sum    = add_them(Vec2(1,2), Vec2(3,4)) qua __add__
#              = (1+3) + (2+4)                = 10
#   total = 10*1000 + 40*100 + 7*10 + 10 = 10000 + 4000 + 70 + 10 = 14080
# ---------------------------------------------------------------------------
exe_main = HERE / '_dtinfer_sample.exe'
try:
    compile_tkv_cli(str(SAMPLE), str(exe_main), entry_name='main')
    rc, out, err = _run(exe_main)
    check('Step1-4 sample_duck_typing.tkv build+chay dung 14080 '
          '(field+method+toan tu+ke thua qua 1 main duy nhat)',
          rc == 0 and out == '14080', f'rc={rc} out={out!r} err={err[:300]!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step1-4: build/chay sample THAT BAI khong mong doi: '
                  f'{type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Step 1 rieng (2 record KHONG ke thua chung, CUNG field 'x'): xac nhan
# CUNG 1 ham nguon monomorphize dung cho CA HAI, gia tri dung tinh tay.
# ---------------------------------------------------------------------------
step1_src = '''
class Point:
    x: "i32"
    y: "i32"
    def __init__(self, x, y):
        self.x = x
        self.y = y

class Coin:
    x: "i32"
    value: "i32"
    def __init__(self, x, value):
        self.x = x
        self.value = value

def get_x(p) -> "i32":
    return p.x

def main() -> "i32":
    a = Point(10, 20)
    b = Coin(7, 99)
    return get_x(a) * 100 + get_x(b)
'''
tmp1, exe1 = _build_tmp(step1_src, 'step1_field')
try:
    compile_tkv_cli(str(tmp1), str(exe1), entry_name='main')
    rc, out, err = _run(exe1)
    check('Step1 field: 2 record khong ke thua chung, cung field.x',
          rc == 0 and out == '1007', f'rc={rc} out={out!r} err={err[:300]!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step1: THAT BAI khong mong doi: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Step 5: loi rang buoc - thieu field / thieu method / thieu toan tu.
# ---------------------------------------------------------------------------
expect_raise(
    'Step5a thieu field', '''
class Box:
    w: "i32"
    h: "i32"
    def __init__(self, w, h):
        self.w = w
        self.h = h

def get_x(p) -> "i32":
    return p.x

def main() -> "i32":
    b = Box(1, 2)
    return get_x(b)
''', 'err_field', TranspileError, must_contain="field '.x'")

expect_raise(
    'Step5b thieu method', '''
class Box:
    w: "i32"
    def __init__(self, w):
        self.w = w

def call_speak(a) -> "i32":
    return a.speak()

def main() -> "i32":
    b = Box(1)
    return call_speak(b)
''', 'err_method', TranspileError, must_contain="method '.speak(")

expect_raise(
    'Step5c thieu toan tu (khong co __add__)', '''
class Box:
    w: "i32"
    def __init__(self, w):
        self.w = w

def add_them(a, b) -> "i32":
    return a + b

def main() -> "i32":
    b1 = Box(1)
    b2 = Box(2)
    return add_them(b1, b2)
''', 'err_operator', TranspileError, must_contain='__add__')

# ---------------------------------------------------------------------------
# Step 6: gioi han "khong lan truyen" - tham so inferred truyen TIEP lam
# argument cho 1 ham khac (kha nang gian tiep, khong phai field/method/
# toan tu truc tiep) -> loi bien dich RO RANG, khong crash noi bo.
# ---------------------------------------------------------------------------
expect_raise(
    'Step6 khong lan truyen (p truyen tiep vao helper())', '''
class Point:
    x: "i32"
    y: "i32"
    def __init__(self, x, y):
        self.x = x
        self.y = y

def helper(q) -> "i32":
    return q.x

def bad(p) -> "i32":
    return helper(p)

def main() -> "i32":
    pt = Point(1, 2)
    return bad(pt)
''', 'no_propagate', TranspileError, must_contain='GIAN TIEP')

# ---------------------------------------------------------------------------
# Step 7: cache - nhieu call-site CUNG 1 kieu cu the -> CHI 1 ban '.method'.
# ---------------------------------------------------------------------------
step7_src = '''
class Point:
    x: "i32"
    y: "i32"
    def __init__(self, x, y):
        self.x = x
        self.y = y

def get_x(p) -> "i32":
    return p.x

def main() -> "i32":
    p1 = Point(10, 20)
    p2 = Point(3, 4)
    p3 = Point(1, 1)
    return get_x(p1) + get_x(p2) + get_x(p3)
'''
tmp7, exe7 = _build_tmp(step7_src, 'step7_cache')
try:
    compile_tkv_cli(str(tmp7), str(exe7), entry_name='main')
    rc, out, err = _run(exe7)
    check('Step7 cache: gia tri dung (10+3+1=14)', rc == 0 and out == '14',
          f'rc={rc} out={out!r} err={err[:300]!r}')
    il7 = (HERE / '_dtinfer_step7_cache.il')
    if il7.exists():
        il_text = il7.read_text(encoding='utf-8', errors='replace')
        decl_count = len(re.findall(
            r"\.method public static int32 'get_x\$T\$Point'", il_text))
        check('Step7 cache: CHI 1 ban khai bao .method get_x$T$Point '
              '(3 call-site cung kieu khong sinh trung)', decl_count == 1,
              f'tim thay {decl_count} ban khai bao')
    else:
        fails.append('Step7: khong tim thay .il de dem .method')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step7: THAT BAI khong mong doi: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Step 8: fixpoint 2 tang - ham khong-inferred goi 1 ham inferred (mid),
# BEN TRONG than mid (SAU KHI mangle thanh mid$T$Point) lai goi 1 ham
# inferred KHAC (leaf) voi 1 bien CUC BO rieng (khong phai tham so 'p' cua
# chinh mid - khong vi pham "khong lan truyen") -> can 2 vong
# pending_monomorphize moi giai quyet het (mid$T$Point o vong 1, roi
# leaf$T$Box moi phat sinh TU BEN TRONG mid$T$Point o vong 2).
# ---------------------------------------------------------------------------
step8_src = '''
class Point:
    x: "i32"
    y: "i32"
    def __init__(self, x, y):
        self.x = x
        self.y = y

class Box:
    x: "i32"
    h: "i32"
    def __init__(self, x, h):
        self.x = x
        self.h = h

def leaf(y) -> "i32":
    return y.x

def mid(p) -> "i32":
    local = Box(9, 1)
    return p.x + leaf(local)

def main() -> "i32":
    pt = Point(5, 6)
    return mid(pt)
'''
tmp8, exe8 = _build_tmp(step8_src, 'step8_fixpoint')
try:
    compile_tkv_cli(str(tmp8), str(exe8), entry_name='main')
    rc, out, err = _run(exe8)
    check('Step8 fixpoint 2 tang: gia tri dung (pt.x=5 + local.x=9 = 14)',
          rc == 0 and out == '14', f'rc={rc} out={out!r} err={err[:300]!r}')
    il8 = (HERE / '_dtinfer_step8_fixpoint.il')
    if il8.exists():
        il_text = il8.read_text(encoding='utf-8', errors='replace')
        check("Step8: sinh dung ban 'mid$T$Point'",
              ".method public static int32 'mid$T$Point'" in il_text)
        check("Step8: sinh dung ban 'leaf$T$Box' (tu VONG 2, phat sinh "
              "TU BEN TRONG mid$T$Point)",
              ".method public static int32 'leaf$T$Box'" in il_text)
    else:
        fails.append('Step8: khong tim thay .il de kiem tra 2 tang')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step8: THAT BAI khong mong doi: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Step 9: generator goi ham inferred (regression Critical 1 - da fix o
# task4-critical-fix-report.md, xac nhan lai o day KHONG bi thut lui).
# ---------------------------------------------------------------------------
step9_src = '''
class Point:
    x: "i32"
    y: "i32"
    def __init__(self, x, y):
        self.x = x
        self.y = y

def get_x(p) -> "i32":
    return p.x

def gen_from_point(p: "Point") -> "list[i32]":
    yield get_x(p)
    yield get_x(p) + 1

def main() -> "i32":
    total = 0
    pt = Point(10, 20)
    for v in gen_from_point(pt):
        total = total + v
    return total
'''
tmp9, exe9 = _build_tmp(step9_src, 'step9_generator')
try:
    compile_tkv_cli(str(tmp9), str(exe9), entry_name='main')
    rc, out, err = _run(exe9)
    check('Step9 generator goi ham inferred: gia tri dung '
          '(get_x(pt)=10 + get_x(pt)+1=11 = 21), khong MissingMethodException',
          rc == 0 and out == '21', f'rc={rc} out={out!r} err={err[:300]!r}')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step9: THAT BAI khong mong doi: {type(e).__name__}: {e}')

# ---------------------------------------------------------------------------
# Step 10: mangle khong dam va ten (regression Critical 2 - da fix, dau
# noi '$' thay vi '_' de (A, B_C) va (A_B, C) KHONG mangle trung ten).
# ---------------------------------------------------------------------------
step10_src = '''
class A:
    v: "i32"
    def __init__(self, v):
        self.v = v

class B_C:
    v: "i32"
    def __init__(self, v):
        self.v = v

class A_B:
    v: "i32"
    def __init__(self, v):
        self.v = v

class C:
    v: "i32"
    def __init__(self, v):
        self.v = v

def f(a, b) -> "i32":
    return a.v * 1000 + b.v

def main() -> "i32":
    r1 = f(A(1), B_C(2))
    r2 = f(A_B(3), C(4))
    return r1 * 1000000 + r2
'''
tmp10, exe10 = _build_tmp(step10_src, 'step10_mangle')
try:
    compile_tkv_cli(str(tmp10), str(exe10), entry_name='main')
    rc, out, err = _run(exe10)
    check('Step10 mangle: gia tri dung (1002*1000000+3004=1002003004), '
          'khong bi de-dup nham giua (A,B_C) va (A_B,C)',
          rc == 0 and out == '1002003004', f'rc={rc} out={out!r} err={err[:300]!r}')
    il10 = (HERE / '_dtinfer_step10_mangle.il')
    if il10.exists():
        il_text = il10.read_text(encoding='utf-8', errors='replace')
        check("Step10: sinh dung 2 ban '.method' RIENG BIET (khong trung ten)",
              ".method public static int32 'f$T$A$B_C'" in il_text and
              ".method public static int32 'f$T$A_B$C'" in il_text)
    else:
        fails.append('Step10: khong tim thay .il de kiem tra mangle')
except Exception as e:  # noqa: BLE001
    fails.append(f'Step10: THAT BAI khong mong doi: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Don dep cac fixture .tkv/.exe/.il/.pdb tam sinh ra trong luc test.
# ---------------------------------------------------------------------------
for _p in HERE.glob('_dtinfer_*'):
    try:
        _p.unlink()
    except OSError:
        pass

if fails:
    print('duck_typing_infer_test: TRUOT')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('duck_typing_infer_test: dat (10 buoc: field, method, toan tu, ke '
      'thua, 3 loi rang buoc, khong-lan-truyen, cache, fixpoint 2 tang, '
      'generator, mangle khong dam va)')
sys.exit(0)
