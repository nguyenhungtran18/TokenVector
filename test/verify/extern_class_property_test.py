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

# Test 1: doc property scalar
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def main() -> "i32":
    s = Sb("hello")
    n = s.Length
    print(n)
    return 0
'''
tmp = HERE / '_extern_class_prop_read.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_read.exe'), entry_name='main')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('prop_read_returncode', r.returncode == 0, r.stderr)
check('prop_read_output', r.stdout.splitlines()[0].strip() == '5', repr(r.stdout))

# Test 2: doc property tren ket qua bieu thuc goi method (chaining voi property)
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [{"name": "Append", "params": ["str"], "returns": "Sb"}],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def main() -> "i32":
    s = Sb("ab")
    t = s.Append("cd")
    n = t.Length
    print(n)
    return 0
'''
tmp2 = HERE / '_extern_class_prop_chain.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_prop_chain.exe'), entry_name='main')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('prop_chain_returncode', r2.returncode == 0, r2.stderr)
check('prop_chain_output', r2.stdout.splitlines()[0].strip() == '4', repr(r2.stdout))

# Test 3: loi - doc property khong ton tai
src3 = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": []},
]
def main() -> "i32":
    s = Sb()
    n = s.NotAProp
    return 0
'''
tmp3 = HERE / '_extern_class_prop_missing.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_prop_missing.exe'), entry_name='main')
    check('prop_missing_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('prop_missing_raises', True)

# Test 4: ghi property co the ghi (readonly=false)
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": False}],
    },
]

def main() -> "i32":
    s = Sb("hello world")
    s.Length = 5
    print(s.Length)
    return 0
'''
tmp4 = HERE / '_extern_class_prop_write.tkv'
tmp4.write_text(src4, encoding='utf-8')
exe4 = compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_prop_write.exe'), entry_name='main')
r4 = subprocess.run([str(exe4)], capture_output=True, text=True)
check('prop_write_returncode', r4.returncode == 0, r4.stderr)
check('prop_write_output', r4.stdout.splitlines()[0].strip() == '5', repr(r4.stdout))

# Test 5: ghi property readonly=true -> TranspileError
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]
def main() -> "i32":
    s = Sb()
    s.Length = 5
    return 0
'''
tmp5 = HERE / '_extern_class_prop_readonly_err.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_prop_readonly_err.exe'), entry_name='main')
    check('prop_readonly_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('prop_readonly_raises', True)

# Test 6: isolation - dang ky get_X/set_X 2 lan lien tiep cung process, khac file
# il_dispatch nam trong compiler/ - da duoc them vao sys.path (flat, khong
# phai package 'compiler.il_dispatch') boi chinh viec import tkv_compile o
# tren (dong 37 cua tkv_compile.py tu chen COMPILER_DIR vao sys.path[0]
# TRUOC khi no tu import il_dispatch) - dung CUNG duong import de lay
# CHINH XAC cung 1 module object/dict (khong phai 1 ban sao rong qua
# namespace-package 'compiler.il_dispatch').
from il_dispatch import EXPR_METHOD_CODEGEN
src_iso = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": False}]},
]
def main() -> "i32":
    h = H()
    h.Length = 0
    print(h.Length)
    return 0
'''
tmp_iso1 = HERE / '_extern_class_prop_iso1.tkv'
tmp_iso2 = HERE / '_extern_class_prop_iso2.tkv'
tmp_iso1.write_text(src_iso, encoding='utf-8')
tmp_iso2.write_text(src_iso, encoding='utf-8')
check('iso_pre_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'da dang ky truoc khi test')
compile_tkv_cli(str(tmp_iso1), out_exe=str(HERE / '_extern_class_prop_iso1.exe'), entry_name='main')
check('iso_post1_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'khong pop sau lan 1')
check('iso_post1_set_clean', ('extern_class', 'set_Length') not in EXPR_METHOD_CODEGEN, 'khong pop set sau lan 1')
exe_iso2 = compile_tkv_cli(str(tmp_iso2), out_exe=str(HERE / '_extern_class_prop_iso2.exe'), entry_name='main')
check('iso2_builds', exe_iso2 is not None, 'lan 2 that bai')
check('iso_post2_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'khong pop sau lan 2')

for p in HERE.glob('_extern_class_prop_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass

if fails:
    print(f'FAILED {len(fails)}/13:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 13/13')
