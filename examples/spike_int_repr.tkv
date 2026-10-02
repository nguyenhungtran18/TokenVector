# -*- coding: utf-8 -*-
"""Spike 2 (2026-08-05): bieu dien 'int' NAO hop voi codegen nay?

Spike 1 (README.md) da chot "duong nhanh phai NOI TUYEN" va thiet ke "moi
bien int giu HAI local: lo(int64) + big(object)". Nhung no KHONG tra loi
cau hoi chan duong buoc 2:

    _compile_expr() day DUNG MOT gia tri len stack. Mot bieu thuc 'int'
    trung gian (vd 'a + b' lam THAM SO cua f(...)) thi mang hai gia tri
    di kieu gi?

Hai kha nang, do o day CUNG MOT PHIEN (khong so so giua cac ngay - nhieu
~30% che khuat khac biet do ma sinh):

  A int64 thuan (add.ovf)            - moc duoi, ngu nghia SAI (tran)
  B hai local song song, noi tuyen   - thiet ke spike 1; chi dung duoc
                                       cho BIEN, khong cho temp tren stack
  C struct TkvInt{int64 lo; object big} - MOT gia tri tren stack, hop voi
                                       _compile_expr; van noi tuyen duoc

Neu C ~ B thi buoc 2 lam duoc ma khong phai viet lai toan bo giao uoc
"mot gia tri tren stack" cua codegen.
"""
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from tokenvector_compile import ILASM  # noqa: E402

HERE = Path(__file__).resolve().parent
ITERS = 10_000_000  # 2 phep cong moi vong = 20 trieu phep cong

HEAD = """\
.assembly extern mscorlib {}
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly %(name)s {}
.module %(name)s.exe
%(types)s
.class public auto ansi %(name)s extends [mscorlib]System.Object
{
  .method public static void Main() cil managed
  {
    .entrypoint
    .maxstack 8
    .locals init (%(locals)s,
                  class [System]System.Diagnostics.Stopwatch sw,
                  int64 n)
    ldc.i8 %(iters)s
    stloc n
    call class [System]System.Diagnostics.Stopwatch [System]System.Diagnostics.Stopwatch::StartNew()
    stloc sw
%(body)s
    ldloc sw
    callvirt instance void [System]System.Diagnostics.Stopwatch::Stop()
    ldstr "{0} ms  acc={1}"
    ldloc sw
    callvirt instance int64 [System]System.Diagnostics.Stopwatch::get_ElapsedMilliseconds()
    box [mscorlib]System.Int64
%(show_acc)s
    call void [mscorlib]System.Console::WriteLine(string, object, object)
    ret
  }
}
"""

# ---------------------------------------------------------------- A: int64
A_LOCALS = "int64 acc, int64 i"
A_BODY = """\
    ldc.i8 0
    stloc acc
    ldc.i8 1
    stloc i
  LOOP:
    ldloc i
    ldloc n
    bgt.s ENDLOOP
    ldloc acc
    ldloc i
    add.ovf
    stloc acc
    ldloc i
    ldc.i8 1
    add.ovf
    stloc i
    br.s LOOP
  ENDLOOP:
"""
A_SHOW = "    ldloc acc\n    box [mscorlib]System.Int64\n"

# ------------------------------------------- B: hai local song song, inline
B_LOCALS = ("int64 acc_lo, object acc_big, int64 i_lo, object i_big, "
            "int64 r")


def _b_add(dst_lo, dst_big, a_lo, a_big, b_lo, b_big, tag):
    """acc = a + b, duong nhanh NOI TUYEN tren hai local song song."""
    return f"""\
    ldloc {a_big}
    brtrue SLOW_{tag}
    ldloc {b_big}
    brtrue SLOW_{tag}
    ldloc {a_lo}
    ldloc {b_lo}
    add
    stloc r
    ldloc {a_lo}
    ldloc r
    xor
    ldloc {b_lo}
    ldloc r
    xor
    and
    ldc.i8 0
    blt SLOW_{tag}
    ldloc r
    stloc {dst_lo}
    ldnull
    stloc {dst_big}
    br DONE_{tag}
  SLOW_{tag}:
    ldloc {a_lo}
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Implicit(int64)
    ldloc {b_lo}
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Implicit(int64)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Addition(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    box [System.Numerics]System.Numerics.BigInteger
    stloc {dst_big}
    ldc.i8 0
    stloc {dst_lo}
  DONE_{tag}:
"""


B_BODY = ("""\
    ldc.i8 0
    stloc acc_lo
    ldnull
    stloc acc_big
    ldc.i8 1
    stloc i_lo
    ldnull
    stloc i_big
    ldc.i8 1
    stloc r
  LOOP:
    ldloc i_lo
    ldloc n
    bgt ENDLOOP
"""
          + _b_add('acc_lo', 'acc_big', 'acc_lo', 'acc_big', 'i_lo', 'i_big', 'A')
          + """\
    ldloc i_lo
    ldc.i8 1
    add
    stloc r
    ldloc i_lo
    ldloc r
    xor
    ldc.i8 1
    ldloc r
    xor
    and
    ldc.i8 0
    blt SLOW_B
    ldloc r
    stloc i_lo
    br DONE_B
  SLOW_B:
    ldloc i_lo
    stloc i_lo
  DONE_B:
    br LOOP
  ENDLOOP:
""")
B_SHOW = "    ldloc acc_lo\n    box [mscorlib]System.Int64\n"

# ------------------------------------------------- C: struct, MOT gia tri
C_TYPES = """\
.class public sequential ansi sealed beforefieldinit TkvInt
       extends [mscorlib]System.ValueType
{
  .field public int64 lo
  .field public object big
}
"""
C_LOCALS = ("valuetype TkvInt acc, valuetype TkvInt i, valuetype TkvInt ta, "
            "valuetype TkvInt tb, valuetype TkvInt res, valuetype TkvInt one, "
            "int64 r")


def _c_add(tag):
    """MO PHONG DUNG cach _compile_expr lam viec: hai toan hang da nam
    tren stack duoi dang struct (do compile_expr day len), ket qua cung
    phai la MOT struct tren stack."""
    return f"""\
    stloc tb
    stloc ta
    ldloca ta
    ldfld object TkvInt::big
    brtrue SLOW_{tag}
    ldloca tb
    ldfld object TkvInt::big
    brtrue SLOW_{tag}
    ldloca ta
    ldfld int64 TkvInt::lo
    ldloca tb
    ldfld int64 TkvInt::lo
    add
    stloc r
    ldloca ta
    ldfld int64 TkvInt::lo
    ldloc r
    xor
    ldloca tb
    ldfld int64 TkvInt::lo
    ldloc r
    xor
    and
    ldc.i8 0
    blt SLOW_{tag}
    ldloca res
    ldloc r
    stfld int64 TkvInt::lo
    ldloca res
    ldnull
    stfld object TkvInt::big
    ldloc res
    br DONE_{tag}
  SLOW_{tag}:
    ldloca res
    ldloca ta
    ldfld int64 TkvInt::lo
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Implicit(int64)
    ldloca tb
    ldfld int64 TkvInt::lo
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Implicit(int64)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Addition(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    box [System.Numerics]System.Numerics.BigInteger
    stfld object TkvInt::big
    ldloc res
  DONE_{tag}:
"""


C_BODY = ("""\
    ldloca acc
    initobj TkvInt
    ldloca i
    initobj TkvInt
    ldloca i
    ldc.i8 1
    stfld int64 TkvInt::lo
    ldloca one
    initobj TkvInt
    ldloca one
    ldc.i8 1
    stfld int64 TkvInt::lo
  LOOP:
    ldloca i
    ldfld int64 TkvInt::lo
    ldloc n
    bgt ENDLOOP
    ldloc acc
    ldloc i
"""
          + _c_add('A')
          + """\
    stloc acc
    ldloc i
    ldloc one
"""
          + _c_add('B')
          + """\
    stloc i
    br LOOP
  ENDLOOP:
""")
C_SHOW = ("    ldloca acc\n    ldfld int64 TkvInt::lo\n"
          "    box [mscorlib]System.Int64\n")

VARIANTS = {
    'A_int64': (A_LOCALS, A_BODY, A_SHOW, '', False),
    'B_two_locals': (B_LOCALS, B_BODY, B_SHOW, '', True),
    'C_struct': (C_LOCALS, C_BODY, C_SHOW, C_TYPES, True),
}

NUMERICS = ('.assembly extern System.Numerics { .publickeytoken = '
            '(B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }\n')


def build(name):
    locals_, body, show, types, needs_numerics = VARIANTS[name]
    il = HEAD % {'name': name, 'types': types, 'locals': locals_,
                 'body': body, 'show_acc': show, 'iters': ITERS}
    if needs_numerics:
        il = il.replace('.assembly extern mscorlib {}\n',
                        '.assembly extern mscorlib {}\n' + NUMERICS)
    il_path = HERE / f'{name}.il'
    exe_path = HERE / f'{name}.exe'
    il_path.write_text(il, encoding='utf-8')
    res = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                         capture_output=True, text=True)
    if res.returncode != 0:
        raise SystemExit(f'{name}: ilasm that bai\n{res.stdout}\n{res.stderr}')
    return exe_path


def run(exe, reps=3):
    times = []
    acc = None
    for _ in range(reps):
        out = subprocess.run([str(exe)], capture_output=True, text=True).stdout
        m = re.match(r'(\d+) ms\s+acc=(-?\d+)', out.strip())
        if not m:
            raise SystemExit(f'{exe}: khong doc duoc ket qua: {out!r}')
        times.append(int(m.group(1)))
        acc = int(m.group(2))
    return statistics.median(times), acc


def cpython_baseline():
    t0 = time.perf_counter()
    acc = 0
    i = 1
    while i <= ITERS:
        acc = acc + i
        i = i + 1
    return int((time.perf_counter() - t0) * 1000), acc


def main():
    expected = ITERS * (ITERS + 1) // 2
    py_ms, py_acc = cpython_baseline()
    assert py_acc == expected, (py_acc, expected)
    rows = [('CPython (int vo han)', py_ms, py_acc)]
    for name in VARIANTS:
        rows.append((name, *run(build(name))))
    print(f'\n{ITERS:,} vong, 2 phep cong/vong. Ky vong acc = {expected}\n')
    print(f'{"Cach lam":<24}{"ms":>8}{"so CPython":>13}   ket qua')
    for name, ms, acc in rows:
        ratio = f'{py_ms / ms:.1f}x' if ms else '-'
        ok = 'DUNG' if acc == expected else f'SAI ({acc})'
        print(f'{name:<24}{ms:>8}{ratio:>13}   {ok}')


if __name__ == '__main__':
    main()
