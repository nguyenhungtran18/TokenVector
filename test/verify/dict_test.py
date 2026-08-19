# -*- coding: utf-8 -*-
"""Kiem chung THAT Dict dong vua them: chay sample_dict.tkv THAT duoi
CPython, transpile CUNG file sang .exe, doi chieu."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_dict.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_sum_via_dict = py_ns['sum_via_dict']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='DictProgram', extra_classes=_extra_classes)
print("Da transpile 1 ham (sum_via_dict) tu sample_dict.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 n, float32 scale, float32 r)',
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call int32 [mscorlib]System.Int32::Parse(string)',
    '    stloc.0',
    '    ldarg.0', '    ldc.i4.1', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, class [mscorlib]System.IFormatProvider)',
    '    stloc.1',
    '    ldloc.0',
    '    ldloc.1',
    '    call float32 DictProgram::sum_via_dict(int32, float32)',
    '    stloc.2',
    '    ldloca.s 2',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call instance string [mscorlib]System.Single::ToString(class [mscorlib]System.IFormatProvider)',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly DictProgram {}\n.module DictProgram.exe\n\n'
    '.class public auto ansi DictProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_dict.il'
exe_path = HERE / 'sample_dict.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

cases = [(0, 1.0), (1, 2.0), (4, 0.5), (7, 1.5)]
mismatches = []
for n, scale in cases:
    expected = float(py_sum_via_dict(n, scale))
    r = subprocess.run([str(exe_path), str(n), str(scale)], capture_output=True, text=True)
    if r.returncode != 0:
        mismatches.append((n, scale, expected, None, r.stdout, r.stderr))
        continue
    got = float(r.stdout.strip())
    if abs(got - expected) > 1e-4:
        mismatches.append((n, scale, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {len(cases)}")
print(f"Khop (exe == CPython that): {len(cases) - len(mismatches)}/{len(cases)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("DICT SUPPORT: PASS - Dict dong ({}, ghi/doc, 'in') bien dich THAT va dung 100%.")
