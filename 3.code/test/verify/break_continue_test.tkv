# -*- coding: utf-8 -*-
"""Kiem chung THAT break/continue vua them: chay sample_break_continue.tkv
THAT duoi CPython, transpile CUNG file sang .exe (4 ham, dispatch qua
mode o Main), doi chieu."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_break_continue.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_first_square_over = py_ns['first_square_over']
py_sum_odds = py_ns['sum_odds']
py_first_square_over_while = py_ns['first_square_over_while']
py_sum_while_odds = py_ns['sum_while_odds']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='BCProgram', extra_classes=_extra_classes)
print(f"Da transpile {source_text.count('def ')} ham tu sample_break_continue.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 mode, int32 n, int32 arg2, int32 result)',
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.0',
    '    ldarg.0', '    ldc.i4.1', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.1',
    '    ldarg.0', '    ldc.i4.2', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.2',
    '    ldloc.0', '    ldc.i4.0', '    beq mode0',
    '    ldloc.0', '    ldc.i4.1', '    beq mode1',
    '    ldloc.0', '    ldc.i4.2', '    beq mode2',
    '    br mode3',
    '  mode0:',
    '    ldloc.1', '    ldloc.2',
    '    call int32 BCProgram::first_square_over(int32, int32)',
    '    stloc.3',
    '    br done',
    '  mode1:',
    '    ldloc.1',
    '    call int32 BCProgram::sum_odds(int32)',
    '    stloc.3',
    '    br done',
    '  mode2:',
    '    ldloc.1', '    ldloc.2',
    '    call int32 BCProgram::first_square_over_while(int32, int32)',
    '    stloc.3',
    '    br done',
    '  mode3:',
    '    ldloc.1',
    '    call int32 BCProgram::sum_while_odds(int32)',
    '    stloc.3',
    '  done:',
    '    ldloca.s 3',
    '    call instance string [mscorlib]System.Int32::ToString()',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly BCProgram {}\n.module BCProgram.exe\n\n'
    '.class public auto ansi BCProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_break_continue.il'
exe_path = HERE / 'sample_break_continue.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

cases = [
    (0, py_first_square_over, [(10, 20), (5, 100), (0, 5), (3, -1)]),
    (1, py_sum_odds, [(10, 0), (1, 0), (0, 0), (7, 0)]),
    (2, py_first_square_over_while, [(10, 20), (5, 100), (0, 5), (3, -1)]),
    (3, py_sum_while_odds, [(10, 0), (1, 0), (0, 0), (7, 0)]),
]

total = 0
mismatches = []
for mode, py_func, arg_pairs in cases:
    for n, arg2 in arg_pairs:
        total += 1
        if mode in (0, 2):
            expected = int(py_func(n, arg2))
        else:
            expected = int(py_func(n))
        r = subprocess.run([str(exe_path), str(mode), str(n), str(arg2)],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((mode, n, arg2, expected, None, r.stdout, r.stderr))
            continue
        got = int(r.stdout.strip())
        if got != expected:
            mismatches.append((mode, n, arg2, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("BREAK/CONTINUE SUPPORT: PASS - break/continue (for+while) bien dich THAT va dung 100%.")
