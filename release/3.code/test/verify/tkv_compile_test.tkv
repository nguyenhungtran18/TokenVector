# -*- coding: utf-8 -*-
"""Kiem chung THAT tkv_compile.py: lay 1 file .tkv THAT (sample_program.tkv,
van la Python hop le - annotation kieu DSL chi la string), chay TRUC TIEP
duoi CPython that (khong gia lap) de lay ket qua tham chieu, roi transpile
CUNG file do sang .exe qua TokenVector, doi chieu SO HOC tren nhieu mau
ngau nhien - phai khop, khong chi "bien dich duoc". Dac biet kiem tra goi
ham CHEO NHAU (sum_of_squares goi square 2 lan, sum_clamped_squares goi ca
sum_of_squares lan clamp) - tinh nang MOI vua them vao il_codegen.py
(gen_il_program/func_table)."""
import runpy
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_program.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

# 1) Chay THAT duoi CPython (chinh file .tkv, khong sua) de lay ham tham chieu.
py_ns = runpy.run_path(str(SRC_PATH))
py_sum_clamped = py_ns['sum_clamped_squares']

# 2) Transpile CUNG file .tkv do sang IL (nhieu ham, goi cheo nhau that).
# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='SampleProgram', extra_classes=_extra_classes)
print(f"Da transpile {source_text.count('def ')} ham tu sample_program.tkv")

# 3) Main() doc 2 float tu argv, goi sum_clamped_squares, in ket qua.
main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (float32 a, float32 b, float32 result)',
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stloc.0',
    '    ldarg.0', '    ldc.i4.1', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stloc.1',
    '    ldloc.0', '    ldloc.1',
    '    call float32 SampleProgram::sum_clamped_squares(float32, float32)',
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
    '.assembly extern mscorlib {}\n.assembly SampleProgram {}\n.module SampleProgram.exe\n\n'
    '.class public auto ansi SampleProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_program.il'
exe_path = HERE / 'sample_program.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

rng = np.random.default_rng(1)
test_pairs = rng.normal(scale=5.0, size=(12, 2)).astype(np.float32)
mismatches = []
for a, b in test_pairs:
    expected = float(py_sum_clamped(float(a), float(b)))
    r = subprocess.run([str(exe_path), repr(float(a)), repr(float(b))],
                        capture_output=True, text=True)
    got = float(r.stdout.strip())
    if abs(got - expected) > 1e-4:
        mismatches.append((float(a), float(b), expected, got, r.stderr))

print(f"So mau doi chieu: {len(test_pairs)}")
print(f"Khop (exe == CPython that): {len(test_pairs) - len(mismatches)}/{len(test_pairs)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("TKV-COMPILE: PASS - file .tkv THAT (chay duoc duoi CPython) "
      "bien dich thang qua TokenVector, goi ham cheo nhau dung 100%.")
