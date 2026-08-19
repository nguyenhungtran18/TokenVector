import sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

"""extern_class_list_codegen_gap_test.py (2026-08-18, fix sau code review
Task 1 / extern-class-list; LAT lai sau Task 2).

Task 1's bao cao goc claim sai rang codegen list[T] cho extern-class
ctor/method/property "da hoat dong end-to-end", dua tren 3 test case
CHI khai bao pragma nhung khong bao gio THUC SU goi/tao doi tuong voi
dtype list[T] trong main() - nen duong codegen (_il_ctor_param_type,
compiler/il_codegen.py) chua bao gio duoc thuc thi trong cac test do.

File nay ban dau (truoc Task 2) xac nhan LAI tinh trang THAT: goi
Sb([1,2,3]) (ctor thuc su nhan list[i32]) va s.ToString() (method thuc
su tra list[i32]) nem KeyError('list[i32]') tu codegen.

Task 2 (2026-08-18) da dong gap nay - file nay GIO xac nhan build THANH
CONG THAT (khong con KeyError) cho ca 2 case, dung construct+call THAT
(khong chi khai bao pragma):
  - Case 1 (ctor): truyen 1 BIEN list ('xs = [1, 2, 3]' roi 'Sb(xs)') chu
    KHONG PHAI list-literal INLINE ngay tai vi tri doi so goi ham
    ('Sb([1, 2, 3])') - ly do: truyen list-literal INLINE lam doi so cho
    BAT KY loi goi ham/ctor nao (extern-class hay khong) la 1 GAP KHAC,
    RIENG BIET, chua duoc _compile_expr ho tro (tag 'list_literal' hien
    CHI duoc xu ly qua nhanh assign-statement RHS, khong phai nhu 1
    bieu thuc con tong quat) - nam NGOAI scope cua Task 2 (chi mo rong
    _il_ctor_param_type/il_list_elem_ilstr, khong dong cham
    _compile_expr's list_literal dispatch). Dung bien list la cach THAT
    de nguoi dung viet code nay (Python that cung thuong gan list ra
    bien truoc khi truyen).
  - Case 2 (method return list[T]): xac nhan qua khai bao local
    ('r = s.ToString()') that su duoc bien dich (truoc Task 2, day cung
    la 1 KeyError khac tu _local_il_type/il_type_str, do
    tkv_compile.py's _make_extern_class_method_return_ta chua parse dung
    'list[T]' thanh TypeAnn shape='list' - da sua cung Task 2, xem
    task-2-report.md)."""

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent


def _expect_codegen_ok(tmp_path, src, label):
    """Bien dich mot .tkv THUC SU goi/tao doi tuong voi list[T]. Ky vong
    (sau Task 2): build THANH CONG HOAN TOAN, khong raise gi ca."""
    tmp_path.write_text(src, encoding='utf-8')
    try:
        exe = compile_tkv_cli(str(tmp_path), out_exe=str(tmp_path.with_suffix('.exe')),
                               entry_name='main')
        check(label, bool(exe) and Path(exe).exists(), f'khong tra ve duong dan .exe hop le: {exe!r}')
    except TranspileError as e:
        check(label, False, f'validate tu choi nham (TranspileError): {e}')
    except KeyError as e:
        check(label, False, f'GAP CODEGEN VAN CON (KeyError, Task 2 chua dong het): {e}')
    except Exception as e:
        check(label, False, f'loi khong ro nguon goc, can dieu tra: {type(e).__name__}: {e}')


# Case 1: ctor thuc su duoc goi voi list[i32] (truyen qua 1 BIEN, xem
# docstring module o tren ve ly do khong dung list-literal INLINE).
src_ctor = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["list[i32]"], "methods": [],
    },
]
def main() -> "i32":
    xs = [1, 2, 3]
    s = Sb(xs)
    return 0
'''
_expect_codegen_ok(HERE / '_extern_class_list_codegen_ctor.tkv', src_ctor,
                    'ctor_list_i32_actually_called')

# Case 2: method thuc su duoc goi, tra ve list[i32]
src_method = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "list[i32]"}],
    },
]
def main() -> "i32":
    s = Sb()
    r = s.ToString()
    return 0
'''
_expect_codegen_ok(HERE / '_extern_class_list_codegen_method.tkv', src_method,
                    'method_list_i32_return_actually_called')

# Case 3 (fix-report, sau review Task 2 - reviewer's repro): list[HandleType]
# - PHAN TU la 1 handle-type extern-class (khac Case 1/2 la list[i32] vo
# huong). Bug that: khai bao local 'ys = [a]' (a la 1 the hien Sb) crash
# SyntaxError tu il_type_str (compiler/il_codegen.py:141) vi ham nay goi
# il_list_type(dtype, records) KHONG truyen extern_class_defs - da sua (xem
# task-2-report.md, muc 'Fix report'). Test THAT SU build+CHAY .exe, doc lai
# tung phan tu tu list qua index roi goi method tren no de xac nhan DUNG doi
# tuong duoc lay ra lai (khong chi build thanh cong khong loi).
src_handle_list = '''
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
    a = Sb("first")
    b = Sb("second")
    ys = [a]
    ys.append(b)
    print(ys[0].ToString())
    print(ys[1].ToString())
    return 0
'''
tmp3 = HERE / '_extern_class_list_codegen_handle.tkv'
tmp3.write_text(src_handle_list, encoding='utf-8')
try:
    exe3 = compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_list_codegen_handle.exe'),
                            entry_name='main')
    check('handle_list_build_ok', bool(exe3) and Path(exe3).exists(),
          f'khong tra ve duong dan .exe hop le: {exe3!r}')
    if exe3 and Path(exe3).exists():
        r3 = subprocess.run([str(exe3)], capture_output=True, text=True)
        check('handle_list_returncode', r3.returncode == 0, r3.stderr)
        lines = r3.stdout.strip().splitlines()
        check('handle_list_output', lines[:2] == ['first', 'second'], repr(r3.stdout))
except SyntaxError as e:
    check('handle_list_build_ok', False, f'GAP CODEGEN VAN CON (SyntaxError, list[HandleType]): {e}')
except TranspileError as e:
    check('handle_list_build_ok', False, f'validate tu choi nham (TranspileError): {e}')
except Exception as e:
    check('handle_list_build_ok', False, f'loi khong ro nguon goc, can dieu tra: {type(e).__name__}: {e}')

for p in HERE.glob('_extern_class_list_codegen_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass

if fails:
    print(f'FAILED {len(fails)}/3:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 3/3')
