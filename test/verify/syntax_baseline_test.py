# -*- coding: utf-8 -*-
"""Test cho compiler/syntax_baseline.py - doi chieu voi bao cao dieu tra
Task 1 (docs/superpowers/plans/2026-08-17-syntax-baseline-linter.md)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from compiler.syntax_baseline import check_syntax_baseline

passed = 0
failed = 0


def check(desc, cond):
    global passed, failed
    if cond:
        passed += 1
    else:
        failed += 1
        print(f"  FAIL: {desc}")


def only(findings, name_substr):
    """Loc cac finding co construct_name chua name_substr (khong phan
    biet hoa/thuong)."""
    return [f for f in findings if name_substr.lower() in f.construct_name.lower()]


# ---------------------------------------------------------------------
# Case 1: list comprehension - KHONG ho tro (khung suon TDD, Step 1)
# ---------------------------------------------------------------------
src_listcomp = '''
def run() -> None:
    xs = [x for x in range(10) if x > 5 if x < 8]
'''
findings = check_syntax_baseline(src_listcomp)
check("list comprehension (2 filter if) bi bao loi", len(findings) >= 1)
if findings:
    check("bao dung dong (dong 3)", findings[0].line == 3)
    check("ten construct dung", 'comprehension' in findings[0].construct_name.lower())
    check("co goi y thay the", findings[0].suggestion is not None)

# doi chung (Task 4, commit 44f4d46): shape HEP van hop le - 1 generator
# DUY NHAT, khong filter, target la 1 ten don - KHONG bi flag.
findings = check_syntax_baseline('''
def run() -> None:
    xs = [x for x in range(10)]
''')
check("list comprehension shape hep (khong filter) KHONG bi bao loi",
      len(only(findings, 'list comprehension')) == 0)

# ---------------------------------------------------------------------
# Step 5: bo sung 1 test case cho MOI construct "khong ho tro" trong bao
# cao Task 1 (danh sach "XAC NHAN KHONG ho tro" + cac hang "Khong" khac
# trong Bang 1-4).
# ---------------------------------------------------------------------

# dict comprehension (2 filter if - van khong ho tro, comprehension.py
# CHI cho toi da 1 'if')
findings = check_syntax_baseline('''
def run() -> None:
    d = {x: x for x in range(10) if x > 5 if x < 8}
''')
check("dict comprehension (2 filter if) bi bao loi", len(only(findings, 'dict comprehension')) >= 1)

# dict comprehension doi chung (Task 4): shape hep hop le - KHONG bi flag
findings = check_syntax_baseline('''
def run() -> None:
    d = {x: x for x in range(10)}
''')
check("dict comprehension shape hep KHONG bi bao loi", len(only(findings, 'dict comprehension')) == 0)

# set comprehension (2 filter if - van khong ho tro)
findings = check_syntax_baseline('''
def run() -> None:
    s = {x for x in range(10) if x > 5 if x < 8}
''')
check("set comprehension (2 filter if) bi bao loi", len(only(findings, 'set comprehension')) >= 1)

# set comprehension doi chung (Task 4): shape hep hop le - KHONG bi flag
findings = check_syntax_baseline('''
def run() -> None:
    s = {x for x in range(10)}
''')
check("set comprehension shape hep KHONG bi bao loi", len(only(findings, 'set comprehension')) == 0)

# generator expression
findings = check_syntax_baseline('''
def run() -> None:
    g = sum(x for x in range(10))
''')
check("generator expression bi bao loi", len(only(findings, 'generator expression')) >= 1)

# f-string voi bieu thuc phuc tap ben trong placeholder ({x+1}) - van
# khong ho tro (macro fstring.py chi nhan 1 IDENT tran).
findings = check_syntax_baseline('''
def run() -> None:
    x = 1
    s = f"gia tri {x+1}"
''')
check("f-string voi bieu thuc phuc tap bi bao loi", len(only(findings, 'f-string')) >= 1)

# f-string doi chung (Task 4): placeholder don ({x}) hop le - KHONG bi flag
findings = check_syntax_baseline('''
def run() -> None:
    x = 1
    s = f"gia tri {x}"
''')
check("f-string placeholder don KHONG bi bao loi", len(only(findings, 'f-string')) == 0)

# walrus operator
findings = check_syntax_baseline('''
def run() -> None:
    if (n := 10) > 5:
        return
''')
check("walrus operator bi bao loi", len(only(findings, 'walrus')) >= 1)

# match/case
findings = check_syntax_baseline('''
def run(x: "i32") -> None:
    match x:
        case 1:
            return
        case _:
            return
''')
check("match/case bi bao loi", len(only(findings, 'match')) >= 1)

# gan da muc tieu a = b = c
findings = check_syntax_baseline('''
def run() -> None:
    a = b = 1
''')
check("gan da muc tieu bi bao loi", len(only(findings, 'multiple-target')) >= 1)

# augmented assign khong ho tro: //=
findings = check_syntax_baseline('''
def run() -> None:
    x = 10
    x //= 2
''')
check("//= bi bao loi", len(only(findings, 'augmented assign')) >= 1)

# augmented assign khong ho tro: **=
findings = check_syntax_baseline('''
def run() -> None:
    x = 10
    x **= 2
''')
check("**= bi bao loi", len(only(findings, 'augmented assign')) >= 1)

# augmented assign khong ho tro: &=, |=, ^=, <<=, >>=
for op_src, op_name in [
    ('x &= 1', '&='), ('x |= 1', '|='), ('x ^= 1', '^='),
    ('x <<= 1', '<<='), ('x >>= 1', '>>='),
]:
    findings = check_syntax_baseline(f'''
def run() -> None:
    x = 10
    {op_src}
''')
    check(f"{op_name} bi bao loi", len(only(findings, 'augmented assign')) >= 1)

# augmented assign HO TRO (khong duoc bao loi): +=, -=, *=, /=, %=
for op_src in ['x += 1', 'x -= 1', 'x *= 1', 'x /= 1', 'x %= 1']:
    findings = check_syntax_baseline(f'''
def run() -> None:
    x = 10
    {op_src}
''')
    check(f"'{op_src}' KHONG bi bao loi (ho tro)", len(only(findings, 'augmented assign')) == 0)

# decorator xep chong tren ham top-level
findings = check_syntax_baseline('''
def deco1(f):
    def wrapper(*a):
        return f(*a)
    return wrapper


def deco2(f):
    def wrapper(*a):
        return f(*a)
    return wrapper


@deco1
@deco2
def run() -> None:
    return
''')
check("decorator xep chong bi bao loi", len(only(findings, 'decorator')) >= 1)

# decorator co tham so tren ham top-level
findings = check_syntax_baseline('''
def deco(x):
    def wrap(f):
        return f
    return wrap


@deco(1)
def run() -> None:
    return
''')
check("decorator co tham so bi bao loi", len(only(findings, 'decorator')) >= 1)

# decorator DON tren ham top-level - HO TRO, khong bao loi
findings = check_syntax_baseline('''
def deco(f):
    def wrapper(*a):
        return f(*a)
    return wrapper


@deco
def run() -> None:
    return
''')
check("decorator don KHONG bi bao loi (ho tro)", len(only(findings, 'decorator')) == 0)

# decorator khac @staticmethod/@property tren method trong class (vd @classmethod)
findings = check_syntax_baseline('''
class Foo:
    x: "i32"

    @classmethod
    def make(cls) -> "i32":
        return 1
''')
check("@classmethod tren method bi bao loi", len(only(findings, 'decorator')) >= 1)

# @staticmethod + @property cung luc
findings = check_syntax_baseline('''
class Foo:
    x: "i32"

    @staticmethod
    @property
    def bad() -> "i32":
        return 1
''')
check("@staticmethod+@property cung luc bi bao loi", len(only(findings, 'decorator')) >= 1)

# @staticmethod DON tren method - HO TRO
findings = check_syntax_baseline('''
class Foo:
    x: "i32"

    @staticmethod
    def make() -> "i32":
        return 1
''')
check("@staticmethod don KHONG bi bao loi", len(only(findings, 'decorator')) == 0)

# @property DON tren method - HO TRO
findings = check_syntax_baseline('''
class Foo:
    x: "i32"

    @property
    def val(self) -> "i32":
        return self.x
''')
check("@property don KHONG bi bao loi", len(only(findings, 'decorator')) == 0)

# ternary Python chuan a if cond else b
findings = check_syntax_baseline('''
def run(x: "i32") -> "i32":
    return 1 if x > 0 else 0
''')
check("ternary Python chuan bi bao loi", len(only(findings, 'ternary')) >= 1)

# nested attribute obj.a.b (2+ tang)
findings = check_syntax_baseline('''
def run(obj) -> None:
    y = obj.a.b
''')
check("nested attribute (2 tang) bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# attribute 1 tang - HO TRO
findings = check_syntax_baseline('''
def run(obj) -> None:
    y = obj.a
''')
check("attribute 1 tang KHONG bi bao loi", len(only(findings, 'nested attribute')) == 0)

# dict literal co noi dung
findings = check_syntax_baseline('''
def run() -> None:
    d = {"a": 1}
''')
check("dict literal co noi dung bi bao loi", len(only(findings, 'dict literal')) >= 1)

# dict literal RONG - HO TRO
findings = check_syntax_baseline('''
def run() -> None:
    d = {}
''')
check("dict literal rong KHONG bi bao loi", len(only(findings, 'dict literal')) == 0)

# set literal co noi dung
findings = check_syntax_baseline('''
def run() -> None:
    s = {1, 2, 3}
''')
check("set literal co noi dung bi bao loi", len(only(findings, 'set literal')) >= 1)

# slice co buoc nhay x[a:b:c]
findings = check_syntax_baseline('''
def run(xs) -> None:
    y = xs[0:5:2]
''')
check("slice co buoc nhay bi bao loi", len(only(findings, 'slice')) >= 1)

# slice khong buoc nhay - HO TRO
findings = check_syntax_baseline('''
def run(xs) -> None:
    y = xs[0:5]
''')
check("slice khong buoc nhay KHONG bi bao loi", len(only(findings, 'slice')) == 0)

# for a, b in items (khong phai .items())
findings = check_syntax_baseline('''
def run(pairs) -> None:
    for a, b in pairs:
        return
''')
check("for a,b in pairs (khong .items()) bi bao loi", len(only(findings, 'tuple-unpack')) >= 1)

# for k, v in d.items(): - HO TRO (ngoai le)
findings = check_syntax_baseline('''
def run(d) -> None:
    for k, v in d.items():
        return
''')
check("for k,v in d.items() KHONG bi bao loi", len(only(findings, 'tuple-unpack')) == 0)

# with a, b: (nhieu context manager)
findings = check_syntax_baseline('''
def run() -> None:
    with open("a", "r") as a, open("b", "r") as b:
        return
''')
check("with nhieu context manager bi bao loi", len(only(findings, 'with')) >= 1)

# with 1 context manager - HO TRO
findings = check_syntax_baseline('''
def run() -> None:
    with open("a", "r") as a:
        return
''')
check("with 1 context manager KHONG bi bao loi", len(only(findings, 'with')) == 0)

# so dang mu 1e10
findings = check_syntax_baseline('''
def run() -> None:
    x = 1e10
''')
check("so dang mu 1e10 bi bao loi", len(only(findings, 'so dac biet')) >= 1
      or len(only(findings, 'special number')) >= 1)

# so dang hex 0x1F
findings = check_syntax_baseline('''
def run() -> None:
    x = 0x1F
''')
check("so dang hex 0x1F bi bao loi", len(only(findings, 'so dac biet')) >= 1
      or len(only(findings, 'special number')) >= 1)

# so co underscore-separator 1_000
findings = check_syntax_baseline('''
def run() -> None:
    x = 1_000
''')
check("so co underscore 1_000 bi bao loi", len(only(findings, 'so dac biet')) >= 1
      or len(only(findings, 'special number')) >= 1)

# so thuong - HO TRO
findings = check_syntax_baseline('''
def run() -> None:
    x = 1000
    y = 3.14
''')
check("so thuong KHONG bi bao loi", (len(only(findings, 'so dac biet')) +
      len(only(findings, 'special number'))) == 0)

# *args/**kwargs trong loi goi ham (Starred)
findings = check_syntax_baseline('''
def run(xs) -> None:
    print(*xs)
''')
check("*xs trong loi goi ham bi bao loi", len(only(findings, 'starred')) >= 1)

# a, *rest = xs (Starred trong unpack gan)
findings = check_syntax_baseline('''
def run(xs) -> None:
    a, *rest = xs
''')
check("a,*rest = xs bi bao loi", len(only(findings, 'starred')) >= 1)

# nested class (class trong class)
findings = check_syntax_baseline('''
class Outer:
    x: "i32"

    class Inner:
        y: "i32"
''')
check("nested class bi bao loi", len(only(findings, 'nested class')) >= 1)

# *args/**kwargs trong CHU KY method trong class - KHONG ho tro (khac ham top-level)
findings = check_syntax_baseline('''
class Foo:
    x: "i32"

    def bad(self, *args) -> "i32":
        return 1
''')
check("*args trong chu ky method bi bao loi", len(only(findings, 'vararg')) >= 1)

# *args/**kwargs trong CHU KY ham top-level - HO TRO (allow_varargs=True)
findings = check_syntax_baseline('''
def run(a: "i32", *args: "i32") -> "i32":
    return a
''')
check("*args trong chu ky ham top-level KHONG bi bao loi", len(only(findings, 'vararg')) == 0)

# keyword-only args - KHONG ho tro (bat ky dau)
findings = check_syntax_baseline('''
def run(a: "i32", *, b: "i32") -> "i32":
    return a
''')
check("keyword-only arg bi bao loi", len(only(findings, 'keyword-only')) >= 1)

# ---------------------------------------------------------------------
# Finding 1 (review): lambda truyen INLINE vao map/filter/reduce/sort(key=)
# ---------------------------------------------------------------------

# map(lambda x: x*2, xs) - lambda inline KHONG ho tro
findings = check_syntax_baseline('''
def run(xs) -> None:
    ys = map(lambda x: x * 2, xs)
''')
check("map(lambda...) bi bao loi", len(only(findings, 'lambda')) >= 1)

# xs.sort(key=lambda x: x) - lambda inline trong sort(key=) KHONG ho tro
findings = check_syntax_baseline('''
def run(xs) -> None:
    xs.sort(key=lambda x: x)
''')
check("xs.sort(key=lambda...) bi bao loi", len(only(findings, 'lambda')) >= 1)

# duong vong HOP LE: gan lambda vao bien kieu func(...)->... TRUOC, roi
# truyen TEN bien do vao map() - KHONG bi flag boi rule lambda-inline nay.
findings = check_syntax_baseline('''
def run(xs) -> None:
    g: "func(i32)->i32" = lambda x: x * 2
    ys = map(g, xs)
''')
check("map(g, xs) voi g=lambda gan truoc KHONG bi bao loi",
      len(only(findings, 'lambda')) == 0)

# ---------------------------------------------------------------------
# Finding 2 (review): ngu canh TOP-LEVEL (ngoai ham/class) - construct
# chi hop le BEN TRONG than ham thi bi flag khi dung truc tiep o top-level.
# ---------------------------------------------------------------------

# for ... o top-level (khong nam trong def)
findings = check_syntax_baseline('''
for i in range(10):
    print(i)
''')
check("for o top-level bi bao loi", len(findings) >= 1)

# if ... o top-level
findings = check_syntax_baseline('''
if True:
    x = 1
''')
check("if o top-level bi bao loi", len(findings) >= 1)

# while ... o top-level
findings = check_syntax_baseline('''
while True:
    break
''')
check("while o top-level bi bao loi", len(findings) >= 1)

# goi ham doc lap o top-level (khong phai docstring)
findings = check_syntax_baseline('''
print(1)
''')
check("goi ham doc lap o top-level bi bao loi", len(findings) >= 1)

# AnnAssign voi dtype container o top-level
findings = check_syntax_baseline('''
x: "list[i32]" = [1, 2, 3]
''')
check("AnnAssign dtype container o top-level bi bao loi", len(findings) >= 1)

# doi chung: cac construct nay VAN duoc phep khi nam BEN TRONG than ham
# (khong bi Finding 2's context check chan nham)
findings = check_syntax_baseline('''
def run() -> None:
    for i in range(10):
        if i > 5:
            print(i)
        while False:
            break
''')
check("for/if/while/print BEN TRONG than ham KHONG bi bao loi", len(findings) == 0)

# doi chung: docstring o top-level (Expr voi Constant str) KHONG bi flag
findings = check_syntax_baseline('''
"""Day la docstring module."""


def run() -> None:
    return
''')
check("docstring top-level KHONG bi bao loi", len(findings) == 0)

# ---------------------------------------------------------------------
# Finding 3 (review): nested attribute 3+ tang chi sinh 1 finding duy nhat
# ---------------------------------------------------------------------
findings = check_syntax_baseline('''
def run(obj) -> None:
    y = obj.a.b.c
''')
nested = only(findings, 'nested attribute')
check("obj.a.b.c (3 tang) chi sinh DUNG 1 finding", len(nested) == 1)

# ---------------------------------------------------------------------
# Step 6: test tich cuc - file .tkv hop le co san trong repo, khong bi
# false-positive.
# ---------------------------------------------------------------------
sample_path = Path(__file__).resolve().parents[2] / 'test' / 'sample_extern_method.tkv'
src_valid = sample_path.read_text(encoding='utf-8')
findings_valid = check_syntax_baseline(src_valid)
check(f"file hop le khong bi bao loi (file: {sample_path.name})", len(findings_valid) == 0)
if findings_valid:
    for f in findings_valid:
        print(f"  false-positive: dong {f.line}: {f.construct_name}")

sample_path2 = Path(__file__).resolve().parents[2] / 'test' / 'sample_multi_inherit.tkv'
src_valid2 = sample_path2.read_text(encoding='utf-8')
findings_valid2 = check_syntax_baseline(src_valid2)
check(f"file hop le khong bi bao loi (file: {sample_path2.name})", len(findings_valid2) == 0)
if findings_valid2:
    for f in findings_valid2:
        print(f"  false-positive: dong {f.line}: {f.construct_name}")

# ---------------------------------------------------------------------
# Critical-2 (review sau Task 4, 2026-08-17): 6 bien the false-negative
# xac nhan qua compile THAT (`tkv.py build --no-lint`) - linter im lang
# nhung compiler THAT tu choi. Moi finding: 1 case PHAI bi flag + 1 case
# doi chung shape hep van KHONG bi flag (khong regression nguoc).
# ---------------------------------------------------------------------

# --- finding 1: nested attribute trong header block (if/while/with/except) ---

# if b.items.count("x") > 0: - attribute chain 2-tang trong 'test' cua if
findings = check_syntax_baseline('''
def run(b) -> None:
    if b.items.count("x") > 0:
        return
''')
check("nested attribute trong header 'if' bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# doi chung: CUNG shape (2-tang lam doi tuong nhan cua method call) nhung
# KHONG nam trong header block - van duoc mien tru nhu Task 4.
findings = check_syntax_baseline('''
def run(b) -> None:
    n = b.items.count("x")
''')
check("nested attribute NGOAI header (than ham) KHONG bi bao loi",
      len(only(findings, 'nested attribute')) == 0)

# while b.items.count("x") > 0:
findings = check_syntax_baseline('''
def run(b) -> None:
    while b.items.count("x") > 0:
        break
''')
check("nested attribute trong header 'while' bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# with b.items.count("x") as n: (context_expr la attribute chain)
findings = check_syntax_baseline('''
def run(b) -> None:
    with b.items.open("x") as n:
        return
''')
check("nested attribute trong header 'with' bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# except b.items.err: (type cua handler la attribute chain)
findings = check_syntax_baseline('''
def run(b) -> None:
    try:
        return
    except b.items.err:
        return
''')
check("nested attribute trong header 'except' bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# field 'shape' (b.a.shape[0]) - KHONG duoc mien tru du dung lam chi so
# (expr_hoist.py's _NO_HOIST_FIELDS = ('shape',))
findings = check_syntax_baseline('''
def run(b) -> None:
    n = b.a.shape[0]
''')
check("b.a.shape[0] (field 'shape') VAN bi bao loi", len(only(findings, 'nested attribute')) >= 1)

# --- finding 2: comprehension nhieu dong (multiline) ---

findings = check_syntax_baseline('''
def run(xs) -> None:
    ys = [
        x * 2 for x in xs
    ]
''')
check("list comprehension NHIEU DONG bi bao loi", len(only(findings, 'list comprehension')) >= 1)

# doi chung: CUNG shape nhung tren 1 dong duy nhat - van duoc mien tru.
findings = check_syntax_baseline('''
def run(xs) -> None:
    ys = [x * 2 for x in xs]
''')
check("list comprehension 1 DONG KHONG bi bao loi", len(only(findings, 'list comprehension')) == 0)

# --- finding 3: zip()/enumerate() sai so luong target ---

# for x, y in zip(a): - 1 list nhung 2 target
findings = check_syntax_baseline('''
def run(a) -> None:
    for x, y in zip(a):
        return
''')
check("for x,y in zip(a) (1 list/2 target) bi bao loi", len(only(findings, 'tuple-unpack')) >= 1)

# for x, y, z in zip(a, b): - 2 list nhung 3 target
findings = check_syntax_baseline('''
def run(a, b) -> None:
    for x, y, z in zip(a, b):
        return
''')
check("for x,y,z in zip(a,b) (2 list/3 target) bi bao loi", len(only(findings, 'tuple-unpack')) >= 1)

# doi chung: zip() dung so luong (2 list, 2 target) - van duoc mien tru.
findings = check_syntax_baseline('''
def run(a, b) -> None:
    for x, y in zip(a, b):
        return
''')
check("for x,y in zip(a,b) (dung so luong) KHONG bi bao loi", len(only(findings, 'tuple-unpack')) == 0)

# for i, x, y in enumerate(a): - 3 target cho enumerate (chi ho tro 2)
findings = check_syntax_baseline('''
def run(a) -> None:
    for i, x, y in enumerate(a):
        return
''')
check("for i,x,y in enumerate(a) (3 target) bi bao loi", len(only(findings, 'tuple-unpack')) >= 1)

# doi chung: enumerate() dung 2 target - van duoc mien tru.
findings = check_syntax_baseline('''
def run(a) -> None:
    for i, x in enumerate(a):
        return
''')
check("for i,x in enumerate(a) (2 target) KHONG bi bao loi", len(only(findings, 'tuple-unpack')) == 0)

# --- finding 4: f-string nhay don (f'...') ---

findings = check_syntax_baseline('''
def run() -> None:
    n = 1
    s = f'gia tri {n}'
''')
check("f-string nhay DON bi bao loi", len(only(findings, 'f-string')) >= 1)

# doi chung: f-string nhay KEP (shape hep hop le) - van duoc mien tru.
findings = check_syntax_baseline('''
def run() -> None:
    n = 1
    s = f"gia tri {n}"
''')
check("f-string nhay KEP KHONG bi bao loi", len(only(findings, 'f-string')) == 0)

print(f"syntax_baseline_test: {'dat' if failed == 0 else 'THAT BAI'} ({passed}/{passed+failed})")
sys.exit(0 if failed == 0 else 1)
