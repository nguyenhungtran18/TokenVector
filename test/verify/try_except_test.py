# -*- coding: utf-8 -*-
"""Kiem chung THAT try/except vua them: chay sample_try_except.tkv THAT
duoi CPython, transpile CUNG file sang .exe (2 ham, dispatch qua mode o
Main), doi chieu - dac biet CHIA CHO 0 (phai vao nhanh except that ca
2 phia, khong crash chuong trinh)."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_try_except.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_safe_div = py_ns['safe_div']
py_try_get_or_fallback = py_ns['try_get_or_fallback']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='TEProgram', extra_classes=_extra_classes)
print(f"Da transpile {source_text.count('def ')} ham tu sample_try_except.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 mode, int32 a, int32 b, int32 c, int32 result)',
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.0',
    '    ldarg.0', '    ldc.i4.1', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.1',
    '    ldarg.0', '    ldc.i4.2', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.2',
    '    ldarg.0', '    ldc.i4.3', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.3',
    '    ldloc.0', '    ldc.i4.0', '    beq mode0',
    '    br mode1',
    '  mode0:',
    '    ldloc.1', '    ldloc.2',
    '    call int32 TEProgram::safe_div(int32, int32)',
    '    stloc.s 4',
    '    br done',
    '  mode1:',
    '    ldloc.1', '    ldloc.2', '    ldloc.3',
    '    call int32 TEProgram::try_get_or_fallback(int32, int32, int32)',
    '    stloc.s 4',
    '  done:',
    '    ldloca.s 4',
    '    call instance string [mscorlib]System.Int32::ToString()',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly TEProgram {}\n.module TEProgram.exe\n\n'
    '.class public auto ansi TEProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_try_except.il'
exe_path = HERE / 'sample_try_except.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

cases = [
    # (mode, a, b, c, py_call)
    (0, 10, 2, 0, lambda: py_safe_div(10, 2)),
    (0, 9, 3, 0, lambda: py_safe_div(9, 3)),
    (0, 0, 5, 0, lambda: py_safe_div(0, 5)),
    (0, 100, 10, 0, lambda: py_safe_div(100, 10)),
    (0, 7, 0, 0, lambda: py_safe_div(7, 0)),      # chia cho 0 -> except -> -1
    (0, -9, 0, 0, lambda: py_safe_div(-9, 0)),    # chia cho 0 -> except -> -1
    (1, 10, 2, -1, lambda: py_try_get_or_fallback(10, 2, -1)),
    (1, 9, 3, -1, lambda: py_try_get_or_fallback(9, 3, -1)),
    (1, 7, 0, 42, lambda: py_try_get_or_fallback(7, 0, 42)),   # chia cho 0 -> except -> fallback
    (1, 0, 0, 99, lambda: py_try_get_or_fallback(0, 0, 99)),   # chia cho 0 -> except -> fallback
]

mismatches = []
for mode, a, b, c, py_call in cases:
    expected = int(py_call())
    r = subprocess.run([str(exe_path), str(mode), str(a), str(b), str(c)],
                        capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((mode, a, b, c, expected, None, r.stdout, r.stderr))
        continue
    got = int(r.stdout.strip())
    if got != expected:
        mismatches.append((mode, a, b, c, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {len(cases)}")
print(f"Khop (exe == CPython that): {len(cases) - len(mismatches)}/{len(cases)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("TRY/EXCEPT SUPPORT: PASS - try/except (return trong/ngoai khoi) bien dich THAT va dung 100%.")
