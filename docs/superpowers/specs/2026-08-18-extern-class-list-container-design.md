# `__tkv_extern_class__` Phase 5 — `List<T>` container trên tham số/return

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem". Phase 1-4
(`__tkv_extern_method__`, `__tkv_extern_pinvoke__`, `__tkv_extern_class__`
constructor/method Phase 3, property Phase 4 — tất cả đã shipped) mở khoá
gọi static method, P/Invoke DLL, constructor + instance method + property
.NET ngoài — nhưng tham số/return LUÔN giới hạn scalar
(`i32/i64/f32/f64/str`) hoặc 1 handle type đơn. Rất nhiều API .NET thực tế
(kể cả trong `mscorlib`) nhận/trả `List<T>` (vd
`List<T>.AddRange(IEnumerable<T>)`, nhiều constructor `List<T>(...)`,
API thư viện tính toán trả `List<double>` kết quả) — CHƯA gọi được.

Xác nhận quan trọng trước khi viết spec này (đọc code thật, không đoán):
DSL `list[...]` KHÔNG phải kiểu tự chế của compiler — nó biên dịch TRỰC
TIẾP sang `System.Collections.Generic.List\`1<T>` THẬT
(`compiler/il_features/list_type.py::il_list_elem_ilstr`, dòng 45:
`f'class [mscorlib]System.Collections.Generic.List\`1<{il_list_elem_ilstr(dtype, records)}>'`).
Vì vậy Phase 5 này KHÔNG phải "xây generic từ đầu" — chỉ là **cầu nối
marshaling** giữa 1 dtype `list[...]` DSL đã tồn tại và tham số/return
của method/property/constructor extern-class.

Quyết định phạm vi (2026-08-18, xem hội thoại brainstorm):
1. Chỉ container .NET **`List<T>` cụ thể** (không `Dictionary<K,V>`,
   không interface `IEnumerable<T>`/`IList<T>`/mảng `T[]`) — lát cắt hẹp,
   rủi ro thấp, tận dụng NGUYÊN cơ chế `list[...]` DSL sẵn có.
2. `T` (phần tử) là scalar (`i32/i64/f32/f64/str`) HOẶC 1 handle type đã
   khai — nhất quán với giới hạn dtype hiện có của method/property Phase
   3/4.

## Mục tiêu

Cho phép `params`/`returns` (trong `methods`, `properties`, `ctor`) của
`__tkv_extern_class__` khai dạng `"list[T]"` (T là scalar hoặc tên handle
type đã khai) — compiler sinh đúng CIL `class
[mscorlib]System.Collections.Generic.List\`1<T_il>` cho tham số/return
đó, TÁI DÙNG NGUYÊN kiểu `list[...]` DSL đã có (biến `list[...]` có thể
gán trực tiếp từ kết quả gọi method/property trả `list[T]`, hoặc truyền
thẳng làm tham số).

## Kiến trúc

### 1. Mở rộng validate dtype cho container

Tại các điểm validate dtype hiện có của Phase 3/4 (ctor params, method
params/returns, property dtype — TẤT CẢ đều dùng chung 1 kiểm tra "dtype
∈ scalar HOẶC dtype ∈ tên handle type đã khai"), thêm 1 nhánh: nếu dtype
khớp pattern `list[<elem>]`, đệ quy validate `<elem>` theo ĐÚNG quy tắc
scalar-hoặc-handle-type hiện có (KHÔNG cho phép `<elem>` là 1 `list[...]`
khác — không container-của-container).

### 2. Sinh CIL

Nơi hiện có `_il_ctor_param_type(dtype_name, extern_class_defs, ctx)`
(dùng cho ctor/method/property scalar-hoặc-handle) — thêm nhánh: nếu
`dtype_name` match `list[<elem>]`, gọi
`il_list_elem_ilstr(<elem>, ...)` (đã có sẵn trong
`compiler/il_features/list_type.py`) để lấy CIL type của phần tử, rồi bọc
`f'class [mscorlib]System.Collections.Generic.List\`1<{elem_il}>'` — TÁI
DÙNG chính hàm sinh IL type của `list[...]` DSL, KHÔNG viết logic bọc
List<T> mới.

### 3. Truyền tham số / nhận return

Biến `list[...]` DSL hiện có ĐÃ tương thích CIL với `List<T>` thật — vì
vậy 1 biến `x: "list[i32]"` gán từ kết quả gọi method trả `"list[i32]"`,
hoặc truyền thẳng vào tham số method nhận `"list[i32]"`, hoạt động qua
CHÍNH cơ chế `ctx['compile_expr']`/`load_var_ref` hiện có — KHÔNG cần
logic ép kiểu/marshal thủ công nào thêm, miễn CIL type STRING khớp CHÍNH
XÁC (đây là lý do bước 2 quan trọng: sai chữ ký CIL type-string 1 ký tự
là build lỗi hoặc crash runtime).

## Giới hạn KHÔNG làm ở Phase 5 này

- **CHỈ `List<T>`** — KHÔNG hỗ trợ `Dictionary<K,V>`, `Stack<T>`,
  `Queue<T>`, `HashSet<T>` .NET, hay bất kỳ generic .NET khác.
- **KHÔNG hỗ trợ interface/kiểu trả về khác `List<T>` cụ thể** —
  `IEnumerable<T>`, `IList<T>`, `ICollection<T>`, mảng `T[]` ĐỀU KHÔNG
  tương thích CIL trực tiếp với `List<T>` (khác nhau ở mặt binary/CIL type
  dù cùng "duck-type" ở tầng C# nguồn). Nếu 1 API .NET thật trả kiểu khác
  `List<T>` cụ thể (RẤT PHỔ BIẾN trong API .NET thực tế — nhiều hàm chuẩn
  trả `IEnumerable<T>` để lazy-eval), khai `"list[T]"` cho nó sẽ build
  THÀNH CÔNG nhưng **crash `InvalidCastException` lúc chạy**. Đây là giới
  hạn NGHIÊM TRỌNG cần ghi cảnh báo rõ trong docs — người dùng BẮT BUỘC
  xác nhận qua reflection (ILSpy/PowerShell) chữ ký trả về CHÍNH XÁC là
  `List\`1<T>`, không phải interface, trước khi khai.
- **KHÔNG container-của-container** (`list[list[i32]]`) — chỉ 1 tầng.
- **KHÔNG generic type tự khai khác** (`.tkv` KHÔNG thể khai 1 generic
  .NET class TÙY Ý tham số hoá kiểu — đó là phạm vi RỘNG HƠN nhiều đã
  loại bỏ khỏi Phase 5 khi brainstorm, xem quyết định phạm vi ở trên).
- **KHÔNG thao tác `List<T>`'s method riêng qua cơ chế extern-class** —
  `list[...]` DSL đã có SẴN đầy đủ method (`append`/`len`/index/slice/...)
  qua cơ chế `list_type.py`/`list_methods_batch*.py` hiện có, dùng
  TRỰC TIẾP những cái đó trên biến nhận được từ Phase 5, không cần khai gì
  thêm trong `__tkv_extern_class__`.

## Kiểm chứng

- Test tích cực: 1 method/constructor .NET thật trả/nhận `List<T>` cụ thể
  — ứng viên tốt nhất trong `mscorlib`: `List<T>` chính nó có 1 constructor
  nhận `IEnumerable<T>` (KHÔNG dùng được — interface, đúng giới hạn đã nêu)
  hoặc dùng chính `List<i32>.AddRange(List<i32>)` nếu tồn tại chữ ký cụ
  thể (xác nhận qua reflection lúc implement, KHÔNG đoán — nếu không tìm
  được ví dụ `mscorlib` thuần dùng đúng `List<T>` cụ thể không qua
  interface, tạo 1 class .NET test phụ trợ tối thiểu để kiểm chứng, ghi rõ
  trong test).
- Test phần tử là handle type: method trả `list[Sb]` (list các
  `StringBuilder` handle), lặp qua bằng `list[...]` DSL method có sẵn
  (`for x in lst:` hoặc index), gọi method trên TỪNG phần tử.
- Test lỗi validate: `list[list[i32]]` (container-của-container) →
  `TranspileError`. `dtype` bên trong `list[...]` không hợp lệ (không phải
  scalar/handle type) → `TranspileError`.
- Test tương thích: dùng ĐỒNG THỜI Phase 3 (method/ctor scalar), Phase 4
  (property), Phase 5 (container) trong CÙNG 1 entry `__tkv_extern_class__`.
- Regression toàn bộ test suite hiện có — ĐẶC BIỆT `list_type.py`'s test
  suite hiện có (mọi thao tác `list[...]` THƯỜNG, không qua extern-class,
  vẫn hoạt động y hệt).
- Cả 2 cây (`.py`/`.tkv`) sửa đồng bộ — mirror tree VẪN CHƯA có nền tảng
  Phase 1-4 (đã xác nhận nhiều lần), Phase 5 CŨNG không port, chỉ ghi chú.
  KHÔNG rebuild `tkvc.exe`.
