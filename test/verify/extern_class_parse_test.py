import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import _parse_extern_class_dict_literal, TranspileError
import ast

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

def _dict_node(src):
    tree = ast.parse(src, mode='eval')
    return tree.body

# Test 1: shape hop le, day du field
node = _dict_node("""{
    "name": "Matrix",
    "assembly": "MathNet.Numerics",
    "class": "MathNet.Numerics.LinearAlgebra.Matrix",
    "ctor": ["i32", "i32"],
    "methods": [
        {"name": "Determinant", "params": [], "returns": "f64"},
        {"name": "Transpose", "params": [], "returns": "Matrix"},
    ],
}""")
decl = _parse_extern_class_dict_literal(node)
check('parse_ok_name', decl['name'] == 'Matrix', decl)
check('parse_ok_ctor', decl['ctor'] == ['i32', 'i32'], decl)
check('parse_ok_methods_len', len(decl['methods']) == 2, decl)
check('parse_ok_method0_name', decl['methods'][0]['name'] == 'Determinant', decl)
check('parse_ok_method1_returns', decl['methods'][1]['returns'] == 'Matrix', decl)

# Test 2: ctor rong hop le
node2 = _dict_node("""{
    "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
}""")
decl2 = _parse_extern_class_dict_literal(node2)
check('parse_ok_empty_ctor', decl2['ctor'] == [], decl2)
check('parse_ok_empty_methods', decl2['methods'] == [], decl2)

# Test 3: thieu key bat buoc -> TranspileError
node3 = _dict_node("""{"name": "X", "assembly": "mscorlib", "class": "System.Object"}""")
try:
    _parse_extern_class_dict_literal(node3)
    check('parse_missing_key_raises', False, 'khong raise')
except TranspileError:
    check('parse_missing_key_raises', True)

# Test 4: key la khong hop le
node4 = _dict_node("""{
    "name": "X", "assembly": "mscorlib", "class": "System.Object",
    "ctor": [], "methods": [], "bad_key": 1,
}""")
try:
    _parse_extern_class_dict_literal(node4)
    check('parse_bad_key_raises', False, 'khong raise')
except TranspileError:
    check('parse_bad_key_raises', True)

if fails:
    print(f'FAILED {len(fails)}/8:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 8/8')
