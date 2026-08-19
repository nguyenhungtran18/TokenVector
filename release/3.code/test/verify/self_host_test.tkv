# -*- coding: utf-8 -*-
"""Buoc 8 (Self-host) - kiem chung THAT: sample_self_host_classify.tkv viet
lai inference cua MLPClassifier (dung dung tinh nang cua tokenvector_compile.py)
bang DSL THO (vong lap tay, KHONG dung macro dense/normalize/argmax) -
transpile qua tkv_compile.py (chinh cong cu dang tu chuyen hoa), bien
dich, chay THAT, doi chieu VOI CHINH sklearn model 'golden_iris' (model
that da train boi golden_path_test.py) tren TOAN BO 150 mau Iris - phai
khop 100% voi sklearn.predict(), khong chi voi macro-based tv_classify."""
import sys
from pathlib import Path

import joblib
import numpy as np
import subprocess
from sklearn.datasets import load_iris

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import transpile_program
from tokenvector_compile import ILASM, _LocalAlloc, _emit_1d, _emit_2d, _emit_str_array

HERE = Path(__file__).parent.parent
MODEL_PATH = HERE / 'golden_iris_model.pkl'
SCALER_PATH = HERE / 'golden_iris_scaler.pkl'
if not MODEL_PATH.exists() or not SCALER_PATH.exists():
    print(f"CAN CHAY golden_path_test.py TRUOC (de train+luu {MODEL_PATH.name}/"
          f"{SCALER_PATH.name}) - chua co model that de doi chieu.")
    sys.exit(1)

model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
class_names = load_iris().target_names.tolist()

# 1) Transpile sample_self_host_classify.tkv (file .py THAT, chay duoc that
#    duoi CPython) qua CHINH tkv_compile.py cua TokenVector.
source_text = (HERE / 'sample_self_host_classify.tkv').read_text(encoding='utf-8')
# extra_classes (2026-08-05, lat 4): tu khi hang so nguyen mac dinh la
# 'int', codegen sinh loi goi TkvInt::* o gan nhu moi ham - dinh nghia
# '.class TkvInt' phai duoc ghep RIENG o muc TOP-LEVEL (khong long trong
# class chuong trinh, neu khong ten tham chieu se khong phan giai duoc).
_extra_classes = []
classify_method = transpile_program(source_text, class_name='SelfHostApp', extra_classes=_extra_classes)
print("Da transpile classify_manual (DSL THO, khong macro) tu sample_self_host_classify.tkv")

# 2) Dung LAI ha tang co san cua tokenvector_compile.py (emit hang so
#    mang/parse argv) - CHI phan nay la 'ha tang chung', KHONG phai phan
#    dang self-host (logic inference moi la thu duoc viet lai o Buoc 8).
w1, w2 = model.coefs_
b1, b2 = model.intercepts_
n_in, n_hidden = w1.shape
n_out = w2.shape[1]

alloc = _LocalAlloc()
idx_x = alloc.add('float32[]')
idx_xmin = alloc.add('float32[]')
idx_xmax = alloc.add('float32[]')
idx_w1 = alloc.add('float32[0...,0...]')
idx_b1 = alloc.add('float32[]')
idx_w2 = alloc.add('float32[0...,0...]')
idx_b2 = alloc.add('float32[]')
idx_pred = alloc.add('float32')
idx_i = alloc.add('int32')
idx_labels = alloc.add('string[]')
idx_predidx = alloc.add('int32')

main = []
_emit_1d(idx_x, [0.0] * n_in, main)
_emit_1d(idx_xmin, list(scaler.data_min_), main)
_emit_1d(idx_xmax, list(scaler.data_max_), main)
_emit_2d(idx_w1, w1.tolist(), main)
_emit_1d(idx_b1, b1.tolist(), main)
_emit_2d(idx_w2, w2.tolist(), main)
_emit_1d(idx_b2, b2.tolist(), main)
_emit_str_array(idx_labels, class_names, main)

main += [
    '    ldc.i4.0', f'    stloc.s {idx_i}',
    '  sh_parse_loop:',
    f'    ldloc.s {idx_i}', f'    ldc.i4 {n_in}', '    bge sh_parse_end',
    f'    ldloc.s {idx_x}', f'    ldloc.s {idx_i}',
    '    ldarg.0', f'    ldloc.s {idx_i}', '    ldelem.ref',
    '    call class [mscorlib]System.Globalization.CultureInfo '
    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
    '    call float32 [mscorlib]System.Single::Parse(string, '
    'class [mscorlib]System.IFormatProvider)',
    '    stelem.r4',
    f'    ldloc.s {idx_i}', '    ldc.i4.1', '    add', f'    stloc.s {idx_i}',
    '    br sh_parse_loop',
    '  sh_parse_end:',
    f'    ldloc.s {idx_x}', f'    ldloc.s {idx_xmin}', f'    ldloc.s {idx_xmax}',
    f'    ldloc.s {idx_w1}', f'    ldloc.s {idx_b1}',
    f'    ldloc.s {idx_w2}', f'    ldloc.s {idx_b2}',
    'call float32 SelfHostApp::classify_manual(float32[], float32[], float32[], '
    'float32[0...,0...], float32[], float32[0...,0...], float32[])',
    f'    stloc.s {idx_pred}',
    f'    ldloc.s {idx_pred}', '    conv.i4', f'    stloc.s {idx_predidx}',
    f'    ldloc.s {idx_labels}', f'    ldloc.s {idx_predidx}', '    ldelem.ref',
    '    call void [mscorlib]System.Console::WriteLine(string)',
    '    ret',
]
main_method = [
    '  .method public static void Main(string[] args) cil managed',
    '  {',
    '    .entrypoint',
    '    .maxstack 8',
    f'    .locals init ({alloc.decl_str()})',
] + main + ['  }']

il_text = (
    '.assembly extern mscorlib {}\n.assembly SelfHostApp {}\n.module SelfHostApp.exe\n\n'
    '.class public auto ansi SelfHostApp extends [mscorlib]System.Object\n{\n'
    + '\n'.join(classify_method) + '\n' + '\n'.join(main_method) + '\n}\n' + '\n'.join(_l for _b in _extra_classes for _l in _b) + '\n'
)
il_path = HERE / 'self_host_classify.il'
exe_path = HERE / 'self_host_classify.exe'
il_path.write_text(il_text, encoding='utf-8')

asm = subprocess.run([ILASM, str(il_path), '/exe', f'/output:{exe_path}'],
                      capture_output=True, text=True)
if asm.returncode != 0:
    print("ilasm THAT BAI:\n", asm.stdout, asm.stderr)
    sys.exit(1)

# 3) Doi chieu VOI CHINH sklearn model that (khong phai nhan that) tren
#    TOAN BO 150 mau Iris.
X, _ = load_iris(return_X_y=True)
sklearn_preds = model.predict(scaler.transform(X))

mismatches = []
for i, (row, sk_pred) in enumerate(zip(X, sklearn_preds)):
    args = [str(exe_path)] + [repr(float(v)) for v in row]
    r = subprocess.run(args, capture_output=True, text=True)
    exe_label = r.stdout.strip()
    sk_label = class_names[sk_pred]
    if exe_label != sk_label:
        mismatches.append((i, row.tolist(), sk_label, exe_label, r.stderr))

print(f"Tong so mau doi chieu: {len(X)}")
print(f"Khop (self-host .exe == sklearn that): {len(X) - len(mismatches)}/{len(X)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(f"  mau {m[0]}: x={m[1]} sklearn={m[2]} exe={m[3]} stderr={m[4]!r}")
    sys.exit(1)
print("SELF-HOST: PASS - logic inference cua TokenVector viet lai bang chinh DSL "
      "(khong dung macro dense/normalize/argmax), bien dich qua tkv_compile.py, "
      "khop 100% voi sklearn model that.")
