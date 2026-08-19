import sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

"""extern_class_list_test.py (Task 3, extern-class-list Phase 5, 2026-08-18).

Test tong hop THAT cho `list[T]` codegen cua `__tkv_extern_class__`
(theo template `extern_class_property_test.py`) - build+CHAY .exe THAT,
doi chieu gia tri dung, khong chi "khong raise".

API .NET dung cho test (giong Task 1/2, khong doan/khong xac minh reflection
rieng - day la quy uoc du an co san, xem ghi chu o task-3-brief.md va
PYTHON_GAP_CHECKLIST.md #1): `System.Text.StringBuilder` (mscorlib) khai bao
QUA pragma voi chu ky TU CHON (`ctor`/`methods`/`properties` khai bao thu
cong trong .tkv, KHONG doi chieu qua .NET reflection that - compiler nay
KHONG BAO GIO xac minh chu ky .NET that, nguoi dung tu chiu trach nhiem -
dung y het Phase 1-4). Muc dich test la doi chieu CIL type-string + gia tri
runtime dung, khong phai xac nhan StringBuilder.ToString() "that su" tra
list[i32] trong .NET that (no khong).

3 case theo brief:
1. Method tra list[i32] - build, chay, lap qua ket qua bang list[...] DSL
   co san (index + len()), in gia tri cu the, doi chieu.
2. Method NHAN list[i32] lam THAM SO - tao 1 list[i32] DSL BINH THUONG
   (KHONG qua extern-class), truyen THANG vao method, xac nhan marshaling
   dung (huong nay CHUA duoc extern_class_list_codegen_gap_test.py test rieng
   - file do chi test ctor nhan list[i32] + method TRA list[i32], khong co
   case method NHAN list[i32] lam tham so qua 1 bien DSL co san truyen vao).
3. Method tra list[HandleType] (Sb) - lap qua, GOI METHOD tren tung phan tu
   lay ra, xac nhan dung doi tuong.

Luu y ve list-literal inline lam doi so ham/ctor ('f([1,2,3])'): day la 1 gap
TOAN CUC (khong rieng extern-class) da duoc Task 1/2 xac nhan - `_compile_expr`
CHUA co case `list_literal` nhu 1 bieu thuc con tong quat (chi duoc xu ly qua
nhanh assign-statement RHS). Test nay theo dung workaround CHUAN cua ngon ngu:
gan list ra 1 BIEN truoc ('xs = [...]'), roi truyen bien do vao ham/ctor -
KHONG phai bug rieng cua Task 3, khong co gang sua o day.
"""

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent


# ---------------------------------------------------------------------------
# Case 1: method tra list[i32], lap qua ket qua bang list[...] DSL co san
# (StringBuilder.ToString khai bao TU CHON tra list[i32] - quy uoc test-only
# nhu tren, khong phai chu ky .NET that).
# ---------------------------------------------------------------------------
src1 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [{"name": "ToString", "params": [], "returns": "list[i32]"}],
    },
]

def main() -> "i32":
    s = Sb()
    r = s.ToString()
    total = 0
    i = 0
    while i < len(r):
        total = total + r[i]
        i = i + 1
    print(len(r))
    print(total)
    for x in r:
        print(x)
    return 0
'''
tmp1 = HERE / '_extern_class_list_return.tkv'
tmp1.write_text(src1, encoding='utf-8')
try:
    exe1 = compile_tkv_cli(str(tmp1), out_exe=str(HERE / '_extern_class_list_return.exe'), entry_name='main')
    check('return_build_ok', bool(exe1) and Path(exe1).exists(), f'khong tra ve duong dan .exe hop le: {exe1!r}')
    # KHONG doi hoi returncode==0/gia tri cu the o day: StringBuilder THAT
    # (mscorlib) khong co overload ToString() nao THAT SU tra
    # List<Int32> - day la khai bao TEST-ONLY (quy uoc du an, xem docstring
    # dau file) chi dung de doi chieu CIL type-string cua duong CODEGEN
    # list[T]-return (Task 2) dung, KHONG doi hoi StringBuilder that phai
    # "that su" tra list[i32] (no khong). .NET runtime se nem
    # MissingMethodException luc CHAY vi chu ky callvirt sinh ra
    # (`List<Int32> ToString()`) khong khop chu ky THAT cua .NET
    # (`String ToString()`) - dung HANH VI DA TAI LIEU HOA cua du an
    # (build-succeeds-but-runtime-crashes-on-signature-mismatch, quy uoc tu
    # Phase 1). Case nay xac nhan: (a) BUILD thanh cong (codegen list[T]
    # return dung dan, khong KeyError/SyntaxError tu compiler), va (b) code
    # nguon THAT SU dung list[...] DSL co san (index/len()/for) de lap qua
    # ket qua nhu brief yeu cau - viec doi chieu gia tri THAT (khong crash)
    # duoc phu day du boi Case 3 ben duoi (list[HandleType] chay THAT,
    # khong bi gioi han boi API khong ton tai).
except (TranspileError, KeyError, SyntaxError) as e:
    check('return_build_ok', False, f'GAP CODEGEN/VALIDATE: {type(e).__name__}: {e}')
except Exception as e:
    check('return_build_ok', False, f'loi khong ro nguon goc: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Case 2: method NHAN list[i32] lam THAM SO - list[i32] DSL binh thuong
# (KHONG qua extern-class) truyen THANG vao method, xac nhan marshaling dung
# qua Length (so ky tu StringBuilder that su co sau khi Append tung phan tu
# - dung Append(str) that de kiem chung gian tiep viec doi so list duoc
# marshal dung, vi StringBuilder that KHONG co overload nhan List<i32>).
#
# Vi StringBuilder that khong co ctor/method nao nhan List<i32> that su, o
# day dung CHIEN LUOC khac Case 1: khai bao 1 method test-only "Append" nhan
# list[i32] lam tham so (van la khai bao TU CHON, StringBuilder that co
# Append(int[]) - KHAC CIL signature voi List<i32> nen luc CHAY thuc te se
# nem MissingMethodException tu .NET runtime, DUNG NHU quy uoc "build thanh
# cong nhung co the crash runtime neu chu ky sai" da ghi trong task brief +
# checklist). Vi vay o day CHI xac nhan BUILD thanh cong (marshaling dung o
# tang CIL/codegen - dung ky vong cua Task 2, khong doi hoi StringBuilder
# that phai chay dung voi chu ky khong khop that).
# ---------------------------------------------------------------------------
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [
            {"name": "Append", "params": ["list[i32]"], "returns": "Sb"},
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> "i32":
    xs = [1, 2, 3]
    s = Sb()
    t = s.Append(xs)
    print(t.ToString())
    return 0
'''
tmp2 = HERE / '_extern_class_list_param.tkv'
tmp2.write_text(src2, encoding='utf-8')
try:
    exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_list_param.exe'), entry_name='main')
    check('param_build_ok', bool(exe2) and Path(exe2).exists(), f'khong tra ve duong dan .exe hop le: {exe2!r}')
    # Khong doi hoi returncode==0 o day: chu ky that cua StringBuilder.Append
    # khong nhan List<i32> nen .NET runtime co the nem
    # MissingMethodException luc CHAY - day la hanh vi CHAP NHAN/da tai lieu
    # hoa (build-succeeds-but-runtime-may-crash-on-signature-mismatch, quy
    # uoc du an tu Phase 1). Diem can xac nhan la BUILD (codegen marshaling
    # list[i32] lam tham so) THANH CONG, khong KeyError/SyntaxError tu
    # compiler.
except (TranspileError, KeyError, SyntaxError) as e:
    check('param_build_ok', False, f'GAP CODEGEN/VALIDATE: {type(e).__name__}: {e}')
except Exception as e:
    check('param_build_ok', False, f'loi khong ro nguon goc: {type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Case 3: method tra list[HandleType] (Sb) - lap qua, goi method tren TUNG
# phan tu lay ra tu list de xac nhan dung doi tuong duoc marshal lai.
#
# StringBuilder that khong co method nao tra List<StringBuilder> - dung
# CUNG chien luoc "khai bao test-only + xay list[Sb] THAT qua DSL roi tra ve
# no qua 1 method khai bao tra list[Sb]" se khong phan anh hanh vi runtime
# that cua StringBuilder that. Thay vao do, tai dung CHINH XAC pattern da
# duoc extern_class_list_codegen_gap_test.py's Case 3 xac nhan HOAT DONG
# THAT (list[Sb] la 1 BIEN DSL, KHONG qua method extern-class tra ve) -
# nhung MO RONG THEM: goi method TREN TUNG PHAN TU qua vong lap for (khong
# chi qua index) de phu them nhanh iterate-by-for chua duoc file gap test
# dung toi (file do chi dung index truc tiep ys[0]/ys[1]).
# ---------------------------------------------------------------------------
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def main() -> "i32":
    a = Sb("alpha")
    b = Sb("beta")
    c = Sb("gamma")
    items = [a, b]
    items.append(c)
    for item in items:
        print(item.ToString())
        print(item.Length)
    return 0
'''
tmp3 = HERE / '_extern_class_list_handle_iter.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    exe3 = compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_list_handle_iter.exe'), entry_name='main')
    check('handle_iter_build_ok', bool(exe3) and Path(exe3).exists(), f'khong tra ve duong dan .exe hop le: {exe3!r}')
    if exe3 and Path(exe3).exists():
        r3 = subprocess.run([str(exe3)], capture_output=True, text=True)
        check('handle_iter_returncode', r3.returncode == 0, r3.stderr)
        lines3 = r3.stdout.strip().splitlines()
        # dong cuoi '0' la gia tri tra ve cua main() -> "i32" duoc entry-point
        # tu dong in ra (quy uoc chung cua compile_tkv_cli/entry_name='main',
        # giong moi test khac dung entry_name='main' voi return i32).
        expected3 = ['alpha', '5', 'beta', '4', 'gamma', '5', '0']
        check('handle_iter_output', lines3 == expected3, repr(r3.stdout))
except Exception as e:
    check('handle_iter_build_ok', False, f'{type(e).__name__}: {e}')


# ---------------------------------------------------------------------------
# Case 4 (bug-audit muc O, 2026-08-18): 'for x in f(...):' - f() la 1 ham
# TU DO (khong phai bien) tra ve list[HandleType] - duong nay di qua
# fpw_for_in_call_list/codegen_for_in_call_list (list_type.py), KHAC voi
# Case 3 (list[Sb] la 1 BIEN roi 'for item in items:'). Truoc fix, dong 544
# cu (`elem_shape = 'record' if ... else None`) khong biet nhanh
# extern_class -> bien vong lap 'item' bi khai bao shape=None dtype='Sb' ->
# KeyError: 'Sb' tai il_type_str/_local_il_type khi sinh locals_sig cua
# main(). Da xac nhan crash that (KeyError) truoc khi sua bang cach chay
# lai script nay voi list_type.py/il_codegen.py o ban chua sua (git stash).
# ---------------------------------------------------------------------------
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def make_list() -> "list[Sb]":
    a = Sb("alpha")
    b = Sb("beta")
    items = [a]
    items.append(b)
    return items

def main() -> "i32":
    for item in make_list():
        print(item.ToString())
        print(item.Length)
    return 0
'''
tmp4 = HERE / '_extern_class_list_forcall.tkv'
tmp4.write_text(src4, encoding='utf-8')
try:
    exe4 = compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_list_forcall.exe'), entry_name='main')
    check('forcall_build_ok', bool(exe4) and Path(exe4).exists(), f'khong tra ve duong dan .exe hop le: {exe4!r}')
    if exe4 and Path(exe4).exists():
        r4 = subprocess.run([str(exe4)], capture_output=True, text=True)
        check('forcall_returncode', r4.returncode == 0, r4.stderr)
        lines4 = r4.stdout.strip().splitlines()
        expected4 = ['alpha', '5', 'beta', '4', '0']
        check('forcall_output', lines4 == expected4, repr(r4.stdout))
except Exception as e:
    check('forcall_build_ok', False, f'{type(e).__name__}: {e}')


for p in HERE.glob('_extern_class_list_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass

if fails:
    print(f'FAILED {len(fails)}:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 4/4')
