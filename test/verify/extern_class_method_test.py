import sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

# Test 1: method scalar-return
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> "i32":
    s = Sb("abc")
    print(s.ToString())
    return 0
'''
tmp = HERE / '_extern_class_method_scalar.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_method_scalar.exe'), entry_name='main')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('method_scalar_returncode', r.returncode == 0, r.stderr)
check('method_scalar_output', r.stdout.strip().splitlines()[0] == 'abc', repr(r.stdout))

# Test 2: method tra ve CHINH handle type (fluent chaining) - StringBuilder.Append that su co chu ky nay
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "Append", "params": ["str"], "returns": "Sb"},
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> "i32":
    s = Sb("a")
    t = s.Append("b")
    print(t.ToString())
    return 0
'''
tmp2 = HERE / '_extern_class_method_chain.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_method_chain.exe'), entry_name='main')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('method_chain_returncode', r2.returncode == 0, r2.stderr)
check('method_chain_output', r2.stdout.strip().splitlines()[0] == 'ab', repr(r2.stdout))

# Test 3: goi method tren KET QUA bieu thuc truc tiep (khong qua bien trung gian)
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "Append", "params": ["str"], "returns": "Sb"},
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> "i32":
    s = Sb("x")
    print(s.Append("y").ToString())
    return 0
'''
tmp3 = HERE / '_extern_class_method_direct_chain.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    exe3 = compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_method_direct_chain.exe'), entry_name='main')
    r3 = subprocess.run([str(exe3)], capture_output=True, text=True)
    check('method_direct_chain_returncode', r3.returncode == 0, r3.stderr)
    check('method_direct_chain_output', r3.stdout.strip().splitlines()[0] == 'xy', repr(r3.stdout))
except SyntaxError as e:
    check('method_direct_chain_returncode', False, f'SyntaxError: {e}')
    check('method_direct_chain_output', False, 'skipped (compile failed)')

# Test 4: is None tren bien handle
src4 = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": []},
]

def main() -> "i32":
    s = Sb()
    if s is None:
        print("null")
    else:
        print("notnull")
    return 0
'''
tmp4 = HERE / '_extern_class_method_isnone.tkv'
tmp4.write_text(src4, encoding='utf-8')
exe4 = compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_method_isnone.exe'), entry_name='main')
r4 = subprocess.run([str(exe4)], capture_output=True, text=True)
check('method_isnone_returncode', r4.returncode == 0, r4.stderr)
check('method_isnone_output', r4.stdout.strip().splitlines()[0] == 'notnull', repr(r4.stdout))

# Test 5: loi validate - method dung dtype tham so khong ho tro
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Foo", "params": ["bignum"], "returns": "str"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp5 = HERE / '_extern_class_method_baddtype.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_method_baddtype.exe'), entry_name='main')
    check('method_baddtype_raises', False, 'khong raise')
except TranspileError:
    check('method_baddtype_raises', True)

# Test 6: isolation - 2 lan compile lien tiep CUNG process, khac file, CUNG ten handle type
# (khoa THAT SU trong EXPR_METHOD_CODEGEN la ('extern_class', method_name),
# KHONG PHAI (ten_class, method_name) - xem ghi chu lon o
# tkv_compile.py's _make_extern_class_method_codegen - nen kiem tra o day
# dung khoa THAT.)
src_iso_a = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]
def main() -> "i32":
    h = H()
    print(h.ToString())
    return 0
'''
src_iso_b = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Object", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]
def main() -> "i32":
    h = H()
    print(h.ToString())
    return 0
'''
tmp_iso_a = HERE / '_extern_class_iso_a.tkv'
tmp_iso_b = HERE / '_extern_class_iso_b.tkv'
tmp_iso_a.write_text(src_iso_a, encoding='utf-8')
tmp_iso_b.write_text(src_iso_b, encoding='utf-8')
from il_dispatch import EXPR_METHOD_CODEGEN
check('iso_pre_clean', ('extern_class', 'ToString') not in EXPR_METHOD_CODEGEN, 'ToString da dang ky truoc khi test chay')
compile_tkv_cli(str(tmp_iso_a), out_exe=str(HERE / '_extern_class_iso_a.exe'), entry_name='main')
check('iso_post_a_clean', ('extern_class', 'ToString') not in EXPR_METHOD_CODEGEN, 'khong pop sau compile A')
exe_iso_b = compile_tkv_cli(str(tmp_iso_b), out_exe=str(HERE / '_extern_class_iso_b.exe'), entry_name='main')
check('iso_b_builds', exe_iso_b is not None, 'compile B (cung ten H, class khac) that bai')
check('iso_post_b_clean', ('extern_class', 'ToString') not in EXPR_METHOD_CODEGEN, 'khong pop sau compile B')

for p in HERE.glob('_extern_class_method_*'):
    p.unlink()
for p in HERE.glob('_extern_class_iso_*'):
    p.unlink()

if fails:
    print(f'FAILED {len(fails)}/11:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 11/11')
