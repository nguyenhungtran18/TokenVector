# `__tkv_extern_pinvoke__` — P/Invoke DLL native tổng quát hoá (Phase 2, Package ecosystem) — Design

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem — BLOCKER LỚN
NHẤT": Phase 1 (`__tkv_extern_method__`, 2026-08-17) đã mở khoá gọi
**static method .NET managed** đã biết chữ ký CIL qua khai báo, không cần
sửa compiler. Nhưng P/Invoke tới thư viện **native (C/C++ DLL)** vẫn hoàn
toàn viết tay per-library (`compiler/il_features/stdlib_cjson.py`,
`stdlib_sqlite.py`) — mỗi lần muốn dùng 1 hàm C mới phải tự viết
`pinvokeimpl(...)` + hàm Python codegen thủ công.

Hạ tầng có sẵn xác nhận qua đọc code thật (`stdlib_cjson.py`): khai báo
P/Invoke trong CIL dùng cú pháp
`.method public hidebysig static pinvokeimpl("X.dll" as "FuncName" cdecl)
    <ret_type> __hidden_name(<params>) cil managed preservesig {}`
— hoàn toàn KHÔNG cần `.assembly extern` trước (khác `__tkv_extern_method__`
cần `declared_assembly_names`). `i64` được dùng làm quy ước biểu diễn
pointer/handle (`cjson_parse(chuoi) -> i64` trả handle).

## Mục tiêu

Pragma mới `__tkv_extern_pinvoke__` — tổng quát hoá pattern P/Invoke đã
viết tay, cho phép code `.tkv` TỰ KHAI BÁO gọi 1 hàm trong DLL native (chữ
ký C-ABI phẳng đã biết trước), compiler tự sinh declaration `pinvokeimpl`
+ đăng ký builtin ĐỘNG — KHÔNG cần sửa file compiler cho mỗi hàm mới.

## Kiến trúc

### Pragma

```python
__tkv_extern_pinvoke__ = [
    {"name": "sqrt_native", "dll": "msvcrt.dll", "symbol": "sqrt",
     "convention": "cdecl", "params": ["f64"], "returns": "f64"},
]
```

Dạng list-của-dict, đúng tinh thần `__tkv_extern_method__` (vẫn là phép
gán Python hợp lệ 100% dưới CPython).

### Điểm parse

Thêm nhánh `elif` mới trong `_parse_program_ast` (`tkv_compile.py`), NGAY
SAU nhánh `__tkv_extern_pinvoke__`... à, NGAY SAU nhánh `__tkv_extern_method__`
hiện có. Hàm mới `_parse_extern_pinvoke_dict_literal(node)` — CẤU TRÚC GẦN
NHƯ Y HỆT `_parse_extern_method_dict_literal` (tái dùng phần lớn logic
validate shape dict-literal), chỉ khác tập key bắt buộc:
`name/dll/symbol/convention/params/returns` (KHÔNG có `class`/`method`,
thay bằng `dll`/`symbol`/`convention`). `_parse_program_ast` trả về thêm
`extern_pinvokes`.

### Đăng ký động

Trong `compile_tkv_cli`, CÙNG VỊ TRÍ với đăng ký `extern_methods` (ngay sau
parse, trước `gen_il_program`), thêm vòng lặp riêng cho `extern_pinvokes`:
với mỗi khai báo, `_validate_and_register_extern_pinvoke(decl)`:

1. `dll` khớp regex tên file hợp lệ (kết thúc `.dll`, không chứa path
   traversal `..`/`/`/`\`).
2. `symbol` khớp regex identifier C hợp lệ (chữ/số/gạch dưới, không bắt
   đầu bằng số).
3. `convention` là `'cdecl'` hoặc `'stdcall'` (chỉ 2 giá trị này).
4. `params`/`returns` nằm trong `_EXTERN_DTYPE_TO_IL` (TÁI DÙNG bảng của
   `__tkv_extern_method__` — 5 scalar `i32/i64/f32/f64/str`, GIỜ CHO PHÉP
   CẢ `void` cho `returns` — khác Phase 1, xem mục "Xử lý void" bên dưới).
5. `name` là identifier Python hợp lệ.
6. Sinh 1 tên hidden method DUY NHẤT (vd `__pinvoke_{name}`), APPEND vào
   danh sách dòng `.method ... pinvokeimpl(...)` sẽ được ghép vào class
   chương trình (tương tự `CJSON_PINVOKE_DECL_LINES` nhưng sinh ĐỘNG).
7. `register_expr_builtin(name, codegen_fn, returns if returns != 'void'
   else None)` — codegen_fn qua factory `_make_extern_pinvoke_call_codegen`
   (gần như y hệt `_make_extern_static_call_codegen` của Phase 1, chỉ khác
   `call_prefix` trỏ tới hidden method trong class hiện tại thay vì
   `[assembly]class`).

`finally`-pop y hệt cơ chế Phase 1 (`EXPR_BUILTIN_CODEGEN`/
`EXPR_BUILTIN_DTYPE`, an toàn cùng-process khi compile nhiều file liên
tiếp).

**Điểm chèn dòng `pinvokeimpl` vào IL text**: cần xác định lúc implement
CHÍNH XÁC nơi `CJSON_PINVOKE_DECL_LINES`/`SQLITE_PINVOKE_DECL_LINES` hiện
tại được ghép vào output IL (tìm trong `compile_tkv_cli`/`gen_il_program`)
— danh sách dòng `pinvokeimpl` MỚI sinh động phải ghép vào ĐÚNG cùng vị trí
đó, để không phá layout IL hiện có.

### Xử lý `void` — sửa tận gốc (khác Phase 1)

`__tkv_extern_method__` (Phase 1) đã CHẶN `returns:"void"` vì phát hiện
`codegen_call_stmt` (`compiler/il_features/file_io.py`) khi gọi 1 hàm dạng
LỆNH ĐỘC LẬP (không gán biến) chỉ tra `func_table` (hàm `.tkv` người dùng)
+ 1 bảng builtin void RIÊNG (`log_*`/`pickle_dump_*`/`sys_exit`) — KHÔNG
tra `EXPR_BUILTIN_CODEGEN`.

Phase 2 sửa tận gốc: thêm 1 nhánh fallback trong `codegen_call_stmt` — nếu
tên hàm KHÔNG có trong `func_table` VÀ KHÔNG có trong bảng builtin void
riêng, tra tiếp `EXPR_BUILTIN_CODEGEN` (builtin registered qua
`register_expr_builtin` với `return_dtype=None`, tức đã đăng ký như hàm
void) — nếu tìm thấy, gọi codegen đó, `pop` giá trị trả về nếu builtin đó
LỠ đẩy giá trị lên stack (an toàn 2 chiều: cho phép builtin nào có push giá
trị vẫn hoạt động đúng khi gọi độc lập, IL `pop` sau `call` nếu
`return_dtype` gốc không phải `None`).

**Tác dụng phụ có lợi**: điều này ĐỒNG THỜI mở khoá gọi `void` cho
`__tkv_extern_method__` (Phase 1 cũ) nếu người dùng khai `returns:"void"`
— NHƯNG Phase 1's validate HIỆN TẠI vẫn đang chặn cứng ở bước validate
(xem `docs/superpowers/specs/2026-08-14-extern-method-design.md`, review
finding I1). Spec này KHÔNG yêu cầu gỡ bỏ chặn đó của Phase 1 (ngoài phạm
vi, tránh side-effect không mong muốn lên tính năng đã đóng) — chỉ đảm bảo
cơ chế `codegen_call_stmt` mới hoạt động đúng cho `__tkv_extern_pinvoke__`.
Việc có gỡ chặn `void` cho Phase 1 cũ hay không để lại quyết định riêng
sau, không phải phạm vi Phase 2.

## Phạm vi KHÔNG làm ở Phase 2 này

Struct/complex-type marshaling; callback (function pointer truyền vào
native); tham số `ref`/`out`; tự động dò export DLL (người dùng tự biết
đúng `symbol`); C++ name mangling (chỉ C-ABI phẳng, `extern "C"`); mảng/
buffer marshaling tùy biến (dùng `i64` làm con trỏ thô nếu cần, người dùng
tự quản lý bộ nhớ qua các hàm native khác, giống cách `cjson_parse`/
`cjson_delete` hiện có hoạt động); charset marshaling tùy biến (`str` dùng
marshaling mặc định của CLR, không có tuỳ chọn ANSI/Unicode riêng); DLL
không tồn tại/symbol sai lúc runtime báo lỗi CLR gốc
(`DllNotFoundException`/`EntryPointNotFoundException`), không dịch riêng.

## Kiểm chứng

- Test tích cực dùng 1 hàm thật trong `msvcrt.dll` (có sẵn trên mọi máy
  Windows, không cần cài thêm) — vd `sqrt` (double sqrt(double)) hoặc
  `abs`(int abs(int)) — đối chiếu kết quả với Python thật.
- Test `convention` cả `cdecl` VÀ `stdcall` (tìm 1 hàm Windows API chuẩn
  dùng stdcall để test, vd hàm trong `kernel32.dll` không cần tham số phức
  tạp — xác nhận lúc implement).
- Test `returns:"void"` — 1 hàm native void thật, gọi dạng lệnh độc lập,
  xác nhận `codegen_call_stmt`'s nhánh mới hoạt động đúng.
- Test lỗi validate: `dll` sai định dạng/path traversal, `symbol` sai
  regex, `convention` không phải cdecl/stdcall, dtype không hỗ trợ, tên
  trùng builtin có sẵn.
- Test isolation (2 lần gọi `compile_tkv_cli` liên tiếp cùng process, cùng
  tên builtin `extern_pinvoke` — giống bài test quan trọng nhất của Phase 1).
- Test tương thích với `__tkv_extern_method__` (Phase 1) VÀ P/Invoke viết
  tay có sẵn (`cjson_*`/`sqlite_*`) dùng ĐỒNG THỜI trong cùng 1 file —
  không xung đột `extern_lines`/`CJSON_PINVOKE_DECL_LINES` cũ.
- Regression toàn bộ test suite hiện có, đặc biệt mọi test dùng
  `cjson_*`/`db_*` (P/Invoke viết tay cũ) — không builtin nào bị ảnh hưởng.
- Cả 2 cây (`tkv_compile.py`/`release/3.code/tkv_compile.tkv`) sửa đồng
  bộ. KHÔNG rebuild `tkvc.exe`.
