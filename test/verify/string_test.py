# -*- coding: utf-8 -*-
"""Kiem chung THAT ho tro string vua them vao il_codegen.py: chay
sample_program_str.tkv THAT duoi CPython (runpy) de lay ket qua tham
chieu, transpile CUNG file sang .exe, doi chieu tung ham (noi chuoi,
str(so), so sanh chuoi) - phai khop CHU KHONG chi bien dich duoc."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_program_str.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_greet, py_describe_temp, py_is_admin = py_ns['greet'], py_ns['describe_temp'], py_ns['is_admin']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='StrProgram', extra_classes=_extra_classes)
print("Da transpile 3 ham (greet/describe_temp/is_admin) tu sample_program_str.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (string s, float32 c, int32 admin_flag)',
    # greet(args[0])
    '    ldarg.0', '    ldc.i4.0', '    ldelem.ref',
    '    call string StrProgram::greet(string)',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    # describe_temp(parse(args[1]))
    '    ldarg.0', '    ldc.i4.1', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stloc.1',
    '    ldloc.1',
    '    call string StrProgram::describe_temp(float32)',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    # is_admin(args[2])
    '    ldarg.0', '    ldc.i4.2', '    ldelem.ref',
    '    call int32 StrProgram::is_admin(string)',
    '    call void [mscorlib]System.Console::WriteLine(int32)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly StrProgram {}\n.module StrProgram.exe\n\n'
    '.class public auto ansi StrProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_program_str.il'
exe_path = HERE / 'sample_program_str.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

test_cases = [
    ('World', 36.6, 'admin'),
    ('Nguyen', -5.25, 'guest'),
    ('', 0.0, 'Admin'),  # 'Admin' != 'admin' - phan biet hoa thuong
]
mismatches = []
for name, celsius, name2 in test_cases:
    expected = [py_greet(name), py_describe_temp(celsius), str(py_is_admin(name2))]
    r = subprocess.run([str(exe_path), name, repr(float(celsius)), name2],
                        capture_output=True, text=True)
    got = r.stdout.strip().split('\n')
    if got != expected:
        mismatches.append((name, celsius, name2, expected, got, r.stderr))

print(f"So bo test case: {len(test_cases)}")
print(f"Khop (exe == CPython that): {len(test_cases) - len(mismatches)}/{len(test_cases)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("STRING SUPPORT: PASS - noi chuoi/str(so)/so sanh chuoi bien dich THAT va dung 100%.")
