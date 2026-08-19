# __len__ cho record — Design

## Bối cảnh

`len()` được xử lý ở LÕI (`compiler/il_codegen.py`'s `_expr_call`,
KHÔNG qua registry `il_features`) — nhánh `len(<biến>)` (dòng ~1611-1628)
hiện chỉ nhận `arg_ta.shape in ('list', 'dict', 'set')` hoặc chuỗi
(`arg_ta.dtype == 'str'`), còn lại `raise SyntaxError` rõ ràng ("len()
hien CHI ho tro list/dict/set/string"). Đây là mục thứ 3 trong 5 dunder
của 6.5, sub-project độc lập tiếp theo sau `__str__`
(commit `458816a`) và `__eq__` (commit `a4053b8`).

## Mục tiêu

`len(r)` với `r` là 1 BIẾN kiểu record có định nghĩa `def __len__(self)
-> "i32": ...` sẽ TỰ ĐỘNG gọi method đó.

## Kiến trúc

Sửa `_expr_call` (`compiler/il_codegen.py`), nhánh `if name == 'len':`
— TRƯỚC `raise SyntaxError` hiện tại (dòng ~1614-1618), thêm kiểm tra:
nếu `arg_ta.shape == 'record'`:

1. **Validate chữ ký**: `__len__` PHẢI đúng 0 tham số (ngoài `self`
   ngầm định), PHẢI trả về `dtype='i32'`, `shape=None`. Sai bất kỳ điều
   kiện nào → `SyntaxError` rõ ràng.
2. **Sinh IL**: `_load_var_ref(arg[1], scope, out)` (đã có sẵn, dùng
   chung với nhánh list/dict/set phía dưới) đẩy record instance lên
   stack, rồi `callvirt instance int32 {owner}::__len__()` (`owner` qua
   `_method_owner_class` — import cục bộ từ `record_feature.py`, cùng
   cơ chế đã dùng cho `__str__`/`__eq__`, hỗ trợ kế thừa), rồi
   `_widen_if_needed('i32', dtype, out)` giống nhánh list/dict/set kế
   bên.
3. Record KHÔNG có `__len__` → raise lỗi rõ ràng (mở rộng message lỗi
   hiện có để nhắc thêm khả năng "hoặc 1 record có `__len__`", giống
   cách message lỗi của `emit_to_str` đã được cập nhật ở batch
   `__str__`).

## Phạm vi

- CHỈ hỗ trợ `len(<biến>)` — biến đơn, GIỐNG giới hạn hiện có của nhánh
  `len()` var-arg (nhánh `_compile_len_of_expr` riêng cho biểu thức
  phức tạp KHÔNG được mở rộng trong batch này — ngoài phạm vi, giống
  giới hạn "chỉ 1 biến đơn" đã áp dụng cho `sample`/`choice`/`shuffle`
  trước đó).
- Không đụng nhánh `list`/`dict`/`set`/`str` hiện có.

## Kiểm chứng

- Test mới: record CÓ `__len__` — `len(r)` trả đúng giá trị người dùng
  định nghĩa. Record CON (kế thừa) không tự định nghĩa `__len__` nhưng
  lớp CHA có — vẫn dùng đúng method của cha (kể cả kế thừa nhiều tầng,
  theo đúng cách `__eq__` đã kiểm chứng). Record KHÔNG có `__len__` —
  vẫn raise lỗi rõ ràng như cũ (regression check).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `len()` trên
  `list`/`dict`/`set`/`str` hiện có không đổi hành vi.
- Cả 2 cây (`compiler/il_codegen.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
