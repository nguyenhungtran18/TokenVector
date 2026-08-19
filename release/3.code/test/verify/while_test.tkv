# -*- coding: utf-8 -*-
"""Kiem chung THAT 'while' vua them vao il_codegen.py: chay sample_while.tkv
THAT duoi CPython, transpile CUNG file sang .exe, doi chieu."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_while.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_factorial, py_count_down_sum = py_ns['factorial'], py_ns['count_down_sum']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='WhileProgram', extra_classes=_extra_classes)
print("Da transpile 2 ham (factorial/count_down_sum) tu sample_while.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 n, int32 r)',
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.0',
    '    ldloc.0',
    '    call int32 WhileProgram::factorial(int32)',
    '    call void [mscorlib]System.Console::WriteLine(int32)',
    '    ldloc.0',
    '    call int32 WhileProgram::count_down_sum(int32)',
    '    call void [mscorlib]System.Console::WriteLine(int32)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly WhileProgram {}\n.module WhileProgram.exe\n\n'
    '.class public auto ansi WhileProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_while.il'
exe_path = HERE / 'sample_while.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

mismatches = []
for n in [0, 1, 5, 8, 12]:
    expected = [py_factorial(n), py_count_down_sum(n)]
    r = subprocess.run([str(exe_path), str(n)], capture_output=True, text=True)
    got = [int(x) for x in r.stdout.strip().split('\n')]
    if got != expected:
        mismatches.append((n, expected, got, r.stderr))

print(f"So mau doi chieu: 5")
print(f"Khop (exe == CPython that): {5 - len(mismatches)}/5")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("WHILE SUPPORT: PASS - vong lap while bien dich THAT va dung 100%.")
