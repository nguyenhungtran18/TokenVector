# __str__ cho record — Design

## Bối cảnh

`str(x)`/`print(x)` dùng chung 1 điểm dispatch trung tâm: `emit_to_str(dtype,
out, ctx)` (`compiler/il_features/tkvstr.py`) — hiện chỉ nhận
`str`/`int`/`i32`/`i64`/`f32`/`f64`/`bool`, `dtype` khác (kể cả tên 1
record) raise `SyntaxError` rõ ràng ("chua co duong chuyen '{dtype}'
sang chuoi"). Đây là mục đầu tiên trong 5 dunder method của 6.5
(`docs/PYTHON_GAP_CHECKLIST.md`) — quyết định tách thành sub-project
riêng vì mỗi dunder móc vào 1 điểm dispatch khác nhau.

Method trên record (kể cả tên có dấu gạch dưới đôi như `__str__`) ĐÃ
compile được như method thường — `tkv_compile.py` chỉ đặc cách bỏ qua
`__init__` lúc biên dịch, mọi method khác (bất kể tên) đều sinh CIL
instance method thật. Chỉ THIẾU bước DISPATCH TỰ ĐỘNG khi gọi
`str()`/`print()` trên 1 giá trị record.

## Mục tiêu

`str(r)`/`print(r)` với `r` là record có định nghĩa `def __str__(self)
-> "str": ...` sẽ TỰ ĐỘNG gọi method đó thay vì raise lỗi biên dịch.

## Kiến trúc

Mở rộng `emit_to_str` (`compiler/il_features/tkvstr.py`) — trước nhánh
`else: raise SyntaxError(...)` hiện tại, thêm kiểm tra: nếu `dtype` là
tên 1 record đã khai báo (`dtype in ctx.get('records', {})`) VÀ record
đó có `__str__` trong `ctx['record_methods'][dtype]`:

1. **Validate chữ ký**: `__str__` PHẢI đúng 0 tham số (ngoài `self`
   ngầm định), PHẢI có `return_type` với `dtype='str'`, `shape=None`.
   Sai bất kỳ điều kiện nào → `SyntaxError` rõ ràng (không âm thầm sinh
   IL sai — khớp kỷ luật dự án).
2. **Sinh IL**: giá trị record ĐÃ CÓ SẴN trên stack (đúng hợp đồng của
   `emit_to_str` — "Gia tri kieu dtype DANG NAM TREN STACK"). Gọi thẳng
   `callvirt instance string {owner}::__str__()`, với `owner` tra qua
   `_method_owner_class(ctx, dtype, '__str__')` (hàm có sẵn trong
   `record_feature.py`, hỗ trợ kế thừa — record con không tự định
   nghĩa `__str__` nhưng lớp cha có vẫn dùng được đúng method của cha).

Vì `print()` (`print_feature.py`) và `str()` builtin CÙNG đi qua
`emit_to_str`, sửa 1 điểm này làm CẢ 2 hoạt động — đúng tinh thần
"central dispatch point" đã dùng nhiều lần trong dự án (vd `.line`
directive cho Debug PDB, batch trước).

## Phạm vi

- CHỈ áp dụng cho record — KHÔNG mở rộng sang list/dict/set/kiểu
  built-in khác (Python cũng chỉ cho `__str__` trên class người dùng
  định nghĩa theo nghĩa tương đương).
- Không hỗ trợ `__repr__` (khác `__str__`, Python phân biệt 2 cái —
  ngoài phạm vi mục 6.5 hiện tại, chỉ liệt kê 5 dunder cụ thể).
- Nếu record KHÔNG có `__str__`, giữ NGUYÊN hành vi lỗi rõ ràng hiện có
  (không tự sinh chuỗi mặc định kiểu `<ClassName object at 0x...>` như
  Python thật — ngoài phạm vi, giữ đơn giản).

## Kiểm chứng

- Test mới: record CÓ `__str__` — `str(r)`/`print(r)` cho đúng chuỗi
  người dùng định nghĩa. Record CON (kế thừa) không tự định nghĩa
  `__str__` nhưng lớp CHA có — vẫn dùng đúng method của cha. Record
  KHÔNG có `__str__` — vẫn raise lỗi rõ ràng như cũ (regression check).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — mọi `str()`/`print()`
  trên kiểu vô hướng hiện có không đổi hành vi.
- Cả 2 cây (`compiler/il_features/tkvstr.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
