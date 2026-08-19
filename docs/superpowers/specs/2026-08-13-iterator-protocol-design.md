# Iterator protocol tuỳ biến (`__iter__`/`__next__`) — Design

## Bối cảnh

`for x in ...:` hiện chỉ có 2 dạng: `for x in range(...)` (đếm số,
`try_parse_for`/`codegen_for` trong `compiler/il_features/control_flow.py`,
dòng ~433-676 — vòng lặp CIL thật với biến đếm `i32`) và `for x in
<list/dict/set>:` (MACRO TEXT-LEVEL — desugar thành `for i in
range(len(lst)): x = lst[i]` TRƯỚC khi parse AST, xem
`try_expand_for_in_list`). KHÔNG có khái niệm "giao thức iterator"
thật — record không thể tự định nghĩa cách nó được duyệt trong `for`.
Đây là mục 6.7, sau khi 6.5 (5 dunder) và 6.6 (context manager) đã
xong. Ghi chú trong checklist: `product()` (đã bỏ ở batch 5.3 vì thiếu
đúng cơ chế này) sẽ dùng LẠI được hạ tầng 6.7 xây ở đây trong 1 sub-
project riêng SAU, không phải việc của batch này.

## Mục tiêu

`for x in <bien_record>:` với record có:
- `def __iter__(self) -> "IterT": ...` — trả về 1 đối tượng iterator
  (có thể là `self`, hoặc 1 record iterator riêng — kiểu tuỳ ý).
- `IterT` (kiểu record trả về bởi `__iter__`) có
  `def __next__(self) -> "(T, i32)": ...` — trả về 1 TUPLE 2 phần tử:
  `T` là giá trị phần tử, `i32` là cờ "còn phần tử" (`1`=còn, `0`=hết
  — giá trị `T` khi cờ=`0` bị BỎ QUA, không dùng).

sẽ tự động chạy đúng vòng lặp, gán `x` = giá trị mỗi lần, dừng khi cờ
về `0`.

**Quyết định thiết kế đã chốt** (thay vì `StopIteration` qua
exception như Python thật): dùng TUPLE `(T, i32)` — tránh
try/catch bên trong mỗi vòng lặp (phức tạp/rủi ro cao hơn hẳn về
codegen CIL và hiệu năng), nhất quán với triết lý dự án "tránh
exception cho control-flow bình thường" đã áp dụng xuyên suốt (vd
`set.remove()` mới là exception thật vì đó ĐÚNG LÀ lỗi, không phải
control-flow). Cú pháp khai `-> "(T, i32)"` ĐÃ được `typed_dsl_parser.py`
hỗ trợ SẴN cho MỌI vị trí return-type (không phải tính năng riêng của
`divmod`) — không cần thêm cú pháp mới ở tầng parser kiểu.

## Kiến trúc

### Nhận dạng ở `codegen_for`/first-pass

Sửa `try_parse_for`/`_FOR_RANGE_RE`... KHÔNG — `_FOR_RANGE_RE` chỉ
khớp `for x in range(...)`. Cần 1 NHÁNH SONG SONG hoàn toàn mới (không
đụng macro `for_in_list` hiện có cho list/dict/set — đó vẫn giữ đường
macro text-level riêng, KHÔNG chuyển sang giao thức mới ở batch này,
tránh rủi ro phá 12+ chỗ đang dùng `for x in lst:`).

Thêm regex `_FOR_IN_RE = re.compile(r'^for\s+(\w+)\s+in\s+(\w+)\s*:\s*$')`
và parser `try_parse_for_in_record` — CHỈ áp dụng khi biến vế phải
(tại thời điểm PARSE, biết được qua `known_shapes` — cơ chế đã có sẵn,
dùng bởi `list`/`dict`/macro khác để biết 1 tên là gì trước khi tới
codegen) là 1 record. Nếu KHÔNG phải record (vd list/dict/set/1 biến
chưa biết) → trả `None`, để macro `for_in_list`/`_FOR_RANGE_RE` xử lý
như cũ (thứ tự thử parser đúng: macro text-level `for_in_list` chạy
TRƯỚC khi vào `LINE_PARSERS`, nên `for x in lst:` KHÔNG bao giờ chạm
parser mới này — chỉ record mới rơi tới đây).

Desugar thành stmt kind `'for_in_iter'`:
```python
{'kind': 'for_in_iter', 'var': var, 'record_var': record_var_name, 'body': body}
```

### First-pass walk

Tra `record_methods[record_type]['__iter__']` — thiếu → `SyntaxError`
rõ ("record '{X}' khong co __iter__, khong dung duoc trong 'for x in
{X}:'"). Validate `__iter__`: 0 tham số, có `return_type`. Lấy
`IterT = __iter__.return_type` (dtype tên record của kiểu iterator).
Tra `record_methods[IterT.dtype]['__next__']` — thiếu → `SyntaxError`
rõ. Validate `__next__`: 0 tham số, `return_type.shape == 'tuple'`,
`len(return_type.tuple_dtypes) == 2`, phần tử THỨ HAI PHẢI `i32` (cờ
còn/hết) — sai bất kỳ điều nào → `SyntaxError` rõ ("`__next__` phai
tra ve tuple 2 phan tu (T, i32) - phan tu thu 2 la co con/het").

Khai `x` kiểu = `tuple_dtypes[0]` (giá trị phần tử). Khai 2 hidden
local: 1 giữ đối tượng iterator (`__iterobj{id(stmt)}`, kiểu `IterT`),
1 giữ tuple tạm để đọc `Item1`/`Item2` (`__iternext{id(stmt)}`, kiểu
`ValueTuple<T, i32>` — tái dùng ĐÚNG pattern `__tupleassign{id(stmt)}_tmp`
đã có trong `tuple_type.py`'s `codegen_tuple_assign`).

### Sinh IL

Y HỆT khung `codegen_while` (nhãn begin/end, `br`/`brtrue`) + gọi
method:

1. `load_var_ref(record_var)`, `callvirt instance {IterT_il}
   {owner}::__iter__()` (owner qua `_method_owner_class`), `store_var`
   vào hidden iterator local.
2. Nhãn `begin`.
3. `load_var_ref(hidden_iterobj)`, `callvirt instance
   valuetype...ValueTuple\`2<T,i32> {owner_next}::__next__()`,
   `stloc.s` vào hidden tuple local.
4. `ldloc.s hidden_tuple; ldfld !1 ...::Item2` (cờ) → `brfalse end`
   (cờ=0 → thoát).
5. `ldloc.s hidden_tuple; ldfld !0 ...::Item1` → `store_var(x)`.
6. Sinh thân khối (`codegen_stmts_fn`) — `break`/`continue` dùng CHUNG
   cơ chế nhãn `begin`/`end` hiện có của `codegen_while`/`codegen_for`
   (đọc lại `ctx['break_label']`/`ctx['continue_label']` hoặc tương
   đương đã tồn tại trong `codegen_while` để tái dùng ĐÚNG, không tự
   chế cơ chế mới).
7. `br begin`. Nhãn `end`.

## Phạm vi

- CHỈ `for x in <bien_record>:` (biến ĐƠN đã khai báo, không
  constructor call/biểu thức phức tạp) — giống giới hạn đã áp dụng
  nhiều lần trước (`with`, `__len__`, `__getitem__`).
- KHÔNG đụng macro `for_in_list` hiện có (`for x in <list/dict/set>:`
  vẫn macro text-level như cũ, KHÔNG refactor sang giao thức mới ở
  batch này — đó là rủi ro lớn, để dành cho 1 sub-project riêng SAU
  nếu thật sự cần thống nhất, không phải mục tiêu 6.7).
- KHÔNG tự động làm lại `product()`/`chain()` (việc của 5.3, dùng LẠI
  hạ tầng này sau, không phải phạm vi batch này).
- `break`/`continue` bên trong `for x in <record>:` hoạt động bình
  thường (tái dùng cơ chế nhãn có sẵn).
- `IterT` có thể CHÍNH LÀ record gốc (`__iter__` trả `self`) — không
  bắt buộc phải là 1 record iterator riêng, tuỳ người dùng.

## Kiểm chứng

- Test mới: record có `__iter__`/`__next__` (vd `Range` tự định nghĩa
  lặp qua 1 khoảng, hoặc `LinkedList` lặp qua node) — `for x in r:`
  duyệt đúng thứ tự, đúng số lần, dừng đúng khi hết. `break`/`continue`
  bên trong hoạt động đúng. `IterT` KHÁC record gốc (record riêng cho
  iterator, kiểu `__iter__` trả về không phải `self`) — xác nhận vẫn
  hoạt động đúng. Record kế thừa dùng `__iter__`/`__next__` của cha
  (không tự định nghĩa) — vẫn đúng qua `_method_owner_class`. Record
  thiếu `__iter__` hoặc `IterT` thiếu `__next__` — spike riêng xác
  nhận `SyntaxError` rõ.
- Regression toàn bộ `Testkit/*.tkv` — `for x in range(...)`/`for x in
  list/dict/set:` hiện có KHÔNG đổi hành vi (macro `for_in_list` không
  bị đụng).
- Cả 2 cây (`compiler/il_features/control_flow.py`/`.tkv`) sửa đồng
  bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
