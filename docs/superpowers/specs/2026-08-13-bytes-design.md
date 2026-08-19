# `bytes` — Design

## Bối cảnh

`_EXPR_TOKEN_RE` (`compiler/il_core.py`, dòng ~146-156 — tokenizer
biểu thức DÙNG CHUNG cho toàn bộ `il_features/*.py`, KHÔNG phải
`typed_dsl_parser.py` — đó là parser riêng cho CHỮ KÝ KIỂU, không
phải biểu thức giá trị) hiện KHÔNG có token cho `b"..."`. `bytearray`
(6.8 mục 3/4, commit `3773217`) đã xây xong hạ tầng đọc `List<uint8>`
(`bytearray_type.py`'s `il_bytearray_type()`, `il_type_str`'s nhánh
`shape == 'bytearray'`, index/len/for-in dùng chung). Đây là mục CUỐI
(4/4) của 6.8.

## Mục tiêu

`data = b"AB"` — literal `bytes` (CHỈ ký tự ASCII, escape giống string
literal thường) — tạo 1 `List<uint8>` BẤT BIẾN điền sẵn giá trị byte
của từng ký tự (`ord(ch)`), gắn `shape='bytes'`. Đọc (`len()`, index,
`for b in data:`) dùng CHUNG hạ tầng `bytearray`. `.append()`/mutate
→ `SyntaxError` rõ (giống `frozenset` chặn `.add()`).

## Kiến trúc

- **Token mới**: thêm `(?P<BYTES>b"(?:[^"\\]|\\.)*")` vào
  `_EXPR_TOKEN_RE`, ĐẶT TRƯỚC group `ID` trong chuỗi alternation (Python
  `re` thử từng nhánh theo THỨ TỰ VIẾT tại cùng vị trí bắt đầu, chọn
  nhánh ĐẦU TIÊN khớp — nếu `ID` đứng trước, `b"AB"` sẽ bị tách nhầm
  thành `ID('b')` + `STR('"AB"')`; đặt `BYTES` trước `STR` cũng được vì
  không giao nhau, nhưng PHẢI trước `ID`).
- **AST node**: `_parse_factor_primary` (`il_core.py`) thêm nhánh
  `if k == 'BYTES': return ('bytes_lit', v)` (`v` giữ nguyên cả tiền tố
  `b` và dấu ngoặc kép, giống cách `'str_lit'` giữ nguyên dấu ngoặc).
- **Xử lý ASCII-only + escape**: 1 hàm helper (vị trí: `il_core.py`
  cạnh `_tokenize_expr`, hoặc file `bytes_type.py` mới trong
  `il_features/`) parse `v` (bỏ `b"`/`"` 2 đầu, xử lý escape THEO
  CÙNG QUY TẮC string literal thường — TÁI DÙNG hàm unescape hiện có
  nếu có, KHÔNG viết lại logic escape mới) thành `list[int]` (mỗi phần
  tử 0-255). Ký tự nào có `ord(ch) > 127` → `SyntaxError` rõ ("bytes
  literal chi ho tro ASCII").
- **Codegen `('bytes_lit', v)`** (ĐK gán vào biến MỚI, giống cách
  `list_literal`/`str_lit` được gán): tại vị trí gán (`declare_scalar`
  hoặc tương đương xử lý RHS là literal container), sinh
  `newobj {il_bytearray_type()}::.ctor()` rồi N lần
  `dup; ldc.i4 {byte_value}; conv.u1; callvirt Add(!0)` (mỗi phần tử 1
  hằng số BIẾT TRƯỚC lúc compile — không cần vòng lặp runtime), gắn
  `known_shapes[name] = 'bytes'`.
- **Đọc + chặn mutate**: mở rộng CÁC ĐIỂM đã sửa cho `bytearray`
  (`il_type_str`, `_expr_index`, `len()` × 2, `for_in_list` — macro
  KHÔNG cần sửa gì thêm, đã tổng quát theo `bytearray` task trước) để
  nhận thêm `'bytes'`. Chặn `.append()` trên `shape=='bytes'` — tái
  dùng ĐÚNG cơ chế guard vừa thêm cho `try_parse_list_append` (mục
  `bytearray`, đã loại trừ `known_shapes.get(name) == 'bytearray'` —
  mở rộng thành `in ('bytearray', 'bytes')` rồi phân biệt: `bytearray`
  → cho append bình thường, `bytes` → `SyntaxError` bất biến).

## Phạm vi

- CHỈ literal `b"..."` gán trực tiếp vào biến MỚI — không
  `bytes(bytearray_var)` (chuyển đổi từ `bytearray`), không
  `bytes(list)`, không nối 2 `bytes` bằng `+`.
- Chỉ ASCII (0-127) — không hỗ trợ `\xNN` escape byte tuỳ ý ngoài
  ASCII (nếu escape đó đã tồn tại trong string literal thường, xác
  nhận lại phạm vi escape hỗ trợ TRƯỚC khi viết, không giả định).
- `.append()`/mọi method mutate → `SyntaxError` rõ.

## Kiểm chứng

- Test mới: `data = b"AB"` — `len(data)`==2, `data[0]`==65 (`'A'`),
  `data[1]`==66 (`'B'`), `for b in data:` duyệt đúng. `b""` (rỗng) —
  `len==0`. Ký tự ngoài ASCII trong `b"..."` — spike riêng xác nhận
  `SyntaxError` rõ. `.append()` trên biến `bytes` — spike riêng xác
  nhận `SyntaxError` bất biến.
- Regression: `bytearray`/`list[i32]`/`str` thường không đổi hành vi.
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
