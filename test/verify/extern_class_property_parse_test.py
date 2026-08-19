import sys, ast
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import _parse_extern_class_dict_literal, compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

def _dict_node(src):
    return ast.parse(src, mode='eval').body

# Test 1: properties day du, co readonly ro
node = _dict_node("""{
    "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [
        {"name": "Length", "dtype": "i32", "readonly": True},
        {"name": "Capacity", "dtype": "i32", "readonly": False},
    ],
}""")
decl = _parse_extern_class_dict_literal(node)
check('props_len', len(decl['properties']) == 2, decl)
check('prop0_name', decl['properties'][0]['name'] == 'Length', decl)
check('prop0_readonly', decl['properties'][0]['readonly'] is True, decl)
check('prop1_readonly', decl['properties'][1]['readonly'] is False, decl)

# Test 2: properties vang readonly -> mac dinh True
node2 = _dict_node("""{
    "name": "Sb2", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [{"name": "Length", "dtype": "i32"}],
}""")
decl2 = _parse_extern_class_dict_literal(node2)
check('prop_default_readonly', decl2['properties'][0]['readonly'] is True, decl2)

# Test 3: khong khai 'properties' -> tu dien vao [] (tuong thich nguoc)
node3 = _dict_node("""{
    "name": "Sb3", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
}""")
decl3 = _parse_extern_class_dict_literal(node3)
check('props_absent_defaults_empty', decl3['properties'] == [], decl3)

# Test 4: key la trong property dict -> TranspileError
node4 = _dict_node("""{
    "name": "Sb4", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [{"name": "X", "dtype": "i32", "bad_key": 1}],
}""")
try:
    _parse_extern_class_dict_literal(node4)
    check('prop_bad_key_raises', False, 'khong raise')
except TranspileError:
    check('prop_bad_key_raises', True)

# ---------------------------------------------------------------------------
# Task 1 review finding: vong lap validate trong compile_tkv_cli (~dong 2491
# tkv_compile.py) chua co coverage - cac test tren chi goi thang
# _parse_extern_class_dict_literal (shape parsing), khong bao gio chay qua
# compile_tkv_cli (noi business-logic validation that su nam). Bo sung o day
# theo mau extern_class_ctor_test.py (compile_tkv_cli + fixture .tkv).
# ---------------------------------------------------------------------------
HERE = Path(__file__).parent

# Test 5 (NEGATIVE): 2 property TRUNG TEN trong CUNG 1 decl -> TranspileError.
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
        "properties": [
            {"name": "X", "dtype": "i32"},
            {"name": "X", "dtype": "i32"},
        ],
    },
]

def main() -> "i32":
    return 0
'''
tmp5 = HERE / '_extern_class_prop_dupname_err.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_prop_dupname_err.exe'), entry_name='main')
    check('prop_dupname_raises', False, 'khong raise')
except TranspileError:
    check('prop_dupname_raises', True)
except Exception as e:
    check('prop_dupname_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# Test 6 (NEGATIVE): ten property sai dinh dang (bat dau bang so) -> TranspileError.
src6 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
        "properties": [{"name": "123bad", "dtype": "i32"}],
    },
]

def main() -> "i32":
    return 0
'''
tmp6 = HERE / '_extern_class_prop_nameformat_err.tkv'
tmp6.write_text(src6, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp6), out_exe=str(HERE / '_extern_class_prop_nameformat_err.exe'), entry_name='main')
    check('prop_nameformat_raises', False, 'khong raise')
except TranspileError:
    check('prop_nameformat_raises', True)
except Exception as e:
    check('prop_nameformat_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# Test 7 (NEGATIVE): dtype khong ho tro (khong phai scalar, khong phai handle
# type da khai trong CUNG pragma) -> TranspileError.
src7 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
        "properties": [{"name": "X", "dtype": "bignum"}],
    },
]

def main() -> "i32":
    return 0
'''
tmp7 = HERE / '_extern_class_prop_dtype_err.tkv'
tmp7.write_text(src7, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp7), out_exe=str(HERE / '_extern_class_prop_dtype_err.exe'), entry_name='main')
    check('prop_dtype_unsupported_raises', False, 'khong raise')
except TranspileError:
    check('prop_dtype_unsupported_raises', True)
except Exception as e:
    check('prop_dtype_unsupported_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# Test 8 (NEGATIVE): property 'X' sinh pseudo-method 'get_X', TRUNG voi 1
# method THAT ten 'get_X' da khai trong 'methods' cua CUNG decl -> TranspileError.
src8 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [{"name": "get_X", "params": [], "returns": "i32"}],
        "properties": [{"name": "X", "dtype": "i32"}],
    },
]

def main() -> "i32":
    return 0
'''
tmp8 = HERE / '_extern_class_prop_collision_getx_err.tkv'
tmp8.write_text(src8, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp8), out_exe=str(HERE / '_extern_class_prop_collision_getx_err.exe'), entry_name='main')
    check('prop_collision_getx_raises', False, 'khong raise')
except TranspileError:
    check('prop_collision_getx_raises', True)
except Exception as e:
    check('prop_collision_getx_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

# Test 9 (NEGATIVE, bonus): chieu nguoc lai - method 'set_X' khai TRUOC trong
# danh sach 'methods', property 'X' khai SAU - guard van phai bat duoc bat ke
# thu tu khai bao trong dict nguon (vi _seen_method_names duoc build 1 lan tu
# TOAN BO _decl['methods'] truoc khi duyet properties, xem dong 2492
# tkv_compile.py).
src9 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [{"name": "set_X", "params": ["i32"], "returns": "i32"}],
        "properties": [{"name": "X", "dtype": "i32"}],
    },
]

def main() -> "i32":
    return 0
'''
tmp9 = HERE / '_extern_class_prop_collision_setx_err.tkv'
tmp9.write_text(src9, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp9), out_exe=str(HERE / '_extern_class_prop_collision_setx_err.exe'), entry_name='main')
    check('prop_collision_setx_raises', False, 'khong raise')
except TranspileError:
    check('prop_collision_setx_raises', True)
except Exception as e:
    check('prop_collision_setx_raises', False, f'sai loai exception: {type(e).__name__}: {e}')

for p in HERE.glob('_extern_class_prop_*'):
    try:
        p.unlink()
    except OSError:
        pass

_TOTAL = 11
if fails:
    print(f'FAILED {len(fails)}/{_TOTAL}:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print(f'OK {_TOTAL}/{_TOTAL}')
