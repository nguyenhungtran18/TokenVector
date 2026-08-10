# TOKENVECTOR SYSTEM FILE & LIBRARY REGISTRY
### (Danh Sách Toàn Bộ Tệp Hệ Thống & Thư Viện Native TokenVector Trong Bản Phát Hành Release)

Tài liệu liệt kê và phân loại chính thức toàn bộ **278 tệp hệ thống, nhân trình biên dịch, thư viện chuẩn và bộ kiểm thử Native `.tkv`** nằm trong bộ phát hành thương mại [`release/`](file:///C:/Claude%20AI%20Project/TokenVector/release/).

---

## 1. THÀNH PHẦN THỰC THI NÒNG NỐT (CORE SYSTEM EXECUTABLE)

- `release/3.code/dist/tkvc.exe`: File thực thi độc lập chính thức của Trình biên dịch & Bộ biên dịch AOT Native TokenVector.

---

## 2. NHÂN TRÌNH BIÊN DỊCH NATIVE (COMPILER CORE SYSTEM - `.tkv`)

- `release/3.code/tkv_compile.tkv`: Trình biên dịch dòng lệnh chính phân tích AST, quản lý module cây phụ thuộc và phát sinh CIL PE Binary.
- `release/3.code/tkv.tkv`: Điểm vào dòng lệnh CLI (`tkv` / `tkvc`).
- `release/3.code/tokenvector_compile.tkv`: Module gọi Assembler ILASM dịch file `.il` thành file `.exe` / `.dll`.
- `release/3.code/build_tkvc.ps1`: Tập lệnh đóng gói trình biên dịch TokenVector.

---

## 3. BỘ MÁY TÍNH NĂNG NỘI HÀM CIL (`release/3.code/compiler/`)

- `release/3.code/compiler/il_codegen.tkv`: Trình sinh mã CIL chính quản lý hàm, record/class, closure, scope và main method.
- `release/3.code/compiler/il_core.tkv`: Nhân phân tích biểu thức (Expr Parser) và phát sinh mã lệnh CIL cơ bản.
- `release/3.code/compiler/il_dispatch.tkv`: Hệ thống Dispatch Table (`register_expr_builtin`, `register_stmt_codegen`).
- `release/3.code/compiler/typed_dsl_parser.tkv`: Trình phân tích kiểu DSL (`i32`, `i64`, `f32`, `f64`, `str`, `TypeAnn`).
- `release/3.code/compiler/il_features/control_flow.tkv`: Xử lý `if/elif/else`, `for range`, `while`, `break`, `continue`, `try/except/finally`.
- `release/3.code/compiler/il_features/int_type.tkv`: Struct `TkvInt` xử lý số nguyên vô hạn (BigInteger).
- `release/3.code/compiler/il_features/string_feature.tkv`: Xử lý chuỗi ký tự UTF-8, phép nối, cắt chuỗi và `TkvStr`.
- `release/3.code/compiler/il_features/list_type.tkv`: Danh sách động `List<T>` và `List<object>`.
- `release/3.code/compiler/il_features/dict_type.tkv`: Bảng băm `Dictionary<K,V>`.
- `release/3.code/compiler/il_features/set_type.tkv`: Tập hợp `HashSet<T>`.
- `release/3.code/compiler/il_features/tuple_type.tkv`: Bộ dữ liệu bất biến Tuple.
- `release/3.code/compiler/il_features/record_feature.tkv`: Lớp/Record OOP, đơn kế thừa và đa kế thừa lớp.
- `release/3.code/compiler/il_features/generator_lazy.tkv`: Sinh mã State Machine CIL cho Generator `yield` và `yield from`.
- `release/3.code/compiler/il_features/async_await.tkv`: Ánh xạ `async def` / `await` sang `.NET Task<T>`.
- `release/3.code/compiler/il_features/threading_feature.tkv`: Hỗ trợ đa luồng thật `thread_spawn` / `thread_join` không GIL.
- `release/3.code/compiler/il_features/ffi_feature.tkv`: Hỗ trợ `ctypes` & P/Invoke binding C native functions.
- `release/3.code/compiler/il_features/dynamic_exec.tkv`: Hỗ trợ `eval_code()` và `exec_code()` thực thi mã động tại runtime.
- `release/3.code/compiler/il_features/stdlib_bcl.tkv`: Mở rộng PyStdlib sang .NET BCL (`re`, `datetime`, `random`).
- `release/3.code/compiler/il_features/pycapi_shim.tkv`: Shim tương thích CPython C-API (`PyTuple`, `PyDict`).
- `release/3.code/compiler/il_features/closures.tkv`: Xử lý biến tự do (Closure & Nonlocal capture).

---

## 4. THƯ VIỆN CHUẨN NATIVE (`release/3.code/stdlib/`)

- `release/3.code/stdlib/math.tkv`: Thư viện toán học Native (`sqrt`, `pow`, `abs`).
- `release/3.code/stdlib/pystdlib.tkv`: Thư viện cầu nối BCL (`tkv_re_replace`, `tkv_now`, `tkv_randint`).
- `release/3.code/stdlib/sys.tkv`: Thư viện thông tin hệ thống và đường dẫn module.
- `release/3.code/stdlib/datetime.tkv`: Thư viện thời gian và ngày tháng.
- `release/3.code/stdlib/re.tkv`: Thư viện xử lý Biểu thức chính quy (Regular Expressions).
- `release/3.code/stdlib/os.tkv`: Thư viện tương tác Hệ điều hành & File System.

---

## 5. CÔNG CỤ NATIVE TRANSPILER (`release/3.code/tools/`)

- `release/3.code/tools/tkv_transpiler.tkv`: Trình chuyển đổi mã hai chiều tự động giữa `.py` và `.tkv` viết 100% bằng TokenVector Native.

---

## 6. TÀI LIỆU & BÁO CÁO GIAO DIỆN (`release/2.UI/` & `release/3.code/docs/`)

- `release/2.UI/benchmark_results.html`: Báo cáo so sánh hiệu năng giao diện HTML interactive.
- `release/3.code/docs/SACH_HUONG_DAN_LAP_TRINH_TOKENVECTOR.md`: Sách hướng dẫn lập trình TokenVector chuẩn học thuật (Unit I - Unit V).
- `release/3.code/docs/DANH_SACH_TEP_CHUAN_TOKENVECTOR.md`: Tài liệu quy định tệp chuẩn.
- `release/README.md`: Hướng dẫn vận hành nhanh bản phát hành.

---

## 7. BỘ KIỂM THỬ NGIỆM THU NATIVE (`release/3.code/test/verify/`)

Gồm **160 tệp kiểm thử Native `.tkv`** bảo chứng 100% chức năng hệ thống:
- `ledger_test.tkv`: Bộ kiểm thử nghiệm thu tổng (0 open entries, PASS 100%).
- `async_await_test.tkv`: Kiểm thử bất đồng bộ native.
- `generator_test.tkv` & `yield_from_test.tkv`: Kiểm thử Generator state machine.
- `site_packages_import_test.tkv` & `pkg_installer_test.tkv`: Kiểm thử import package.
- `multiple_inheritance_test.tkv`: Kiểm thử đa kế thừa lớp.
- `ctypes_ffi_bridge_test.tkv`: Kiểm thử C-Extension P/Invoke FFI.
- `dotnet_assembly_import_test.tkv`: Kiểm thử liên kết Assembly .NET.
- `reflection_emit_repl_test.tkv`: Kiểm thử thực thi mã động `eval_code`/`exec_code`.
- `_file_io_helpers.tkv`, `_json_helpers.tkv`, `_repeat_helpers.tkv`, `_re_helpers.tkv`: Thư viện helper nghiệm thu.
