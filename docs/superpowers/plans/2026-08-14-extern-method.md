# `__tkv_extern_method__` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pragma `__tkv_extern_method__` — code `.tkv` khai báo 1 static method .NET, compiler tự đăng ký động thành builtin gọi được, không cần sửa file compiler.

**Architecture:** Parse pragma trong `_parse_program_ast` (`tkv_compile.py`) → validate → đăng ký động qua `register_expr_builtin` NGAY TRƯỚC `gen_il_program`, `finally`-pop sau khi compile xong (tránh rò rỉ giữa các lần gọi trong cùng process).

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror.

## Global Constraints

- Sửa đồng bộ cả 2 cây (`tkv_compile.py` + `release/3.code/tkv_compile.tkv`). KHÔNG rebuild `tkvc.exe`.
- Chỉ static method, 5 dtype scalar (`i32/i64/f32/f64/str`). Không instance/ctor/generic/container/P-Invoke.
- BẮT BUỘC `finally`-pop đăng ký động — dict registry là process-global.
- Tái dùng nguyên `register_expr_builtin`/guard chống trùng tên có sẵn trong `il_dispatch.py` — KHÔNG viết logic kiểm tra trùng tên riêng, KHÔNG sửa `il_dispatch.py`.

---

### Task 1: Điều tra pipeline compile + điểm parse pragma

**Files:**
- Read only: `tkv.py`, `tkv_compile.py` (toàn bộ `_parse_program_ast`, `extract_program`/`extract_program_file`, `_transpile_extracted`/`transpile_program`, `compile_tkv_cli`)

**Interfaces:**
- Produces: xác nhận bằng văn bản (ghi vào report) — `tkv.py build` gọi hàm nào, pipeline nào thực sự dùng cho build CLI chính (đã dùng xuyên suốt session này qua `python tkv.py build ... --entry run --out ...`), pipeline nào là đường khác (nếu có, dùng cho mục đích gì — test/API khác).

- [ ] **Step 1: Đọc `tkv.py`'s lệnh `build`** — xác nhận nó gọi `compile_tkv_cli` trực tiếp (khớp cách build đã dùng suốt session: `python tkv.py build <file> --entry run --out <exe>`).

- [ ] **Step 2: Đọc `_parse_program_ast`, `extract_program`/`extract_program_file`, `_transpile_extracted`/`transpile_program`** — xác định: `compile_tkv_cli` có gọi `_parse_program_ast` TRỰC TIẾP hay qua `extract_program_file` trung gian? `transpile_program`/`_transpile_extracted` được dùng ở đâu khác trong codebase (grep lời gọi 2 hàm này toàn repo) — nếu KHÔNG có nơi nào gọi ngoài chính `tkv_compile.py` nội bộ, hoặc chỉ dùng cho 1 API phụ không liên quan `tkv.py build`, thì CHỈ CẦN patch `compile_tkv_cli`'s pipeline, ghi rõ kết luận này vào report và bỏ qua `_transpile_extracted` ở các Step sau — KHÔNG patch nếu không cần thiết (tránh thay đổi thừa).

- [ ] **Step 3: Xác nhận số dòng chính xác** của nhánh `__tkv_extern_assembly__` trong `_parse_program_ast` (khoảng 874-911, có thể lệch), `extern_assemblies = []` (khoảng 796), và điểm gọi `gen_il_program` trong `compile_tkv_cli` (khoảng 1679) — ghi lại số dòng THẬT vào report để Task 2 dùng.

---

### Task 2: Parse pragma `__tkv_extern_method__`

**Files:**
- Modify: `tkv_compile.py`
- Modify: mirror `release/3.code/tkv_compile.tkv`

**Interfaces:**
- Consumes: kết luận Task 1 (số dòng chính xác, pipeline nào cần patch).
- Produces: `_parse_program_ast` trả về thêm `extern_methods: list[dict]` trong tuple kết quả — Task 3 tiêu thụ.

- [ ] **Step 1: Thêm `extern_methods = []`** cạnh `extern_assemblies = []` (đầu `_parse_program_ast`).

- [ ] **Step 2: Viết `_parse_extern_method_dict_literal(node)`**:
```python
_EXTERN_METHOD_KEYS = {'name', 'assembly', 'class', 'method', 'params', 'returns'}
_EXTERN_METHOD_REQUIRED = {'name', 'assembly', 'class', 'method', 'returns'}

def _parse_extern_method_dict_literal(node):
    if not isinstance(node, ast.Dict):
        raise TranspileError(
            "__tkv_extern_method__: moi phan tu phai la 1 dict voi cac key "
            "name/assembly/class/method/params/returns")
    result = {}
    for k, v in zip(node.keys, node.values):
        if not (isinstance(k, ast.Constant) and isinstance(k.value, str)):
            raise TranspileError("__tkv_extern_method__: key dict phai la chuoi")
        key = k.value
        if key not in _EXTERN_METHOD_KEYS:
            raise TranspileError(
                f"__tkv_extern_method__: key '{key}' khong hop le - chi chap nhan "
                f"{sorted(_EXTERN_METHOD_KEYS)}")
        if key == 'params':
            if not isinstance(v, ast.List):
                raise TranspileError("__tkv_extern_method__: 'params' phai la 1 list chuoi")
            params = []
            for elt in v.elts:
                if not (isinstance(elt, ast.Constant) and isinstance(elt.value, str)):
                    raise TranspileError("__tkv_extern_method__: moi phan tu 'params' phai la chuoi")
                params.append(elt.value)
            result['params'] = params
        else:
            if not (isinstance(v, ast.Constant) and isinstance(v.value, str)):
                raise TranspileError(f"__tkv_extern_method__: gia tri '{key}' phai la chuoi")
            result[key] = v.value
    result.setdefault('params', [])
    missing = _EXTERN_METHOD_REQUIRED - result.keys()
    if missing:
        raise TranspileError(
            f"__tkv_extern_method__: thieu key bat buoc {sorted(missing)}")
    return result
```

- [ ] **Step 3: Thêm nhánh `elif`** trong `_parse_program_ast` NGAY SAU nhánh `__tkv_extern_assembly__` (số dòng theo Task 1):
```python
elif isinstance(node, ast.Assign) and len(node.targets) == 1 and \
        isinstance(node.targets[0], ast.Name) and node.targets[0].id == '__tkv_extern_method__':
    v = node.value
    if not isinstance(v, ast.List):
        raise TranspileError("__tkv_extern_method__ phai la 1 list cac dict")
    for elt in v.elts:
        extern_methods.append(_parse_extern_method_dict_literal(elt))
```

- [ ] **Step 4: Thêm `extern_methods` vào tuple trả về** của `_parse_program_ast` (cạnh `extern_assemblies`) — cập nhật CẢ HAI call site đang unpack tuple này (dòng ~1084, ~1160 theo grep trước đó — xác nhận lại số dòng thật, cả 2 nơi PHẢI unpack thêm 1 giá trị dù nơi nào không dùng tới `extern_methods` thì gán `_` hoặc bỏ qua theo đúng convention Python hiện có trong file).

- [ ] **Step 5: Build thử 1 file `.tkv` có `__tkv_extern_method__` hợp lệ** (không cần chạy hết pipeline, chỉ xác nhận KHÔNG crash ở bước parse) — nếu Task 1 xác định `compile_tkv_cli` không đi qua đường vừa sửa, điều chỉnh lại điểm chèn cho đúng pipeline thật trước khi tiếp tục.

---

### Task 3: Validate + đăng ký động + factory codegen

**Files:**
- Modify: `tkv_compile.py` (tiếp tục)
- Modify: mirror `.tkv`
- Read: `compiler/il_core.py` (`IL_SCALAR`), `compiler/il_features/stdlib_math.py` (mẫu `codegen_fn`), `compiler/il_dispatch.py` (`register_expr_builtin`, xác nhận chữ ký chính xác + guard trùng tên)

**Interfaces:**
- Consumes: `extern_methods` (Task 2), `extern_assemblies` (đã có sẵn).
- Produces: builtin đăng ký động qua `register_expr_builtin` — dùng được ngay trong `gen_il_program` của CÙNG lượt compile.

- [ ] **Step 1: Đọc `register_expr_builtin`** (`il_dispatch.py`) — xác nhận CHÍNH XÁC chữ ký tham số (tên hàm, thứ tự tham số: `name, codegen_fn, return_dtype` hay khác — đối chiếu cách `stdlib_math.py` gọi nó), và đọc đoạn guard chống trùng tên (comment nhắc bug `json_get_str`) để hiểu nó raise lỗi gì (`ValueError`? thông điệp thế nào) — Task 4 cần biết chính xác để viết test assert đúng loại exception.

- [ ] **Step 2: Đọc `stdlib_math.py::_make_math_func_compiler`/`compile_pow`** làm mẫu `codegen_fn` — xác nhận CHÍNH XÁC chữ ký `fn(args, scope, out, dtype, ctx)`, cách `ctx['compile_expr']` được gọi, cách widen (nếu `_make_math_func_compiler` có widen thì Task 3 Step 4 cần đối chiếu lại xem factory mới có cần làm tương tự không, dù thiết kế dự kiến KHÔNG cần).

- [ ] **Step 3: Viết `_EXTERN_DTYPE_TO_IL`** (dict hằng số, đặt gần đầu file hoặc cạnh các hàm mới) — đối chiếu `IL_SCALAR` (`il_core.py`) để xác nhận tên kiểu CIL đúng chuẩn dự án đang dùng (`int32`/`float64`/`string`... không lệch chính tả).

- [ ] **Step 4: Viết `_make_extern_static_call_codegen(assembly, dotnet_class, method_name, param_dtypes, return_dtype)`** theo đúng logic đã mô tả trong spec (`docs/superpowers/specs/2026-08-14-extern-method-design.md`) — factory tính trước `il_param_types`/`il_ret_type`/`call_prefix` NGOÀI closure, trả về `_codegen(args, scope, out, dtype, ctx)` check số lượng args, ép TỪNG tham số theo dtype RIÊNG vị trí, emit dòng `call`.

- [ ] **Step 5: Viết `_validate_and_register_extern_method(decl, declared_assembly_names)`** — 7 bước validate theo đúng thứ tự trong spec, mỗi lỗi 1 `TranspileError` message riêng biệt rõ ràng liệt kê giá trị sai + giá trị hợp lệ mong đợi. Gọi `register_expr_builtin(...)` ở bước cuối.

- [ ] **Step 6: Chèn đoạn đăng ký/`finally`-pop trong `compile_tkv_cli`** — NGAY SAU khi có `extern_methods` (từ `_parse_program_ast`), TRƯỚC lời gọi `gen_il_program`. `declared_assembly_names` gộp `extern_assemblies` (lấy tên, phần tử đầu mỗi tuple/hoặc string đơn — xác nhận lại cấu trúc `extern_assemblies` thật, có thể là list string HOẶC list tuple 3 phần tử theo 2 dạng cú pháp `__tkv_extern_assembly__`, đọc lại Task 1's ghi chú để xử lý đúng cả 2 dạng khi trích tên) với `{'mscorlib', 'System', 'System.Core'}`. Dùng `try/finally` bọc TOÀN BỘ phần còn lại của `compile_tkv_cli` (không chỉ `gen_il_program` — mọi exception giữa chừng đều phải trigger pop).

---

### Task 4: Test + regression + isolation

**Files:**
- Create: `test/sample_extern_method.tkv` (hoặc theo đúng quy ước thư mục xác nhận ở Task 1)
- Create: `test/verify/extern_method_test.py` (theo mẫu `assert_test.py` hoặc file test Python hiện có gần nhất về cấu trúc)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: toàn bộ Task 1-3.

- [ ] **Step 1: Test tích cực** — file `.tkv` mẫu 6a trong spec (`net_pow` qua `System.Math::Pow`), build qua `tkv.py build`, chạy `.exe`, so sánh với `math.pow(2.0, 10.0)` = `1024.0` qua CPython thật (dùng subprocess/so sánh output).

- [ ] **Step 2: Test dtype khác nhau theo vị trí** — khai `params=["i32","f64"]`, `returns="f64"` (hoặc method .NET nào phù hợp có sẵn trong `mscorlib` nhận đúng dạng này — nếu không tìm được method thật phù hợp, có thể dùng `System.Math::Pow` nhưng ép 1 literal `i32` truyền vào vị trí `f64` để test riêng biệt việc coerce đúng theo khai báo, không phải theo giá trị truyền vào).

- [ ] **Step 3: Test lỗi validate** (mỗi case 1 file `.tkv` riêng hoặc 1 hàm test riêng, assert build FAIL với `TranspileError`):
  - `assembly` chưa khai qua `__tkv_extern_assembly__` (dùng 1 tên assembly bịa, không nằm trong 3 mặc định).
  - dtype không hỗ trợ trong `params`/`returns` (vd `"list"`, `"int"`, `"complex"`).
  - `name` trùng 1 builtin có sẵn (vd `"pow"`) — xác nhận lỗi phát ra ĐÚNG từ guard sẵn có của `register_expr_builtin` (đối chiếu message/loại exception xác nhận ở Task 3 Step 1), không phải 1 lỗi khác.
  - `class`/`method` sai regex (vd chứa ký tự lạ).

- [ ] **Step 4: Test isolation — QUAN TRỌNG NHẤT**: viết 1 script Python gọi `compile_tkv_cli` 2 LẦN LIÊN TIẾP trong CÙNG process (không subprocess riêng) — 2 file `.tkv` KHÁC nhau nhưng CẢ HAI đều khai `__tkv_extern_method__` với CÙNG `name` (vd `net_pow`) — xác nhận lần gọi thứ 2 build THÀNH CÔNG, KHÔNG báo lỗi "đã đăng ký trước đó". Nếu FAIL ở bước này, quay lại Task 3 Step 6 kiểm tra lại `finally`-pop.

- [ ] **Step 5: Test tương thích P/Invoke** — 1 file `.tkv` dùng ĐỒNG THỜI `cjson_*`/`sqlite_*` (P/Invoke có sẵn) VÀ `__tkv_extern_method__` mới trong cùng hàm — build+chạy PASS, không xung đột `extern_lines`.

- [ ] **Step 6: Regression toàn bộ test suite hiện có** — đặc biệt mọi test dùng `pow`/`math_pow`/`Math.*` khác (builtin viết tay cũ) — xác nhận không builtin nào bị ghi đè/ảnh hưởng.

- [ ] **Step 7: Mirror `.tkv`** cho toàn bộ thay đổi Task 2-3.

- [ ] **Step 8: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package ecosystem"** — đánh dấu Phase 1 ĐÃ XONG (nền tảng static method .NET qua khai báo), liệt kê rõ phạm vi CHƯA làm (instance/ctor/generic/P-Invoke tổng quát) để phiên sau không hiểu nhầm đây là giải pháp trọn vẹn.

- [ ] **Step 9: Commit.**

```bash
git commit -m "feat(compiler): __tkv_extern_method__ - khai bao goi static method .NET ngoai (Phase 1, package ecosystem)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
