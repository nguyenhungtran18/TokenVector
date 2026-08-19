# Duck-typing qua Type-Inference Tĩnh (#2, phần 1/2) — Design

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#2 eval/exec/metaclass/duck-typing —
LÀM CUỐI/tùy nhu cầu" (Loại 2, giới hạn kiến trúc). Nghiên cứu trước đó
(`docs/_qwen3_architecture_gap_research_full.md`, mục "Gap Tính Động") đã
khuyến nghị RÕ: **KHÔNG mô phỏng duck-typing đầy đủ** kiểu Python thật
(runtime, không giới hạn) — hiệu năng tụt, compiler phức tạp không cần
thiết cho 1 ngôn ngữ AOT tĩnh. Hướng đúng: **Type Inference mạnh** (như
TypeScript) — người dùng viết code KHÔNG cần khai kiểu tường minh ở MỌI
chỗ, nhưng compiler vẫn suy ra kiểu tĩnh 100% tại compile-time, không có
chi phí runtime nào (không reflection, không dynamic dispatch).

Hiện trạng: TokenVector bắt buộc MỌI tham số hàm phải khai annotation kiểu
DSL tường minh (`_extract_signature_line`/`_params_with_defaults`,
`tkv_compile.py:~106` — raise `TranspileError` nếu thiếu). Không có cách
nào viết 1 hàm nhận "bất kỳ record nào có field/method phù hợp" mà không
liệt kê tường minh union kiểu hoặc dùng interface khai báo trước
(`@interface`).

`eval()`/`exec()` tổng quát đã CHỐT non-goal vĩnh viễn (phá AOT) —
KHÔNG nằm trong phạm vi spec này. Monkey-patch/metaclass (qua Source
Generator) là 1 hướng ĐỘC LẬP khác, cũng KHÔNG nằm trong phạm vi spec này
(sub-project riêng nếu cần sau).

## Mục tiêu

Cho phép tham số hàm **top-level** KHÔNG khai annotation kiểu — compiler
tự suy 1 **"interface ẩn"** từ CÁCH tham số đó được dùng TRỰC TIẾP trong
thân hàm (đọc thuộc tính, gọi method, dùng toán tử), rồi tại MỖI điểm gọi
hàm, kiểm tra kiểu đối số truyền vào có thỏa mãn interface ẩn đó không —
nếu có, sinh 1 bản CIL RIÊNG (monomorphization) cho tổ hợp `(hàm, kiểu cụ
thể)`; nếu không, báo lỗi biên dịch rõ ràng. Zero runtime cost — không
sinh interface .NET, không reflection, không dynamic dispatch.

## Kiến trúc

### 1. Cú pháp — tham số không khai kiểu

Nới lỏng `_extract_signature_line`/`_params_with_defaults`
(`tkv_compile.py`): CHỈ cho phép thiếu annotation trên tham số của hàm
**top-level** (`ast.FunctionDef` KHÔNG lồng trong `ast.ClassDef`, KHÔNG
phải nested-def bên trong hàm khác — cả 2 trường hợp này VẪN bắt buộc
annotation như hiện tại, không mở rộng phạm vi). Tham số không-annotation
được đánh dấu nội bộ `dtype = 'inferred'` (khác `None` — phân biệt rõ với
lỗi thiếu annotation thật của các ngữ cảnh KHÔNG được phép thiếu).

### 2. Thu thập "interface ẩn" — quét thân hàm

Với MỖI tham số `dtype='inferred'`, quét (đệ quy) các câu lệnh trong thân
hàm, thu thập RÀNG BUỘC từ 3 loại usage TRỰC TIẾP trên biến đó (không qua
biến trung gian gán lại, không qua truyền vào lời gọi khác — xem mục
"Giới hạn"):

- **Đọc thuộc tính** `param.field` → ràng buộc "cần field `field`" (KHÔNG
  ràng buộc dtype của field tại bước này — dtype thật lấy từ kiểu record
  cụ thể lúc monomorphize).
- **Gọi method** `param.method(a1, a2, ...)` → ràng buộc "cần method
  `method` với ĐÚNG arity N tham số" (không ràng buộc dtype tham số/trả
  về ở bước thu thập — kiểm tra khớp dtype thật xảy ra lúc compile bản
  monomorphize, tái dùng nguyên cơ chế gọi method record hiện có).
- **Toán tử nhị nguyên/so sánh** (`param + x`, `param == y`, `x < param`,
  ...) → ràng buộc "kiểu của `param` PHẢI HOẶC LÀ 1 scalar hỗ trợ toán tử
  đó tự nhiên (`i32/i64/f32/f64/str` theo bảng toán tử sẵn có), HOẶC LÀ 1
  record có định nghĩa dunder tương ứng" (`__add__`/`__eq__`/... — tái
  dùng 100% cơ chế dunder đã có từ 6.5, không viết logic toán tử mới).

Nếu tham số `param` xuất hiện trong 1 usage KHÔNG thuộc 3 loại trên (vd
`f(param)` gọi hàm khác, `param[i]` index, gán `x = param` rồi dùng `x`
thay `param` trực tiếp) → **lỗi biên dịch NGAY tại bước thu thập** (xem
mục "Giới hạn" — quyết định có chủ đích, không lan truyền suy kiểu).

### 3. Monomorphization tại call-site

Tại MỖI lời gọi `func(arg)` tới 1 hàm có tham số `inferred`: compiler đã
biết kiểu TĨNH của `arg` (mọi biểu thức khác trong TokenVector đều suy
dtype được tại compile-time, không có gì thay đổi ở đây). Kiểm tra kiểu đó
có thỏa MỌI ràng buộc thu thập ở bước 2 hay không:
- Field required → record đó (hoặc tổ tiên qua kế thừa, tái dùng
  `_field_owner_class`) có field cùng tên?
- Method required → record đó (hoặc tổ tiên, tái dùng `_method_owner_class`)
  có method cùng tên đúng arity?
- Toán tử required → kiểu là scalar hỗ trợ toán tử đó, HOẶC record định
  nghĩa dunder tương ứng?

**Thỏa mãn** → tra cache `(func_name, concrete_type)`. Nếu CHƯA sinh bản
này, compile 1 bản CIL RIÊNG (tên mangled, vd `f'{func_name}__T{type_tag}'`
— quy tắc mangle chính xác xác nhận lúc implement, tránh trùng tên với
hàm người dùng khác) — TÁI DÙNG NGUYÊN pipeline compile hàm hiện có, chỉ
thay `dtype='inferred'` bằng `concrete_type` thật rồi chạy lại toàn bộ
first-pass/codegen như 1 hàm bình thường đã khai kiểu. Nếu ĐÃ có trong
cache, KHÔNG sinh lại — call-site gọi thẳng bản đã cache.

**KHÔNG thỏa mãn** → `TranspileError` rõ ràng, liệt kê: tên hàm, tham số
nào, ràng buộc nào không thỏa (field/method/toán tử thiếu), vị trí ĐỊNH
NGHĨA hàm VÀ vị trí CALL-SITE gây lỗi.

### 4. Nhiều tham số `inferred` cùng lúc / nhiều call-site khác kiểu

Mỗi tham số `inferred` có tập ràng buộc RIÊNG, độc lập. 1 hàm có N tham số
`inferred` → key cache là tuple N kiểu cụ thể (không chỉ 1 kiểu). Cùng 1
hàm được gọi với NHIỀU tổ hợp kiểu khác nhau ở nhiều call-site khác nhau
→ sinh NHIỀU bản CIL riêng biệt (đúng tinh thần monomorphization, đánh đổi
code size lấy zero-cost — chấp nhận được với quy mô chương trình mục
tiêu của dự án).

## Giới hạn KHÔNG làm ở MVP này

- **KHÔNG lan truyền suy kiểu xuyên lời gọi hàm/method khác** (kể cả
  tự-đệ-quy) — tham số `inferred` truyền vào 1 lời gọi KHÁC là lỗi biên
  dịch rõ ràng ("không suy được kiểu qua lời gọi gián tiếp — dùng trực
  tiếp `.field`/`.method()`/toán tử, hoặc khai kiểu tường minh"). Đây là
  quyết định có chủ đích tránh whole-program type inference (Hindley-Milner
  đầy đủ) — effort/rủi ro cao hơn nhiều so với giá trị tăng thêm ở MVP.
- KHÔNG hỗ trợ index/slice (`param[i]`) trên tham số `inferred`.
- KHÔNG hỗ trợ gán lại tham số `inferred` rồi dùng biến mới thay thế
  (`x = param; x.field` KHÔNG được suy — chỉ `param.field` trực tiếp).
- CHỈ hàm top-level — KHÔNG mở rộng cho method-trong-class/nested-def
  trong MVP này (vẫn bắt buộc annotation như hiện tại ở 2 ngữ cảnh đó).
- KHÔNG suy từ container ops (`in`/`len()`/`for x in param:`).
- KHÔNG có return type suy từ tham số `inferred` một cách đặc biệt — return
  type hàm VẪN phải khai tường minh như hiện tại (không đổi).

## Kiểm chứng

- Test tích cực: 1 hàm top-level nhận 2 record KHÁC NHAU cùng có field
  `name: str` (không kế thừa chung) — gọi hàm với cả 2 record, xác nhận
  sinh 2 bản CIL riêng, cả 2 chạy đúng, đối chiếu output CPython thật (mô
  phỏng semantics tương đương bằng Python thuần).
- Test method: tương tự, dùng `.greet()` thay vì field.
- Test toán tử: 1 hàm `def add_them(a, b): return a + b` gọi với
  `(i32, i32)` VÀ với `(RecordCóDunderAdd, RecordCóDunderAdd)` — cả 2 kiểu
  đều compile+chạy đúng qua CÙNG 1 định nghĩa hàm nguồn.
- Test lỗi: gọi hàm với 1 kiểu THIẾU field/method cần thiết → `TranspileError`
  rõ, đúng thông tin (tên hàm/tham số/field-method thiếu/vị trí).
- Test giới hạn: tham số `inferred` truyền tiếp vào hàm khác → lỗi biên
  dịch rõ ràng đúng như thiết kế (không phải crash nội bộ).
- Test cache: gọi CÙNG hàm với CÙNG kiểu ở NHIỀU call-site → xác nhận chỉ
  sinh 1 bản CIL (đếm số `.method` xuất hiện trong IL text sinh ra).
- Test kế thừa: field/method required nằm ở LỚP CHA (không phải chính
  record truyền vào) → vẫn thỏa mãn (tái dùng `_field_owner_class`/
  `_method_owner_class`).
- Regression toàn bộ test suite hiện có — đặc biệt mọi hàm CÓ khai
  annotation tường minh vẫn hoạt động y hệt (thay đổi này KHÔNG được ảnh
  hưởng đường code cũ).
- Chạy `tkv.py build` (mặc định có `syntax_baseline.py` linter) — xác nhận
  linter KHÔNG chặn nhầm cú pháp tham số thiếu annotation MỚI hợp lệ này
  (cần cập nhật whitelist nếu linter hiện đang coi thiếu annotation là lỗi
  cú pháp — xác nhận lúc implement, đối chiếu lại `syntax_baseline.py`).
- Cả 2 cây (`tkv_compile.py`/`.tkv`, `il_codegen.py`/`.tkv`) sửa đồng bộ.
  KHÔNG rebuild `tkvc.exe`.
