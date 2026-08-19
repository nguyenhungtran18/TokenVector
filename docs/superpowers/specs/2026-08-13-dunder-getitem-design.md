# __getitem__ cho record — Design

## Bối cảnh

`_expr_index` (`compiler/il_codegen.py`, dòng ~1104) là điểm dispatch
LÕI xử lý `<biến>[i]` — hiện chỉ hỗ trợ `type_ann.shape` trong
`('list', 'dict', 'defaultdict', 'counter')`, chuỗi (`dtype=='str'`,
`shape is None`), hoặc báo lỗi rõ cho `set` (không có indexer). Trường
hợp `type_ann.shape is None` (không suy được) rơi vào 1 `SyntaxError`
chung. Record hiện có `type_ann.shape == 'record'` nhưng KHÔNG được
nhánh nào xử lý — tự động rơi vào lỗi generic
"'{name}[...]' khong phai list/dict/string/mang...". Đây là mục thứ 4
trong 5 dunder của 6.5, sub-project độc lập tiếp theo sau `__str__`
(commit `458816a`), `__eq__` (commit `a4053b8`), `__len__` (commit
`6a061ca`).

## Mục tiêu

`r[i]` với `r` là 1 BIẾN kiểu record có định nghĩa
`def __getitem__(self, i) -> "T": ...` sẽ TỰ ĐỘNG gọi method đó, `i`
là chỉ số nguyên (`i32`), `T` là kiểu trả về tuỳ ý do người dùng khai
báo (khác `__len__` — không ép cứng `i32`).

## Kiến trúc

Sửa `_expr_index` (`compiler/il_codegen.py`): thêm nhánh MỚI khi
`type_ann.shape == 'record'`, đặt TRƯỚC nhánh `type_ann.shape is None`
hiện có (record không rơi vào nhánh đó, nhưng đặt sớm cho rõ mạch xử
lý — giống thứ tự các nhánh `list`/`dict`/`defaultdict`/`counter`/`str`
đã có):

1. **Giới hạn số chiều**: `len(indices) != 1` → `SyntaxError` rõ
   ("record chi ho tro 1 chi so — khong ho tro r[i, j]").
2. **Validate chữ ký `__getitem__`**: tra `ctx['record_methods']` (qua
   `record_methods.get(type_ann.dtype, {}).get('__getitem__')`, dùng
   `ctx` truyền vào `_expr_index` — cần thêm tham số `ctx` nếu hàm
   hiện tại chưa nhận, xác nhận lại khi đọc code thật). Không tìm thấy
   → `SyntaxError` rõ, mở rộng thông báo lỗi generic hiện có ("hoac 1
   record co `__getitem__`"). Tìm thấy → validate: đúng 1 tham số
   (`i`), tham số đó PHẢI `dtype='i32'`, `shape=None` (chỉ hỗ trợ chỉ
   số nguyên — không hỗ trợ slice/key kiểu khác). Return type LẤY
   NGUYÊN từ khai báo `__getitem__` (không ép `i32` như `__len__` —
   phần tử trả về có thể là bất kỳ kiểu nào record khai báo, kể cả
   `str`/`f64`/record khác).
3. **Sinh IL**: `_load_var_ref(name, scope, out)` đẩy record instance,
   compile chỉ số (`indices[0]`) thành `i32` (dùng lại
   `_compile_expr(idx_node, scope, out, 'i32', ctx)`, KHÔNG có nhánh
   chỉ số âm hằng số đặc biệt như mảng cố định — record là dữ liệu
   động, không có kích thước biết trước compile-time), rồi
   `callvirt instance {ret_il_type} {owner}::__getitem__(int32)`
   (`owner` qua `_method_owner_class`, hỗ trợ kế thừa — cùng cơ chế đã
   dùng cho `__str__`/`__eq__`/`__len__`), rồi
   `_widen_if_needed(return_dtype, dtype, out)` nếu return type là
   scalar đơn giản (không phải container — record method chỉ khai báo
   kiểu trả về đơn theo cú pháp hiện có của DSL, không cần xử lý case
   container phức tạp).

## Phạm vi

- CHỈ hỗ trợ `r[i]` — `r` là BIẾN record ĐƠN (nhánh `_expr_index`,
  `node[1]` là tên biến). KHÔNG mở rộng `<biểu thức>[i]` (nhánh
  `_expr_index_expr` riêng, vd `get_record()[0]`) — ngoài phạm vi,
  giống giới hạn đã áp dụng cho `__len__`.
- CHỈ hỗ trợ chỉ số NGUYÊN đơn (`i32`) — không hỗ trợ slice
  (`r[1:3]`), không hỗ trợ key kiểu khác (`r["key"]`) — Python thật
  cho phép `__getitem__` nhận bất kỳ kiểu key nào, nhưng DSL này tĩnh
  kiểu và mọi indexer hiện có (list/dict) đã phân biệt rõ theo shape,
  nên `__getitem__` trên record thu hẹp về đúng ngữ nghĩa "list-like"
  phổ biến nhất (chỉ số nguyên) — nếu cần dict-like sau này là 1
  sub-project riêng.
- KHÔNG hỗ trợ `__setitem__` (gán `r[i] = x`) — ngoài phạm vi 5 dunder
  đã liệt kê ở 6.5 (chỉ có `__getitem__`, không có `__setitem__`).
- KHÔNG hỗ trợ chỉ số âm (`r[-1]`) — giống giới hạn hiện có của
  `_expr_index_expr` (biểu thức phức tạp), vì `__getitem__` do người
  dùng tự viết logic bên trong, "chỉ số âm" không có ngữ nghĩa cố định
  sẵn để compiler tự động chuyển đổi (khác mảng cố định kích thước biết
  trước) — người dùng tự xử lý chỉ số âm trong thân `__getitem__` nếu
  muốn.

## Kiểm chứng

- Test mới: record CÓ `__getitem__` trả về kiểu scalar (vd `i32`) —
  `r[i]` với vài giá trị `i` khác nhau trả đúng giá trị người dùng
  định nghĩa (vd wrapper quanh 1 field kiểu list nội bộ, hoặc công
  thức tính trực tiếp từ `i`). Record CON (kế thừa) không tự định
  nghĩa `__getitem__` nhưng lớp CHA có — vẫn dùng đúng method của cha.
  Record KHÔNG có `__getitem__` — vẫn raise lỗi rõ như cũ (regression
  check). `__getitem__` trả về kiểu khác (vd `str`) — xác nhận không
  ép `i32`.
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — index trên
  `list`/`dict`/`defaultdict`/`counter`/`str` hiện có không đổi hành
  vi.
- Cả 2 cây (`compiler/il_codegen.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
