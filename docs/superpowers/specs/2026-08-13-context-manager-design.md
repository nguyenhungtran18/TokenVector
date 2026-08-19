# Context manager tuỳ biến (`__enter__`/`__exit__`) — Design

## Bối cảnh

`with` hiện CHỈ hỗ trợ 1 dạng cứng: `with open(path, "mode") as f:`
(`_WITH_OPEN_RE`/`try_parse_with_open` trong
`compiler/il_features/control_flow.py`, dòng ~917-955) — desugar thành
stmt kind `with_open`, codegen qua `codegen_with_open` (dòng ~1038)
dùng khung `.try { than } finally { Dispose() }` tái dùng hạ tầng
try/finally đã xác minh của `codegen_try`. KHÔNG có cú pháp `with
<bieu_thuc> as v:` tổng quát cho record người dùng tự định nghĩa
`__enter__`/`__exit__`. Đây là mục 6.6, sau khi 6.5 (5 dunder overload:
`__str__`/`__eq__`/`__len__`/`__getitem__`/`__add__`) đã xong hoàn
toàn.

## Mục tiêu

`with <bieu_thuc_record> as v:` — record có
`def __enter__(self) -> "T": ...` và `def __exit__(self) -> "U": ...`
sẽ tự động: gọi `__enter__` lúc vào khối (kết quả gán vào `v`, kiểu
`T`), gọi `__exit__` lúc RA khỏi khối (dù có exception/return bên
trong hay không, giống `finally`).

## Kiến trúc

### Cú pháp nhận dạng (parse)

Thêm 1 regex/parser MỚI (KHÔNG sửa `_WITH_OPEN_RE`/`try_parse_with_open`
hiện có — 2 cú pháp độc lập, `with open(...)` vẫn đi đường cũ):
`with <bieu_thuc> as <ten_bien>:` — CHỈ chấp nhận 2 dạng cho
`<bieu_thuc>`:

1. **Gọi constructor trực tiếp**: `with Lock() as lk:` — tên hàm gọi
   TRÙNG 1 record đã khai báo (dùng lại logic phát hiện giống
   `is_record_ctor_rhs` trong `record_feature.py`) → biết ngay class
   từ cú pháp, không cần suy kiểu.
2. **1 biến ĐÃ khai báo kiểu record**: `with existing_lock as lk:` —
   tra `scope[ten_bien]` lấy `TypeAnn`, xác nhận `shape == 'record'`.

Không hỗ trợ biểu thức phức tạp khác (method call trả về record,
biểu thức lồng, v.v.) — giống giới hạn "chỉ biến đơn"/"chỉ constructor
đơn" đã áp dụng nhiều lần trước đây (`sample`/`shuffle`, `__len__`,
`__getitem__`).

### Validate chữ ký

Record đích PHẢI có CẢ 2 method — thiếu 1 trong 2 → `SyntaxError` rõ
("record '{X}' can dinh nghia CA __enter__ VA __exit__ de dung trong
'with'"):
- `__enter__(self) -> "T"`: đúng 0 tham số, `return_type` PHẢI được
  khai (không ép cứng `T` cụ thể — giống `__getitem__`/`__add__`, kiểu
  trả về tuỳ ý, thường là chính record đó nhưng không bắt buộc).
- `__exit__(self) -> "U"`: đúng 0 tham số, `return_type` PHẢI được
  khai. Giá trị trả về BỊ BỎ QUA hoàn toàn ở nơi gọi (`pop` khỏi stack
  nếu không phải kiểu `void` — xem phần "Không hỗ trợ" bên dưới).

### Sinh IL

Tái dùng NGUYÊN khung `.try/finally` của `codegen_with_open`:

1. Sinh IL tạo/lấy record instance (constructor call hoặc load biến).
2. `callvirt instance {T_il} {owner}::__enter__()` (owner qua
   `_method_owner_class`, hỗ trợ kế thừa) → `store_var` vào `v`.
   **Lưu ý khác `with_open`**: `with_open` gán THẲNG object file vào
   biến; ở đây phải GIỮ LẠI tham chiếu record GỐC riêng (1 hidden
   local ẩn, vd `__ctxmgr{id(stmt)}`, đặt tên theo quy ước
   `__strtmp{id(...)}`/`__dictiter{id(...)}` đã dùng ở nơi khác trong
   codebase) — vì `v` nhận kết quả `__enter__` (có thể KHÁC record gốc
   nếu `T` không phải chính record đó), nhưng `__exit__` phải gọi TRÊN
   RECORD GỐC, không phải trên `v`.
3. `.try { than khoi (stmt['body']) }`.
4. `.finally { load hidden local record goc, callvirt __exit__, neu
   return_type khac void thi 'pop', endfinally }`.
5. Nhãn cuối `{sig.name}_With{n}_end` — giống `codegen_with_open`.

### Không hỗ trợ (ghi rõ, không phải thiếu sót)

- **KHÔNG suppress exception**: Python thật, `__exit__` trả `True` sẽ
  "nuốt" exception đang lan truyền (không raise tiếp). DSL này KHÔNG
  mô phỏng hành vi đó — `__exit__` LUÔN chạy trong `finally` (không
  phải `catch`), giá trị trả về bị bỏ qua hoàn toàn, exception (nếu
  có) LUÔN tiếp tục lan ra ngoài sau khi `__exit__` chạy xong. Đây là
  giới hạn CÓ Ý THỨC — bao phủ đúng use-case phổ biến nhất (cleanup
  tài nguyên: đóng file/khoá/kết nối), không bao phủ use-case hiếm
  (context manager tự xử lý exception, vd `contextlib.suppress`).
- **KHÔNG hỗ trợ `with a, b:`** (nhiều context manager cùng dòng) —
  chỉ 1 context manager mỗi `with`. Cần lồng `with` nếu muốn nhiều.
- **KHÔNG hỗ trợ `__exit__(self, exc_type, exc_val, exc_tb)`** (chữ ký
  đầy đủ 4 tham số của Python thật) — chỉ `__exit__(self)` 0 tham số,
  vì DSL không có khái niệm truyền thông tin exception vào hàm (không
  có object exception chung kiểu `Optional[Exception]`).

## Phạm vi

- Chỉ `with <ctor_call_hoac_bien_record> as v:` — không hỗ trợ biểu
  thức phức tạp, không hỗ trợ nhiều context manager 1 dòng.
- Không đụng cú pháp `with open(...) as f:` hiện có (đường xử lý riêng
  biệt hoàn toàn, `with_open` stmt kind không đổi).
- `__exit__` không suppress exception (luôn chạy trong `finally`,
  không phải `except`).

## Kiểm chứng

- Test mới: record có `__enter__`/`__exit__` — `with Res() as r:` gọi
  đúng thứ tự (in log trong `__enter__`/thân khối/`__exit__` để xác
  nhận thứ tự chạy). `__exit__` VẪN chạy khi thân khối có `return` sớm
  (giống cách `with_open` đã kiểm chứng qua `_contains_return`).
  `__enter__` trả về kiểu KHÁC chính record đó (vd 1 record khác hoặc
  scalar) — xác nhận `v` nhận đúng kiểu đó. Record CHỈ có `__enter__`
  thiếu `__exit__` (hoặc ngược lại) — spike riêng xác nhận `SyntaxError`
  rõ.
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `with open(...)`
  hiện có không đổi hành vi, `try`/`finally`/`return` bên trong khối
  khác không đổi.
- Cả 2 cây (`compiler/il_features/control_flow.py`/`.tkv`) sửa đồng
  bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
