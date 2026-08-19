# __add__ cho record — Design

## Bối cảnh

`compile_binop` (`compiler/il_features/operators.py`, dòng ~131) suy
`operand_dtype` qua `infer_dtype(left, scope, func_table)` — với 1
biến record, `_infer_dtype`'s nhánh `tag == 'var'` trả về
`scope[node[1]][2].dtype`, tức TÊN CLASS record (vd `'Point'`), không
phải 1 dtype vô hướng. `operand_dtype` này không khớp `'str'` (nhánh
concat) cũng không khớp `'int'` (nhánh BigInteger), nên rơi thẳng
xuống nhánh chung cuối hàm: `compile_expr` sinh IL đẩy 2 giá trị,
kiểm tra `operand_dtype in ctx['int_dtypes']` (sai với record) rồi
phát thẳng opcode CIL `add`/`sub`/`mul`/`div`/`rem` — với record (kiểu
`class`, reference type) `add` trên 2 tham chiếu object là VÔ NGHĨA
(ilasm có thể assemble được nhưng hành vi runtime sai/crash). Khác
`__eq__` (thiếu `__eq__` vẫn có hành vi mặc định hợp lệ - so sánh
reference), `'+'` trên record không có nghĩa mặc định nào — cần báo
lỗi RÕ nếu thiếu `__add__`, không được để rơi xuống nhánh sinh `add`
sai. Đây là dunder CUỐI CÙNG (5/5) trong 6.5, sau `__str__`
(`458816a`), `__eq__` (`a4053b8`), `__len__` (`6a061ca`),
`__getitem__` (`29cc149`).

## Mục tiêu

`a + b` với `a`/`b` CÙNG kiểu record có định nghĩa
`def __add__(self, other) -> "T": ...` sẽ TỰ ĐỘNG gọi method đó, `T`
là kiểu trả về tuỳ ý (có thể là 1 record khác, hoặc scalar) — không ép
cứng kiểu như `__len__`/`__eq__`, giống cách `__getitem__` đã làm.

## Kiến trúc

Sửa `compile_binop` (`compiler/il_features/operators.py`): thêm nhánh
MỚI ngay đầu hàm (sau khi tính `operand_dtype`), TRƯỚC nhánh
`if operand_dtype == 'str' or ...:` hiện có — khi
`op == '+'` VÀ `operand_dtype` là tên 1 record (tra `ctx['records']`):

1. **Tra `__add__`**: `ctx['record_methods'].get(operand_dtype, {}).get('__add__')`.
   Không tìm thấy → `SyntaxError` rõ ("record '{X}' khong co __add__ -
   '+' tren record can dinh nghia
   'def __add__(self, other) -> \"T\": ...'").
2. **Validate chữ ký** (khi tìm thấy): đúng 1 tham số (`other`) — kiểu
   PHẢI là `operand_dtype` HOẶC 1 tổ tiên của nó trong `record_bases`
   (đi lại đúng thuật toán "walk ancestor chain" đã sửa cho `__eq__`,
   tránh lặp lại bug tương tự khi method được kế thừa), `return_type`
   PHẢI được khai báo (không `None` — record method mặc định `void`
   nếu không có `-> "T"`). KHÔNG ép cứng `return_type.dtype`/`shape` cụ
   thể (khác `__eq__`/`__len__` — `T` tuỳ ý, đúng tinh thần
   `__getitem__`).
3. **Sinh IL**: `compile_expr(left, ..., operand_dtype, ctx)` đẩy
   `self`, `compile_expr(right, ..., operand_dtype, ctx)` đẩy `other`,
   rồi `callvirt instance {ret_il} {owner}::__add__({param_il})`
   (`owner` qua `_method_owner_class`, `ret_il`/`param_il` qua
   `il_type_str` — cùng cơ chế đã dùng cho `__eq__`/`__getitem__`).
   Nếu `return_type.shape is None` (scalar) → `_widen_if_needed`.
4. Hàm `compile_binop` TRẢ VỀ ngay sau khi sinh xong (không rơi tiếp
   xuống các nhánh `int`/`str`/số học phía dưới).

## Phạm vi

- CHỈ `op == '+'` — không mở rộng `-`/`*`/`/`/`%`/`**`/`//` (chỉ 1
  dunder `__add__` được liệt kê trong 5 dunder của 6.5; các toán tử
  khác cần `__sub__`/`__mul__`/... riêng, ngoài phạm vi).
- CHỈ khi CẢ 2 vế CÙNG kiểu record (giống giới hạn đã áp dụng cho
  `__eq__`) — không hỗ trợ `record + scalar` hay `record + record khác
  kiểu`.
- Record không có `__add__` → LUÔN `SyntaxError` (khác `__eq__` — ở
  đây không có "hành vi mặc định hợp lý" để rơi về, vì CIL `add` trên
  2 object reference không có ngữ nghĩa Python tương ứng).
- Không đụng nhánh `'str'` (concat)/`'int'` (BigInteger)/số học
  `i32`/`i64`/`f32`/`f64` hiện có trong `compile_binop`.

## Kiểm chứng

- Test mới: record CÓ `__add__` trả về CÙNG kiểu record (vd
  `Point.__add__` cộng từng field, trả `Point` mới) — `a + b` trả
  đúng field. record CÓ `__add__` trả về kiểu KHÁC (vd `i32`, tổng 2
  field) — xác nhận không bị ép sai kiểu. Record CON (kế thừa) không
  tự định nghĩa `__add__` nhưng lớp CHA có — vẫn dùng đúng method của
  cha (kể cả kế thừa nhiều tầng). Record KHÔNG có `__add__` — spike
  riêng xác nhận `SyntaxError` rõ (không đưa vào test chính vì test
  chính phải build+chạy thành công).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `+` trên
  `i32`/`i64`/`f32`/`f64`/`str`/`int` hiện có không đổi hành vi.
- Cả 2 cây (`compiler/il_features/operators.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
