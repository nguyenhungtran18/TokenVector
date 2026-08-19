# __len__ cho record Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `len(r)` với `r` là 1 biến kiểu record có định nghĩa `def
__len__(self) -> "i32": ...` sẽ TỰ ĐỘNG gọi method đó. Đóng mục thứ 3
trong 5 dunder của 6.5 (`docs/PYTHON_GAP_CHECKLIST.md`).

**Architecture:** Sửa nhánh `if name == 'len':` trong `_expr_call`
(`compiler/il_codegen.py`, dòng ~1594-1628) — thêm kiểm tra
`arg_ta.shape == 'record'` TRƯỚC `raise SyntaxError` hiện có, validate
chữ ký `__len__`, sinh `callvirt instance int32 {owner}::__len__()`
(owner qua `_method_owner_class`, hỗ trợ kế thừa — cùng cơ chế
`__str__`/`__eq__`).

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe`.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100%.
- `len()` trên `list`/`dict`/`set`/`str` hiện có PHẢI giữ NGUYÊN hành
  vi — không regression.
- Record KHÔNG có `__len__` PHẢI vẫn raise lỗi rõ ràng như cũ.
- CHỈ hỗ trợ `len(<biến>)` — không mở rộng nhánh `_compile_len_of_expr`
  (biểu thức phức tạp) trong batch này.
- Không refactor phần nào khác của `_expr_call`/`il_codegen.py` ngoài
  nhánh `if name == 'len':` ở dòng ~1594.
- **BÀI HỌC từ `__str__`/`__eq__`**: kiểm tra kỹ chữ ký IL tham số
  record trong `callvirt` (dùng `il_type_str(...)` cho dạng `class
  {TenRecord}`, KHÔNG dùng tên trần) và logic validate chữ ký PHẢI
  chấp nhận trường hợp kế thừa (không chỉ đúng type chính xác) NẾU có
  tham số record liên quan — `__len__` không có tham số nào ngoài
  `self` nên rủi ro này THẤP hơn `__eq__`, nhưng vẫn double-check chữ
  ký `callvirt instance int32 {owner}::__len__()` không có tham số dư.

---

### Task 1: Mở rộng `len()` + test + regression + docs

**Files:**
- Modify: `compiler/il_codegen.py` — sửa nhánh `if name == 'len':`
  trong `_expr_call`, dòng ~1594-1628
- Modify: `release/3.code/compiler/il_codegen.tkv` (mirror — tìm đúng
  vị trí tương ứng bằng
  `grep -n "len(lst)/len(d)/len(s)" release/3.code/compiler/il_codegen.tkv`)
- Test: `release/3.code/Testkit/dunder_len_test.tkv` (MỚI)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `_method_owner_class(ctx, record_name, method_name)`
  (`compiler/il_features/record_feature.py`, đã dùng cho `__str__`/
  `__eq__`).
- Produces: không có interface mới cho task khác — sub-project độc
  lập, `__getitem__`/`__add__` (còn lại) KHÔNG phụ thuộc cơ chế này.

- [ ] **Step 1: Sửa nhánh `len()` trong `_expr_call`**

Sửa `compiler/il_codegen.py`, thay đoạn hiện tại (dòng 1594-1628):

```python
    if name == 'len':
        # len(lst)/len(d)/len(s) - list/dict/string (mang co san dung
        # .shape[N], da biet hang so luc codegen, khong can len() runtime).
        # __len__ cho record (6.5, dunder overload - muc 3, 2026-08-13):
        # len(r) tren 1 BIEN record co __len__(self) -> "i32" goi callvirt
        # thay vi raise loi.
        if len(args) != 1:
            raise SyntaxError("il_codegen: len() chi nhan dung 1 tham so")
        arg = args[0]
        if arg[0] != 'var':
            # len(<bieu thuc>) - vd len(s.split(","))/len(d.keys())/
            # len(os_list_files(p))/len(a + b) (2026-08-03, sau khi Giai
            # doan 0.2 cho phep builtin/method chay o moi vi tri bieu thuc:
            # gioi han "chi 1 BIEN don" o day tro thanh nut that CUOI CUNG
            # cho cac cach viet thuong ngay nhat cua Python).
            #
            # Hinh dang ket qua lay tu CHINH ha tang da co:
            # _shaped_return_ta_of_call (call/method_call tra container),
            # roi den _infer_dtype cho chuoi. Khong co duong suy luan MOI.
            return _compile_len_of_expr(arg, scope, out, dtype, ctx)
        _, _, arg_ta = scope[arg[1]]
        if arg_ta.dtype == 'str' and arg_ta.shape is None:
            return _string_compile_len_str(arg[1], scope, out, dtype, ctx)
        if arg_ta.shape == 'record':
            records = (ctx or {}).get('records') or {}
            record_methods = (ctx or {}).get('record_methods') or {}
            dunder = record_methods.get(arg_ta.dtype, {}).get('__len__')
            if dunder is None:
                raise SyntaxError(
                    f"il_codegen: record '{arg_ta.dtype}' khong co __len__ - len(r) tren "
                    f"record can dinh nghia 'def __len__(self) -> \"i32\": ...'")
            if dunder.params or dunder.return_type is None or \
                    dunder.return_type.dtype != 'i32' or dunder.return_type.shape is not None:
                raise SyntaxError(
                    f"il_codegen: record '{arg_ta.dtype}' co __len__ nhung chu ky sai - "
                    f"can dung 0 tham so va tra ve \"i32\" ('def __len__(self) -> \"i32\":')")
            _load_var_ref(arg[1], scope, out)
            from il_features.record_feature import _method_owner_class
            owner = _method_owner_class(ctx, arg_ta.dtype, '__len__')
            out.append(f'    callvirt instance int32 {owner}::__len__()')
            _widen_if_needed('i32', dtype, out)
            return
        if arg_ta.shape not in ('list', 'dict', 'set'):
            raise SyntaxError(
                f"il_codegen: len() hien CHI ho tro list/dict/set/string, hoac 1 record co "
                f"__len__ ('{arg[1]}' co dtype={arg_ta.dtype!r} shape={arg_ta.shape!r}) - "
                f"mang co san dung .shape[0] thay the")
        _load_var_ref(arg[1], scope, out)
        if arg_ta.shape == 'list':
            col_type = il_list_type(arg_ta.dtype, (ctx or {}).get('records'))
        elif arg_ta.shape == 'set':
            col_type = il_set_type(arg_ta.dtype, (ctx or {}).get('records'))
        else:
            col_type = il_dict_type(arg_ta.key_dtype, arg_ta.dtype, (ctx or {}).get('records'))
        out.append(f'    callvirt instance int32 {col_type}::get_Count()')
        _widen_if_needed('i32', dtype, out)
        return
```

**LƯU Ý**: `records` biến khai trong nhánh mới KHÔNG dùng tới trực tiếp
(chỉ `record_methods` được dùng) — XÓA dòng khai `records = ...` nếu
không cần, TRÁNH biến thừa không dùng (linting sạch). Kiểm tra lại kỹ
trước khi viết code thật — chỉ giữ `record_methods`.

- [ ] **Step 2: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN vào `release/3.code/compiler/il_codegen.tkv` (tìm
đúng vị trí nhánh `if name == 'len':` tương ứng trong file `.tkv`).

- [ ] **Step 3: Viết test mới `dunder_len_test.tkv`**

Tạo `release/3.code/Testkit/dunder_len_test.tkv`:

```python
__tkv_import__ = ["tkv_test_lib"]


class Bag:
    count: "i32"

    def __len__(self) -> "i32":
        return self.count


class Base:
    n: "i32"

    def __len__(self) -> "i32":
        return self.n


class Sub(Base):
    extra: "i32"


class NoLen:
    v: "i32"


def run() -> "i32":
    total = 0
    tested = 0

    b = Bag(7)
    tested = tested + 1
    total = total + check("len_calls_dunder", str(len(b)), "7")

    s = Sub(3, 99)
    tested = tested + 1
    total = total + check("inherited_dunder_len", str(len(s)), "3")

    return test_summary("dunder_len_test", total, tested)
```

**LƯU Ý**: KHÔNG viết test cho `NoLen` (record không có `__len__`)
trong file test chính thức này (build sẽ THẤT BẠI ngay ở bước biên
dịch nếu gọi `len()` trên nó — không phải runtime exception bắt được
qua `try`/`except`). Xác nhận hành vi này ở Step 5 riêng (spike tạm,
không commit).

- [ ] **Step 4: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/dunder_len_test.tkv --entry run --out "$env:TEMP/dlen_t1.exe"
"$env:TEMP/dlen_t1.exe"
```
Expected: build PASS, `SUMMARY 2/2`.

- [ ] **Step 5: Xác nhận record KHÔNG có `__len__` vẫn báo lỗi biên
  dịch rõ ràng (regression check thủ công)**

Viết 1 file `.tkv` tạm (KHÔNG thuộc plan, không commit) định nghĩa
record `NoLen` (không `__len__`), gọi `len()` trên nó — xác nhận build
THẤT BẠI với message lỗi rõ ràng (không phải crash nội bộ compiler
kiểu `KeyError`/`AttributeError`). Xóa file tạm sau khi xác nhận.

- [ ] **Step 6: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/dlen_reg_${base}.exe" > "$TEMP/dlen_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/dlen_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan). ĐẶC BIỆT chú ý mọi file dùng `len()` trên
`list`/`dict`/`set`/`str` (tìm bằng `grep -l "len(" release/3.code/Testkit/*.tkv`)
không hồi quy, và `dunder_str_test`/`dunder_eq_test`/
`inheritance_py_tree_test` (2 batch trước) không hồi quy.

- [ ] **Step 7: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đọc lại nội dung THẬT của dòng 6.5 (đã có ghi chú `__str__`/`__eq__` từ
2 batch trước). Thêm `__len__` vào phần đã xong, giữ `[ ]` cho toàn mục
(còn `__getitem__`/`__add__`):

```
- [ ] 6.5 Dunder method overload (`__eq__`/`__len__`/`__getitem__`/
      `__add__`/`__str__`) — **`__str__`, `__eq__` VÀ `__len__` ĐÃ XONG
      (2026-08-13)**, xem `docs/superpowers/specs/2026-08-13-dunder-
      str-design.md`, `docs/superpowers/specs/2026-08-13-dunder-eq-
      design.md`, `docs/superpowers/specs/2026-08-13-dunder-len-
      design.md`. `len(r)` tự động gọi `__len__` (biến đơn, hỗ trợ kế
      thừa). Còn lại: `__getitem__` (`r[i]`), `__add__` (`+`) — mỗi
      cái là 1 sub-project riêng.
```

(Đọc lại nội dung THẬT của file trước khi sửa — không giả định đúng
format trên nếu khác thực tế.)

- [ ] **Step 8: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_codegen.py \
        release/3.code/compiler/il_codegen.tkv \
        release/3.code/Testkit/dunder_len_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): __len__ cho record - len(r) tu dong goi dunder

Nhanh len(<bien>) trong _expr_call them kiem tra shape=='record' co
__len__(self) -> "i32" thi callvirt thay vi raise loi. Ho tro ke thua
qua _method_owner_class (cung co che __str__/__eq__). Validate chu ky
truoc khi sinh IL. Chi ho tro len(<bien don>), khong mo rong len(<bieu
thuc>). Test moi xac nhan dung + ke thua, regression khong-len van bao
loi ro rang. Muc 3 trong 5 dunder cua 6.5 - con lai __getitem__/__add__.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
