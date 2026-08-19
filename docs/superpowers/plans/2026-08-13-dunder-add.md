# __add__ cho record Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `a + b` với `a`/`b` cùng kiểu record có `def __add__(self, other) -> "T": ...` tự động gọi method đó thay vì sinh opcode `add` sai/crash trên 2 tham chiếu object.

**Architecture:** Thêm 1 nhánh mới đầu `compile_binop` (`compiler/il_features/operators.py`) cho `op == '+'` và `operand_dtype` là tên 1 record — validate chữ ký `__add__` (1 tham số cùng kiểu/tổ tiên, có khai `return_type`), sinh `callvirt` qua `_method_owner_class`, return type lấy nguyên theo khai báo. Thiếu `__add__` → `SyntaxError` rõ (khác `__eq__` — không có fallback mặc định hợp lệ cho `+`).

**Tech Stack:** Python compiler (`compiler/`), self-hosted `.tkv` mirror (`release/3.code/compiler/`), CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ CẢ 2 cây: `compiler/il_features/operators.py` (Python) VÀ file mirror `.tkv` tương ứng trong `release/3.code/compiler/il_features/` (grep `def compile_binop` hoặc tương đương để định vị).
- KHÔNG rebuild `release/3.code/dist/tkvc.exe` trong bất kỳ bước nào của plan này.
- Chỉ `op == '+'`, chỉ khi CẢ 2 vế cùng kiểu record. Không đụng nhánh `'str'`/`'int'`/số học `i32`/`i64`/`f32`/`f64` hiện có.
- Record không có `__add__` → LUÔN `SyntaxError` rõ ràng (không rơi xuống nhánh `add` sinh sai).
- Không hỗ trợ `-`/`*`/`/` trên record (chỉ `__add__`, đúng phạm vi 5 dunder của 6.5).

---

### Task 1: `__add__` dispatch trong `compile_binop`

**Files:**
- Modify: `compiler/il_features/operators.py:131-231` (`compile_binop`)
- Modify: file mirror `.tkv` tương ứng trong `release/3.code/compiler/il_features/` (xác định tên file chính xác bằng cách grep `compile_binop` trong thư mục đó trước khi sửa)
- Create: `release/3.code/Testkit/dunder_add_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (đánh dấu mục 6.5 ĐÃ XONG cả 5/5 dunder — đây là dunder cuối cùng)

**Interfaces:**
- Consumes: `ctx['records']`, `ctx['record_methods']`, `ctx['record_bases']`, `ctx['il_type_str']`, `ctx['compile_expr']`, `_method_owner_class(ctx, record_name, method_name)` từ `compiler/il_features/record_feature.py` (đã có sẵn — KHÔNG sửa file này), `_widen_if_needed` (đã có sẵn trong `il_codegen.py`, truy cập qua `ctx` — xác nhận tên khoá chính xác bằng cách xem cách `__eq__`'s `compile_compare` gọi widen nếu có, hoặc gọi trực tiếp nếu `operators.py` đã import).
- Produces: không có API mới cho task khác — leaf change.

- [ ] **Step 1: Đọc lại đúng đoạn code hiện tại của `compile_binop`**

Đọc `compiler/il_features/operators.py` dòng 131-231 để xác nhận số dòng chính xác. Xác nhận `_method_owner_class` được import cục bộ (`from il_features.record_feature import _method_owner_class`) đúng như cách `compile_compare` đã làm ở dòng ~332 (cùng file này) — copy cùng cách import.

Xác nhận `_widen_if_needed` — kiểm tra xem `compile_compare`/các hàm khác trong `operators.py` có gọi widen ở đâu không (thực tế `compile_compare` KHÔNG cần widen vì kết quả so sánh luôn `i32` cố định). Nếu `operators.py` chưa có sẵn cách gọi widen, kiểm tra `ctx` có key `widen_if_needed` hay tương đương được core (`il_codegen.py`) tiêm vào không (grep `ctx\[.widen` hoặc đọc chỗ `ctx = {...}` được khởi tạo trong `il_codegen.py`/`tkv_compile.py`). Nếu KHÔNG có sẵn trong `ctx`, thêm 1 dòng tiêm `'widen_if_needed': _widen_if_needed` vào dict khởi tạo `ctx` ở `il_codegen.py` (tìm đúng vị trí bằng cách grep `'il_type_str':` trong `il_codegen.py`/`tkv_compile.py` — nơi các hàm khác đã được tiêm theo cùng cách, thêm dòng mới cạnh đó).

- [ ] **Step 2: Thêm nhánh `__add__` vào `compile_binop`**

Chèn đoạn sau NGAY SAU dòng tính `operand_dtype = left_dtype or right_dtype or dtype` (dòng ~144) và TRƯỚC nhánh `if operand_dtype == 'str' or ...:` hiện có:

```python
    records = (ctx or {}).get('records') or {}
    if op == '+' and operand_dtype in records:
        # __add__ cho record (6.5, dunder overload - muc 5/5, 2026-08-13):
        # a + b tren 2 gia tri CUNG kieu record co
        # __add__(self, other) -> T goi callvirt. KHONG co fallback mac
        # dinh nhu __eq__ - thieu __add__ la loi RO, khong ROI xuong
        # nhanh 'add' CIL tren 2 object reference (vo nghia/crash).
        # Xem docs/superpowers/specs/2026-08-13-dunder-add-design.md.
        record_methods = (ctx or {}).get('record_methods') or {}
        dunder = record_methods.get(operand_dtype, {}).get('__add__')
        if dunder is None:
            raise SyntaxError(
                f"il_codegen: record '{operand_dtype}' khong co __add__ - "
                f"'+' tren record can dinh nghia "
                f"'def __add__(self, other) -> \"T\": ...' (T la kieu tra ve tuy chon)")
        record_bases = (ctx or {}).get('record_bases') or {}
        ancestors = {operand_dtype}
        walk = operand_dtype
        while isinstance(record_bases.get(walk), str) and record_bases.get(walk):
            walk = record_bases[walk]
            ancestors.add(walk)
        if len(dunder.params) != 1 or \
                dunder.params[0].type_ann.dtype not in ancestors or \
                dunder.params[0].type_ann.shape != 'record' or \
                dunder.return_type is None:
            raise SyntaxError(
                f"il_codegen: record '{operand_dtype}' co __add__ nhung chu ky sai - "
                f"can dung 1 tham so CUNG kieu record (hoac to tien) va tra ve 1 kieu "
                f"bat ky ('def __add__(self, other) -> \"T\":')")
        compile_expr = ctx['compile_expr']
        compile_expr(left, scope, out, operand_dtype, ctx)
        compile_expr(right, scope, out, operand_dtype, ctx)
        from il_features.record_feature import _method_owner_class
        owner = _method_owner_class(ctx, operand_dtype, '__add__')
        param_il = ctx['il_type_str'](dunder.params[0].type_ann, records)
        ret_dtype, ret_shape = dunder.return_type.dtype, dunder.return_type.shape
        ret_il = ctx['il_type_str'](dunder.return_type, records)
        out.append(f'    callvirt instance {ret_il} {owner}::__add__({param_il})')
        if ret_shape is None:
            ctx['widen_if_needed'](ret_dtype, dtype, out)
        return
```

Lý do từng phần (giống lập luận đã dùng cho `__eq__`/`__getitem__`, không lặp lại chi tiết ở đây — đọc `compile_compare` trong cùng file và nhánh `record` của `_expr_index` trong `il_codegen.py` nếu cần đối chiếu mẫu).

QUAN TRỌNG: đoạn này PHẢI đặt trước dòng `if operand_dtype == 'str' or (op == '*' and ...)：` hiện có (dòng ~145 hiện tại) — record dtype không bao giờ `== 'str'` nên thứ tự trước/sau không xung đột, nhưng đặt sớm giúp mạch đọc rõ ràng (theo đúng comment trong plan).

- [ ] **Step 3: Xác nhận `dunder.params[0].type_ann.shape != 'record'` là điều kiện đúng**

Kiểm tra cách `TypeAnn` biểu diễn tham số kiểu record trong khai báo hàm (vd `def __add__(self, other) -> "T":` với `other` được parse thành `TypeAnn(dtype='Point', shape='record')` — xác nhận bằng cách đọc lại đoạn validate của `__eq__` trong `compile_compare` (dòng ~317-329 file này) — chữ ký đó dùng `dunder.params[0].type_ann.dtype not in ancestors` nhưng KHÔNG kiểm tra `shape` — đọc kỹ xem có cần thêm `shape != 'record'` hay không (có thể dư thừa nếu `dtype` đã đủ phân biệt, vì dtype của record LÀ tên class, không trùng với dtype vô hướng nào khác). Nếu xác nhận dư thừa, bỏ điều kiện `shape` để nhất quán với `__eq__` — ưu tiên GIỐNG HỆT logic `__eq__` đã được review chấp thuận, trừ khi có lý do kỹ thuật thật để khác.

- [ ] **Step 4: Viết test `release/3.code/Testkit/dunder_add_test.tkv`**

Đọc `dunder_eq_test.tkv`/`dunder_getitem_test.tkv` trước để khớp cú pháp record/kế thừa/format `SUMMARY N/N` hiện có. Case bắt buộc:

1. Record `Point(x: i32, y: i32)` với
   `def __add__(self, other) -> "Point": return Point(self.x + other.x, self.y + other.y)`
   — `p3 = p1 + p2`, in `p3.x`/`p3.y`, xác nhận đúng tổng từng field
   (return type CÙNG kiểu record).
2. Record khác (hoặc method khác trên `Point`) với `__add__` trả về
   kiểu SCALAR (vd `i32`, tổng `x+y` của 2 điểm) — xác nhận không bị
   ép sai kiểu, giống cách `__getitem__` đã kiểm chứng "return type
   không ép cứng".
3. Record con kế thừa KHÔNG tự định nghĩa `__add__` nhưng lớp cha có —
   `c1 + c2` (cả 2 cùng kiểu con) vẫn dùng đúng method cha.

Case lỗi (record không có `__add__`) xác nhận bằng spike riêng ở Step
6, KHÔNG đưa vào test chính.

- [ ] **Step 5: Build và chạy test qua cây `.py`**

```bash
python tkv.py build "D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_add_test.tkv" --entry run --out "D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_add_test.exe"
"D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_add_test.exe"
```

(Lệnh build xác nhận đúng từ report của task `__getitem__` trước đó —
nếu khác, dùng lệnh thật đang hoạt động trong dự án.)

Expected: build sạch, `SUMMARY N/N` đúng số case đã viết, không FAIL.

- [ ] **Step 6: Spike xác nhận case lỗi (không đưa vào test chính)**

File `.tkv` tạm với 1 record KHÔNG có `__add__`, thử `r1 + r2` — xác
nhận `SyntaxError` rõ có chữ `__add__` (không phải crash mơ hồ hay
`ilasm` lỗi khó hiểu). Xoá file spike sau khi xác nhận.

- [ ] **Step 7: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

Đặc biệt các test dùng `+` trên scalar/string (`str`/`i32`/`i64`/
`f32`/`f64`/`int` BigInteger) và 4 test dunder trước
(`dunder_str_test`, `dunder_eq_test`, `dunder_len_test`,
`dunder_getitem_test`) — xác nhận KHÔNG regression (trừ lỗi
pre-existing đã biết `path_isfile_isdir_test` nếu còn).

- [ ] **Step 8: Mirror sang cây `.tkv` tự-host**

Sửa file mirror tương ứng trong `release/3.code/compiler/il_features/`
với logic TƯƠNG ĐƯƠNG Step 2, bám đúng convention/style hiện có của
file đó (tham khảo đoạn `__eq__` đã mirror trong cùng file, nếu file
mirror của `operators.py` đã có đoạn đó).

- [ ] **Step 9: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đánh dấu mục 6.5 "Dunder method overload" ĐÃ XONG HOÀN TOÀN (5/5:
`__str__`/`__eq__`/`__len__`/`__getitem__`/`__add__`), trỏ tới cả 5
file spec tương ứng.

- [ ] **Step 10: Commit**

```bash
git add compiler/il_features/operators.py <duong-dan-file-mirror-tkv-that> release/3.code/Testkit/dunder_add_test.tkv docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): __add__ dunder cho record (a + b -> callvirt) - hoan tat 6.5 (5/5 dunder)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
