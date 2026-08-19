# __eq__ cho record — Design

## Bối cảnh

`compile_compare` (`compiler/il_features/operators.py`) hiện suy
`operand_dtype` từ 2 toán hạng qua `_resolve_compare_operand_dtype`
(`il_codegen.py`), xử lý riêng `str`/`int`, còn lại (kể cả record —
dtype là tên class) rơi vào nhánh chung: đẩy cả 2 giá trị lên stack rồi
dùng `ceq`/`cgt`/`clt`. Với record (reference type), `ceq` cho ra SO
SÁNH REFERENCE (giống Python mặc định khi không override `__eq__`),
KHÔNG PHẢI so sánh nội dung. Đây là mục thứ 2 trong 5 dunder của 6.5,
sub-project độc lập tiếp theo sau `__str__` (đã xong, commit `458816a`).

## Mục tiêu

`a == b`/`a != b` với `a`/`b` cùng kiểu record có định nghĩa `def
__eq__(self, other) -> "i32": ...` sẽ TỰ ĐỘNG gọi method đó thay vì so
sánh reference.

## Kiến trúc

Sửa `compile_compare` (`compiler/il_features/operators.py`): khi `op
in ('==', '!=')` VÀ `operand_dtype` là tên 1 record CÓ định nghĩa
`__eq__` (tra `ctx['record_methods']`):

1. **Validate chữ ký**: đúng 1 tham số (`other`) CÙNG kiểu record với
   `self` (dtype khớp `operand_dtype`, shape khớp record — không nhận
   kiểu khác), `return_type` đúng `dtype='i32'`, `shape=None`. Sai bất
   kỳ điều kiện nào → `SyntaxError` rõ ràng (không âm thầm sinh IL
   sai). Dự án KHÔNG có dtype `bool` riêng — mọi phép so sánh LUÔN trả
   `i32` 0/1 (đúng quy ước docstring gốc của `compile_compare`), nên
   `__eq__` PHẢI khai `-> "i32"`, không phải kiểu nào khác.
2. **Sinh IL**: `compile_expr(left, ..., operand_dtype, ctx)` đẩy
   `self`, `compile_expr(right, ..., operand_dtype, ctx)` đẩy `other`
   — đúng thứ tự stack cho
   `callvirt instance int32 {owner}::__eq__({record_type})` (`owner`
   qua `_method_owner_class(ctx, operand_dtype, '__eq__')`, hỗ trợ kế
   thừa — cùng cơ chế đã dùng cho `__str__`).
3. Nếu `op == '!='`: phủ định kết quả qua `ldc.i4.0; ceq` (đúng pattern
   phủ định đã dùng ở nhánh `else` hiện có của `compile_compare` cho
   các toán tử suy từ phủ định — vd `!=` suy từ `==`, `>=` suy từ `<`).
4. Record KHÔNG có `__eq__` → giữ NGUYÊN hành vi cũ (so sánh reference
   qua `ceq`/`bne.un` như hiện tại — KHÔNG phải lỗi, là hành vi mặc
   định giống Python khi không override `__eq__`).

## Phạm vi

- Chỉ so sánh 2 giá trị CÙNG kiểu record — không hỗ trợ so sánh khác
  kiểu record với nhau (giống hầu hết ngôn ngữ tĩnh, và Python thật
  cũng thường trả `NotImplemented`/`False` khi kiểu không khớp — DSL
  này không mô phỏng `NotImplemented`, ngoài phạm vi).
- KHÔNG hỗ trợ override `__ne__` riêng — `!=` LUÔN suy tự động từ phủ
  định `__eq__` (đúng đa số trường hợp thực tế trong Python, override
  `__ne__` riêng biệt là hiếm gặp).
- Chỉ áp dụng cho toán tử `==`/`!=` — không ảnh hưởng `<`/`>`/`<=`/`>=`
  (những toán tử đó cần `__lt__`/`__gt__`/... riêng, ngoài phạm vi 5
  dunder đã liệt kê ở 6.5).

## Kiểm chứng

- Test mới: record CÓ `__eq__` — `a == b` với nội dung GIỐNG nhau (2
  instance khác nhau nhưng field giống hệt) → `True`/1, KHÁC nhau →
  `False`/0; `a != b` phủ định đúng. Record CON (kế thừa) không tự
  định nghĩa `__eq__` nhưng lớp CHA có — vẫn dùng đúng method của cha.
  Record KHÔNG có `__eq__` — vẫn so sánh reference như cũ (2 instance
  khác nhau dù field giống hệt vẫn `False` — regression check, xác
  nhận hành vi CŨ không đổi).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — so sánh `==`/`!=`
  trên `i32`/`i64`/`f32`/`f64`/`str`/`int` hiện có không đổi hành vi.
- Cả 2 cây (`compiler/il_features/operators.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
