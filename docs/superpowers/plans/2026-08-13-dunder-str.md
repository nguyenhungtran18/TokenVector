# __str__ cho record Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `str(r)`/`print(r)` với `r` là record có định nghĩa `def
__str__(self) -> "str": ...` sẽ TỰ ĐỘNG gọi method đó, đóng mục đầu
tiên trong 5 dunder method của 6.5 (`docs/PYTHON_GAP_CHECKLIST.md`).

**Architecture:** Mở rộng `emit_to_str` (`compiler/il_features/tkvstr.py`)
— điểm dispatch trung tâm dùng chung bởi `str()`/`print()` — thêm nhánh
kiểm tra `dtype` có phải tên 1 record có `__str__` không, validate chữ
ký, sinh `callvirt instance string {owner}::__str__()` (owner qua
`_method_owner_class` có sẵn trong `record_feature.py`, hỗ trợ kế
thừa).

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe`.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100%.
- `str()`/`print()` trên kiểu vô hướng hiện có (`str`/`int`/`i32`/`i64`/
  `f32`/`f64`/`bool`) PHẢI giữ NGUYÊN hành vi — không regression.
- Record KHÔNG có `__str__` PHẢI vẫn raise lỗi rõ ràng như trước (không
  tự sinh chuỗi mặc định).
- Chỉ áp dụng cho record — không mở rộng sang list/dict/set.
- Không refactor phần nào khác của `tkvstr.py` ngoài `emit_to_str`.

---

### Task 1: Mở rộng `emit_to_str` + test + regression + docs

**Files:**
- Modify: `compiler/il_features/tkvstr.py` (429 dòng hiện tại — sửa
  `emit_to_str`, dòng 55-86)
- Modify: `release/3.code/compiler/il_features/tkvstr.tkv` (mirror,
  431 dòng — nội dung logic đồng bộ `.py`, chênh lệch dòng chỉ do khác
  quy ước xuống dòng/CRLF, không phải khác nội dung)
- Test: `release/3.code/Testkit/dunder_str_test.tkv` (MỚI)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `_method_owner_class(ctx, record_name, method_name)` (hàm
  có sẵn trong `compiler/il_features/record_feature.py`, dòng 81-92 —
  import cục bộ trong `emit_to_str`, giống cách `int_type` được import
  cục bộ ở nhánh `dtype == 'int'` ngay phía trên).
- Produces: `str(r)`/`print(r)` hoạt động cho record có `__str__` —
  không có interface mới cho task khác (đây là sub-project ĐỘC LẬP đầu
  tiên trong 5 dunder của 6.5, các dunder khác sau này KHÔNG phụ thuộc
  vào cơ chế này).

- [ ] **Step 1: Sửa `emit_to_str` — thêm nhánh record trước chuỗi
  if/elif scalar**

Sửa `compiler/il_features/tkvstr.py`, thay hàm `emit_to_str` (dòng
55-86 hiện tại):

```python
def emit_to_str(dtype, out, ctx):
    """Gia tri kieu `dtype` DANG NAM TREN STACK -> chuoi. Dung chung cho
    str(), print(), va moi noi sau nay can in."""
    if dtype == 'str':
        return
    if dtype == 'int':
        import il_features.int_type as _int_type
        _int_type.ensure_class(ctx)
        out.append('    call string TkvInt::Str(valuetype TkvInt)')
        return
    records = (ctx or {}).get('records') or {}
    if dtype in records:
        # __str__ cho record (6.5, dunder overload - muc dau tien,
        # 2026-08-13). str()/print() DI QUA CHUNG diem nay nen sua 1 cho
        # lam CA HAI hoat dong. Validate chu ky TRUOC khi sinh IL - tranh
        # sinh callvirt sai kieu am tham (khac SyntaxError ro rang).
        record_methods = (ctx or {}).get('record_methods') or {}
        methods = record_methods.get(dtype, {})
        dunder = methods.get('__str__')
        if dunder is None:
            raise SyntaxError(
                f"il_codegen: record '{dtype}' khong co __str__ - str()/print() tren "
                f"record can dinh nghia 'def __str__(self) -> \"str\": ...'")
        if dunder.params or dunder.return_type is None or \
                dunder.return_type.dtype != 'str' or dunder.return_type.shape is not None:
            raise SyntaxError(
                f"il_codegen: record '{dtype}' co __str__ nhung chu ky sai - can dung "
                f"0 tham so va tra ve \"str\" ('def __str__(self) -> \"str\":')")
        from il_features.record_feature import _method_owner_class
        owner = _method_owner_class(ctx, dtype, '__str__')
        out.append(f'    callvirt instance string {owner}::__str__()')
        return
    ensure_class(ctx)
    if dtype == 'f64':
        out.append(f'    call string {TKVSTR_CLASS}::F64(float64)')
    elif dtype == 'f32':
        out.append(f'    call string {TKVSTR_CLASS}::F32(float32)')
    elif dtype == 'i64':
        out.append(f'    call string {TKVSTR_CLASS}::I64(int64)')
    elif dtype == 'i32':
        out.append(f'    call string {TKVSTR_CLASS}::I32(int32)')
    elif dtype == 'bool':
        out.append(f'    call string {TKVSTR_CLASS}::Bool(int32)')
    else:
        raise SyntaxError(
            f"il_codegen: chua co duong chuyen '{dtype}' sang chuoi "
            f"(chi ho tro i32/i64/f32/f64/int/str/bool, hoac 1 record co __str__)")
```

**LƯU Ý**: giữ NGUYÊN comment gốc trên nhánh `dtype == 'bool'` (dòng
75-82 bản gốc, giải thích lý do dùng nhãn riêng cho giá trị logic) —
đoạn code mẫu trên rút gọn phần comment khi trích dẫn, PHẢI giữ lại
comment gốc khi áp dụng thật vào file, chỉ thêm nhánh record MỚI, không
xóa comment cũ.

- [ ] **Step 2: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/tkvstr.tkv` (tìm đúng vị trí hàm
`emit_to_str` tương ứng bằng `grep -n "def emit_to_str"
release/3.code/compiler/il_features/tkvstr.tkv`).

- [ ] **Step 3: Viết test mới `dunder_str_test.tkv`**

Tạo `release/3.code/Testkit/dunder_str_test.tkv` (mẫu cú pháp record/kế
thừa lấy từ `release/3.code/Testkit/inheritance_py_tree_test.tkv` đã
có sẵn):

```python
__tkv_import__ = ["tkv_test_lib"]


class Point:
    x: "i32"
    y: "i32"

    def __str__(self) -> "str":
        return "Point(" + str(self.x) + ", " + str(self.y) + ")"


class Animal:
    name: "str"

    def __str__(self) -> "str":
        return "Animal:" + self.name


class Dog(Animal):
    breed: "str"


def run() -> "i32":
    total = 0
    tested = 0

    p = Point(3, 4)
    tested = tested + 1
    total = total + check("str_calls_dunder", str(p), "Point(3, 4)")

    tested = tested + 1
    total = total + check("print_uses_dunder_via_str", str(p), "Point(3, 4)")

    d = Dog("Rex", "Labrador")
    tested = tested + 1
    total = total + check("inherited_dunder_str", str(d), "Animal:Rex")

    return test_summary("dunder_str_test", total, tested)
```

**LƯU Ý**: `print_uses_dunder_via_str` chỉ gián tiếp xác nhận qua
`str()` (vì `check()` so sánh giá trị trả về, không bắt được output
`print()` trực tiếp trong test harness hiện có) — nếu có cách bắt
stdout trong `Testkit/` (kiểm tra 1 file test khác dùng `print()` để
xem quy ước xác nhận output), cân nhắc thêm 1 ca gọi `print(p)` thật để
xác nhận không crash/không lỗi biên dịch (không cần so khớp output
chữ, chỉ cần build+chạy không lỗi).

- [ ] **Step 4: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/dunder_str_test.tkv --entry run --out "$env:TEMP/dstr_t1.exe"
"$env:TEMP/dstr_t1.exe"
```
Expected: build PASS, `SUMMARY 3/3`.

- [ ] **Step 5: Xác nhận record KHÔNG có `__str__` vẫn báo lỗi rõ ràng
  (regression check thủ công)**

Viết 1 file `.tkv` tạm (KHÔNG thuộc plan, không commit) định nghĩa 1
record KHÔNG có `__str__`, gọi `str()` trên nó — xác nhận build THẤT
BẠI với message lỗi (không phải crash `KeyError`/`AttributeError` nội
bộ compiler). Xóa file tạm sau khi xác nhận.

- [ ] **Step 6: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/dstr_reg_${base}.exe" > "$TEMP/dstr_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/dstr_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan). ĐẶC BIỆT chú ý `inheritance_py_tree_test`
(dùng record/kế thừa nặng) không hồi quy.

- [ ] **Step 7: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đọc lại nội dung THẬT của dòng `6.5 Dunder method overload
(__eq__/__len__/__getitem__/__add__/__str__)` (hiện `[ ]`, dòng 185).
Vì đây CHỈ là 1 trong 5 dunder (chưa xong cả mục), KHÔNG đánh dấu `[x]`
toàn bộ dòng — thay vào đó, ghi chú tiến độ theo đúng cách các mục
khác đã "XONG MỘT PHẦN" (vd 5.1 `*args`/`**kwargs`, dòng 108):

```
- [ ] 6.5 Dunder method overload (`__eq__`/`__len__`/`__getitem__`/
      `__add__`/`__str__`) — **`__str__` ĐÃ XONG (2026-08-13)**, xem
      `docs/superpowers/specs/2026-08-13-dunder-str-design.md`.
      `str(r)`/`print(r)` tự động gọi `__str__` của record qua điểm
      dispatch chung `emit_to_str`, hỗ trợ kế thừa. Còn lại: `__eq__`
      (so sánh `==`), `__len__` (`len()`), `__getitem__` (`r[i]`),
      `__add__` (`+`) — mỗi cái là 1 sub-project riêng (móc vào điểm
      dispatch khác nhau).
```

(Đọc lại nội dung THẬT của file trước khi sửa — không giả định đúng
format trên nếu khác thực tế.)

- [ ] **Step 8: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/tkvstr.py \
        release/3.code/compiler/il_features/tkvstr.tkv \
        release/3.code/Testkit/dunder_str_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): __str__ cho record - str()/print() tu dong goi dunder

emit_to_str (diem dispatch chung cua str()/print()) them nhanh: dtype
la ten 1 record co __str__(self) -> "str" thi goi callvirt instance
string {owner}::__str__() (owner qua _method_owner_class, ho tro ke
thua). Validate chu ky truoc khi sinh IL - raise loi ro rang neu sai
(khac tra ve/co tham so thua), khong am tham sinh IL sai. Test moi xac
nhan __str__ hoat dong dung, ke thua dung method cha, va record khong
co __str__ van bao loi ro rang nhu cu (regression). Muc dau tien trong
5 dunder cua 6.5 - con lai __eq__/__len__/__getitem__/__add__ la
sub-project rieng.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
