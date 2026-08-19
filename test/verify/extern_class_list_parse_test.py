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


def _validate_ok(tmp_path, src, label):
    """Task 1 (extern-class-list, 2026-08-18), SUA LAI sau code review
    (xem task-1-report.md muc 'Fix report' - claim goc "da hoat dong
    end-to-end" la SAI, KeyError that su xay ra khi THUC SU goi/tao
    doi tuong co list[T]).

    Task 1 CHI lam validate (Task 2 se lam codegen that cho 'list[T]').
    Cac case src1/src2/src5 o duoi day CHI khai bao pragma
    __tkv_extern_class__ (list[T] o ctor/method/property) nhung main()
    KHONG THUC SU goi/tao doi tuong dung dtype list[T] do - nen chi di
    qua duong VALIDATE (o tkv_compile.py, truoc luc sinh IL), KHONG bao
    gio cham toi codegen (_il_ctor_param_type o compiler/il_codegen.py)
    - vi vay ket qua "build thanh cong" o day CHI chung minh VALIDATION
    pass, KHONG chung minh codegen hoat dong. Xem
    test/verify/extern_class_list_codegen_gap_test.py (Task 2) cho bang
    chung THUC SU goi list[T] ctor/method -> KeyError('list[i32]') that,
    xac nhan codegen container CHUA duoc ho tro."""
    tmp_path.write_text(src, encoding='utf-8')
    try:
        compile_tkv_cli(str(tmp_path), out_exe=str(tmp_path.with_suffix('.exe')),
                         entry_name='main')
        check(label, True)
    except TranspileError as e:
        check(label, False, f'bi tu choi nham (TranspileError trong validate): {e}')
    except Exception as e:
        # Khong nen xay ra cho cac case nay (main() khong thuc su goi
        # member list[T] nen khong cham codegen) - neu xay ra la regression
        # that can dieu tra, KHONG coi la "chap nhan duoc".
        check(label, False, f'loi khong mong doi tu codegen (dtype nay khong duoc goi thuc su trong main): {type(e).__name__}: {e}')


# Test 1: list[scalar] hop le trong method return
src1 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "list[i32]"}],
    },
]
def main() -> "i32":
    return 0
'''
_validate_ok(HERE / '_extern_class_list_parse_ok.tkv', src1, 'list_scalar_return_accepted')

# Test 2: list[HandleType] hop le
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Foo", "params": [], "returns": "list[Sb]"}],
    },
]
def main() -> "i32":
    return 0
'''
_validate_ok(HERE / '_extern_class_list_parse_handle.tkv', src2, 'list_handle_return_accepted')

# Test 3: list[list[i32]] -> TranspileError (validate phai tu choi that)
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Bad", "params": [], "returns": "list[list[i32]]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp3 = HERE / '_extern_class_list_parse_nested_err.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_list_parse_nested_err.exe'), entry_name='main')
    check('nested_list_rejected', False, 'khong raise')
except TranspileError:
    check('nested_list_rejected', True)

# Test 4: list[bignum] (dtype ben trong khong hop le) -> TranspileError
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Bad2", "params": [], "returns": "list[bignum]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp4 = HERE / '_extern_class_list_parse_baddtype_err.tkv'
tmp4.write_text(src4, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_list_parse_baddtype_err.exe'), entry_name='main')
    check('bad_inner_dtype_rejected', False, 'khong raise')
except TranspileError:
    check('bad_inner_dtype_rejected', True)

# Test 5: list[T] trong ctor params + property dtype cung phai validate dung
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["list[i32]"], "methods": [],
        "properties": [{"name": "X", "dtype": "list[str]", "readonly": True}],
    },
]
def main() -> "i32":
    return 0
'''
_validate_ok(HERE / '_extern_class_list_parse_ctor_prop.tkv', src5, 'list_ctor_and_property_accepted')

for p in HERE.glob('_extern_class_list_parse_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass

if fails:
    print(f'FAILED {len(fails)}/5:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 5/5')
