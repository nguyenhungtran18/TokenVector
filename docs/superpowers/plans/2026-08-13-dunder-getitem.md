# __getitem__ cho record Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `r[i]` với `r` là biến record có `def __getitem__(self, i) -> "T": ...` tự động gọi method đó thay vì raise lỗi generic.

**Architecture:** Thêm 1 nhánh mới trong `_expr_index` (`compiler/il_codegen.py`) cho `type_ann.shape == 'record'` — validate chữ ký `__getitem__` (đúng 1 tham số `i32`), sinh `callvirt` qua `_method_owner_class` (hỗ trợ kế thừa), return type lấy nguyên từ khai báo (không ép `i32`).

**Tech Stack:** Python compiler (`compiler/`), self-hosted `.tkv` mirror (`release/3.code/compiler/`), CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ CẢ 2 cây: `compiler/il_codegen.py` (Python) VÀ `release/3.code/compiler/il_codegen.tkv` (self-hosted mirror) — nội dung 2 file phải khớp logic 100%.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe` trong bất kỳ bước nào của plan này.
- Chỉ hỗ trợ `r[i]` với `r` là BIẾN record đơn (nhánh `_expr_index`), chỉ số nguyên `i32` đơn (không slice, không đa chiều, không âm).
- Record không có `__getitem__` → `SyntaxError` rõ ràng (không silent).
- Không đụng các nhánh `list`/`dict`/`defaultdict`/`counter`/`str`/`set` hiện có trong `_expr_index`.

---

### Task 1: `__getitem__` dispatch trong `_expr_index`

**Files:**
- Modify: `compiler/il_codegen.py:1104-1163` (`_expr_index`)
- Modify: `release/3.code/compiler/il_codegen.tkv` (mirror của cùng hàm — tìm bằng cách grep `def _expr_index` hoặc tương đương trong cú pháp `.tkv`)
- Create: `release/3.code/Testkit/dunder_getitem_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (đánh dấu `__getitem__` đã xong trong mục 6.5)

**Interfaces:**
- Consumes: `ctx['record_methods']` (dict record_name -> {method_name -> Signature}), `ctx['record_bases']`, `_method_owner_class(ctx, record_name, method_name)` từ `compiler/il_features/record_feature.py` (đã có sẵn, dùng nguyên — KHÔNG sửa file này), `ctx['il_type_str'](type_ann, records)` (đã có sẵn trong `ctx` — xem cách `operators.py`'s `compile_compare` dùng `ctx['il_type_str']`), `_load_var_ref`, `_compile_expr`, `_widen_if_needed` (tất cả đã có sẵn trong `il_codegen.py`, cùng module).
- Produces: không có API mới cho task khác dùng — đây là điểm cuối (leaf change) trong `_expr_index`.

- [ ] **Step 1: Đọc lại đúng đoạn code hiện tại của `_expr_index`**

Đọc `compiler/il_codegen.py` dòng 1104-1163 để xác nhận số dòng chính xác (có thể lệch nhẹ nếu file đã đổi từ lúc viết plan này). Cấu trúc hiện tại (tham khảo, KHÔNG copy nguyên — chỉ để định vị nơi chèn):

```python
def _expr_index(node, scope: _Scope, out: list, dtype: str, ctx: dict = None):
    name, indices = node[1], node[2]
    _, _, type_ann = scope[name]
    if type_ann.shape == 'list':
        return _list_compile_index_list(name, indices, scope, out, dtype, ctx)
    if type_ann.shape == 'dict':
        return _dict_compile_index_dict(name, indices, scope, out, dtype, ctx)
    if type_ann.shape == 'defaultdict':
        from il_features.defaultdict_type import compile_index_defaultdict
        return compile_index_defaultdict(name, indices, scope, out, dtype, ctx)
    if type_ann.shape == 'counter':
        from il_features.counter_type import compile_index_counter
        return compile_index_counter(name, indices, scope, out, dtype, ctx)
    if type_ann.dtype == 'str' and type_ann.shape is None:
        return _string_compile_index_str(name, indices, scope, out, ctx)
    if type_ann.shape == 'set':
        raise SyntaxError(...)
    if type_ann.shape is None:
        raise SyntaxError(...)
    rank = len(type_ann.shape)
    ...
```

Ghi chú quan trọng: sau nhánh `set` và TRƯỚC nhánh `type_ann.shape is None`, KHÔNG có nhánh nào xử lý `type_ann.shape == 'record'` — nó hiện rơi thẳng xuống `rank = len(type_ann.shape)` (dòng cuối, `len('record')` = 6 → sẽ raise `'chi ho tro mang rank 1 hoac 2'` ở nhánh `else` bên dưới, SAI hoàn toàn về mặt thông báo lỗi — đây chính là bug cần sửa, không chỉ là "thêm tính năng").

- [ ] **Step 2: Thêm nhánh `record` vào `_expr_index`**

Chèn đoạn sau NGAY SAU nhánh `if type_ann.shape == 'set': raise SyntaxError(...)` và TRƯỚC nhánh `if type_ann.shape is None:`:

```python
    if type_ann.shape == 'record':
        # __getitem__ cho record (6.5, dunder overload - muc 4, 2026-08-13):
        # r[i] tren 1 BIEN record co __getitem__(self, i) -> T goi callvirt
        # thay vi raise loi generic. Xem docs/superpowers/specs/
        # 2026-08-13-dunder-getitem-design.md.
        if len(indices) != 1:
            raise SyntaxError(
                f"il_codegen: '{name}[...]' - record chi ho tro 1 chi so nguyen, "
                f"khong ho tro '{name}[i, j]' (da nhan {len(indices)} chi so)")
        record_methods = (ctx or {}).get('record_methods') or {}
        dunder = record_methods.get(type_ann.dtype, {}).get('__getitem__')
        if dunder is None:
            raise SyntaxError(
                f"il_codegen: record '{type_ann.dtype}' khong co __getitem__ - "
                f"'{name}[i]' can dinh nghia "
                f"'def __getitem__(self, i) -> \"T\": ...' (T la kieu tra ve tuy chon)")
        if len(dunder.params) != 1 or dunder.params[0].type_ann.dtype != 'i32' or \
                dunder.params[0].type_ann.shape is not None or dunder.return_type is None:
            raise SyntaxError(
                f"il_codegen: record '{type_ann.dtype}' co __getitem__ nhung chu ky sai - "
                f"can dung 1 tham so \"i32\" va tra ve 1 kieu bat ky "
                f"('def __getitem__(self, i) -> \"T\":')")
        records = (ctx or {}).get('records') or {}
        _load_var_ref(name, scope, out)
        idx_node = indices[0]
        if _neg_literal_int(idx_node) is not None:
            raise SyntaxError(
                f"il_codegen: '{name}[-i]' - __getitem__ tren record chua ho tro chi so "
                f"am (tu xu ly chi so am ben trong than __getitem__ neu can).")
        _compile_expr(idx_node, scope, out, 'i32', ctx)
        from il_features.record_feature import _method_owner_class
        owner = _method_owner_class(ctx, type_ann.dtype, '__getitem__')
        ret_dtype, ret_shape = dunder.return_type.dtype, dunder.return_type.shape
        ret_il = il_type_str(dunder.return_type, records)
        out.append(f'    callvirt instance {ret_il} {owner}::__getitem__(int32)')
        if ret_shape is None:
            _widen_if_needed(ret_dtype, dtype, out)
        return
```

Lý do từng phần:
- `len(indices) != 1`: `indices` là list các node chỉ số (cú pháp `r[i]` cho `len==1`, `r[i,j]` cho `len==2` — giống cách nhánh mảng cố định bên dưới dùng `rank = len(type_ann.shape)` cho đa chiều). Record không có khái niệm rank — luôn đúng 1 chỉ số.
- `dunder.params[0].type_ann.dtype != 'i32' or ... .shape is not None`: chỉ chấp nhận tham số chỉ số kiểu `i32` vô hướng — không nhận `i64`/`str`/container.
- `dunder.return_type is None`: hàm không khai `-> "T"` (record method mặc định trả `void` nếu không khai — tái dùng đúng field `return_type` của `Signature`, giống cách `__len__`/`__eq__` đã kiểm tra `dunder.return_type is None`).
- KHÔNG kiểm tra `ret_dtype`/`ret_shape` cụ thể (khác `__len__`/`__eq__` ép `i32`) — đây là điểm khác biệt chính của `__getitem__`: trả về kiểu tuỳ ý.
- `_neg_literal_int(idx_node)`: hàm đã có sẵn trong `il_codegen.py` (dùng ở nhánh mảng cố định phía trên) — phát hiện hằng số âm tại compile-time (vd `r[-1]`) để báo lỗi RÕ thay vì để `ilasm`/runtime lỗi mơ hồ.
- `if ret_shape is None: _widen_if_needed(...)`: chỉ widen khi kiểu trả về là SCALAR đơn (record/list/... không cần và không nên widen).

- [ ] **Step 3: Kiểm tra `il_type_str` đã import/khả dụng trong `il_codegen.py`**

`il_type_str` là hàm ĐỊNH NGHĨA NGAY TRONG `il_codegen.py` (dòng 111) — gọi trực tiếp `il_type_str(...)`, KHÔNG qua `ctx['il_type_str']` (khác `operators.py` vì đó là module riêng cần lấy qua `ctx`). Xác nhận bằng cách grep 1 lệnh gọi `il_type_str(` khác đã có trong cùng file (vd trong `_expr_index_expr` dòng 1512: `col_type = il_type_str(ta, records)`) để chắc chắn không cần import gì thêm.

- [ ] **Step 4: Viết test `release/3.code/Testkit/dunder_getitem_test.tkv`**

Tạo file test theo format các test `dunder_*_test.tkv` đã có (xem `dunder_len_test.tkv` làm mẫu cấu trúc `SUMMARY N/N`). Nội dung cụ thể (viết bằng cú pháp DSL của dự án — xác nhận cú pháp record/method chính xác bằng cách đọc `dunder_len_test.tkv`/`dunder_eq_test.tkv` trước khi viết, để khớp 100% style hiện có: khai báo record, kế thừa, in kết quả theo format `SUMMARY x/y`). Các case bắt buộc:

1. Record `Box` có field `values: list[i32]` (hoặc tương đương) và
   `def __getitem__(self, i) -> "i32": return self.values[i]` — gọi
   `b[0]`, `b[2]` với vài giá trị, xác nhận đúng.
2. Record `Box` có `def __getitem__(self, i) -> "str": ...` trả về
   `str` (không phải `i32`) — xác nhận KHÔNG bị ép kiểu sai (khác
   `__len__` luôn `i32`).
3. Record con kế thừa (`SubBox(Box)`) KHÔNG tự định nghĩa
   `__getitem__` nhưng lớp cha có — `sb[1]` vẫn dùng đúng method cha.
4. (Không test case lỗi runtime trong file `SUMMARY` — case "record
   không có `__getitem__`" và "chữ ký sai" được xác nhận bằng spike
   riêng ở Step 6, giống cách `__len__`/`__eq__` đã làm, KHÔNG đưa
   vào file test chính vì file test chính phải build+chạy thành công.)

In kết quả theo dạng `SUMMARY 3/3` (hoặc số lượng case thật đã viết) giống các test dunder trước.

- [ ] **Step 5: Build và chạy test qua cây `.py`**

```bash
python "D:\Claude AI Project\TokenVector\tkv_compile.py" "D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_getitem_test.tkv" -o "D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_getitem_test.exe"
"D:\Claude AI Project\TokenVector\release\3.code\Testkit\dunder_getitem_test.exe"
```

Expected: build thành công (không lỗi `ilasm`), chạy in ra `SUMMARY N/N` với N/N khớp (không có case FAIL).

(Nếu lệnh build thực tế của dự án khác cú pháp trên — kiểm tra lại bằng cách xem cách task `__len__`/`__eq__` trước đó đã build, vd đọc `.superpowers/sdd/progress.md` hoặc report file cũ nếu còn, để dùng ĐÚNG lệnh build/run thật của dự án thay vì đoán.)

- [ ] **Step 6: Spike xác nhận case lỗi (không đưa vào test chính)**

Viết 1 file `.tkv` tạm (KHÔNG commit, xoá sau khi xác nhận) với 1 record KHÔNG có `__getitem__`, thử `r[0]` — xác nhận compiler raise đúng `SyntaxError` với thông báo có chữ `__getitem__` (không phải crash generic mơ hồ). Tương tự 1 spike khác cho record có `__getitem__` nhưng chữ ký sai (vd tham số kiểu `str` thay vì `i32`) — xác nhận raise đúng lỗi chữ ký. Xoá cả 2 file spike sau khi xác nhận xong.

- [ ] **Step 7: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

Build + chạy lại toàn bộ các file `.tkv` trong `release/3.code/Testkit/` (đặc biệt: `dunder_str_test`, `dunder_eq_test`, `dunder_len_test`, và mọi test dùng index trên `list`/`dict`/`defaultdict`/`counter`/`str` — vd `list_type_test`, `dict_type_test` nếu tồn tại, xác nhận tên file thật bằng cách liệt kê thư mục trước). Xác nhận KHÔNG có regression mới (trừ lỗi pre-existing đã biết `path_isfile_isdir_test`, nếu vẫn còn).

- [ ] **Step 8: Mirror sang cây `.tkv` tự-host**

Sửa `release/3.code/compiler/il_codegen.tkv` với logic TƯƠNG ĐƯƠNG đoạn code Python ở Step 2 (cú pháp DSL của chính dự án — tham khảo cách `__len__`/`__eq__` đã mirror trong cùng file này ở các đoạn tương ứng đã tồn tại, giữ đúng style/convention hiện có của file `.tkv`, KHÔNG phải dịch máy móc từng dòng Python).

- [ ] **Step 9: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Cập nhật dòng mục 6.5 để phản ánh `__getitem__` đã xong (theo cùng format annotation đã dùng cho `__str__`/`__eq__`/`__len__` trước đó — trỏ tới file spec này), còn lại `__add__` là dunder cuối cùng chưa làm.

- [ ] **Step 10: Commit**

```bash
git add compiler/il_codegen.py release/3.code/compiler/il_codegen.tkv release/3.code/Testkit/dunder_getitem_test.tkv docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): __getitem__ dunder cho record (r[i] -> callvirt)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
