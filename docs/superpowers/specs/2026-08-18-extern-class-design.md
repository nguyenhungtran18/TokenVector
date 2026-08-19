# `__tkv_extern_class__` — Instance method + constructor cho .NET class ngoài (Phase 3, Package ecosystem)

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem — BLOCKER LỚN
NHẤT". Đã xong 2 giai đoạn:

- **Phase 1** (`__tkv_extern_method__`): gọi **static method** .NET ngoài,
  tham số/trả về giới hạn scalar (`i32/i64/f32/f64/str`).
- **Phase 2** (`__tkv_extern_pinvoke__`): gọi hàm **P/Invoke DLL native**
  tổng quát hoá qua khai báo (`dll`/`symbol`/`convention`/`params`/`returns`).

Cả 2 đều dùng chung 1 kiến trúc: pragma khai báo (list-của-dict, phép GÁN
hợp lệ dưới CPython) → compiler parse → validate → đăng ký ĐỘNG builtin qua
`register_expr_builtin` (`compiler/il_dispatch.py`) theo TỪNG lượt
`compile_tkv_cli`, `finally`-pop sau khi build xong (tránh rò rỉ giữa các
lần compile trong cùng process) — **không cần sửa file compiler cho mỗi
method/hàm DLL mới**.

Giới hạn chung của cả 2 Phase: chỉ gọi được hàm **static** hoặc **P/Invoke
DLL** — không có cách nào tạo 1 **object .NET** (constructor) rồi gọi
**instance method** trên nó. Đây là khoảng trống lớn nhất còn lại để dùng
được các thư viện NuGet hướng-object thật (Math.NET Numerics, v.v.) — hầu
hết API dạng `new Foo(args).Method(args)`, không phải static.

Quyết định phạm vi (2026-08-18, xem hội thoại brainstorm): bắt đầu bằng lát
cắt **instance method + constructor trên object handle** — phần LÕI thiếu
nhất để dùng bất kỳ NuGet lib hướng-object nào. Property get/set và generic
type/method là lát cắt RIÊNG, KHÔNG thuộc phạm vi spec này.

## Mục tiêu

Cho phép code `.tkv` khai báo 1 class .NET ngoài thành **1 dtype DSL mới**
(gọi là "handle type") — tạo object qua constructor (`newobj`), gọi instance
method trên object đó (`callvirt`), gán/truyền/trả về như bất kỳ kiểu DSL
nào khác — **không cần sửa file compiler** cho mỗi class .NET mới.

## Kiến trúc

### 1. Pragma mới: `__tkv_extern_class__`

```python
__tkv_extern_class__ = [
    {
        "name": "Matrix",
        "assembly": "MathNet.Numerics",
        "class": "MathNet.Numerics.LinearAlgebra.Matrix",
        "ctor": ["i32", "i32"],
        "methods": [
            {"name": "Determinant", "params": [], "returns": "f64"},
            {"name": "Transpose", "params": [], "returns": "Matrix"},
            {"name": "Get", "params": ["i32", "i32"], "returns": "f64"},
        ],
    },
]
```

Dạng LIST-CỦA-DICT (nhất quán `__tkv_extern_method__`/`__tkv_extern_pinvoke__`)
— nhiều khai báo nối tiếp, tự validate trùng tên tường minh thay vì để Python
âm thầm ghi đè key dict.

- `name`: tên dtype DSL mới, phải là 1 identifier Python hợp lệ, KHÔNG trùng
  tên record/handle-type/builtin khác đã đăng ký.
- `assembly`: PHẢI nằm trong tập assembly đã khai qua `__tkv_extern_assembly__`
  (hoặc `mscorlib`/`System`/`System.Core` mặc định) — tái dùng NGUYÊN
  `declared_assembly_names` từ Phase 1.
- `class`: tên đầy đủ (namespace-qualified) class .NET, khớp regex tên class
  hợp lệ — tái dùng NGUYÊN validate từ Phase 1.
- `ctor`: list dtype tham số constructor (`[]` = constructor không tham số).
  MỖI phần tử là scalar (`i32/i64/f32/f64/str`) hoặc tên 1 handle type ĐÃ
  khai trước đó trong CÙNG `__tkv_extern_class__` (cho phép constructor nhận
  object khác làm tham số).
- `methods`: list dict `{"name", "params", "returns"}` — `params` giống
  `ctor`; `returns` là scalar HOẶC tên handle type (kể cả CHÍNH `name` của
  entry đang khai — method trả về chính nó, fluent API — hoặc tên handle
  type KHÁC đã khai trước trong CÙNG pragma).

### 2. Handle là gì trong CIL

Handle KHÔNG có struct/layout riêng do compiler tự dựng (khác record DSL
hiện có — record được compiler layout field cụ thể). Handle chỉ là 1 tham
chiếu .NET thật: biến/tham số/return khai `dtype='Matrix'` (ví dụ) sinh CIL
kiểu `class [MathNet.Numerics]MathNet.Numerics.LinearAlgebra.Matrix` —
compiler CẦM tham chiếu, KHÔNG đọc/ghi field bên trong (field của object
.NET ngoài không phải phạm vi khai báo — chỉ method + constructor).

### 3. Cú pháp dùng trong `.tkv`

```python
def main() -> None:
    m: Matrix = Matrix(3, 3)         # newobj — cú pháp GIỐNG constructor record DSL hiện có
    x: f64 = m.Get(0, 0)             # callvirt instance method
    t: Matrix = m.Transpose()        # method trả về handle khác — dùng tiếp bình thường
    if m is None:                    # tái dùng NGUYÊN cơ chế 'null' node đã có (parser, il_core.py:553-556)
        pass
```

- Constructor call (`Matrix(3, 3)`) và method call (`m.Method(...)`) TÁI
  DÙNG nguyên đường phân giải hiện có cho record constructor/`param.method(...)`
  trong `_expr_call`/attribute-call resolution (`il_codegen.py`) — thêm 1
  nhánh tra cứu "đây là tên handle-type đã đăng ký" TRƯỚC khi rơi về nhánh
  record cũ, tương tự cách Phase 1 chèn nhánh resolve NGAY sau
  `callee = func_table[name]`.
- `is None`/`is not None` trên biến handle dùng CHÍNH XÁC cơ chế `('null',)`
  node đã có cho record — không viết logic null-check mới.

### 4. Đăng ký động — mở rộng registry hiện có

Ngoài đăng ký vào `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE`
(`il_dispatch.py`, cho method call như 1 "builtin" gọi qua tên mangled nội
bộ, TÁI DÙNG nguyên `finally`-pop pattern của Phase 1/2 để tránh rò rỉ giữa
các lần compile trong cùng process), MỖI handle type còn cần đăng ký vào
CHÍNH bảng dtype DSL nơi record hiện có đăng ký (`records`/`record_methods`
trong `ctx`, xác nhận cấu trúc chính xác lúc implement) — để pipeline hiện
có (parser kiểu tham số/return, `_infer_dtype`, `il_type_str`, gán biến,
truyền tham số hàm DSL) coi `Matrix` như 1 kiểu hợp lệ mà KHÔNG cần sửa
từng điểm riêng lẻ. Đăng ký này CŨNG phải tự gỡ (`finally`) sau mỗi lượt
`compile_tkv_cli`, cùng lý do isolation như `EXPR_BUILTIN_*`.

### 5. Constructor và method — cơ chế codegen

- Constructor: sinh `newobj instance void [assembly]FullClassName::.ctor(params...)`
  — factory tương tự `_make_extern_static_call_codegen` (Phase 1) nhưng emit
  `newobj` thay vì `call`, KHÔNG cần "gọi trên 1 object có sẵn" (constructor
  không có receiver).
- Method: sinh `callvirt instance <ret> [assembly]FullClassName::MethodName(params...)`
  — factory MỚI `_make_extern_instance_call_codegen`, nhận thêm receiver
  expression (biến/kết quả biểu thức đứng trước dấu `.`) — compile receiver
  TRƯỚC (đẩy lên stack), rồi compile TỪNG tham số theo ĐÚNG dtype khai báo ở
  vị trí đó (giống Phase 1, KHÔNG đồng loạt 1 dtype), rồi emit `callvirt`.
- Tham số/return là handle type khác: KHÔNG cần xử lý đặc biệt gì thêm ngoài
  ánh xạ tên dtype DSL → tên CIL class đầy đủ (`[assembly]FullClassName`)
  đã lưu lúc đăng ký — tái dùng NGUYÊN cơ chế `ctx['compile_expr']` ép dtype
  hiện có.

## Giới hạn KHÔNG làm ở Phase 3 này

- **Không multi-ctor/overload resolution** — 1 khai báo `name` = đúng 1 chữ
  ký constructor cố định, giống Phase 1 không overload static method.
- **Không property get/set** — chỉ method call. Lát cắt riêng, không thuộc
  phạm vi spec này.
- **Không generic type/method** (`List<T>`, `Dictionary<K,V>` cụ thể hoá
  theo tham số kiểu người dùng chọn) — nền tảng instance-method phải ổn
  định trước khi tính tới generic.
- **Không container marshaling** — tham số/return method/ctor CHỈ scalar
  hoặc 1 handle type đã khai, KHÔNG hỗ trợ mảng/list .NET.
- **Không static field/method của handle type** — method tĩnh vẫn dùng
  `__tkv_extern_method__` (Phase 1) như cũ; `__tkv_extern_class__` CHỈ cho
  instance method + constructor.
- **Handle type KHÔNG tham gia duck-typing-inference** (`#2 phần 1/2`) —
  dùng handle type làm tham số hàm top-level thiếu annotation (`inferred`)
  là lỗi biên dịch rõ ràng, tránh nhập nhằng 2 cơ chế suy kiểu khác nhau.
- **Không dịch riêng exception .NET** — lan truyền như exception thường
  (giữ nguyên tinh thần Phase 1/2); khai sai chữ ký constructor/method →
  build OK nhưng chạy `MissingMethodException`/tương tự, không có safety
  net runtime.
- **Không tự dò chữ ký qua reflection** — người dùng tự xác minh đúng chữ ký
  CIL (ILSpy/PowerShell reflection) trước khi khai, giữ nguyên nguyên tắc dự
  án xuyên suốt.
- **Không quản lý lifetime/Dispose thủ công** — dựa hoàn toàn vào GC của
  CLR; nếu class implement `IDisposable` cần gọi `Dispose`, người dùng tự
  khai `Dispose` như 1 method bình thường trong `methods`.

## Kiểm chứng

- Test tích cực KHÔNG cần NuGet thật: dùng 1 class sẵn có trong
  `mscorlib`/`System` (vd `System.Text.StringBuilder` — `ctor:[]` hoặc
  `ctor:["str"]`, method `Append(str)->StringBuilder`/`ToString()->str`) —
  build + chạy `.exe` thật, đối chiếu CPython tương đương thủ công (chuỗi
  nối tay).
- Test method trả về CHÍNH handle type (fluent chaining): `sb.Append("a").Append("b")`
  nếu `Append` khai `returns:"StringBuilder"` (đúng chữ ký thật của
  `StringBuilder.Append`) — xác nhận gọi tiếp method trên kết quả không lỗi.
- Test method trả về handle type KHÁC: 2 entry trong CÙNG `__tkv_extern_class__`,
  method của class A trả về class B, dùng tiếp object B trả về.
- Test constructor nhận handle type khác làm tham số.
- Test `is None`/`is not None` trên biến handle — xác nhận tái dùng đúng cơ
  chế null hiện có, không crash/false-positive/false-negative.
- Test lỗi validate (1 test riêng mỗi case, assert lỗi rõ ràng đúng nguyên
  nhân): assembly chưa khai; `class`/method-name sai regex; dtype tham
  số/return không hỗ trợ (không phải scalar, không phải handle type đã
  khai); `name` trùng record/handle-type/builtin có sẵn.
- Test isolation qua nhiều lần compile cùng process (như Phase 1/2 — quan
  trọng nhất để bắt regression rò rỉ registry): gọi `compile_tkv_cli` 2 LẦN
  liên tiếp, 2 file khác nhau cùng tên handle type `Matrix` NHƯNG định nghĩa
  khác nhau (`ctor`/`methods` khác) — lần 2 build đúng theo định nghĩa của
  chính nó, không dính định nghĩa của lần 1.
- Test tương thích: dùng ĐỒNG THỜI `__tkv_extern_class__` + `__tkv_extern_method__`
  (Phase 1) + `__tkv_extern_pinvoke__` (Phase 2) + P/Invoke viết tay
  (`db_*`) trong CÙNG 1 file — không xung đột `extern_lines`/registry.
- Test duck-typing giới hạn: dùng handle type làm tham số hàm top-level
  thiếu annotation → `TranspileError` rõ ràng (không phải crash nội bộ),
  đúng như thiết kế "không tham gia duck-typing".
- Regression toàn bộ test suite hiện có — ĐẶC BIỆT mọi chỗ dùng record DSL
  cũ (không phải handle) vẫn hoạt động y hệt, xác nhận nhánh handle-type
  mới không đụng đường code record cũ (record constructor/method resolution
  path được TÁI DÙNG, rủi ro cao nhất là vô tình đổi hành vi record thường).
- Cả 2 cây (`tkv_compile.py`/`.tkv`, `il_codegen.py`/`.tkv`) sửa đồng bộ.
  KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
