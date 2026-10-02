# TOKENVECTOR SYSTEM FILE & LIBRARY REGISTRY
### (Danh Sách Toàn Bộ Tệp Hệ Thống & Thư Viện Native TokenVector Trong Bản Phát Hành Release)

Tài liệu liệt kê và phân loại chính thức toàn bộ **364 tệp** (đếm trực tiếp, gồm cả `.exe`/`.il` build sẵn) nằm trong bộ phát hành thương mại ``. Riêng phần **thư viện chức năng thật của `tkvc.exe`** (mã nguồn compiler, không tính chương trình mẫu/test) chỉ gồm **82 file `.tkv`** — xem mục 2-3 bên dưới, đã xác minh bằng phân tích reachability từ `tkv.tkv` (2026-08-10).

---

## 1. THÀNH PHẦN THỰC THI NÒNG NỐT (CORE SYSTEM EXECUTABLE)

- `dist/tkvc.exe`: File thực thi độc lập chính thức của Trình biên dịch & Bộ biên dịch AOT Native TokenVector.

---

## 2. NHÂN TRÌNH BIÊN DỊCH NATIVE (COMPILER CORE SYSTEM - `.tkv`)

- `tkv_compile.tkv`: Trình biên dịch dòng lệnh chính phân tích AST, quản lý module cây phụ thuộc và phát sinh CIL PE Binary.
- `tkv.tkv`: Điểm vào dòng lệnh CLI (`tkv` / `tkvc`).
- `tokenvector_compile.tkv`: Module gọi Assembler ILASM dịch file `.il` thành file `.exe` / `.dll`.
- `build_tkvc.ps1`: Tập lệnh đóng gói trình biên dịch TokenVector.

---

## 3. BỘ MÁY TÍNH NĂNG NỘI HÀM CIL (`compiler/`)

- `compiler/il_codegen.tkv`: Trình sinh mã CIL chính quản lý hàm, record/class, closure, scope và main method.
- `compiler/il_core.tkv`: Nhân phân tích biểu thức (Expr Parser) và phát sinh mã lệnh CIL cơ bản.
- `compiler/il_dispatch.tkv`: Hệ thống Dispatch Table (`register_expr_builtin`, `register_stmt_codegen`).
- `compiler/typed_dsl_parser.tkv`: Trình phân tích kiểu DSL (`i32`, `i64`, `f32`, `f64`, `str`, `TypeAnn`).
- `compiler/il_features/control_flow.tkv`: Xử lý `if/elif/else`, `for range`, `while`, `break`, `continue`, `try/except/finally`.
- `compiler/il_features/int_type.tkv`: Struct `TkvInt` xử lý số nguyên vô hạn (BigInteger).
- `compiler/il_features/string_feature.tkv`: Xử lý chuỗi ký tự UTF-8, phép nối, cắt chuỗi và `TkvStr`.
- `compiler/il_features/list_type.tkv`: Danh sách động `List<T>` và `List<object>`.
- `compiler/il_features/dict_type.tkv`: Bảng băm `Dictionary<K,V>`.
- `compiler/il_features/set_type.tkv`: Tập hợp `HashSet<T>`.
- `compiler/il_features/tuple_type.tkv`: Bộ dữ liệu bất biến Tuple.
- `compiler/il_features/record_feature.tkv`: Lớp/Record OOP, đơn kế thừa và đa kế thừa lớp.
- `compiler/il_features/generator_lazy.tkv`: Sinh mã State Machine CIL cho Generator `yield` và `yield from`.
- `compiler/il_features/async_await.tkv`: Ánh xạ `async def` / `await` sang `.NET Task<T>`.
- `compiler/il_features/threading_feature.tkv`: Hỗ trợ đa luồng thật `thread_spawn` / `thread_join` không GIL.
- `compiler/il_features/ffi_feature.tkv`: Hỗ trợ `ctypes` & P/Invoke binding C native functions.
- `compiler/il_features/dynamic_exec.tkv`: Hỗ trợ `eval_code()` và `exec_code()` thực thi mã động tại runtime.
- `compiler/il_features/stdlib_bcl.tkv`: Mở rộng PyStdlib sang .NET BCL (`re`, `datetime`, `random`).
- `compiler/il_features/pycapi_shim.tkv`: Shim tương thích CPython C-API (`PyTuple`, `PyDict`).
- `compiler/il_features/closures.tkv`: Xử lý biến tự do (Closure & Nonlocal capture).

---

## 4. VÍ DỤ THƯ VIỆN TIỆN ÍCH (`examples/stdlib/`)

Đúng **2 file** (đã xác minh trực tiếp — KHÔNG có `sys.tkv`/`datetime.tkv`/`re.tkv`/`os.tkv` như phiên bản tài liệu trước đây ghi nhầm; các hàm `re`/`datetime`/`os` khác đã có sẵn dạng builtin toàn cục trong compiler, không cần file riêng):

- `examples/stdlib/math.tkv`: Ví dụ thư viện toán học Native (`sqrt`, `pow`, `abs`).
- `examples/stdlib/pystdlib.tkv`: Ví dụ thư viện cầu nối BCL (`tkv_re_replace`, `tkv_now`, `tkv_randint`).

---

## 5. CHƯƠNG TRÌNH MẪU & CÔNG CỤ (`projects/`)

**15 công cụ thật** dùng làm case-study (đã build sẵn `.exe`, biên dịch lại thành công từ nguồn `.tkv` — xác minh 2026-08-10): `codestat.tkv`, `ctxpack.tkv`, `defmeta.tkv`, `domain.tkv`, `graphreview.tkv`, `graphstale.tkv`, `impact.tkv`, `impgraph.tkv`, `layers.tkv`, `mergedefs.tkv`, `mergemeta.tkv`, `nodemeta.tkv`, `pytok.tkv`, `tkvcalc.tkv`, `tkvcalc_ast.tkv`, `tour.tkv`, `typegraph.tkv`, `whylink.tkv`, và `tkv_transpiler.tkv` (trình chuyển đổi mã hai chiều `.py`↔`.tkv`).

Lưu ý: đây là **chương trình mẫu do `tkvc.exe` biên dịch**, KHÔNG phải mã nguồn của chính `tkvc.exe` — xem mục 2-3 để biết đâu là thư viện chức năng thật.

---

## 6. TÀI LIỆU & BÁO CÁO GIAO DIỆN (`assets/` & `docs/`)

- `assets/benchmark_results.html`: Báo cáo so sánh hiệu năng giao diện HTML interactive.
- `docs/TUTORIAL.md`: Sách hướng dẫn lập trình TokenVector (Unit I - Unit V, một số bài trong mục lục chưa có nội dung — xem ghi chú đầu file đó).
- `README.md`: Hướng dẫn vận hành nhanh bản phát hành.

---

## 7. BỘ KIỂM THỬ NGIỆM THU NATIVE (`test/verify/`)

Gồm **174 tệp `.tkv`** (đếm trực tiếp 2026-08-10, không phải 160 như phiên bản trước) — nhưng **KHÔNG tự chạy được nếu chỉ tải riêng `` về**: bộ test này cần ~115 file mẫu `sample_*.tkv` và `test/parity/arbiter.py` nằm ở gốc repo (`test/`), hiện chưa được đóng gói kèm theo. Xem `docs/BUGS_TODO.md` mục F để biết chi tiết. Bộ test tiêu biểu:
- `ledger_test.tkv`: Bộ kiểm thử nghiệm thu tổng (0 open entries, PASS 100%).
- `async_await_test.tkv`: Kiểm thử bất đồng bộ native.
- `generator_test.tkv` & `yield_from_test.tkv`: Kiểm thử Generator state machine.
- `site_packages_import_test.tkv` & `pkg_installer_test.tkv`: Kiểm thử import package.
- `multiple_inheritance_test.tkv`: Kiểm thử đa kế thừa lớp.
- `ctypes_ffi_bridge_test.tkv`: Kiểm thử C-Extension P/Invoke FFI.
- `dotnet_assembly_import_test.tkv`: Kiểm thử liên kết Assembly .NET.
- `reflection_emit_repl_test.tkv`: Kiểm thử thực thi mã động `eval_code`/`exec_code`.
- `_file_io_helpers.tkv`, `_json_helpers.tkv`, `_repeat_helpers.tkv`, `_re_helpers.tkv`: Thư viện helper nghiệm thu.
