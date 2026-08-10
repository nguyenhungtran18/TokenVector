# -*- coding: utf-8 -*-
"""Kiem chung THAT 'for x in lst:' vua them (huong #2 sau ROADMAP.md 9
buoc) - khai trien THANG VAN BAN sang for-range+doc-chi-so da co san
(khong codegen moi), gom ca truong hop LONG NHAU (for x in outer: for y
in inner:) de xac nhan bo dem hidden-index khong dung ten bien."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_for_in_list.tkv'
source_text = SRC_PATH.read_text(encoding='utf-8')

py_ns = runpy.run_path(str(SRC_PATH))
py_sum_list_direct = py_ns['sum_list_direct']
py_sum_nested = py_ns['sum_nested_list_direct']

# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
il_method_lines = transpile_program(source_text, class_name='ForInListProgram', extra_classes=_extra_classes)
print(f"Da transpile {source_text.count('def ')} ham tu sample_for_in_list.tkv")

main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    '    .locals init (int32 mode, int32 n, int32 m, float32 r)',
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
    '    br mode1',
    '  mode0:',
    '    ldloc.1',
    '    call float32 ForInListProgram::sum_list_direct(int32)',
    '    stloc.3',
    '    br done',
    '  mode1:',
    '    ldloc.1', '    ldloc.2',
    '    call float32 ForInListProgram::sum_nested_list_direct(int32, int32)',
    '    stloc.3',
    '  done:',
    '    ldloca.s 3',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call instance string [mscorlib]System.Single::ToString(class [mscorlib]System.IFormatProvider)',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
    '  }',
]
il_text = (
    '.assembly extern mscorlib {}\n.assembly ForInListProgram {}\n.module ForInListProgram.exe\n\n'
    '.class public auto ansi ForInListProgram extends [mscorlib]System.Object\n{\n'
    + '\n'.join(il_method_lines) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'sample_for_in_list.il'
exe_path = HERE / 'sample_for_in_list.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

cases = [
    (0, py_sum_list_direct, [(0, 0), (1, 0), (4, 0), (7, 0)]),
    (1, py_sum_nested, [(0, 0), (1, 1), (3, 2), (4, 4)]),
]
total = 0
mismatches = []
for mode, py_func, arg_sets in cases:
    for n, m in arg_sets:
        total += 1
        expected = float(py_func(n, m)) if mode == 1 else float(py_func(n))
        r = subprocess.run([str(exe_path), str(mode), str(n), str(m)],
                            capture_output=True, text=True)
        if r.returncode != 0:
            mismatches.append((mode, n, m, expected, None, r.stdout, r.stderr))
            continue
        got = float(r.stdout.strip())
        if abs(got - expected) > 1e-3:
            mismatches.append((mode, n, m, expected, got, r.stdout, r.stderr))

print(f"So mau doi chieu: {total}")
print(f"Khop (exe == CPython that): {total - len(mismatches)}/{total}")
if mismatches:
    print("SAI LECH:")
    for x in mismatches:
        print(" ", x)
    sys.exit(1)
print("FOR-IN-LIST SUPPORT: PASS - 'for x in lst:' (gom ca long nhau) bien dich THAT va dung 100%.")
