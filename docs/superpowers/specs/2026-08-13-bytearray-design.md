# `bytearray` — Design

## Bối cảnh

`list[i32]` hiện dùng `List<int32>` (`il_list_type`/`IL_LDELEM['i32']`).
Python `bytearray` là dãy BYTE (0-255) khả biến — .NET tương ứng
`List<byte>` (khác `List<int32>` ở KÍCH THƯỚC phần tử: `byte` = 1
byte, `int32` = 4 byte, cần opcode CIL riêng `ldelem.u1`/narrow `conv.u1`
khi ghi). Đây là mục 3/4 trong 6.8 (sau `frozenset`, `complex`).

## Mục tiêu

`ba = bytearray()` rồi `.append(x)` (x kiểu `i32`, giá trị NÊN trong
`0-255` — KHÔNG validate range lúc chạy, tràn bị cắt bởi `conv.u1`
giống Python thật KHÔNG làm nhưng đây là giới hạn chấp nhận được, ghi
rõ). Đọc `ba[i]`/`len(ba)`/`for b in ba:` hoạt động giống `list[i32]`
thường (giá trị đọc ra LUÔN là `i32` không âm 0-255, do `ldelem.u1`
zero-extend tự nhiên).

## Kiến trúc

- **`il_bytearray_type()`**: hàm mới trong 1 file mới
  `bytearray_type.py`, trả `'class [mscorlib]System.Collections.Generic.List`1<unsigned int8>'`.
- **`ASSIGN_RHS_PARSERS` entry**: `try_rhs_bytearray_new` (song song
  `try_rhs_list_new`) — khớp `ba = bytearray()`, gắn
  `known_shapes[name] = 'bytearray'`.
- **`.append(x)`**: `LINE_PARSERS` entry mới (song song
  `try_parse_list_append`, PHẢI đăng ký TRƯỚC `method_call_stmt` tổng
  quát giống mọi tiền lệ `.append`/`.add`) — sinh `compile_expr(x, ...,
  'i32', ctx)` rồi `conv.u1` (narrow về byte, CHẤP NHẬN tràn bị cắt —
  giống mọi nơi khác dự án đã chấp nhận đánh đổi rõ ràng thay vì cấm
  hoàn toàn), rồi `callvirt instance void List<byte>::Add(!0)`.
- **Đọc (`ba[i]`, `len(ba)`, `for b in ba:`)**: THÊM `'bytearray'` vào
  các điểm dispatch hiện có xử lý theo `shape == 'list'` — CHỈ ở
  những nơi có Ý NGHĨA (đọc phần tử, độ dài, duyệt), KHÔNG áp dụng cho
  các method `list` khác không có tương đương Python thật trên
  `bytearray` (vd `.sort()`/`.extend()` — để nguyên phạm vi, không mở
  rộng nếu không cần).

## Phạm vi

- Chỉ `bytearray()` RỖNG + `.append(x)` — không `bytearray(n)` (tạo N
  byte 0), không `bytearray(list_co_san)`, không literal `b"..."`
  (đó là phạm vi riêng của mục `bytes` kế tiếp).
- KHÔNG validate giá trị `0-255` lúc chạy (tràn bị `conv.u1` cắt lặng
  lẽ) — giới hạn có ý thức, rẻ.
- Chỉ `.append()`/index đọc/`len()`/`for-in` — không `.extend()`,
  không slice, không các method `bytes`-specific khác (`.hex()`,
  `.decode()`).

## Kiểm chứng

- Test mới: `ba = bytearray()`, `.append(65)`, `.append(66)` —
  `len(ba)`==2, `ba[0]`==65, `ba[1]`==66, `for b in ba:` duyệt đúng
  2 giá trị. Giá trị tràn (vd `.append(300)`) — xác nhận bị cắt còn
  `300 % 256 = 44` (không phải lỗi, ghi rõ trong test là hành vi CÓ Ý
  THỨC, không phải bug).
- Regression: `list[i32]` thường không đổi hành vi.
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
