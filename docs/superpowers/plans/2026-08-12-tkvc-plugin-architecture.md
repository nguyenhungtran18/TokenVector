# tkvc.exe Plugin Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tách `tkvc.exe` thành core nhẹ (engine dịch + ngữ nghĩa kiểu dữ liệu lõi) và các "thư viện" builtin (math/re/random/os.path/file I/O/sqlite/http/json/...) nạp động từ thư mục `il_features/` cạnh file exe — không cần build lại `tkvc.exe` từ source khi thêm thư viện mới.

**Architecture:** Migrate 6 module đang dùng cơ chế dispatch CŨ (if/elif hardcode trong `_expr_call`) sang cơ chế MỚI (`register_expr_builtin`, đã dùng cho ~15+ module khác) để gỡ import cứng. Thêm 1 module `plugin_loader.py` quét thư mục + `import` động từng file `.py` (thay cho khối `import il_features.X` cứng trong `il_codegen.py`). Sửa `build_tkvc.ps1` để tách staging thành 2 thư mục (core đóng gói vào exe, library copy rời cạnh exe).

**Tech Stack:** Python 3.12, `importlib.util` (nạp module động), PyInstaller (đóng gói `tkvc.exe`), ilasm.exe (assemble IL sinh ra).

## Global Constraints

- Mọi thay đổi phải áp dụng cho CẢ 2 cây: `compiler/il_features/*.py` (cây `.py` gốc, dev) VÀ `release/3.code/compiler/il_features/*.tkv` (cây tự-host) — kiểm tra `diff` giữa 2 bản TRƯỚC khi copy đè, không copy mù nếu 2 cây đã phân kỳ sẵn (đã có tiền lệ `il_codegen.tkv`/`file_io.tkv` phân kỳ ở phiên trước).
- Sau MỖI task: build + test qua `.py` tree (`python tkv.py build ...`) TRƯỚC, chỉ rebuild `tkvc.exe` (`powershell -File release/3.code/build_tkvc.ps1`) và test lại ở các task có đánh dấu "rebuild tkvc.exe".
- KHÔNG sửa hành vi runtime của bất kỳ builtin nào (`pow`/`str`/`re_match`/...) — chỉ đổi CƠ CHẾ ĐĂNG KÝ, code IL sinh ra phải giống hệt trước/sau từng task (verify bằng chạy lại test cũ, không cần test mới cho hành vi không đổi).
- Chỉ commit khi người dùng nói "commit đi" (quy ước xuyên suốt dự án).
- Comment/docstring mới viết bằng tiếng Việt không dấu (ASCII), khớp văn phong hiện có trong `compiler/il_features/*.py`.

---

## Task 1: Guard chống trùng tên đăng ký trong `il_dispatch.py`

Việc migrate ở các Task sau đổi THỨ TỰ import — nếu 2 file vô tình đăng
ký cùng 1 tên (như bug thật `json_get_str` bị `stdlib_cjson` đè âm thầm
ở phiên trước), phải bung lỗi RÕ RÀNG lúc import thay vì im lặng sai.
Làm task này TRƯỚC để mọi migrate sau nếu lỡ tay trùng tên sẽ bị bắt
ngay, không phải dò bằng test.

**Files:**
- Modify: `compiler/il_dispatch.py:101-123` (`register_expr_builtin`)
- Modify: `compiler/il_dispatch.py:181-194` (`register_expr_codegen`/`register_stmt_codegen`/`register_first_pass_walk`/`register_first_pass_prescan`)
- Mirror: `release/3.code/compiler/il_dispatch.tkv`

**Interfaces:**
- Produces: `register_expr_builtin(name, ...)` giờ raise `ValueError` nếu `name` đã có trong `EXPR_BUILTIN_CODEGEN` — mọi Task sau gọi hàm này với tên MỚI (không trùng tên cũ) là an toàn, không cần biết chi tiết bên trong.

- [ ] **Step 1: Đọc lại `compiler/il_dispatch.py` để xác nhận đúng vị trí sửa**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "^def register_" compiler/il_dispatch.py
```

Expected output có đúng 9 dòng, khớp các hàm: `register_expr_builtin`,
`register_expr_method`, `register_line_parser`, `register_assign_rhs_parser`,
`register_macro_expander`, `register_expr_codegen`, `register_stmt_codegen`,
`register_first_pass_walk`, `register_first_pass_prescan`.

- [ ] **Step 2: Sửa `register_expr_builtin`**

Tìm đoạn:
```python
def register_expr_builtin(name, codegen_fn, return_dtype, return_shape=None,
                           temps_fn=None, return_dtype_fn=None, return_ta=None,
                           native_int=False):
    EXPR_BUILTIN_CODEGEN[name] = codegen_fn
```

Sửa thành:
```python
def register_expr_builtin(name, codegen_fn, return_dtype, return_shape=None,
                           temps_fn=None, return_dtype_fn=None, return_ta=None,
                           native_int=False):
    if name in EXPR_BUILTIN_CODEGEN:
        # BUG THAT tim thay o phien truoc (json_get_str bi stdlib_cjson
        # de am tham, chi phat hien qua doc code ky, khong bao loi luc
        # build) - gan thang dict truoc day KHONG canh bao trung ten.
        # Tu 2026-08-12: bung loi RO RANG ngay luc import, tranh lap lai
        # kieu bug do khi thu tu import doi (vd chuyen sang nap plugin
        # dong theo thu tu thu muc, xem plugin_loader.py).
        raise ValueError(
            f"il_dispatch: register_expr_builtin({name!r}) - ten nay DA duoc dang "
            f"ky truoc do (co the do 2 module khac nhau vo tinh dung trung ten "
            f"builtin) - doi ten 1 trong 2, khong duoc de de am tham")
    EXPR_BUILTIN_CODEGEN[name] = codegen_fn
```

- [ ] **Step 3: Sửa `register_expr_codegen`/`register_stmt_codegen`/`register_first_pass_walk`/`register_first_pass_prescan`**

Tìm đoạn:
```python
def register_expr_codegen(tag, fn):
    EXPR_CODEGEN[tag] = fn


def register_stmt_codegen(kind, fn):
    STMT_CODEGEN[kind] = fn


def register_first_pass_walk(kind, fn):
    FIRST_PASS_WALK[kind] = fn


def register_first_pass_prescan(kind, fn):
    FIRST_PASS_PRESCAN[kind] = fn
```

Sửa thành:
```python
def _register_unique(table, key, fn, table_name):
    if key in table:
        raise ValueError(
            f"il_dispatch: {table_name}({key!r}) - khoa nay DA duoc dang ky truoc "
            f"do (co the do 2 module khac nhau vo tinh dung trung ten/kind) - doi "
            f"ten 1 trong 2, khong duoc de de am tham")
    table[key] = fn


def register_expr_codegen(tag, fn):
    _register_unique(EXPR_CODEGEN, tag, fn, 'register_expr_codegen')


def register_stmt_codegen(kind, fn):
    _register_unique(STMT_CODEGEN, kind, fn, 'register_stmt_codegen')


def register_first_pass_walk(kind, fn):
    _register_unique(FIRST_PASS_WALK, kind, fn, 'register_first_pass_walk')


def register_first_pass_prescan(kind, fn):
    _register_unique(FIRST_PASS_PRESCAN, kind, fn, 'register_first_pass_prescan')
```

- [ ] **Step 4: Build lại 3 file test bất kỳ qua `.py` tree để xác nhận KHÔNG có trùng tên nào trong toàn bộ codebase hiện tại (nếu có, sẽ lộ ra ngay ở bước này)**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t1_math.exe
python tkv.py build release/3.code/Testkit/aggregates_variadic_py_tree_test.tkv --entry run --out /tmp/plan_t1_agg.exe
python tkv.py build release/3.code/Testkit/list_sort_kwargs_py_tree_test.tkv --entry run --out /tmp/plan_t1_sort.exe
```

Expected: cả 3 lệnh in `[tkv] Da bien dich: ...` KHÔNG có traceback
`ValueError: il_dispatch: register_...` nào. Nếu có lỗi trùng tên xuất
hiện ở bước này (bug ẨN đã tồn tại từ trước, không phải do Task này gây
ra) — dừng lại, báo cáo tên bị trùng, KHÔNG tự ý đổi tên mà không hỏi
trước khi tiếp tục các Task sau.

- [ ] **Step 5: Chạy lại 3 file exe vừa build để xác nhận hành vi không đổi**

```bash
/tmp/plan_t1_math.exe; /tmp/plan_t1_agg.exe; /tmp/plan_t1_sort.exe
```

Expected: mỗi lệnh in `=== <ten_test>: N/N PASS ===` với N/N khớp với
kết quả PASS đã ghi trong `docs/PYTHON_GAP_CHECKLIST.md` cho 3 file này
(không có dòng `FAIL`).

- [ ] **Step 6: Copy `compiler/il_dispatch.py` sang `release/3.code/compiler/il_dispatch.tkv`, xác nhận diff chỉ gồm đúng thay đổi vừa làm**

```bash
diff compiler/il_dispatch.py release/3.code/compiler/il_dispatch.tkv
```

Nếu diff hiện RA THÊM nội dung khác ngoài 2 đoạn vừa sửa ở Step 2/3 (vd
`.tkv` tree đã có sẵn phần khác), KHÔNG copy đè cả file — dùng Edit áp
đúng 2 đoạn patch vào `.tkv` tree, giữ nguyên phần khác biệt sẵn có
(đúng bài học từ vụ `il_codegen.tkv` bị ghi đè nhầm ở phiên trước). Nếu
diff CHỈ gồm đúng 2 đoạn vừa sửa (không có gì khác trước đó), copy đè an
toàn:

```bash
cp compiler/il_dispatch.py release/3.code/compiler/il_dispatch.tkv
```

- [ ] **Step 7: Build lại qua chính `tkvc.exe` hiện có (CHƯA rebuild `tkvc.exe`, dùng bản cũ để xác nhận `.tkv` tree không hỏng cú pháp) — thực ra bước này KHÔNG có tác dụng kiểm chứng thay đổi (đổi trong `il_dispatch.tkv`, cần rebuild `tkvc.exe` mới thấy hiệu lực), BỎ QUA, để dành xác nhận gộp ở Task 12.**

(Không có lệnh nào — ghi chú tại sao bỏ qua rebuild `tkvc.exe` ở Task
này: rebuild tốn ~1-2 phút mỗi lần, dồn xác nhận `tkvc.exe` vào cuối
Task 7 (migrate xong toàn bộ if/elif cũ) và Task 12 (build script mới)
để đỡ rebuild lặp lại nhiều lần không cần thiết.)

---

## Task 2: Migrate `file_io.py` (`read_file`/`file_exists`) sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/file_io.py`
- Modify: `compiler/il_codegen.py:56-58` (xóa import), `compiler/il_codegen.py:1720-1723` (xóa if/elif)
- Mirror: `release/3.code/compiler/il_features/file_io.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` từ Task 1 (đã có guard chống trùng tên).
- Produces: `read_file`/`file_exists` giờ đăng ký qua `EXPR_BUILTIN_CODEGEN`, KHÔNG còn bị `il_codegen.py` import trực tiếp.

- [ ] **Step 1: Đọc `compiler/il_features/file_io.py` để xác nhận đúng nội dung hiện tại**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "^def compile_read_file\|^def compile_file_exists\|^from il_dispatch\|^register_" compiler/il_features/file_io.py
```

Expected: thấy `def compile_read_file(args, scope, out, dtype, ctx):` và
`def compile_file_exists(args, scope, out, dtype, ctx):`, KHÔNG có dòng
`register_` nào (2 hàm này hiện chỉ được `il_codegen.py` import thẳng).

- [ ] **Step 2: Thêm `register_expr_builtin` vào cuối `compiler/il_features/file_io.py`**

Thêm import ở đầu file (sau dòng `from il_dispatch import register_stmt_codegen`):

```python
from il_dispatch import register_stmt_codegen, register_expr_builtin
```

Thêm vào CUỐI file (sau dòng `register_stmt_codegen('call_stmt', codegen_call_stmt)`):

```python
# Migrate tu co che if/elif cu trong il_codegen.py's _expr_call sang
# register_expr_builtin (2026-08-12, Phase "tach tkvc.exe thanh plugin")
# - gia CHUAN de goi thu vien tu ben ngoai duoc, khong can il_codegen.py
# import thang ten ham. Hanh vi IL sinh ra KHONG DOI, chi doi CO CHE
# DANG KY.
register_expr_builtin('read_file', compile_read_file, 'str')
register_expr_builtin('file_exists', compile_file_exists, 'i32')
```

- [ ] **Step 3: Xóa import trực tiếp trong `compiler/il_codegen.py`**

Tìm đoạn (dòng 56-58):
```python
from il_features.file_io import (
    compile_read_file as _file_io_compile_read_file, compile_file_exists as _file_io_compile_file_exists,
)
```

Xóa hoàn toàn 3 dòng này. Thêm dòng thay thế (đúng quy ước side-effect
import các module plugin khác đang dùng trong cùng file):

```python
import il_features.file_io  # noqa: F401 - dang ky expr-builtin (read_file/file_exists) + call_stmt (write_file/append_file) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

- [ ] **Step 4: Xóa nhánh if/elif cũ trong `_expr_call`**

Tìm đoạn (dòng ~1720-1723):
```python
    if name == 'read_file':
        return _file_io_compile_read_file(args, scope, out, dtype, ctx)
    if name == 'file_exists':
        return _file_io_compile_file_exists(args, scope, out, dtype, ctx)
```

Xóa hoàn toàn 4 dòng này (dispatch giờ đi qua `EXPR_BUILTIN_CODEGEN` ở
nhánh `if name in EXPR_BUILTIN_CODEGEN:` đã có sẵn phía dưới, dòng
~1827).

- [ ] **Step 5: Build test file_io qua `.py` tree**

Tìm file test hiện có cho `read_file`/`file_exists`:

```bash
grep -rl "read_file\|file_exists" release/3.code/Testkit/*.tkv
```

Build + chạy file tìm được (nếu không có, tạo `/tmp/plan_t2_file_io.tkv`
tối thiểu):

```bash
cat > /tmp/plan_t2_file_io.tkv << 'EOF'
def run() -> "i32":
    write_file("/tmp/plan_t2_probe.txt", "hello")
    ok = file_exists("/tmp/plan_t2_probe.txt")
    content = read_file("/tmp/plan_t2_probe.txt")
    if ok == 1:
        if content == "hello":
            return 0
    return 1
EOF
cd "D:\Claude AI Project\TokenVector"
python tkv.py build /tmp/plan_t2_file_io.tkv --entry run --out /tmp/plan_t2_file_io.exe
/tmp/plan_t2_file_io.exe
echo "EXIT:$?"
```

Expected: `EXIT:0` (không phải lỗi build, không phải exit code khác 0).

- [ ] **Step 6: Chạy full regression qua `.py` tree (tất cả file trong `Testkit/`)**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  out="/tmp/plan_t2_reg_${base}.exe"
  python tkv.py build "$f" --entry run --out "$out" > "/tmp/plan_t2_build_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$out" 2>&1)
  if echo "$res" | grep -qi "^FAIL \|Exception"; then
    echo "=== $base ==="; echo "$res" | tail -5
  else
    echo "OK $base"
  fi
done
```

Expected: mọi dòng `OK <ten>`, ngoại trừ `path_isfile_isdir_test` (đã
xác nhận PRE-EXISTING fail, không liên quan) — nếu có file khác FAIL,
dừng lại và sửa trước khi qua Task tiếp theo.

- [ ] **Step 7: Mirror sang `.tkv` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
diff compiler/il_features/file_io.py release/3.code/compiler/il_features/file_io.tkv
```

`.tkv` tree đã có phân kỳ SẴN từ Task `sys.argv` (thêm nhánh fallback
`EXPR_BUILTIN_DTYPE` khác `.py` tree) — dùng Edit áp đúng thay đổi ở
Step 2/3/4 vào `release/3.code/compiler/il_features/file_io.tkv` (giữ
nguyên phần khác biệt sẵn có), KHÔNG `cp` đè cả file. Với
`il_codegen.tkv`, kiểm tra diff trước:

```bash
diff compiler/il_codegen.py release/3.code/compiler/il_codegen.tkv | head -30
```

Nếu vùng quanh dòng import file_io/nhánh if `read_file`/`file_exists`
KHÔNG có khác biệt so với `.py` tree (chỉ có thể có khác biệt ở NHỮNG
đoạn code KHÁC không liên quan Task này), áp đúng patch Step 3/4 bằng
Edit (không `cp` toàn file, tránh lặp lại lỗi ghi đè `il_codegen.tkv` đã
xảy ra 1 lần ở phiên trước).

- [ ] **Step 8: Commit KHI người dùng nói "commit đi" (không tự ý commit)**

```bash
git add compiler/il_features/file_io.py compiler/il_codegen.py compiler/il_dispatch.py \
        release/3.code/compiler/il_features/file_io.tkv release/3.code/compiler/il_codegen.tkv \
        release/3.code/compiler/il_dispatch.tkv
git commit -m "refactor(compiler): migrate file_io read_file/file_exists sang register_expr_builtin

Phase tach tkvc.exe thanh core+plugin: bo import cung il_features.file_io
trong il_codegen.py, chuyen sang dang ky qua register_expr_builtin (co
che da dung cho ~15+ module khac) - dieu kien can de file nay tach ra
khoi tkvc.exe duoc o Task sau. Hanh vi IL sinh ra khong doi, xac nhan
qua full regression .py tree.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Migrate `stdlib_math.py`/`stdlib_math_trig.py` sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/stdlib_math.py`, `compiler/il_features/stdlib_math_trig.py`
- Modify: `compiler/il_codegen.py:84-90` (xóa import `stdlib_math`/`stdlib_math_trig`), `:169-182` (`_MATH_FUNCS` dict), `:1724-1731` (if/elif `pow`/`math_pi`/`math_e`/`math_gcd`), `:1770-1790` (nhánh `_MATH_FUNCS`)
- Mirror: `release/3.code/compiler/il_features/stdlib_math.tkv`, `stdlib_math_trig.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: `pow`/`math_pi`/`math_e`/`math_gcd`/toàn bộ tên trong `_MATH_FUNCS` cũ (`exp`/`sqrt`/`tanh`/`sin`/`cos`/`floor`/`ceil`/`log`/`round`, cộng bất kỳ tên nào `stdlib_math_trig.py` thêm) đăng ký qua `EXPR_BUILTIN_CODEGEN`. `abs` GIỮ NGUYÊN trong core (không migrate — gắn với `int_type.py`, không thuộc module thư viện nào).

- [ ] **Step 1: Đọc lại 2 file nguồn để xác nhận nội dung chính xác**

```bash
cd "D:\Claude AI Project\TokenVector"
cat compiler/il_features/stdlib_math_trig.py
grep -n "^def compile_" compiler/il_features/stdlib_math.py
```

Expected: `stdlib_math_trig.py` export 1 dict tên `EXTRA_FUNCS` (dtype:
tên DSL → tên method .NET, giống cấu trúc `_MATH_FUNCS`). `stdlib_math.py`
có 4 hàm: `compile_math_pi`, `compile_math_e`, `compile_math_gcd`,
`compile_pow`.

- [ ] **Step 2: Viết hàm dispatch dùng chung cho `_MATH_FUNCS` (1-tham-số, gọi `System.Math`) trong `stdlib_math.py`**

Thêm vào CUỐI `compiler/il_features/stdlib_math.py`:

```python
from il_core import IL_LDC_OP as _IL_LDC_OP
from il_dispatch import register_expr_builtin

# _MATH_FUNCS (2026-08-12, Phase tach tkvc.exe thanh plugin): danh sach
# ham 1-tham-so goi thang System.Math, TRUOC DAY dinh nghia LITERAL
# trong il_codegen.py roi .update() them tu stdlib_math_trig.py's
# EXTRA_FUNCS - nay CHUYEN HAN vao day (module thu vien) de il_codegen.py
# khong con giu literal nao ve danh sach ham toan hoc, chi con 1 diem
# dang ky trung tam. GIU NGUYEN cach anh xa cu (chi co overload float64,
# conv.r8 truoc goi / conv nguoc lai sau goi neu dtype!='f64').
_MATH_FUNCS = {'exp': 'Exp', 'sqrt': 'Sqrt', 'tanh': 'Tanh', 'sin': 'Sin', 'cos': 'Cos',
               'floor': 'Floor', 'ceil': 'Ceiling', 'log': 'Log', 'round': 'Round'}


def register_math_extra_funcs(extra_dict):
    """Goi boi stdlib_math_trig.py (va bat ky module 'ham toan hoc 1-tham-
    so' nao khac sau nay) de gop them vao _MATH_FUNCS - THAY THE cho
    cach cu 'il_codegen.py tu import EXTRA_FUNCS roi .update() thang vao
    dict cua chinh no' (doi huong phu thuoc: truoc day il_codegen.py biet
    ve stdlib_math_trig, nay stdlib_math_trig biet ve stdlib_math qua
    ham nay, il_codegen.py khong can biet ca hai)."""
    _MATH_FUNCS.update(extra_dict)


def _make_math_func_compiler(method_name):
    def _compile(args, scope, out, dtype, ctx):
        if len(args) != 1:
            raise SyntaxError(f"il_codegen: ham toan hoc chi nhan dung 1 tham so")
        ctx['compile_expr'](args[0], scope, out, dtype, ctx)
        out.append('    conv.r8')
        out.append(f'    call float64 [mscorlib]System.Math::{method_name}(float64)')
        if dtype != 'f64':
            out.append(f'    {_IL_LDC_OP[dtype].replace("ldc.", "conv.")}')
    return _compile


def _register_all_math_funcs():
    """Dang ky TOAN BO _MATH_FUNCS qua register_expr_builtin - goi 1 LAN
    DUY NHAT luc module nap XONG (sau khi stdlib_math_trig.py da kip
    .update() vao _MATH_FUNCS qua register_math_extra_funcs - xem thu tu
    import trong stdlib_math_trig.py: PHAI import stdlib_math truoc roi
    moi goi register_math_extra_funcs). return_dtype=None vi ham tu
    widen theo dtype yeu cau (giong pow/math_pi/... ben duoi), khong can
    EXPR_BUILTIN_DTYPE lam gi them."""
    for name, method_name in _MATH_FUNCS.items():
        register_expr_builtin(name, _make_math_func_compiler(method_name), None)


def compile_math_pi(args, scope, out, dtype, ctx):
    ...  # (giu nguyen than ham cu, khong doi)


def compile_math_e(args, scope, out, dtype, ctx):
    ...  # (giu nguyen than ham cu, khong doi)


def compile_math_gcd(args, scope, out, dtype, ctx):
    ...  # (giu nguyen than ham cu, khong doi)


def compile_pow(args, scope, out, dtype, ctx):
    ...  # (giu nguyen than ham cu, khong doi)


register_expr_builtin('pow', compile_pow, None)
register_expr_builtin('math_pi', compile_math_pi, 'f64')
register_expr_builtin('math_e', compile_math_e, 'f64')
register_expr_builtin('math_gcd', compile_math_gcd, 'i64')
_register_all_math_funcs()
```

**LƯU Ý QUAN TRỌNG khi thực thi Step 2 thật (không phải chỉ chép plan)**:
đoạn `...  # (giu nguyen than ham cu, khong doi)` ở trên là CHỖ ĐÁNH DẤU
trong plan này để khỏi chép lại 40 dòng code đã đọc ở Task trước (xem
`compile_pow`/`compile_math_pi`/`compile_math_e`/`compile_math_gcd` đầy
đủ trong `compiler/il_features/stdlib_math.py` HIỆN TẠI trước khi sửa) —
khi làm THẬT, KHÔNG xóa 4 hàm này, chỉ THÊM đoạn code mới phía dưới
chúng (giữ nguyên định nghĩa hàm, KHÔNG thay thân hàm bằng `...`).

Vị trí chèn: đoạn code mới (từ `from il_core import IL_LDC_OP` tới hết
`_register_all_math_funcs()` + 4 dòng `register_expr_builtin` cuối) đặt
NGAY SAU 4 hàm `compile_math_pi`/`compile_math_e`/`compile_math_gcd`/
`compile_pow` đã có sẵn trong file, KHÔNG chèn xen giữa chúng.

- [ ] **Step 3: Sửa `stdlib_math_trig.py` gọi `register_math_extra_funcs` thay vì chỉ export `EXTRA_FUNCS`**

Đọc nội dung hiện tại:

```bash
cat compiler/il_features/stdlib_math_trig.py
```

Thêm vào CUỐI file (sau dòng định nghĩa `EXTRA_FUNCS = {...}`):

```python
from il_features.stdlib_math import register_math_extra_funcs

register_math_extra_funcs(EXTRA_FUNCS)
```

- [ ] **Step 4: Xóa import + literal `_MATH_FUNCS` + 4 dòng if/elif `pow`/`math_pi`/`math_e`/`math_gcd` trong `compiler/il_codegen.py`**

Tìm và xóa (dòng ~84-90):
```python
from il_features.stdlib_math import (
    compile_pow as _stdlib_math_compile_pow,
    compile_math_pi as _stdlib_math_compile_math_pi,
    compile_math_e as _stdlib_math_compile_math_e,
    compile_math_gcd as _stdlib_math_compile_math_gcd,
)
from il_features.stdlib_math_trig import EXTRA_FUNCS as _stdlib_math_trig_extra_funcs
```

Thay bằng:
```python
import il_features.stdlib_math  # noqa: F401 - dang ky expr-builtin (pow/math_pi/math_e/math_gcd + toan bo _MATH_FUNCS) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
import il_features.stdlib_math_trig  # noqa: F401 - .update() them EXTRA_FUNCS vao _MATH_FUNCS cua stdlib_math.py qua side-effect luc import - PHAI import SAU stdlib_math (xem register_math_extra_funcs)
```

Tìm và xóa hoàn toàn (dòng ~169-182):
```python
_MATH_FUNCS = {'exp': 'Exp', 'sqrt': 'Sqrt', 'tanh': 'Tanh', 'sin': 'Sin', 'cos': 'Cos',
                'floor': 'Floor', 'ceil': 'Ceiling', 'log': 'Log', 'round': 'Round'}
_MATH_FUNCS.update(_stdlib_math_trig_extra_funcs)
```

**QUAN TRỌNG**: `_MATH_FUNCS` VẪN được dùng ở chỗ khác trong
`il_codegen.py` (dòng ~1770 `if name in _MATH_FUNCS or name == 'abs':`
và dòng ~1850 thông báo lỗi `f"{sorted(_MATH_FUNCS)}+abs, ..."`) — 2 chỗ
này PHẢI XÓA LUÔN ở Step 5 (không thể xóa định nghĩa `_MATH_FUNCS` mà
để sót chỗ dùng, sẽ lỗi `NameError` lúc build).

Tìm và xóa (dòng ~1724-1731):
```python
    if name == 'pow':
        return _stdlib_math_compile_pow(args, scope, out, dtype, ctx)
    if name == 'math_pi':
        return _stdlib_math_compile_math_pi(args, scope, out, dtype, ctx)
    if name == 'math_e':
        return _stdlib_math_compile_math_e(args, scope, out, dtype, ctx)
    if name == 'math_gcd':
        return _stdlib_math_compile_math_gcd(args, scope, out, dtype, ctx)
```

- [ ] **Step 5: Xóa nhánh `_MATH_FUNCS`/`abs` cũ, viết lại chỉ còn `abs` (giữ trong core)**

Tìm đoạn (dòng ~1770-1790):
```python
    if name in _MATH_FUNCS or name == 'abs':
        if len(args) != 1:
            raise SyntaxError(f"il_codegen: ham '{name}' chi nhan dung 1 tham so")
        if name == 'abs' and dtype == 'int':
            # Kieu 'int' (vo han chu so): System.Math::Abs KHONG co
            # overload nao nhan struct TkvInt - xem int_type.compile_abs.
            return _int_type.compile_abs(args[0], scope, out, ctx)
        _compile_expr(args[0], scope, out, dtype, ctx)
        if name == 'abs':
            # Math.Abs CO overload float32 rieng - khong can chuyen doi.
            out.append(f'    call {IL_SCALAR[dtype]} [mscorlib]System.Math::Abs({IL_SCALAR[dtype]})')
        else:
            # Cac ham con lai cua System.Math CHI co overload float64 -
            # phai conv.r8 truoc goi; chi conv nguoc lai neu dtype KHONG
            # phai f64 san (tranh conv.r4 sai khi dtype la f64).
            method = _MATH_FUNCS[name]
            out.append('    conv.r8')
            out.append(f'    call float64 [mscorlib]System.Math::{method}(float64)')
            if dtype != 'f64':
                out.append(f'    {IL_LDC_OP[dtype].replace("ldc.", "conv.")}')
        return
```

Thay bằng (CHỈ còn `abs`, nhánh `_MATH_FUNCS` đã chuyển sang
`EXPR_BUILTIN_CODEGEN`, dispatch tự động đi qua nhánh
`if name in EXPR_BUILTIN_CODEGEN:` có sẵn phía dưới):
```python
    if name == 'abs':
        if len(args) != 1:
            raise SyntaxError("il_codegen: ham 'abs' chi nhan dung 1 tham so")
        if dtype == 'int':
            # Kieu 'int' (vo han chu so): System.Math::Abs KHONG co
            # overload nao nhan struct TkvInt - xem int_type.compile_abs.
            return _int_type.compile_abs(args[0], scope, out, ctx)
        _compile_expr(args[0], scope, out, dtype, ctx)
        # Math.Abs CO overload float32 rieng - khong can chuyen doi.
        out.append(f'    call {IL_SCALAR[dtype]} [mscorlib]System.Math::Abs({IL_SCALAR[dtype]})')
        return
```

- [ ] **Step 6: Sửa thông báo lỗi còn tham chiếu `_MATH_FUNCS`**

Tìm dòng (~1850):
```python
        f"{sorted(_MATH_FUNCS)}+abs, cung khong co trong chuong trinh dang bien dich)")
```

Sửa thành (không còn `_MATH_FUNCS` để tham chiếu, dùng thông báo chung
chung hơn — danh sách builtin giờ nằm rải rác nhiều module, không còn 1
dict trung tâm để liệt kê):
```python
        f"cung khong phai builtin thu vien nao (str/pow/re_*/path_*/...), "
        f"cung khong co trong chuong trinh dang bien dich)")
```

- [ ] **Step 7: Build test math qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t3_math.exe
/tmp/plan_t3_math.exe
echo "EXIT:$?"
```

Expected: `=== math_extra_test: N/N PASS ===`, `EXIT:0`, không có `FAIL`.

- [ ] **Step 8: Chạy full regression qua `.py` tree (lặp lại lệnh Task 2 Step 6)**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  out="/tmp/plan_t3_reg_${base}.exe"
  python tkv.py build "$f" --entry run --out "$out" > "/tmp/plan_t3_build_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$out" 2>&1)
  if echo "$res" | grep -qi "^FAIL \|Exception"; then
    echo "=== $base ==="; echo "$res" | tail -5
  else
    echo "OK $base"
  fi
done
```

Expected: mọi dòng `OK <ten>` (trừ `path_isfile_isdir_test` pre-existing).

- [ ] **Step 9: Mirror sang `.tkv` tree (theo đúng quy trình Task 2 Step 7 — diff trước, Edit patch từng đoạn, KHÔNG `cp` đè `il_codegen.tkv`)**

```bash
cd "D:\Claude AI Project\TokenVector"
diff compiler/il_features/stdlib_math.py release/3.code/compiler/il_features/stdlib_math.tkv
diff compiler/il_features/stdlib_math_trig.py release/3.code/compiler/il_features/stdlib_math_trig.tkv
```

Nếu 2 diff trên KHÔNG có nội dung nào khác ngoài phần vừa sửa (2 file
này chưa từng phân kỳ trong các Task trước, khả năng cao giống hệt),
`cp` đè an toàn:
```bash
cp compiler/il_features/stdlib_math.py release/3.code/compiler/il_features/stdlib_math.tkv
cp compiler/il_features/stdlib_math_trig.py release/3.code/compiler/il_features/stdlib_math_trig.tkv
```

Với `il_codegen.tkv`, áp đúng patch Step 4/5/6 bằng Edit (không `cp` cả
file).

- [ ] **Step 10: Commit khi được yêu cầu**

```bash
git add compiler/il_features/stdlib_math.py compiler/il_features/stdlib_math_trig.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/stdlib_math.tkv release/3.code/compiler/il_features/stdlib_math_trig.tkv \
        release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): migrate stdlib_math/stdlib_math_trig sang register_expr_builtin

pow/math_pi/math_e/math_gcd + toan bo _MATH_FUNCS (exp/sqrt/tanh/sin/
cos/floor/ceil/log/round + EXTRA_FUNCS tu stdlib_math_trig) chuyen tu
if/elif hardcode trong _expr_call sang register_expr_builtin. _MATH_FUNCS
chuyen han vao stdlib_math.py (khong con la literal trong il_codegen.py),
stdlib_math_trig.py goi register_math_extra_funcs() thay vi bi
il_codegen.py .update() thang tu ben ngoai - doi huong phu thuoc, khong
con ai giu 'danh sach ham toan hoc' ngoai chinh stdlib_math.py. abs()
GIU trong core (gan voi int_type.py, khong thuoc module thu vien nao).
Hanh vi IL sinh ra khong doi, xac nhan qua full regression .py tree.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: Migrate `stdlib_random.py` sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/stdlib_random.py`
- Modify: `compiler/il_codegen.py:92-98` (xóa import), `:1732-1741` (xóa if/elif)
- Mirror: `release/3.code/compiler/il_features/stdlib_random.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: `random`/`randint`/`choice`/`uniform`/`randrange` đăng ký qua `EXPR_BUILTIN_CODEGEN`. `choice` cần `return_dtype_fn` (dtype phụ thuộc phần tử list, KHÔNG cố định) — dùng đúng pattern `_agg_elem_dtype` đã có ở `stdlib_aggregates.py`.

- [ ] **Step 1: Thêm `register_expr_builtin` vào cuối `compiler/il_features/stdlib_random.py`**

Sửa dòng import đầu file:
```python
from il_features.list_type import il_list_type
```
thành:
```python
from il_features.list_type import il_list_type
from il_dispatch import register_expr_builtin
```

Thêm vào CUỐI file:
```python
def _choice_dtype_fn(args, scope):
    """dtype tra ve cua choice(lst) PHU THUOC dtype phan tu 'lst' - khong
    co dinh, giong het cach _agg_elem_dtype cua stdlib_aggregates.py xu
    ly cho sum/min/max. Tra None neu chua suy duoc (fallback ve
    return_dtype='i32' dang ky ben duoi khi khong suy duoc gi hon)."""
    if len(args) != 1 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


register_expr_builtin('random', compile_random, 'f64')
register_expr_builtin('randint', compile_randint, 'i32')
register_expr_builtin('uniform', compile_uniform, 'f64')
register_expr_builtin('randrange', compile_randrange, 'i32')
register_expr_builtin('choice', compile_choice, 'i32', return_dtype_fn=_choice_dtype_fn)
```

- [ ] **Step 2: Xóa import + if/elif cũ trong `compiler/il_codegen.py`**

Xóa (dòng ~92-98):
```python
from il_features.stdlib_random import (
    compile_random as _stdlib_random_compile_random,
    compile_randint as _stdlib_random_compile_randint,
    compile_choice as _stdlib_random_compile_choice,
    compile_uniform as _stdlib_random_compile_uniform,
    compile_randrange as _stdlib_random_compile_randrange,
)
```

Thay bằng:
```python
import il_features.stdlib_random  # noqa: F401 - dang ky expr-builtin (random/randint/choice/uniform/randrange) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

Xóa (dòng ~1732-1741):
```python
    if name == 'random':
        return _stdlib_random_compile_random(args, scope, out, dtype, ctx)
    if name == 'randint':
        return _stdlib_random_compile_randint(args, scope, out, dtype, ctx)
    if name == 'choice':
        return _stdlib_random_compile_choice(args, scope, out, dtype, ctx)
    if name == 'uniform':
        return _stdlib_random_compile_uniform(args, scope, out, dtype, ctx)
    if name == 'randrange':
        return _stdlib_random_compile_randrange(args, scope, out, dtype, ctx)
```

- [ ] **Step 3: Xóa nhánh `'choice'` cũ trong `_infer_dtype` (nếu còn) — nay đã thay bằng `_choice_dtype_fn` đăng ký ở Step 1**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "name == 'choice'" compiler/il_codegen.py
```

Nếu grep ra dòng trong hàm `_infer_dtype` (khoảng dòng ~588-592, đoạn
`if name == 'choice': args = node[2]; if args and args[0][0] == 'var': return scope[args[0][1]][2].dtype`),
xóa đoạn đó — `EXPR_BUILTIN_DTYPE_FN['choice']` (đăng ký qua
`return_dtype_fn` ở Step 1) đã đảm nhiệm việc này qua nhánh
`if name in EXPR_BUILTIN_DTYPE_FN:` có sẵn trong `_infer_dtype` (xem
dòng ~593-596 `if name in EXPR_BUILTIN_DTYPE_FN: return EXPR_BUILTIN_DTYPE_FN[name](node[2], scope)`).

- [ ] **Step 4: Build test random qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/random_extend_test.tkv --entry run --out /tmp/plan_t4_random.exe
/tmp/plan_t4_random.exe
echo "EXIT:$?"
```

Expected: `=== random_extend_test: N/N PASS ===`, `EXIT:0`.

- [ ] **Step 5: Full regression `.py` tree (lặp lại vòng lặp Task 2 Step 6, đổi tiền tố log thành `plan_t4_`)**

- [ ] **Step 6: Mirror sang `.tkv` tree (diff trước, `cp` nếu không phân kỳ, Edit patch nếu `il_codegen.tkv` có phân kỳ)**

- [ ] **Step 7: Commit khi được yêu cầu**

```bash
git add compiler/il_features/stdlib_random.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/stdlib_random.tkv release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): migrate stdlib_random sang register_expr_builtin

random/randint/choice/uniform/randrange chuyen tu if/elif hardcode sang
register_expr_builtin. choice() dung return_dtype_fn (dtype phu thuoc
phan tu list nguon, khong co dinh) - cung pattern _agg_elem_dtype cua
stdlib_aggregates.py, thay cho nhanh rieng truoc day trong _infer_dtype.
Hanh vi IL sinh ra khong doi, xac nhan qua full regression .py tree.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: Migrate `stdlib_path.py` sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/stdlib_path.py`
- Modify: `compiler/il_codegen.py:99-106` (xóa import), `:1742-1753` (xóa if/elif)
- Mirror: `release/3.code/compiler/il_features/stdlib_path.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: `path_join`/`path_exists`/`path_basename`/`path_dirname`/`path_isfile`/`path_isdir` đăng ký qua `EXPR_BUILTIN_CODEGEN`, dtype cố định (`'str'` cho `path_join`/`path_basename`/`path_dirname`, `'i32'` cho `path_exists`/`path_isfile`/`path_isdir`).

- [ ] **Step 1: Thêm `register_expr_builtin` vào cuối `compiler/il_features/stdlib_path.py`**

Thêm import đầu file:
```python
from il_dispatch import register_expr_builtin
```

Thêm vào CUỐI file:
```python
register_expr_builtin('path_join', compile_path_join, 'str')
register_expr_builtin('path_exists', compile_path_exists, 'i32')
register_expr_builtin('path_basename', compile_path_basename, 'str')
register_expr_builtin('path_dirname', compile_path_dirname, 'str')
register_expr_builtin('path_isfile', compile_path_isfile, 'i32')
register_expr_builtin('path_isdir', compile_path_isdir, 'i32')
```

- [ ] **Step 2: Xóa import + if/elif cũ trong `compiler/il_codegen.py`**

Xóa (dòng ~99-106):
```python
from il_features.stdlib_path import (
    compile_path_join as _stdlib_path_compile_path_join,
    compile_path_exists as _stdlib_path_compile_path_exists,
    compile_path_basename as _stdlib_path_compile_path_basename,
    compile_path_dirname as _stdlib_path_compile_path_dirname,
    compile_path_isfile as _stdlib_path_compile_path_isfile,
    compile_path_isdir as _stdlib_path_compile_path_isdir,
)
```

Thay bằng:
```python
import il_features.stdlib_path  # noqa: F401 - dang ky expr-builtin (path_join/path_exists/path_basename/path_dirname/path_isfile/path_isdir) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

Xóa (dòng ~1742-1753):
```python
    if name == 'path_join':
        return _stdlib_path_compile_path_join(args, scope, out, dtype, ctx)
    if name == 'path_exists':
        return _stdlib_path_compile_path_exists(args, scope, out, dtype, ctx)
    if name == 'path_basename':
        return _stdlib_path_compile_path_basename(args, scope, out, dtype, ctx)
    if name == 'path_dirname':
        return _stdlib_path_compile_path_dirname(args, scope, out, dtype, ctx)
    if name == 'path_isfile':
        return _stdlib_path_compile_path_isfile(args, scope, out, dtype, ctx)
    if name == 'path_isdir':
        return _stdlib_path_compile_path_isdir(args, scope, out, dtype, ctx)
```

- [ ] **Step 3: Build test path qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/path_isfile_isdir_test.tkv --entry run --out /tmp/plan_t5_path.exe
/tmp/plan_t5_path.exe
```

Expected: `3/4 PASS` (giữ nguyên PRE-EXISTING fail `isfile_true` đã xác
nhận từ trước — KHÔNG phải regression mới, xem
`docs/PYTHON_GAP_CHECKLIST.md`'s ghi chú về file test này).

- [ ] **Step 4: Full regression `.py` tree (đổi tiền tố log thành `plan_t5_`)**

- [ ] **Step 5: Mirror sang `.tkv` tree**

- [ ] **Step 6: Commit khi được yêu cầu**

```bash
git add compiler/il_features/stdlib_path.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/stdlib_path.tkv release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): migrate stdlib_path sang register_expr_builtin

path_join/path_exists/path_basename/path_dirname/path_isfile/path_isdir
chuyen tu if/elif hardcode sang register_expr_builtin. Hanh vi IL sinh
ra khong doi, xac nhan qua full regression .py tree (path_isfile_isdir_test
van 3/4 PASS, fail con lai la PRE-EXISTING da xac nhan truoc do, khong
lien quan Task nay).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 6: Migrate `stdlib_xml.py` sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/stdlib_xml.py`
- Modify: `compiler/il_codegen.py:127` (xóa import), `:1754-1755` (xóa if)
- Mirror: `release/3.code/compiler/il_features/stdlib_xml.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: `xml_encode_name` đăng ký qua `EXPR_BUILTIN_CODEGEN`, dtype cố định `'str'`.

- [ ] **Step 1: Thêm `register_expr_builtin` vào cuối `compiler/il_features/stdlib_xml.py`**

Thêm dòng import đầu file, thêm dòng đăng ký cuối file:
```python
from il_dispatch import register_expr_builtin


def compile_xml_encode_name(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: xml_encode_name(s) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [System.Xml]System.Xml.XmlConvert::EncodeName(string)')


register_expr_builtin('xml_encode_name', compile_xml_encode_name, 'str')
```

(File hiện chỉ có 1 hàm — chỉ cần thêm import + 1 dòng đăng ký, KHÔNG
cần viết lại thân hàm `compile_xml_encode_name` đã có sẵn, ví dụ trên
chỉ để chỉ rõ VỊ TRÍ chèn dòng `register_expr_builtin` — chèn NGAY SAU
định nghĩa hàm hiện có trong file thật, không xóa/viết lại hàm.)

- [ ] **Step 2: Xóa import + if cũ trong `compiler/il_codegen.py`**

Xóa (dòng ~127):
```python
from il_features.stdlib_xml import compile_xml_encode_name as _stdlib_xml_compile_xml_encode_name
```

Thay bằng:
```python
import il_features.stdlib_xml  # noqa: F401 - dang ky expr-builtin (xml_encode_name) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

Xóa (dòng ~1754-1755):
```python
    if name == 'xml_encode_name':
        return _stdlib_xml_compile_xml_encode_name(args, scope, out, dtype, ctx)
```

- [ ] **Step 3: Build 1 test nhỏ dùng `xml_encode_name` qua `.py` tree**

```bash
cat > /tmp/plan_t6_xml.tkv << 'EOF'
__tkv_extern_assembly__ = "System.Xml"


def run() -> "i32":
    r = xml_encode_name("hello world")
    if r == "hello_x0020_world":
        return 0
    return 1
EOF
cd "D:\Claude AI Project\TokenVector"
python tkv.py build /tmp/plan_t6_xml.tkv --entry run --out /tmp/plan_t6_xml.exe
/tmp/plan_t6_xml.exe
echo "EXIT:$?"
```

Expected: `EXIT:0`.

- [ ] **Step 4: Full regression `.py` tree (đổi tiền tố log thành `plan_t6_`)**

- [ ] **Step 5: Mirror sang `.tkv` tree**

- [ ] **Step 6: Commit khi được yêu cầu**

```bash
git add compiler/il_features/stdlib_xml.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/stdlib_xml.tkv release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): migrate stdlib_xml sang register_expr_builtin

xml_encode_name chuyen tu if hardcode sang register_expr_builtin. Hanh
vi IL sinh ra khong doi, xac nhan qua full regression .py tree.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 7: Migrate `stdlib_re.py` sang `register_expr_builtin`

**Files:**
- Modify: `compiler/il_features/stdlib_re.py`
- Modify: `compiler/il_codegen.py:128-133` (xóa import), `:1756-1763` (xóa if/elif)
- Mirror: `release/3.code/compiler/il_features/stdlib_re.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: `re_match`/`re_search`/`re_fullmatch`/`re_sub` đăng ký qua `EXPR_BUILTIN_CODEGEN` (`'i32'` cho 3 cái đầu, `'str'` cho `re_sub`).

- [ ] **Step 1: Thêm `register_expr_builtin` vào cuối `compiler/il_features/stdlib_re.py`**

Thêm vào CUỐI file:
```python
from il_dispatch import register_expr_builtin

register_expr_builtin('re_match', compile_re_match, 'i32')
register_expr_builtin('re_search', compile_re_search, 'i32')
register_expr_builtin('re_fullmatch', compile_re_fullmatch, 'i32')
register_expr_builtin('re_sub', compile_re_sub, 'str')
```

- [ ] **Step 2: Xóa import + if/elif cũ trong `compiler/il_codegen.py`**

Xóa (dòng ~128-133):
```python
from il_features.stdlib_re import (
    compile_re_match as _stdlib_re_compile_re_match,
    compile_re_sub as _stdlib_re_compile_re_sub,
    compile_re_search as _stdlib_re_compile_re_search,
    compile_re_fullmatch as _stdlib_re_compile_re_fullmatch,
)
```

Thay bằng:
```python
import il_features.stdlib_re  # noqa: F401 - dang ky expr-builtin (re_match/re_sub/re_search/re_fullmatch) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

Xóa (dòng ~1756-1763):
```python
    if name == 're_match':
        return _stdlib_re_compile_re_match(args, scope, out, dtype, ctx)
    if name == 're_sub':
        return _stdlib_re_compile_re_sub(args, scope, out, dtype, ctx)
    if name == 're_search':
        return _stdlib_re_compile_re_search(args, scope, out, dtype, ctx)
    if name == 're_fullmatch':
        return _stdlib_re_compile_re_fullmatch(args, scope, out, dtype, ctx)
```

- [ ] **Step 3: Build test re qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/re_extend_test.tkv --entry run --out /tmp/plan_t7_re.exe
/tmp/plan_t7_re.exe
```

Expected: `4/4 PASS`.

- [ ] **Step 4: Full regression `.py` tree (đổi tiền tố log thành `plan_t7_`)**

- [ ] **Step 5: Mirror sang `.tkv` tree**

- [ ] **Step 6: Commit khi được yêu cầu**

```bash
git add compiler/il_features/stdlib_re.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/stdlib_re.tkv release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): migrate stdlib_re sang register_expr_builtin

re_match/re_search/re_fullmatch/re_sub chuyen tu if/elif hardcode sang
register_expr_builtin. Hanh vi IL sinh ra khong doi, xac nhan qua full
regression .py tree (re_extend_test 4/4 PASS).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 8: Tách `string_feature.py` thành core (index/len/concat/compare) + `string_builtin.py` (library, `str()`/`fmt_float()`)

**Files:**
- Modify: `compiler/il_features/string_feature.py` (xóa `compile_str_builtin`/`compile_fmt_float`, giữ 4 hàm core)
- Create: `compiler/il_features/string_builtin.py` (chứa 2 hàm vừa xóa + `register_expr_builtin`)
- Modify: `compiler/il_codegen.py:48-54` (bớt import), `:1764-1767` (xóa if)
- Mirror: `release/3.code/compiler/il_features/string_feature.tkv`, tạo `string_builtin.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Consumes: `register_expr_builtin` (Task 1).
- Produces: file MỚI `string_builtin.py` — nhóm LIBRARY (tách được, đúng phân loại mục 3.2 của spec `docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md`). `string_feature.py` ở lại core, CHỈ còn `compile_index_str`/`compile_len_str`/`compile_binop_concat`/`compile_compare_str` (`il_codegen.py` vẫn `from il_features.string_feature import` 4 hàm này như cũ, KHÔNG đổi).

- [ ] **Step 1: Đọc toàn bộ `compiler/il_features/string_feature.py` để xác định RANH GIỚI cắt chính xác**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "^def \|^import\|^from" compiler/il_features/string_feature.py
```

Xác định: hàm `compile_str_builtin` (bắt đầu dòng 73, đã đọc ở phiên
trước — kết thúc trước hàm tiếp theo trong file) và `compile_fmt_float`
(bắt đầu dòng 257) là 2 hàm cần CHUYỂN sang file mới. Ghi lại dòng bắt
đầu/kết thúc chính xác của CẢ HAI hàm bằng cách đọc file thật (số dòng ở
trên là ước lượng từ phiên trước, PHẢI xác nhận lại bằng `grep -n`
trước khi cắt, vì file có thể đã đổi từ đó tới giờ).

- [ ] **Step 2: Tạo file mới `compiler/il_features/string_builtin.py`**

```python
# -*- coding: utf-8 -*-
"""str()/fmt_float() (Phase "tach tkvc.exe thanh plugin", 2026-08-12) -
TACH RA khoi string_feature.py (file do GIU LAI compile_index_str/
compile_len_str/compile_binop_concat/compile_compare_str - ngu nghia
kieu 'str' CO BAN cua ngon ngu, khong tach duoc, xem docstring dau file
do). 2 ham nay la BUILTIN DANG HAM ('str(x)'/'fmt_float(x,n)'), thuoc
nhom "thu vien" tach duoc theo thiet ke o
docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md
muc 3.2."""
from il_dispatch import register_expr_builtin

# (dan toan bo than ham compile_str_builtin + compile_fmt_float TU
# string_feature.py sang day - GIU NGUYEN 100% code, chi doi VI TRI file,
# khong doi 1 dong logic nao ben trong 2 ham)


register_expr_builtin('str', compile_str_builtin, 'str')
register_expr_builtin('fmt_float', compile_fmt_float, 'str')
```

Khi làm THẬT: copy nguyên văn 2 hàm `compile_str_builtin` và
`compile_fmt_float` (đọc được ở Step 1) vào giữa dòng `from il_dispatch
import register_expr_builtin` và 2 dòng `register_expr_builtin(...)`
cuối — bao gồm MỌI import phụ mà 2 hàm này cần bên trong thân hàm (ví
dụ `import il_features.int_type as _int_type`, `import il_features.tkvstr
as _tkvstr` — các dòng `import` LỒNG TRONG thân hàm `compile_str_builtin`
đã thấy ở lần đọc trước, giữ nguyên vị trí trong thân hàm, không cần đưa
lên đầu file).

- [ ] **Step 3: Xóa `compile_str_builtin`/`compile_fmt_float` khỏi `compiler/il_features/string_feature.py`**

Xóa đúng 2 khối hàm đã xác định ở Step 1 (từ dòng bắt đầu tới dòng cuối
cùng của mỗi hàm, không xóa hàm liền kề).

- [ ] **Step 4: Sửa `compiler/il_codegen.py` — bớt import, thêm import module mới, xóa if cũ**

Tìm đoạn (dòng ~48-54):
```python
from il_features.string_feature import (
    compile_index_str as _string_compile_index_str, compile_len_str as _string_compile_len_str,
    compile_str_builtin as _string_compile_str_builtin,
    compile_fmt_float as _string_compile_fmt_float,
    compile_binop_concat as _string_compile_binop_concat,
    compile_compare_str as _string_compile_compare_str,
)
```

Sửa thành (BỚT 2 dòng `compile_str_builtin`/`compile_fmt_float`, GIỮ
NGUYÊN 4 dòng còn lại):
```python
from il_features.string_feature import (
    compile_index_str as _string_compile_index_str, compile_len_str as _string_compile_len_str,
    compile_binop_concat as _string_compile_binop_concat,
    compile_compare_str as _string_compile_compare_str,
)
import il_features.string_builtin  # noqa: F401 - dang ky expr-builtin (str()/fmt_float()) qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

Xóa (dòng ~1764-1767):
```python
    if name == 'str':
        return _string_compile_str_builtin(args, scope, out, dtype, ctx)
    if name == 'fmt_float':
        return _string_compile_fmt_float(args, scope, out, dtype, ctx)
```

- [ ] **Step 5: Build 1 test dùng `str()` cơ bản qua `.py` tree (str() dùng RẤT NHIỀU trong hầu hết test — chạy `funcvar_test` là đủ phủ)**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/funcvar_test.tkv --entry run --out /tmp/plan_t8_funcvar.exe
/tmp/plan_t8_funcvar.exe
```

Expected: `5/5 PASS` (khớp kết quả đã ghi trong checklist cho file này
từ phiên trước).

- [ ] **Step 6: Full regression `.py` tree — QUAN TRỌNG NHẤT trong toàn bộ Task này vì `str()` được dùng ở HẦU HẾT mọi file test (đổi tiền tố log thành `plan_t8_`)**

Chạy đúng vòng lặp ở Task 2 Step 6. Vì `str()` xuất hiện trong gần như
mọi test, đây là bài kiểm tra ĐẦY ĐỦ NHẤT xem việc tách file có làm vỡ
gì không — PHẢI 100% các dòng ra `OK` (trừ `path_isfile_isdir_test`
pre-existing) trước khi qua Step tiếp theo, KHÔNG được bỏ qua fail nào ở
Task này.

- [ ] **Step 7: Mirror sang `.tkv` tree — tạo file mới `string_builtin.tkv`, sửa `string_feature.tkv`, patch `il_codegen.tkv`**

```bash
cd "D:\Claude AI Project\TokenVector"
cp compiler/il_features/string_builtin.py release/3.code/compiler/il_features/string_builtin.tkv
diff compiler/il_features/string_feature.py release/3.code/compiler/il_features/string_feature.tkv
```

Nếu diff không có gì khác ngoài phần vừa xóa, `cp` đè an toàn; nếu có
phân kỳ trước đó, dùng Edit áp đúng thay đổi Step 3 vào bản `.tkv`.
`il_codegen.tkv` patch bằng Edit như các Task trước.

- [ ] **Step 8: Commit khi được yêu cầu**

```bash
git add compiler/il_features/string_feature.py compiler/il_features/string_builtin.py compiler/il_codegen.py \
        release/3.code/compiler/il_features/string_feature.tkv release/3.code/compiler/il_features/string_builtin.tkv \
        release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): tach str()/fmt_float() ra string_builtin.py (module thu vien moi)

string_feature.py truoc day gom CA ngu nghia kieu str co ban (index/len/
concat/compare - khong tach duoc, gan voi bo dich bieu thuc loi) LAN 2
builtin dang ham (str()/fmt_float() - tach duoc). Tach rieng thanh
string_builtin.py (module MOI, dang ky qua register_expr_builtin) de
string_feature.py o lai core con string_builtin.py chuyen sang nhom thu
vien nap dong. Hanh vi IL sinh ra khong doi, xac nhan qua full regression
.py tree (str() dung trong hau het test, kiem tra day du nhat trong
Phase nay).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 9: `string_methods_batch3.py`'s `RETURN_DTYPE` → callback đăng ký (thay vì đọc dict trực tiếp)

**Files:**
- Modify: `compiler/il_features/string_methods_batch3.py`
- Modify: `compiler/il_codegen.py:91` (xóa import trực tiếp `RETURN_DTYPE`, chỗ dùng biến `_STR_METHOD_RETURN_DTYPE`)
- Mirror: `release/3.code/compiler/il_features/string_methods_batch3.tkv`, `release/3.code/compiler/il_codegen.tkv`

**Interfaces:**
- Produces: `il_dispatch.py` có thêm 1 dict module-level mới `STR_METHOD_RETURN_DTYPE` (đặt CẠNH `EXPR_METHOD_DTYPE` đã có) + hàm `register_str_method_return_dtype(mapping)` — `il_codegen.py` đọc qua `from il_dispatch import STR_METHOD_RETURN_DTYPE` thay vì import trực tiếp `RETURN_DTYPE` từ `string_methods_batch3.py`.

- [ ] **Step 1: Xác nhận cách `_STR_METHOD_RETURN_DTYPE` được dùng trong `il_codegen.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "_STR_METHOD_RETURN_DTYPE" compiler/il_codegen.py
```

Expected: 1 dòng import (~91) + ít nhất 1 chỗ dùng (đã thấy ở phiên
trước, dòng ~451: `return _STR_METHOD_RETURN_DTYPE.get(node[2], 'str')`
trong `_infer_dtype`'s nhánh `method_call_expr`).

- [ ] **Step 2: Thêm dict + hàm đăng ký vào `compiler/il_dispatch.py`**

Thêm vào CUỐI `compiler/il_dispatch.py`:
```python
# STR_METHOD_RETURN_DTYPE (2026-08-12, Phase tach tkvc.exe thanh plugin):
# TRUOC DAY il_codegen.py import THANG dict 'RETURN_DTYPE' tu
# string_methods_batch3.py roi doc qua bien _STR_METHOD_RETURN_DTYPE -
# nay chuyen thanh 1 dict trung tam trong il_dispatch.py (giong
# EXPR_METHOD_DTYPE), string_methods_batch3.py TU GOI ham dang ky ben
# duoi de nop mapping cua no vao, il_codegen.py chi con doc dict o day
# (khong con import truc tiep module string_methods_batch3 nua).
STR_METHOD_RETURN_DTYPE = {}


def register_str_method_return_dtype(mapping):
    STR_METHOD_RETURN_DTYPE.update(mapping)
```

- [ ] **Step 3: Sửa `compiler/il_features/string_methods_batch3.py` gọi hàm đăng ký mới**

```bash
grep -n "^RETURN_DTYPE" compiler/il_features/string_methods_batch3.py
```

Thêm vào CUỐI file (sau dòng định nghĩa `RETURN_DTYPE = {...}`):
```python
from il_dispatch import register_str_method_return_dtype

register_str_method_return_dtype(RETURN_DTYPE)
```

- [ ] **Step 4: Sửa `compiler/il_codegen.py`**

Tìm (dòng ~91):
```python
from il_features.string_methods_batch3 import RETURN_DTYPE as _STR_METHOD_RETURN_DTYPE
```

Thay bằng:
```python
from il_dispatch import STR_METHOD_RETURN_DTYPE as _STR_METHOD_RETURN_DTYPE
import il_features.string_methods_batch3  # noqa: F401 - nop RETURN_DTYPE vao il_dispatch.STR_METHOD_RETURN_DTYPE qua side-effect luc import (Phase "tach tkvc.exe thanh plugin", 2026-08-12)
```

- [ ] **Step 5: Build test dùng method string (vd `.find`/`.startswith`) qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/find_strip_extend_test.tkv --entry run --out /tmp/plan_t9_str.exe
/tmp/plan_t9_str.exe
```

Expected: PASS toàn bộ (khớp kết quả cũ).

- [ ] **Step 6: Full regression `.py` tree (đổi tiền tố log thành `plan_t9_`)**

- [ ] **Step 7: Mirror sang `.tkv` tree**

- [ ] **Step 8: Commit khi được yêu cầu**

```bash
git add compiler/il_dispatch.py compiler/il_features/string_methods_batch3.py compiler/il_codegen.py \
        release/3.code/compiler/il_dispatch.tkv release/3.code/compiler/il_features/string_methods_batch3.tkv \
        release/3.code/compiler/il_codegen.tkv
git commit -m "refactor(compiler): string_methods_batch3's RETURN_DTYPE qua dang ky trung tam

Doi tu 'il_codegen.py import thang dict RETURN_DTYPE tu module' sang 'module
tu goi register_str_method_return_dtype() nop vao il_dispatch.py' - dieu
kien can cuoi cung de string_methods_batch3.py tach duoc khoi tkvc.exe
(khong con bi il_codegen.py import truc tiep ten bien). Hanh vi khong
doi, xac nhan qua full regression .py tree.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 10: Viết `compiler/plugin_loader.py` — module nạp plugin động (core, luôn nhúng vào `tkvc.exe`)

**Files:**
- Create: `compiler/plugin_loader.py`
- Mirror: tạo `release/3.code/compiler/plugin_loader.tkv`

**Interfaces:**
- Produces: `discover_plugin_dir() -> str` (đường dẫn thư mục plugin, tùy chế độ dev/frozen), `load_plugins(plugin_dir=None) -> list[str]` (import động mọi `*.py` trong thư mục, trả về danh sách tên file đã nạp — dùng cho test/log).

- [ ] **Step 1: Viết file `compiler/plugin_loader.py`**

```python
# -*- coding: utf-8 -*-
"""Nap dong cac module 'thu vien' (Phase 'tach tkvc.exe thanh core+plugin',
2026-08-12, xem docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md).

2 CHE DO xac dinh thu muc plugin (discover_plugin_dir):
- Che do dev (`python tkv.py build ...`, chay truc tiep tu source, KHONG
  qua PyInstaller): thu muc plugin = 'compiler/il_features/' NHU HIEN TAI
  - khong doi hanh vi cay .py goc, chi doi CACH NAP (dong thay vi import
    cung trong il_codegen.py).
- Che do tkvc.exe dong goi (PyInstaller frozen, phat hien qua co chuan
  'sys.frozen'): thu muc plugin = 'il_features/' dat CANH file .exe dang
  chay (sys.executable).

load_plugins() quet moi file '*.py' trong thu muc do, import DONG qua
importlib.util (KHONG qua 'import' tinh cua Python - file thu vien
KHONG nam trong package 'compiler.il_features' nua sau khi build script
tach staging, xem build_tkvc.ps1). Moi file plugin TU chay cac lenh
register_* cua no luc duoc exec (side-effect, giong het co che import
cung TRUOC DAY - CHI doi CACH file duoc doc vao, khong doi code BEN
TRONG tung module thu vien).

QUAN TRONG: trong che do dev, thu muc plugin VAN la 'compiler/il_features/'
- noi CUNG chua ca nhom "core-dependency" (list_type.py, string_feature.py,
...) LAN nhom "thu vien" (stdlib_math.py, stdlib_re.py, ...). import dong
CA HAI nhom la AN TOAN (Python cache import - file da duoc il_codegen.py
import truc tiep truoc do se KHONG bi nap lai lan 2, importlib chi tra
ve module DA CO trong sys.modules) - khong can phan biet 2 nhom o day."""
import importlib.util
import os
import sys


def discover_plugin_dir():
    if getattr(sys, 'frozen', False):
        return os.path.join(os.path.dirname(sys.executable), 'il_features')
    # Che do dev: file nay nam tai 'compiler/plugin_loader.py', thu muc
    # plugin la 'compiler/il_features/' (cung thu muc cha).
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'il_features')


def load_plugins(plugin_dir=None):
    """Tra ve danh sach TEN FILE (khong duong dan) da nap thanh cong -
    rong neu thu muc khong ton tai (KHONG bao loi - chuong trinh dang
    bien dich co the khong dung builtin thu vien nao ca, thu muc rong/
    khong co la hop le)."""
    if plugin_dir is None:
        plugin_dir = discover_plugin_dir()
    if not os.path.isdir(plugin_dir):
        return []
    loaded = []
    for fname in sorted(os.listdir(plugin_dir)):
        if not fname.endswith('.py') or fname.startswith('_'):
            continue
        fpath = os.path.join(plugin_dir, fname)
        mod_name = f'_tkv_plugin_{fname[:-3]}'
        if mod_name in sys.modules:
            continue
        spec = importlib.util.spec_from_file_location(mod_name, fpath)
        module = importlib.util.module_from_spec(spec)
        sys.modules[mod_name] = module
        try:
            spec.loader.exec_module(module)
        except Exception as exc:
            del sys.modules[mod_name]
            raise ImportError(
                f"plugin_loader: nap thu vien '{fname}' that bai ({type(exc).__name__}: "
                f"{exc}) - file nam o {fpath!r}") from exc
        loaded.append(fname)
    return loaded
```

- [ ] **Step 2: Viết test độc lập cho `plugin_loader.py` (KHÔNG phải file `.tkv`, đây là test Python thuần cho module Python mới)**

```bash
cat > /tmp/plan_t10_test_plugin_loader.py << 'EOF'
import sys, os
sys.path.insert(0, r'D:\Claude AI Project\TokenVector\compiler')
import plugin_loader

# Test 1: discover_plugin_dir() che do dev tra dung thu muc.
d = plugin_loader.discover_plugin_dir()
assert d.endswith(os.path.join('compiler', 'il_features')), f"sai duong dan: {d}"
assert os.path.isdir(d), f"thu muc khong ton tai: {d}"
print("PASS discover_plugin_dir (dev mode)")

# Test 2: load_plugins() nap duoc it nhat 1 file, khong bao loi.
loaded = plugin_loader.load_plugins()
assert len(loaded) > 10, f"chi nap duoc {len(loaded)} file, ky vong > 10 (co ~40+ file trong il_features/)"
assert 'stdlib_math.py' in loaded, "khong thay stdlib_math.py trong danh sach da nap"
print(f"PASS load_plugins nap {len(loaded)} file")

# Test 3: goi load_plugins() LAN 2 khong bao loi (file da nap lan 1 bi
# bo qua qua kiem tra sys.modules, khong nap lai/khong crash vi trung dang ky).
loaded2 = plugin_loader.load_plugins()
assert loaded2 == [], f"lan 2 phai tra danh sach RONG (moi file da nap o lan 1), nhung tra {loaded2}"
print("PASS load_plugins lan 2 khong nap lai (idempotent)")
EOF
python /tmp/plan_t10_test_plugin_loader.py
```

Expected: 3 dòng `PASS` liên tiếp, không có `AssertionError`/`ImportError`
nào. Nếu `ImportError` xảy ra ở Test 2, thông báo lỗi từ `plugin_loader.py`
sẽ nêu rõ file nào gây lỗi — thường là do 1 file trong `il_features/`
phụ thuộc 1 module KHÁC trong cùng thư mục mà chưa được nạp (thứ tự
alphabet khác thứ tự import cứng cũ) — nếu gặp, ghi lại tên file/lỗi cụ
thể, đây CHÍNH LÀ loại rủi ro đã lường trước ở mục 4.3 của spec, xử lý ở
Task 11 (không sửa vội ở đây, thu thập đủ danh sách trước).

- [ ] **Step 3: Nếu Step 2 lỗi do thứ tự import — ghi log lỗi, KHÔNG tự sửa ở Task này**

Nếu gặp lỗi, chạy lại với traceback đầy đủ để xác định module nào phụ
thuộc module nào:

```bash
python -c "
import sys
sys.path.insert(0, r'D:\Claude AI Project\TokenVector\compiler')
import plugin_loader
plugin_loader.load_plugins()
" 2>&1 | tail -30
```

Ghi lại (không sửa) — Task 11 sẽ xử lý toàn bộ vấn đề thứ tự import 1
lần, tránh sửa rời rạc từng lỗi một cách vá víu.

- [ ] **Step 4: Copy `compiler/plugin_loader.py` sang `release/3.code/compiler/plugin_loader.tkv`**

```bash
cd "D:\Claude AI Project\TokenVector"
cp compiler/plugin_loader.py release/3.code/compiler/plugin_loader.tkv
```

(File mới hoàn toàn, không có gì để diff/phân kỳ.)

- [ ] **Step 5: Commit khi được yêu cầu**

```bash
git add compiler/plugin_loader.py release/3.code/compiler/plugin_loader.tkv
git commit -m "feat(compiler): them plugin_loader.py - nap dong module thu vien

Module MOI (core, luon nhung vao tkvc.exe): discover_plugin_dir() xac
dinh thu muc plugin theo che do dev (compiler/il_features/ nhu hien tai)
hoac che do tkvc.exe dong goi (thu muc il_features/ canh file .exe,
phat hien qua co sys.frozen chuan cua PyInstaller). load_plugins() quet
+ import dong moi file .py trong thu muc do qua importlib.util, moi file
tu chay cac lenh register_* cua no (side-effect, KHONG doi code trong
tung module thu vien) - idempotent (goi lai lan 2 khong nap lai file da
nap). CHUA wire vao tkv_compile.py (Task sau).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 11: Xóa toàn bộ khối `import il_features.X` thủ công trong `il_codegen.py`, thay bằng gọi `load_plugins()`

Đây là bước RỦI RO NHẤT trong toàn bộ plan (đổi từ thứ tự import CỐ ĐỊNH
tay viết sang thứ tự QUÉT THƯ MỤC theo alphabet) — làm CẨN THẬN, từng
bước nhỏ, test đầy đủ trước khi qua Task sau.

**Files:**
- Modify: `compiler/il_codegen.py` (xóa toàn bộ khối import side-effect còn lại — CHỈ những dòng `import il_features.X  # noqa: F401` thuần side-effect, GIỮ NGUYÊN mọi dòng `from il_features.Y import ten_ham` — những dòng đó là phụ thuộc CORE, không đổi)
- Modify: `tkv_compile.py` (gọi `load_plugins()` 1 lần lúc khởi động)
- Mirror: `release/3.code/compiler/il_codegen.tkv`, `release/3.code/tkv_compile.tkv`

**Interfaces:**
- Consumes: `plugin_loader.load_plugins()` (Task 10).

- [ ] **Step 1: Liệt kê CHÍNH XÁC mọi dòng `import il_features.X` thuần side-effect còn lại trong `il_codegen.py` (sau khi Task 2-9 đã xóa 1 phần)**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "^import il_features\." compiler/il_codegen.py
```

Ghi lại TOÀN BỘ danh sách này ra — đây là các dòng sẽ bị xóa ở Step 2.
Xác nhận KHÔNG có dòng `from il_features.X import ten` nào lẫn vào danh
sách (những dòng đó KHÔNG bị xóa ở Task này, chỉ xóa dòng side-effect
thuần `import il_features.X  # noqa`).

- [ ] **Step 2: Xóa TOÀN BỘ các dòng `import il_features.X  # noqa: F401 ...` liệt kê ở Step 1**

Dùng Edit xóa từng dòng (hoặc dùng `sed` cho nhanh vì đây là xóa NGUYÊN
DÒNG theo pattern cố định, không sửa nội dung dòng):

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "^import il_features\." compiler/il_codegen.py | wc -l
```

Ghi lại SỐ DÒNG trước khi xóa (để đối chiếu sau). Dùng Edit tool xóa
TỪNG dòng một trong danh sách Step 1 (an toàn hơn `sed -i` vì Edit tool
yêu cầu match chính xác, tránh xóa nhầm dòng tương tự).

- [ ] **Step 3: Thêm gọi `load_plugins()` vào `tkv_compile.py`**

```bash
grep -n "^import\|^from" tkv_compile.py | head -20
```

Thêm vào SAU khối import đầu file (trước dòng định nghĩa hàm/class đầu
tiên):

```python
import plugin_loader

plugin_loader.load_plugins()
```

**LƯU Ý THỨ TỰ**: dòng này PHẢI chạy TRƯỚC bất kỳ lời gọi
`gen_il_program`/`compile_tkv_cli` nào (tức đặt Ở MODULE LEVEL của
`tkv_compile.py`, chạy ngay khi `tkv_compile.py` được import — giống
cách các module `il_features.X` cũ TRƯỚC ĐÂY tự đăng ký ngay lúc
`il_codegen.py` import chúng, chỉ đổi ĐIỂM KÍCH HOẠT từ "lúc import
`il_codegen.py`" sang "lúc import `tkv_compile.py`", vẫn là 1 lần duy
nhất trước khi biên dịch bất kỳ file `.tkv` nào).

- [ ] **Step 4: Build 1 file đơn giản qua `.py` tree, xem lỗi ĐẦU TIÊN nếu có**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t11_probe.exe 2>&1 | tail -50
```

**Nếu lỗi `NameError`/`AttributeError` xuất hiện** (nhiều khả năng —
`il_codegen.py` VẪN còn dùng trực tiếp 1 biến/hàm mà trước đây tới từ 1
dòng `import il_features.X` vừa xóa, ví dụ biến module-level nào đó KHÔNG
qua `from...import` mà qua `il_features.X.some_attr` trực tiếp): dừng
lại, đọc traceback, xác định chính xác biến/module nào bị thiếu, KHÔNG
đoán — grep lại xem có chỗ nào trong `il_codegen.py` tham chiếu module
đó qua tên đầy đủ (`il_features.<ten_module>.<gi_do>`) mà không phải
qua registry, thêm LẠI đúng 1 dòng `import il_features.<ten_module>`
CHO RIÊNG module đó (không phục hồi toàn bộ danh sách), rồi build lại.
Lặp lại tới khi build sạch.

**Nếu lỗi `ValueError: il_dispatch: register_expr_builtin(...) - ten
nay DA duoc dang ky`** (bug trùng tên lộ ra do đổi thứ tự — ĐÚNG rủi ro
đã lường trước ở mục 4.3 của spec): đọc tên bị trùng trong thông báo
lỗi, tìm 2 file nào cùng đăng ký tên đó:

```bash
grep -rn "register_expr_builtin('TEN_BI_TRUNG'" compiler/il_features/*.py
```

Đổi tên 1 trong 2 (theo đúng tiền lệ xử lý bug `json_get_str` ở phiên
trước — đổi tên bên gây xung đột, giữ tên bên "đúng ngữ nghĩa gốc" theo
tên builtin Python tương ứng), build lại.

- [ ] **Step 5: Sau khi build sạch — chạy full regression `.py` tree ĐẦY ĐỦ (đây là bài test quan trọng NHẤT trong toàn bộ plan)**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  out="/tmp/plan_t11_reg_${base}.exe"
  python tkv.py build "$f" --entry run --out "$out" > "/tmp/plan_t11_build_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; tail -20 "/tmp/plan_t11_build_${base}.log"; continue; fi
  res=$("$out" 2>&1)
  if echo "$res" | grep -qi "^FAIL \|Exception"; then
    echo "=== $base ==="; echo "$res" | tail -5
  else
    echo "OK $base"
  fi
done
```

Expected: MỌI dòng `OK <ten>` (trừ `path_isfile_isdir_test` pre-existing
`3/4`). Nếu BẤT KỲ `BUILD-FAIL` hoặc `FAIL` nào xuất hiện, quay lại Step
4, không được bỏ qua/xem là "chấp nhận được" — đây là Task chuyển đổi
CƠ CHẾ NẠP CỐT LÕI, phải sạch 100% trước khi qua Task 12.

- [ ] **Step 6: Mirror sang `.tkv` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
diff compiler/il_codegen.py release/3.code/compiler/il_codegen.tkv | head -60
```

Áp ĐÚNG các thay đổi Step 2 (xóa dòng import) vào bản `.tkv` bằng Edit,
GIỮ NGUYÊN mọi phần khác biệt sẵn có đã biết từ Task 2 (nhánh fallback
`EXPR_BUILTIN_DTYPE` trong `file_io.tkv` — riêng file này KHÔNG đổi ở
Task 11, chỉ `il_codegen.tkv` đổi).

```bash
diff tkv_compile.py release/3.code/tkv_compile.tkv | head -30
```

Áp đúng thay đổi Step 3 vào `release/3.code/tkv_compile.tkv` bằng Edit
(kiểm tra phân kỳ trước, đúng quy trình đã lặp lại xuyên suốt plan này).

- [ ] **Step 7: Commit khi được yêu cầu**

```bash
git add compiler/il_codegen.py tkv_compile.py \
        release/3.code/compiler/il_codegen.tkv release/3.code/tkv_compile.tkv
git commit -m "refactor(compiler): thay import cung il_features bang plugin_loader.load_plugins()

Xoa toan bo khoi 'import il_features.X # noqa: F401' con lai trong
il_codegen.py (~30+ dong, nhung module CHI dang ky side-effect, khong bi
goi ten truc tiep) - thay bang 1 lan goi plugin_loader.load_plugins()
trong tkv_compile.py luc khoi dong. Cac dong 'from il_features.Y import
ten_ham' (phu thuoc CORE that su, il_codegen.py goi thang ten) GIU
NGUYEN, khong doi.

Xac nhan full regression .py tree sach 100% (tru path_isfile_isdir_test
pre-existing) truoc khi commit - day la buoc rui ro nhat trong toan bo
Phase tach tkvc.exe, da kiem tra ky theo dung quy trinh o
docs/superpowers/plans/2026-08-12-tkvc-plugin-architecture.md Task 11.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 12: Sửa `build_tkvc.ps1` — tách staging thành core/library, chỉ đóng gói core vào `tkvc.exe`

**Files:**
- Modify: `release/3.code/build_tkvc.ps1`
- Create (runtime output, không commit): `release/3.code/dist/il_features/*.py`

**Interfaces:**
- Consumes: danh sách "nhóm LIBRARY" — chính là DANH SÁCH các file `il_features/*.tkv` KHÔNG còn bị `release/3.code/compiler/il_codegen.tkv` import trực tiếp (qua `from il_features.Y import ten` — verify được bằng script, không cần liệt kê tay).

- [ ] **Step 1: Viết script xác định danh sách file LIBRARY tự động (không liệt kê tay, tránh sai sót khi thêm module mới sau này)**

```bash
cat > /tmp/plan_t12_split_staging.py << 'EOF'
"""Xac dinh danh sach file il_features CORE (bi il_codegen.tkv import
truc tiep qua 'from il_features.X import') vs LIBRARY (con lai) - dung
trong build_tkvc.ps1 (goi qua python, xem Step 2)."""
import re
import sys
import os

root = sys.argv[1]  # release/3.code
il_codegen_path = os.path.join(root, 'compiler', 'il_codegen.tkv')
il_features_dir = os.path.join(root, 'compiler', 'il_features')

with open(il_codegen_path, encoding='utf-8') as f:
    text = f.read()

# Moi dong 'from il_features.X import ...' (co the nhieu dong lien tuc
# trong 1 khoi ngoac tron) - regex tim TEN MODULE ngay sau 'il_features.'.
core_names = set(re.findall(r'from il_features\.(\w+) import', text))
# 'closures.py' con bi import qua 'from il_features.closures import
# _collect_var_names' - da nam trong core_names qua regex tren, khong
# can xu ly rieng.

all_files = sorted(f for f in os.listdir(il_features_dir) if f.endswith('.tkv'))
core_files = [f for f in all_files if f[:-4] in core_names]
library_files = [f for f in all_files if f[:-4] not in core_names]

print(f"CORE ({len(core_files)}):")
for f in core_files:
    print(f"  {f}")
print(f"LIBRARY ({len(library_files)}):")
for f in library_files:
    print(f"  {f}")
EOF
cd "D:\Claude AI Project\TokenVector"
python /tmp/plan_t12_split_staging.py release/3.code
```

Đọc kỹ output — đối chiếu bằng mắt với danh sách "CORE"/"LIBRARY" đã ghi
trong `docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md`
mục 3. Nếu có file KHÔNG khớp (ví dụ `plugin_loader.tkv` mới thêm ở
Task 10 — file này KHÔNG được import qua `from il_features...` nên regex
sẽ xếp nhầm vào LIBRARY dù nó nằm ở `compiler/` không phải
`compiler/il_features/` — xác nhận `plugin_loader.tkv` nằm NGOÀI thư mục
`il_features/` nên không lọt vào danh sách này, đúng ý muốn), ghi chú
lại để xử lý thủ công ở Step 2.

- [ ] **Step 2: Sửa `release/3.code/build_tkvc.ps1`**

Đọc lại toàn bộ file hiện tại (đã đọc ở phần brainstorm, xác nhận lại
trước khi sửa vì có thể người dùng đã đổi):

```bash
cat "D:\Claude AI Project\TokenVector\release\3.code\build_tkvc.ps1"
```

Thay TOÀN BỘ nội dung file bằng:

```powershell
# Build tkvc.exe - standalone TokenVector compiler (core nhe) + thu vien
# rieng canh file .exe (Phase "tach tkvc.exe thanh plugin", 2026-08-12,
# xem docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md).
#
# Cac file nguon trong package nay dung duoi `.tkv` (tkv.tkv, tkv_compile.tkv,
# tokenvector_compile.tkv, compiler/*.tkv) nhung NOI DUNG la Python that (xem
# docstring dau tkv_compile.tkv). Python import system KHONG tu nhan .tkv la
# module - script nay COPY tam moi file .tkv sang .py cung ten trong 2 thu
# muc staging RIENG (KHONG sua file .tkv goc):
#   - staging/compiler/il_features/  : CHI nhom CORE (bi il_codegen.tkv
#     import truc tiep qua 'from il_features.X import ten') - PyInstaller
#     chi thay package nay, tu dong dong goi dung nhom core.
#   - staging/il_features_library/   : nhom LIBRARY (con lai) - KHONG
#     nam trong package 'compiler', PyInstaller KHONG thay nen KHONG
#     dong goi vao exe - sau khi build xong, COPY THANG sang dist/il_features/
#     (canh tkvc.exe) de plugin_loader.py nap dong luc chay.
#
# Chay: powershell -File build_tkvc.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$staging = Join-Path $root "build\pyinstaller_src"

if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path $staging | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $staging "compiler\il_features") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $staging "il_features_library") | Out-Null

# Entry point + 2 module dung chung o cap goc (LUON core).
Copy-Item (Join-Path $root "tkv.tkv")                 (Join-Path $staging "tkv.py")
Copy-Item (Join-Path $root "tkv_compile.tkv")          (Join-Path $staging "tkv_compile.py")
Copy-Item (Join-Path $root "tokenvector_compile.tkv")  (Join-Path $staging "tokenvector_compile.py")

# compiler/*.tkv NGOAI il_features/ (il_core.py, il_codegen.py, il_dispatch.py,
# typed_dsl_parser.py, plugin_loader.py, ...) -> LUON core, copy nguyen cay.
Get-ChildItem -Path (Join-Path $root "compiler") -Filter "*.tkv" -Recurse |
    Where-Object { $_.DirectoryName -notlike "*il_features*" } |
    ForEach-Object {
        $rel = $_.FullName.Substring((Join-Path $root "compiler").Length + 1)
        $relPy = [System.IO.Path]::ChangeExtension($rel, ".py")
        $dest = Join-Path $staging "compiler\$relPy"
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item $_.FullName $dest
    }

# compiler/il_features/*.tkv - phan loai CORE vs LIBRARY qua script Python
# (doc truc tiep il_codegen.tkv de biet module nao dang duoc 'from
# il_features.X import ten' - tu dong cap nhat khi them/bot module,
# khong can sua tay danh sach o day).
$splitScript = Join-Path $root "build\_split_il_features.py"
@'
import re, os, sys
root = sys.argv[1]
il_codegen_path = os.path.join(root, "compiler", "il_codegen.tkv")
il_features_dir = os.path.join(root, "compiler", "il_features")
with open(il_codegen_path, encoding="utf-8") as f:
    text = f.read()
core_names = set(re.findall(r"from il_features\.(\w+) import", text))
all_files = sorted(f for f in os.listdir(il_features_dir) if f.endswith(".tkv"))
core = [f for f in all_files if f[:-4] in core_names]
library = [f for f in all_files if f[:-4] not in core_names]
print("\n".join(core))
print("---")
print("\n".join(library))
'@ | Out-File -FilePath $splitScript -Encoding utf8

$splitOutput = python $splitScript $root
$splitIdx = [array]::IndexOf($splitOutput, "---")
$coreFiles = $splitOutput[0..($splitIdx - 1)] | Where-Object { $_ -ne "" }
$libraryFiles = $splitOutput[($splitIdx + 1)..($splitOutput.Length - 1)] | Where-Object { $_ -ne "" }

Write-Output "CORE il_features (${coreFiles.Count} file): $($coreFiles -join ', ')"
Write-Output "LIBRARY il_features (${libraryFiles.Count} file): $($libraryFiles -join ', ')"

foreach ($f in $coreFiles) {
    $src = Join-Path $root "compiler\il_features\$f"
    $destName = [System.IO.Path]::ChangeExtension($f, ".py")
    Copy-Item $src (Join-Path $staging "compiler\il_features\$destName")
}
foreach ($f in $libraryFiles) {
    $src = Join-Path $root "compiler\il_features\$f"
    $destName = [System.IO.Path]::ChangeExtension($f, ".py")
    Copy-Item $src (Join-Path $staging "il_features_library\$destName")
}

Push-Location $staging
try {
    python -m PyInstaller --onefile --name tkvc `
      --distpath (Join-Path $root "dist") `
      --workpath (Join-Path $root "build\pyinstaller") `
      --specpath (Join-Path $root "build") `
      --paths compiler `
      tkv.py
} finally {
    Pop-Location
}

# Sau khi PyInstaller build xong: copy nhom LIBRARY sang dist/il_features/
# (canh tkvc.exe) de plugin_loader.py nap dong luc chay.
$distIlFeatures = Join-Path $root "dist\il_features"
if (Test-Path $distIlFeatures) { Remove-Item -Recurse -Force $distIlFeatures }
New-Item -ItemType Directory -Force -Path $distIlFeatures | Out-Null
Copy-Item (Join-Path $staging "il_features_library\*.py") $distIlFeatures

Write-Output "Da build: $(Join-Path $root 'dist\tkvc.exe')"
Write-Output "Thu vien (${libraryFiles.Count} file) o: $distIlFeatures"
Write-Output "(Nguon staging tam thoi o $staging - co the xoa an toan, khong phai nguon that)"
```

**LƯU Ý QUAN TRỌNG**: bỏ flag `--collect-submodules il_features` (đã
xóa so với script cũ — flag này ép PyInstaller nhúng MỌI submodule
trong package `il_features`, kể cả file KHÔNG được import tĩnh ở đâu —
chính là nguyên nhân gốc khiến `tkvc.exe` cũ nhúng hết mọi thứ dù đã
tách core/library ở code Python).

- [ ] **Step 2: Build thử `tkvc.exe` mới**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
powershell -File build_tkvc.ps1 2>&1 | tail -60
```

Expected: output có 2 dòng `CORE il_features (N file): ...` / `LIBRARY
il_features (M file): ...` với N khớp danh sách CORE ở spec mục 3 (khoảng
10-12 file: `list_type`, `set_type`, `dict_type`, `tuple_type`,
`string_feature`, `operators`, `int_type`, `closures`, `generator_lazy`,
`generator_feature`, `comprehension`, `slicing` — LƯU Ý: `comprehension`/
`slicing` được liệt kê "library" trong docstring nhưng "core" trong ý
định cuối của spec mục 2.2 — nếu script Step 1 xếp chúng vào LIBRARY do
`il_codegen.tkv` chỉ `import il_features.comprehension  # noqa` side-effect
thuần chứ KHÔNG `from...import`, đó là ĐÚNG theo tiêu chí phân loại thật
(mục 2.2 cuối cùng: "TÁCH ĐƯỢC ... vì cơ chế đăng ký của chúng ĐÃ đúng
chuẩn registry" — nghĩa là chúng THUỘC nhóm library, không phải core,
dù đứng gần các mục core trong danh sách mục 2.2. Đây KHÔNG phải mâu
thuẫn — đọc lại spec mục 2.2 xác nhận `comprehension.py`/`slicing.py`
CÓ ghi rõ "TÁCH ĐƯỢC", chỉ xếp gần mục 2.2 vì liên quan cú pháp, không
có nghĩa chúng ở nhóm CORE).

Build ra `dist/tkvc.exe` và `dist/il_features/*.py` không lỗi.

- [ ] **Step 3: Đo kích thước `tkvc.exe` mới so với bản CŨ (trước khi bắt đầu toàn bộ Phase này) để xác nhận mục tiêu "gọn nhẹ" đạt thật**

```bash
cd "D:\Claude AI Project\TokenVector"
git show HEAD~11:release/3.code/dist/tkvc.exe > /tmp/plan_t12_old_tkvc.exe 2>/dev/null || echo "khong tim thay ban cu qua git, dung ls -la truoc do"
ls -la /tmp/plan_t12_old_tkvc.exe release/3.code/dist/tkvc.exe 2>/dev/null
```

(Số `HEAD~11` là ước lượng — 11 commit trước Task này trong plan, tính
từ commit gần nhất TRƯỚC Task 1 của Phase này; nếu lệnh `git show` báo
lỗi do số commit không khớp thực tế lúc thực thi, dùng `git log --oneline
release/3.code/dist/tkvc.exe | tail -20` để tìm đúng commit hash TRƯỚC
Task 1, thay vào `HEAD~11`.)

Expected: `dist/tkvc.exe` MỚI nhỏ hơn RÕ RỆT bản cũ (ghi lại số byte cụ
thể vào changelog/commit message ở Step 5 — đây là bằng chứng ĐỊNH LƯỢNG
cho mục tiêu "gọn nhẹ" của Phase này, không chỉ là tuyên bố suông).

- [ ] **Step 4: Test riêng — build 1 chương trình DÙNG `stdlib_math` qua `tkvc.exe` MỚI, xác nhận chạy được (đọc plugin từ `dist/il_features/` thành công)**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
./dist/tkvc.exe build Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t12_tkvc_math.exe
/tmp/plan_t12_tkvc_math.exe
```

Expected: build thành công, chạy PASS toàn bộ — chứng minh `tkvc.exe`
MỚI (core không nhúng `stdlib_math`) vẫn biên dịch được chương trình
dùng `pow()`/`sqrt()` nhờ đọc `dist/il_features/stdlib_math.py` lúc
chạy.

- [ ] **Step 5: Test cơ chế "thiếu plugin báo lỗi rõ ràng" — xóa thử `dist/il_features/stdlib_math.py`, build lại, xác nhận báo lỗi dễ hiểu (không phải crash khó hiểu)**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
mv dist/il_features/stdlib_math.py /tmp/plan_t12_stdlib_math_backup.py
./dist/tkvc.exe build Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t12_should_fail.exe 2>&1 | tail -20
```

Expected: lỗi RÕ RÀNG dạng `il_codegen: ham 'pow' khong ton tai (khong
phai builtin thu vien nao ...)` (từ thông báo lỗi đã sửa ở Task 3 Step
6) — KHÔNG phải traceback Python khó hiểu hay crash không rõ nguyên
nhân. Khôi phục file:

```bash
mv /tmp/plan_t12_stdlib_math_backup.py dist/il_features/stdlib_math.py
./dist/tkvc.exe build Testkit/math_extra_test.tkv --entry run --out /tmp/plan_t12_restored.exe
/tmp/plan_t12_restored.exe
```

Expected: build lại thành công sau khi khôi phục file, không cần build
lại `tkvc.exe`.

- [ ] **Step 6: Commit khi được yêu cầu**

```bash
cd "D:\Claude AI Project\TokenVector"
git add release/3.code/build_tkvc.ps1
git add -f release/3.code/dist/tkvc.exe
git status --short release/3.code/dist/il_features/
```

**LƯU Ý**: `release/3.code/dist/il_features/*.py` là SẢN PHẨM BUILD
(sinh ra bởi `build_tkvc.ps1`, giống `dist/tkvc.exe`) — kiểm tra
`.gitignore` xem thư mục `dist/` có đang bị ignore hay `tkvc.exe` được
`git add -f` cưỡng ép như các commit trước; nếu `tkvc.exe` từng được
commit thẳng (đã thấy ở các Task trước trong session), áp dụng ĐÚNG quy
ước tương tự cho `dist/il_features/*.py` (`git add -f` nếu cần) — hỏi
người dùng nếu không chắc quy ước này có nên tiếp tục cho thư mục
`il_features/` (nhiều file hơn 1 file `.exe` — có thể người dùng muốn
`.gitignore` thay vì commit thẳng, XÁC NHẬN TRƯỚC KHI COMMIT, không tự
quyết).

```bash
git commit -m "build: tach staging build_tkvc.ps1 thanh core/library, bo --collect-submodules

PyInstaller gio CHI dong goi nhom CORE il_features (list_type/set_type/
dict_type/tuple_type/string_feature/operators/int_type/closures/
generator_lazy/generator_feature - xac dinh TU DONG qua script doc
il_codegen.tkv, khong liet ke tay) vao tkvc.exe. Nhom LIBRARY (con lai,
~35+ file) copy sang dist/il_features/ canh tkvc.exe, nap dong luc chay
qua plugin_loader.py (Task truoc). Bo flag --collect-submodules il_features
(nguyen nhan goc khien ban cu nhung MOI submodule bat ke co import tinh
hay khong).

Xac nhan: (1) tkvc.exe moi build+chay duoc chuong trinh dung stdlib_math
qua doc dist/il_features/stdlib_math.py luc chay: PASS. (2) xoa thu 1
file plugin bao loi RO RANG (khong crash kho hieu), khoi phuc lai build
binh thuong: PASS. (3) kich thuoc tkvc.exe: [DIEN SO BYTE THAT DA DO O
STEP 3] so voi ban cu [SO BYTE CU].

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

(Điền số byte THẬT đo được ở Step 3 vào message trước khi commit — đây
là chỗ DUY NHẤT trong plan cần điền số liệu runtime thay vì code tĩnh,
không phải placeholder mơ hồ mà là kết quả đo đạc bắt buộc phải có
trước khi commit.)

---

## Task 13: Regression toàn diện cuối cùng — cả 2 cây, đối chiếu PASS/FAIL không đổi

**Files:** không sửa file nào — Task thuần kiểm chứng.

**Interfaces:** không có (Task cuối, xác nhận toàn bộ Phase hoàn thành đúng).

- [ ] **Step 1: Full regression `.py` tree (lần cuối, sau khi MỌI Task trước đã xong)**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  out="/tmp/plan_t13_reg_${base}.exe"
  python tkv.py build "$f" --entry run --out "$out" > "/tmp/plan_t13_build_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$out" 2>&1)
  if echo "$res" | grep -qi "^FAIL \|Exception"; then
    echo "=== $base ==="; echo "$res" | tail -5
  else
    echo "OK $base"
  fi
done
```

Expected: mọi dòng `OK` (trừ `path_isfile_isdir_test` pre-existing).

- [ ] **Step 2: Full regression qua `tkvc.exe` MỚI (build lại từ chính nó lần cuối, xác nhận build script + toàn bộ migration ổn định)**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
powershell -File build_tkvc.ps1 2>&1 | tail -20
for f in Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  out="/tmp/plan_t13_tkvc_${base}.exe"
  ./dist/tkvc.exe build "$f" --entry run --out "$out" > "/tmp/plan_t13_tkvcbuild_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL(tkvc) $base"; continue; fi
  res=$("$out" 2>&1)
  if echo "$res" | grep -qi "^FAIL \|Exception"; then
    echo "=== $base (tkvc) ==="; echo "$res" | tail -5
  else
    echo "OK(tkvc) $base"
  fi
done
```

Expected: kết quả GIỐNG HỆT Step 1 (mọi dòng `OK(tkvc)`, trừ
`path_isfile_isdir_test`).

- [ ] **Step 3: Đối chiếu 2 bộ kết quả Step 1/Step 2 — số PASS/FAIL của từng file phải KHỚP NHAU tuyệt đối**

```bash
for base in $(ls release/3.code/Testkit/*.tkv | xargs -n1 basename | sed 's/\.tkv$//'); do
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  py_result=$(cat "/tmp/plan_t13_reg_${base}.exe" 2>/dev/null > /dev/null; "/tmp/plan_t13_reg_${base}.exe" 2>&1 | grep "===" || echo "MISSING")
  tkvc_result=$(cat "/tmp/plan_t13_tkvc_${base}.exe" 2>/dev/null > /dev/null; "/tmp/plan_t13_tkvc_${base}.exe" 2>&1 | grep "===" || echo "MISSING")
  if [ "$py_result" != "$tkvc_result" ]; then
    echo "LECH: $base - .py tree: [$py_result] vs tkvc.exe: [$tkvc_result]"
  fi
done
echo "Doi chieu xong - khong co dong 'LECH' nao o tren la DAT"
```

Expected: KHÔNG có dòng `LECH` nào in ra — nếu có, đây là bug thật cần
điều tra trước khi coi Phase này hoàn thành (2 cây phải cho kết quả
GIỐNG HỆT nhau cho cùng 1 test).

- [ ] **Step 4: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md` — ghi lại Phase này đã hoàn thành**

Thêm 1 mục mới vào cuối phần "D. Đã xác nhận ĐÚNG" hoặc tạo mục riêng,
theo đúng văn phong các mục trước (mô tả ngắn gọn: đã tách core/library,
kích thước `tkvc.exe` trước/sau, xác nhận 2 cây cho kết quả giống nhau).

- [ ] **Step 5: Commit khi được yêu cầu**

```bash
cd "D:\Claude AI Project\TokenVector"
git add docs/PYTHON_GAP_CHECKLIST.md
git commit -m "docs: xac nhan hoan thanh Phase tach tkvc.exe thanh core+plugin

Regression toan dien cuoi cung: .py tree va tkvc.exe (build lai tu chinh
no) cho ket qua GIONG HET nhau tren toan bo Testkit/*.tkv (~30+ file,
tru path_isfile_isdir_test pre-existing). Xem chi tiet kien truc o
docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md,
plan thuc thi day du o
docs/superpowers/plans/2026-08-12-tkvc-plugin-architecture.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review (đã thực hiện khi viết plan này)

**1. Spec coverage**: Mục 3 (ranh giới core/library) → Task 2-9 (migrate
if/elif cũ) + Task 12 (script tự động phân loại theo đúng tiêu chí mục
3). Mục 3.1 (`EXTRA_FUNCS`/`RETURN_DTYPE` export không phải side-effect)
→ Task 3 Step 2-3, Task 9. Mục 3.2 (tách `string_feature.py`) → Task 8.
Mục 4 (cơ chế nạp plugin) → Task 10-11. Mục 4.3 (rủi ro thứ tự import)
→ Task 1 (guard) + Task 11 Step 4 (xử lý nếu xảy ra). Mục 5 (build
script) → Task 12. Mục 6 (migration nhóm 2.1) → Task 2-9 (đủ 6 module +
`str`/`fmt_float`). Mục 7 (kiểm chứng) → mọi Task đều có bước regression
riêng + Task 13 tổng hợp cuối. Mục 8 (ngoài phạm vi) → không có Task nào
động tới `list_type`/`dict_type`/`set_type`/`tuple_type`/`operators`/
`int_type`/`closures`/`generator_*` (đúng ý "giữ nguyên core vĩnh viễn").

**2. Placeholder scan**: đã rà lại toàn bộ — chỉ còn 1 chỗ CẦN điền số
liệu THẬT lúc thực thi (Task 12 Step 6, số byte đo được ở Step 3) — đây
KHÔNG phải placeholder mơ hồ ("TBD") mà là kết quả đo đạc bắt buộc, đã
ghi rõ ràng "điền số byte THẬT đo được" chứ không để trống.

**3. Type consistency**: `register_expr_builtin(name, fn, return_dtype,
...)` dùng NHẤT QUÁN đúng 1 chữ ký xuyên suốt Task 2-9 (khớp
`il_dispatch.py`'s định nghĩa thật đã đọc ở Task 1). `plugin_loader.
load_plugins(plugin_dir=None) -> list[str]` (Task 10) được gọi ĐÚNG
KHÔNG THAM SỐ ở Task 11 Step 3 (`plugin_loader.load_plugins()`, dùng
`discover_plugin_dir()` mặc định) — khớp interface đã khai báo.

## Execution Handoff

Plan hoàn chỉnh, lưu tại `docs/superpowers/plans/2026-08-12-tkvc-plugin-architecture.md`.

Hai lựa chọn thực thi:

**1. Subagent-Driven (khuyến nghị)** - tôi giao mỗi Task cho 1 subagent
mới, review giữa các Task, lặp nhanh.

**2. Inline Execution** - thực thi trong phiên này qua executing-plans,
chạy theo lô có checkpoint để bạn review.

Bạn muốn dùng cách nào?
