# `__tkv_extern_method__` — gọi static method .NET ngoài (Phase 1, Package ecosystem) — Design

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem" đánh dấu "BLOCKER
LỚN NHẤT" — chưa code gì cụ thể. Mọi tính năng .NET hiện có
(`complex_type.py`/`stdlib_re.py`/`set_type.py`) đều viết tay 100%: mỗi
method cần compiler dev tự hardcode chữ ký CIL + đăng ký thủ công. Không có
cách nào để CODE `.tkv` tự khai báo gọi 1 method .NET/NuGet khác mà không sửa
file compiler.

`__tkv_extern_assembly__` (`tkv_compile.py:874-911`) ĐÃ CÓ SẴN — cho khai
`.assembly extern` tới 1 assembly managed bất kỳ, nhưng CHỈ sinh dòng
`.assembly extern`, không tạo binding gọi hàm.

## Mục tiêu

Pragma mới `__tkv_extern_method__` — code `.tkv` khai báo 1 static method
.NET (đã biết chữ ký CIL chính xác), compiler tự đăng ký ĐỘNG thành builtin
gọi được, KHÔNG cần sửa file compiler. Đây là Phase 1 của chiến lược nhiều
giai đoạn cho "package ecosystem" — KHÔNG phải giải pháp trọn vẹn.

## Kiến trúc

### Pragma

```python
__tkv_extern_method__ = [
    {"name": "net_pow", "assembly": "mscorlib", "class": "System.Math",
     "method": "Pow", "params": ["f64", "f64"], "returns": "f64"},
]
```
Dạng list-của-dict, giữ tinh thần "vẫn là phép gán Python hợp lệ 100% dưới
CPython" như `__tkv_import__`/`__tkv_extern_assembly__` hiện có.

### Điểm parse

Thêm nhánh `elif` trong `_parse_program_ast` (`tkv_compile.py`) NGAY SAU
nhánh `__tkv_extern_assembly__` (~dòng 874-911). Hàm mới
`_parse_extern_method_dict_literal(node)` duyệt `ast.Dict`, chỉ chấp nhận key
`name/assembly/class/method/params/returns`, tất cả giá trị `ast.Constant`
(riêng `params` là `ast.List` của `ast.Constant(str)`). Thiếu key/sai kiểu →
`TranspileError` rõ. `_parse_program_ast` trả về thêm `extern_methods`.

**Cần xác nhận lúc implement**: dự án có 2 pipeline compile khác nhau
(`compile_tkv_cli` — dùng bởi `tkv.py build`, VÀ `transpile_program`/
`_transpile_extracted` — pipeline khác) đều cuối cùng gọi `gen_il_program`.
Xác định `tkv.py build` đi đường nào và có cần patch cả 2 hay chỉ 1.

### Đăng ký động

Trong `compile_tkv_cli`, NGAY SAU parse AST, TRƯỚC `gen_il_program`:
```python
declared_assembly_names = {asm for asm, *_ in extern_assemblies} | \
    {'mscorlib', 'System', 'System.Core'}
registered_extern_names = []
try:
    for decl in extern_methods:
        _validate_and_register_extern_method(decl, declared_assembly_names)
        registered_extern_names.append(decl['name'])
    # ... gen_il_program(...) và phần còn lại ...
finally:
    for nm in registered_extern_names:
        EXPR_BUILTIN_CODEGEN.pop(nm, None)
        EXPR_BUILTIN_DTYPE.pop(nm, None)
```

**Rủi ro quan trọng nhất**: `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE`
(`il_dispatch.py`) là dict CẤP MODULE, không tự reset giữa 2 lần gọi
`compile_tkv_cli` trong CÙNG process. Builtin viết tay an toàn (đăng ký 1 lần
lúc import module); builtin extern đăng ký THEO TỪNG FILE — BẮT BUỘC
`finally`-pop, nếu không sẽ "rò rỉ" giữa các lần compile hoặc gây lỗi trùng
tên giả ở lần gọi thứ 2 trong cùng process (test runner/CI thường compile
nhiều file liên tiếp).

### Validate

`_EXTERN_DTYPE_TO_IL = {'i32':'int32','i64':'int64','f32':'float32','f64':'float64','str':'string'}`

Thứ tự (mỗi bước fail → `TranspileError` rõ): (1) `assembly` khớp regex tên
assembly .NET hợp lệ VÀ phải nằm trong `declared_assembly_names`; (2) `class`
khớp regex tên class .NET hợp lệ; (3) `method` khớp regex identifier đơn
giản; (4) mọi `params` nằm trong bảng dtype; (5) `returns` phải nằm trong
bảng dtype (5 scalar) — KHÔNG hỗ trợ `void` ở Phase 1 (đường gọi hàm-void-
dạng-lệnh-độc-lập thực tế, `file_io.py::codegen_call_stmt`, chỉ tra
`func_table` + 1 bảng dispatch riêng cho builtin void có sẵn, KHÔNG tra
`EXPR_BUILTIN_CODEGEN` — nên `void` trước đây đăng ký được nhưng không gọi
được thật; xem review finding I1); (6) `name` là identifier Python hợp lệ;
(7) đăng ký qua `register_expr_builtin` (tái dùng guard chống trùng tên có
sẵn từ bug `json_get_str`, KHÔNG viết lại).

### Factory codegen động

`_make_extern_static_call_codegen(assembly, dotnet_class, method_name,
param_dtypes, return_dtype)` trả về closure `fn(args, scope, out, dtype,
ctx)` (đúng chữ ký `codegen_fn` hiện có, đối chiếu
`stdlib_math.py::_make_math_func_compiler`):
1. Check `len(args) == len(param_dtypes)`.
2. MỖI tham số ép theo ĐÚNG dtype khai báo RIÊNG vị trí đó qua
   `ctx['compile_expr'](arg_node, scope, out, want_dtype, ctx)` (KHÁC
   `_make_math_func_compiler` ép đồng loạt 1 dtype).
3. Emit `f'    call {il_ret_type} [{assembly}]{dotnet_class}::{method_name}({params})'`.
4. Không cần widen thủ công — `_expr_call` tự widen theo `EXPR_BUILTIN_DTYPE`.

## Phạm vi KHÔNG làm ở Phase 1

Instance method/ctor/property/field; generic method; tham số/return kiểu
container; overload resolution (1 tên = đúng 1 chữ ký); P/Invoke native
(nhánh riêng, để dành); reflection tự động dò chữ ký (người dùng tự xác minh
qua ILSpy/reflection của họ); `ref`/`out`/`params object[]`; dịch riêng
exception .NET (lan truyền như exception thường).

## Kiểm chứng

- Test tích cực dùng `System.Math::Pow` (không cần NuGet/DLL ngoài) — so
  sánh CPython thật.
- Test dtype khác nhau theo vị trí (`[i32, f64]`).
- Test lỗi validate: assembly chưa khai, dtype không hỗ trợ, tên trùng
  builtin có sẵn (qua guard sẵn có), class/method sai regex.
- Regression toàn bộ test suite, đặc biệt mọi test dùng `pow`/`Math.*`.
- **Test isolation quan trọng nhất**: gọi `compile_tkv_cli` 2 lần liên tiếp
  trong cùng process, 2 file khác nhau, CÙNG tên builtin extern — xác nhận
  lần 2 không báo lỗi trùng tên giả.
- Test tương thích với P/Invoke (`cjson`/`sqlite`) trong cùng 1 file.
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
