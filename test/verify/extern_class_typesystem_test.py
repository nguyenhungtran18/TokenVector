import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

# Test 1 (POSITIVE): 'Sb' phai duoc chap nhan nhu 1 KIEU HOP LE trong
# annotation tham so/return cua 1 ham top-level, VA 1 bien local cung
# kieu do phai type-check ('return s' voi s: Sb) - TAT CA khong can
# constructor/method codegen (do la viec cua Task 3, ngoai pham vi Task 2:
# tich hop type-system). Dung 'Sb' lam THAM SO thay vi goi 'Sb()' (nhu
# brief goc de xuat) de bai test nay CHI phu thuoc dung phan Task 2 lam,
# khong vo tinh phu thuoc newobj codegen chua ton tai.
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [],
    },
]

def identity(s: "Sb") -> "Sb":
    return s

def main() -> "i32":
    print("ok")
    return 0
'''

tmp = HERE / '_extern_class_types_pos.tkv'
tmp.write_text(src, encoding='utf-8')
try:
    exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_types_pos.exe'), entry_name='main')
    check('typesystem_build_ok', exe is not None, 'compile khong tra ve exe path')
except Exception as e:
    check('typesystem_build_ok', False, f'{type(e).__name__}: {e}')

# Test 2 (NEGATIVE): dung ten 'Sb' chua khai bao qua __tkv_extern_class__
# nao trong file -> phai raise TranspileError ro rang (khong roi vao
# nhanh loi khac/nham lan voi record).
src_bad = '''
def f(x: "Sb") -> "i32":
    return 0
'''
tmp_bad = HERE / '_extern_class_types_bad.tkv'
tmp_bad.write_text(src_bad, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp_bad), out_exe=str(HERE / '_extern_class_types_bad.exe'), entry_name='f')
    check('typesystem_unknown_type_raises', False, 'khong raise')
except TranspileError:
    check('typesystem_unknown_type_raises', True)
except Exception as e:
    check('typesystem_unknown_type_raises', False, f'raise sai loai: {type(e).__name__}')

for p in HERE.glob('_extern_class_types_*'):
    p.unlink()

if fails:
    print(f'FAILED {len(fails)}/2:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 2/2')
