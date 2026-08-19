# -*- coding: utf-8 -*-
"""Kiem chung THAT 'for k, v in d.items():' vua them (enumerator CIL that -
GetEnumerator/MoveNext/Current/Key/Value, khong phai text-macro nhu list
vi Dictionary khong co chi so vi tri) - gom ca truong hop LONG NHAU."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_for_in_dict.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_sum_dict_items = py_ns['sum_dict_items']
py_sum_nested = py_ns['sum_nested_dict_items']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='ForInDictProgram', extra_classes=_extra_classes)
print(f"Da transpile {source_text.count('def ')} ham tu sample_for_in_dict.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 mode, int32 n, int32 m, float32 scale, float32 r)',
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
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stloc.3',
    '    ldloc.0', '    ldc.i4.0', '    beq mode0',
    '    br mode1',
    '  mode0:',
    '    ldloc.1', '    ldloc.3',
    '    call float32 ForInDictProgram::sum_dict_items(int32, float32)',
    '    stloc.s 4',
    '    br done',
    '  mode1:',
    '    ldloc.1', '    ldloc.2',
    '    call float32 ForInDictProgram::sum_nested_dict_items(int32, int32)',
    '    stloc.s 4',
    '  done:',
    '    ldloca.s 4',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call instance string [mscorlib]System.Single::ToString(class [mscorlib]System.IFormatProvider)',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly ForInDictProgram {}\n.module ForInDictProgram.exe\n\n'
    '.class public auto ansi ForInDictProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_for_in_dict.il'
exe_path = HERE / 'sample_for_in_dict.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

cases = [
    (0, lambda n, m: py_sum_dict_items(n, 1.5), [(0, 0), (1, 0), (4, 0), (7, 0)]),
    (1, lambda n, m: py_sum_nested(n, m), [(0, 0), (1, 1), (3, 2), (4, 4)]),
]
total = 0
mismatches = []
for mode, py_call, arg_sets in cases:
    for n, m in arg_sets:
        total += 1
        expected = float(py_call(n, m))
        scale = 1.5
        r = subprocess.run([str(exe_path), str(mode), str(n), str(m), str(scale)],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((mode, n, m, expected, None, r.stdout, r.stderr))
            continue
        got = float(r.stdout.strip())
        if abs(got - expected) > 1e-2:
            mismatches.append((mode, n, m, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for x in mismatches:
        print(" ", x)
    sys.exit(1)
print("FOR-IN-DICT-ITEMS SUPPORT: PASS - 'for k, v in d.items():' (gom ca long nhau) "
      "bien dich THAT va dung 100%.")
