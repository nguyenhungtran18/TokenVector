# -*- coding: utf-8 -*-
"""Kiem chung THAT AlphaAI-codegen: yeu cau mot kien truc TokenVector CLI
KHONG ho tro (2 hidden layer - tokenvector_compile.py chi cham 1 hidden
layer va se nem TokenVectorError ro rang cho truong hop nay), de AlphaAI
(Groq) TU VIET than ham DSL, bien dich THAT qua ilasm.exe, roi doi chieu
SO HOC voi numpy tren nhieu mau ngau nhien - khong chi kiem tra "bien
dich duoc" ma con kiem tra KET QUA dung."""
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from alphaai_codegen import generate_and_verify
# alphaai_codegen tu them 'compiler/' vao sys.path - import SAU no.
from il_codegen import tkvint_class_il  # noqa: E402
from tokenvector_compile import _emit_1d, _emit_2d, ILASM

HERE = Path(__file__).parent.parent

SIG_LINE = ('av_2hidden(x: f32[4], w1: f32[4, 6], b1: f32[6], '
            'w2: f32[6, 4], b2: f32[4], w3: f32[4, 3], b3: f32[3]) -> f32:')
TASK = ("Tinh forward-pass mang no-ron 2 hidden layer: "
        "h1 = dense(x, w1, b1, 'relu'); h2 = dense(h1, w2, b2, 'relu'); "
        "o = dense(h2, w3, b3, 'none'); tra ve argmax(o) "
        "(chi so lop co gia tri lon nhat, kieu float).")

result = generate_and_verify(TASK, SIG_LINE, provider='groq')
print(f"Giai doan: {result['stage']}")
if not result['success']:
    print("THAT BAI:", result['error'])
    print("--- Code AI sinh ra (raw) ---")
    print(result['raw_llm_output'])
    sys.exit(1)

print("Than ham DSL do AlphaAI sinh ra:")
for l in result['body_lines']:
    print(" ", l)

# Dung random weights, nhung CUNG mot bo cho ca numpy tham chieu va .exe
rng = np.random.default_rng(0)
w1 = rng.normal(size=(4, 6)).astype(np.float32)
b1 = rng.normal(size=(6,)).astype(np.float32)
w2 = rng.normal(size=(6, 4)).astype(np.float32)
b2 = rng.normal(size=(4,)).astype(np.float32)
w3 = rng.normal(size=(4, 3)).astype(np.float32)
b3 = rng.normal(size=(3,)).astype(np.float32)


def numpy_ref(x):
    h1 = np.maximum(x @ w1 + b1, 0.0)
    h2 = np.maximum(h1 @ w2 + b2, 0.0)
    o = h2 @ w3 + b3
    return int(np.argmax(o))


main = []
_emit_1d(0, [0.0, 0.0, 0.0, 0.0], main)
_emit_2d(1, w1.tolist(), main)
_emit_1d(2, b1.tolist(), main)
_emit_2d(3, w2.tolist(), main)
_emit_1d(4, b2.tolist(), main)
_emit_2d(5, w3.tolist(), main)
_emit_1d(6, b3.tolist(), main)
main += [
    '    ldc.i4.0', '    stloc.s 8',
    '  av_parse_loop:',
    '    ldloc.s 8', '    ldc.i4 4', '    bge av_parse_end',
    '    ldloc.s 0', '    ldloc.s 8', '    ldarg.0', '    ldloc.s 8', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stelem.r4',
    '    ldloc.s 8', '    ldc.i4.1', '    add', '    stloc.s 8',
    '    br av_parse_loop',
    '  av_parse_end:',
    '    ldloc.s 0', '    ldloc.s 1', '    ldloc.s 2', '    ldloc.s 3',
    '    ldloc.s 4', '    ldloc.s 5', '    ldloc.s 6',
    '    call float32 AlphaAIGen::av_2hidden(float32[], float32[0...,0...], float32[], '
    'float32[0...,0...], float32[], float32[0...,0...], float32[])',
    '    stloc.s 7', '    ldloc.s 7', '    conv.i4', '    stloc.s 9',
    '    ldloc.s 9', '    call void [mscorlib]System.Console::WriteLine(int32)',
    '    ret',
]
main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {', '    .entrypoint', '    .maxstack 8',
    '    .locals init (float32[], float32[0...,0...], float32[], float32[0...,0...], '
    'float32[], float32[0...,0...], float32[], float32, int32, int32)',
] + main + ['  }']

il_text = (
    '.assembly extern mscorlib {}\n.assembly AlphaAIGen {}\n.module AlphaAIGen.exe\n\n'
    '.class public auto ansi AlphaAIGen extends [mscorlib]System.Object\n{\n'
    + '\n'.join(result['il_lines']) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(tkvint_class_il()) + '\n'
)
il_path = HERE / 'alphaai_2hidden.il'
exe_path = HERE / 'alphaai_2hidden.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:", asm.stdout, asm.stderr)
    sys.exit(1)

test_inputs = rng.normal(size=(10, 4)).astype(np.float32)
mismatches = []
for x in test_inputs:
    expected = numpy_ref(x)
    r = subprocess.run([str(exe_path)] + [repr(float(v)) for v in x],
                        capture_output=True, text=True)
    got = r.stdout.strip()
    if got != str(expected):
        mismatches.append((x.tolist(), expected, got, r.stderr))

print(f"So mau doi chieu so hoc: {len(test_inputs)}")
print(f"Khop (exe == numpy): {len(test_inputs) - len(mismatches)}/{len(test_inputs)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(" ", m)
    sys.exit(1)
print("ALPHAAI-CODEGEN: PASS - code do AI sinh ra bien dich THAT va cho ket qua dung 100%.")
