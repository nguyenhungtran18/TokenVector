# `__tkv_extern_class__` Phase 4 — Property get/set trên handle type

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem". Phase 3
(`__tkv_extern_class__`, xem `docs/superpowers/specs/2026-08-18-extern-class-design.md`
+ `docs/superpowers/plans/2026-08-18-extern-class.md`, 5/5 task hoàn tất
commit `a2d5127`) đã mở khoá khai báo 1 class .NET ngoài thành 1 dtype DSL
mới ("handle type") — tạo object qua constructor (`newobj`), gọi instance
method (`callvirt`), method trả về scalar HOẶC handle type khác (kể cả
chính nó, fluent chaining). Giới hạn CHƯA làm của Phase 3 (ghi rõ trong
spec đó): **property get/set** — nhiều API .NET thực tế dùng property
(`sb.Length`, `list.Count`) thay vì method, KHÔNG gọi được qua cơ chế
Phase 3.

Quyết định phạm vi (2026-08-18, xem hội thoại brainstorm): thêm key mới
`"properties"` vào entry `__tkv_extern_class__` hiện có (không tạo pragma
riêng) — cú pháp dùng y hệt field record hiện có (`obj.Prop` đọc,
`obj.Prop = x` ghi), dtype giới hạn scalar HOẶC handle type khác đã khai
(nhất quán với method ở Phase 3), mặc định `readonly: true` (an toàn hơn
— chỉ mở setter khi khai RÕ `readonly: false`).

## Mục tiêu

Cho phép code `.tkv` đọc/ghi property của 1 handle type .NET ngoài qua cú
pháp giống hệt field record (`obj.Prop`, `obj.Prop = x`), TÁI DÙNG nguyên
cơ chế `callvirt` đã xây ở Phase 3 — property .NET thật luôn là 2 method
ẩn `get_X()`/`set_X(value)`, không cần cơ chế mới, chỉ cần route đúng cú
pháp truy cập vào đúng lệnh `callvirt` tương ứng.

## Kiến trúc

### 1. Mở rộng khai báo — key `"properties"`

```python
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
        "properties": [
            {"name": "Length", "dtype": "i32", "readonly": true},
            {"name": "Capacity", "dtype": "i32", "readonly": false},
        ],
    },
]
```

`properties` là list-của-dict TÙY CHỌN (entry có thể không khai key này —
tương thích ngược 100% với các khai báo Phase 3 hiện có, không cần sửa gì
ở file `.tkv` cũ). Mỗi phần tử:
- `name`: tên property .NET thật (case-sensitive, đúng chữ property, KHÔNG
  phải `get_Name`/`set_Name` — compiler tự thêm tiền tố `get_`/`set_` lúc
  sinh CIL).
- `dtype`: scalar (`i32/i64/f32/f64/str`) HOẶC tên 1 handle type ĐÃ khai
  trong CÙNG `__tkv_extern_class__` (kể cả chính entry đang khai, kể cả
  handle type khác) — tái dùng NGUYÊN bảng dtype/validate của method
  (Phase 3 Task 4).
- `readonly`: bool, **tùy chọn, mặc định `true`** nếu vắng. `true` → chỉ
  sinh getter, gán `obj.Prop = x` là lỗi biên dịch. `false` → sinh CẢ
  getter và setter.

### 2. Cú pháp dùng trong `.tkv`

```python
def main() -> "i32":
    s = Sb()
    n: "i32" = s.Length          # doc property (callvirt get_Length)
    s.Capacity = 100              # ghi property (callvirt set_Capacity, CHI neu readonly=false)
    return n
```
Cú pháp GIỐNG HỆT truy cập field record hiện có (`obj.field`,
`obj.field = x`) — người dùng KHÔNG phân biệt được property .NET với field
DSL thường ở mặt cú pháp, chỉ khác ở phía compiler route sang `callvirt`
thay vì `ldfld`/`stfld`.

### 3. Codegen — tái dùng `callvirt` của Phase 3

Property .NET LUÔN là 2 method ẩn theo quy ước CLR:
`get_Name()`/`set_Name(value)`. Compiler sinh:
- Đọc: `callvirt instance <dtype_il> [assembly]Class::get_Name()`
- Ghi (chỉ nếu `readonly: false`): `callvirt instance void
  [assembly]Class::set_Name(<dtype_il>)`

Cả 2 dùng NGUYÊN factory `_make_extern_class_method_codegen`/cơ chế
dynamic-dispatch-theo-kiểu-khai-tĩnh đã xây ở Phase 3 Task 4 (registry
`EXPR_METHOD_CODEGEN` khoá theo `('extern_class', method_name)`, tra
`obj_ta.dtype` để lấy đúng chữ ký của CHÍNH class đó) — property CHỈ khác
ở điểm ĐĂNG KÝ: mỗi property `readonly=true` đăng ký 1 entry ẩn tên
`get_Name` (arity 0, return `dtype`); `readonly=false` đăng ký THÊM 1
entry ẩn `set_Name` (arity 1 tham số kiểu `dtype`, return `void`).

**Điểm route cú pháp mới** (KHÁC method — method gọi qua `obj.Method(...)`
với dấu ngoặc, property KHÔNG có ngoặc): tại nơi compiler hiện xử lý truy
cập field record (`obj.field` đọc, `obj.field = x` gán) — thêm nhánh
kiểm tra "đây có phải property của 1 handle type đã khai không" TRƯỚC khi
rơi về nhánh field-record cũ. Đọc nhánh:
- Đọc property → sinh gọi `get_Name()` (0 tham số) qua ĐÚNG cơ chế
  `callvirt` hiện có, KHÔNG viết logic mới, chỉ chọn tên method ẩn
  `get_Name` làm target.
- Ghi property → tại điểm compile statement gán field record hiện có,
  thêm nhánh tương tự: nếu LHS là property của handle type VÀ
  `readonly=false`, sinh gọi `set_Name(rhs_value)`; nếu `readonly=true`,
  `TranspileError` rõ ràng ("property X là readonly, không ghi được").

### 4. Validate

Tái dùng NGUYÊN các bước validate của method (Phase 3 Task 4): `name` là
identifier .NET hợp lệ, `dtype` nằm trong bảng scalar HOẶC là tên handle
type đã khai, KHÔNG trùng tên với 1 method/property khác CÙNG entry.
Thêm: `get_Name`/`set_Name` (tên method ẩn sinh ra) KHÔNG được trùng với
1 method THẬT đã khai trong `methods` của CÙNG entry (tránh 2 khai báo
cùng ánh xạ 1 tên CIL, sinh 2 entry `EXPR_METHOD_CODEGEN` xung đột).

## Giới hạn KHÔNG làm ở Phase 4 này

- **Không static property** — chỉ instance property, giống method Phase 3
  chỉ instance method.
- **Không indexer** (`obj[i]`, tương đương property đặc biệt `Item` có
  tham số trong .NET) — phạm vi riêng, phức tạp hơn property thường (cần
  cú pháp index DSL route sang `get_Item(i)`/`set_Item(i, value)`).
- **Không property kiểu container** — `dtype` chỉ scalar hoặc handle type
  đơn, giống giới hạn tham số/return của method Phase 3.
- **Không auto-detect getter/setter qua reflection** — người dùng tự khai
  đúng `dtype`/`readonly`, khai sai build OK nhưng chạy
  `MissingMethodException` (giữ nguyên nguyên tắc dự án).
- **Handle type's property KHÔNG tham gia duck-typing-inference** — giống
  method/field/operator của handle type đã chặn ở Phase 3 Task 5, dùng
  property của handle type trong tham số hàm `inferred` là lỗi biên dịch
  rõ ràng.

## Kiểm chứng

- Test tích cực đọc property: `System.Text.StringBuilder.Length` (property
  `i32` có thật) — build+chạy `.exe` thật, đối chiếu `len()` CPython.
- Test tích cực ghi property: dùng 1 property `readonly=false` thật của
  `mscorlib` (vd `StringBuilder.Capacity` — set rồi đọc lại xác nhận giá
  trị đổi, hoặc property khác nếu `Capacity` có ràng buộc runtime phức
  tạp — xác nhận chọn đúng property khi implement).
- Test lỗi: ghi vào property `readonly=true` → `TranspileError` rõ ràng.
- Test lỗi validate: `get_Name`/`set_Name` trùng tên method thật đã khai
  trong CÙNG entry → `TranspileError`.
- Test property trả về handle type khác (không chỉ scalar) — tương tự
  test chaining của method Phase 3.
- Test tương thích: property + method + constructor CÙNG 1 entry
  `__tkv_extern_class__`, dùng đồng thời trong 1 chương trình.
- Test duck-typing reject: property của handle type dùng trong tham số
  `inferred` → `TranspileError`.
- Regression toàn bộ test suite Phase 1-3 hiện có — đặc biệt field access
  trên RECORD thường (không phải handle type) vẫn hoạt động y hệt, xác
  nhận nhánh property mới không đụng đường code field-record cũ.
- Cả 2 cây (`.py`/`.tkv`) sửa đồng bộ — LƯU Ý: mirror tree `.tkv` tự-host
  CHƯA có nền tảng Phase 1/2/3 (xác nhận ở Phase 3 Task 5), nên Phase 4
  này CŨNG không port sang mirror tree, giữ nguyên tình trạng đã ghi nhận.
  KHÔNG rebuild `tkvc.exe`.
