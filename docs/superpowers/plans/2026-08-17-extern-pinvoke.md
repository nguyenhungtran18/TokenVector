# `__tkv_extern_pinvoke__` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pragma `__tkv_extern_pinvoke__` cho code `.tkv` tự khai báo gọi 1
hàm trong DLL native (C-ABI phẳng, chữ ký đã biết trước) — compiler tự sinh
`pinvokeimpl` declaration + đăng ký builtin động, không cần sửa file
compiler cho mỗi hàm mới. Đồng thời sửa tận gốc `codegen_call_stmt` để hỗ
trợ gọi builtin `void` dạng lệnh độc lập (giới hạn đã biết từ Phase 1).

**Architecture:** Mirror gần như nguyên vẹn kiến trúc `__tkv_extern_method__`
(Phase 1, `tkv_compile.py:772-1098` parse + `819-940` validate/factory +
`1854-1930` đăng ký động trong `compile_tkv_cli`) — thay `assembly/class/
method` bằng `dll/symbol/convention`, KHÔNG cần `declared_assembly_names`
(P/Invoke không cần `.assembly extern` trước). Hidden `pinvokeimpl` method
sinh động, ghép vào IL text tại đúng vị trí `cjson_decl_lines`/
`sqlite_decl_lines` hiện có (`tkv_compile.py:1973+`).

**Tech Stack:** Python (`ast` module, string templating IL text) — không
thêm dependency.

## Global Constraints

- Whitelist dtype: đúng `_EXTERN_DTYPE_TO_IL` đã có (`i32/i64/f32/f64/str`),
  TÁI DÙNG NGUYÊN, KHÔNG định nghĩa lại. `returns` CHO PHÉP THÊM `'void'`
  (khác Phase 1) — Task 3 phải xử lý nhánh này đúng.
- `convention` CHỈ 2 giá trị: `'cdecl'`/`'stdcall'`.
- `dll` KHÔNG cho phép path traversal (`..`, `/`, `\`) — chỉ tên file đơn
  giản kết thúc `.dll`.
- `finally`-pop `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE` BẮT BUỘC sau
  mỗi lượt `compile_tkv_cli` — TÁI DÙNG cơ chế `registered_extern_names`
  có sẵn của Phase 1 (mở rộng, không viết cơ chế riêng thứ 2).
- Sửa `codegen_call_stmt` (`compiler/il_features/file_io.py`) phải AN
  TOÀN 2 CHIỀU: builtin void thật (return_dtype=None) gọi bình thường;
  NẾU lỡ builtin nào đó có return_dtype khác None nhưng được gọi độc lập
  (trường hợp hiếm, không cố ý) → `pop` giá trị dư khỏi stack, không để
  IL sai (stack imbalance).
- Cả 2 cây `tkv_compile.py`/`release/3.code/tkv_compile.tkv` sửa đồng bộ.
  `compiler/il_features/file_io.py`/mirror `.tkv` tương ứng cũng vậy.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
- KHÔNG đụng `__tkv_extern_method__` (Phase 1) trừ việc TÁI DÙNG
  `_EXTERN_DTYPE_TO_IL`/`_DEFAULT_GAC_ASSEMBLIES`/pattern `finally`-pop —
  không gỡ chặn `void` của Phase 1 (ngoài phạm vi, xem spec).

---

### Task 1: Điều tra — xác nhận điểm chèn chính xác + name-collision hidden method

**Files:**
- Create: báo cáo điều tra `.superpowers/sdd/task-1-report.md` (READ-ONLY,
  không sửa code).
- Read: `tkv_compile.py` (toàn bộ đoạn `772-1098` parse/validate
  `__tkv_extern_method__`, đoạn `1854-1980` đăng ký động +
  ghép `il_text`), `compiler/il_features/stdlib_cjson.py`/
  `stdlib_sqlite.py` (mẫu `pinvokeimpl` viết tay + cách `_uses_cjson`/
  `_uses_sqlite` + `CJSON_PINVOKE_DECL_LINES`/`SQLITE_PINVOKE_DECL_LINES`
  được ghép vào IL — đối chiếu đúng dòng thật, không dùng số dòng cũ đã
  ghi trong plan này vì có thể lệch do các thay đổi trước đó), `compiler/
  il_features/file_io.py::codegen_call_stmt` (toàn bộ, đặc biệt nhánh
  `else` cuối cùng xử lý gọi hàm KHÔNG có trong `func_table`/bảng builtin
  void riêng).

**Interfaces:**
- Produces: báo cáo xác nhận (1) số dòng CHÍNH XÁC hiện tại của mọi điểm
  chèn (parse branch, `_EXTERN_DTYPE_TO_IL`, đăng ký động trong
  `compile_tkv_cli`, điểm ghép `il_text`, nhánh `else` của
  `codegen_call_stmt`); (2) xác nhận cách đặt tên hidden `pinvokeimpl`
  method KHÔNG trùng với hidden method của `__tkv_extern_method__` (Phase
  1 dùng tên gì, quy tắc tránh trùng ra sao — Phase 2 cần quy tắc tên
  riêng, vd tiền tố `__pinvoke_{name}` KHÁC tiền tố Phase 1 dùng); (3) xác
  nhận nhánh `else` cuối `codegen_call_stmt` (dòng ~108+ hiện tại, đọc lại
  cho đúng) xử lý gọi hàm user-defined thế nào, để chèn nhánh mới TRƯỚC
  nhánh đó (builtin registered qua `EXPR_BUILTIN_CODEGEN` phải được ưu
  tiên tra TRƯỚC khi rơi vào nhánh "gọi hàm người dùng").

- [ ] **Step 1: Đọc `tkv_compile.py`, xác nhận dòng thật của TỪNG điểm sau
      (KHÔNG dùng số dòng trong plan này — chúng có thể lệch, đọc lại):**
      nhánh parse `__tkv_extern_method__` trong `_parse_program_ast`
      (tìm bằng grep `__tkv_extern_method__`), `_EXTERN_DTYPE_TO_IL`,
      `_validate_and_register_extern_method`, `_make_extern_static_call_codegen`,
      đoạn đăng ký động + `finally`-pop trong `compile_tkv_cli` (tìm bằng
      grep `registered_extern_names`), đoạn ghép `cjson_decl_lines`/
      `sqlite_decl_lines` vào `il_text` (tìm bằng grep `cjson_decl_lines`).

- [ ] **Step 2: Đọc `codegen_call_stmt` (`compiler/il_features/file_io.py`)
      TOÀN BỘ hàm** — liệt kê chính xác thứ tự các nhánh `if/elif` hiện
      có (`print`/`write_file`/`append_file`/`LOG_STMT_CODEGEN`/
      `DUMP_STMT_CODEGEN`/`SYS_STMT_CODEGEN`/`RANDOM_STMT_CODEGEN`/nhánh
      `else` cuối) và đọc kỹ nhánh `else` xử lý gì (gọi hàm user-defined
      qua `func_table`, hay báo lỗi nếu không tìm thấy?) — ghi rõ dòng
      chính xác cần chèn nhánh MỚI (tra `EXPR_BUILTIN_CODEGEN` khi tên
      KHÔNG có ở bất kỳ bảng nào phía trên VÀ KHÔNG có trong `func_table`).

- [ ] **Step 3: Xác nhận quy tắc đặt tên hidden method của Phase 1**
      (`_make_extern_static_call_codegen` gọi hidden method nào — ĐỌC KỸ:
      Phase 1 gọi THẲNG method .NET có sẵn qua `[assembly]class::method`,
      KHÔNG sinh hidden method riêng — XÁC NHẬN LẠI ĐIỀU NÀY, vì nếu đúng
      thì Phase 2 là trường hợp ĐẦU TIÊN cần sinh hidden method ĐỘNG (khác
      cách cjson/sqlite viết TAY 1 danh sách cố định) — quy tắc đặt tên
      hidden method Phase 2 tự chọn, chỉ cần đảm bảo KHÔNG trùng với
      `__cjson_*`/`__sqlite_*`/tên hàm người dùng/tên khác đã có, PHẢI ghi
      rõ quy tắc (vd `__pinvoke_{name}` với `name` đã qua validate
      identifier hợp lệ, đủ để tránh trùng).

- [ ] **Step 4: Viết báo cáo** theo format mục "Interfaces" — kèm trích
      dẫn dòng thật cho mọi điểm.

---

### Task 2: Parse pragma `__tkv_extern_pinvoke__`

**Files:**
- Modify: `tkv_compile.py`
- Modify: mirror `release/3.code/tkv_compile.tkv`

**Interfaces:**
- Consumes: báo cáo Task 1 (dòng chính xác để chèn).
- Produces: `_parse_program_ast` trả về thêm `extern_pinvokes` (list dict
  `{name, dll, symbol, convention, params, returns}`, `params` mặc định
  `[]`) — TẤT CẢ điểm unpack/return liên quan (`extract_program`/
  `extract_program_file`/`compile_tkv_cli`/`transpile_program`/
  `transpile_file`) PHẢI cập nhật ĐỒNG BỘ (đúng bài học từ Phase 1 — có
  TỚI 6 điểm cần sửa, không chỉ điểm gọi trực tiếp `_parse_program_ast`).

- [ ] **Step 1: Viết `_EXTERN_PINVOKE_KEYS`/`_EXTERN_PINVOKE_REQUIRED`
      (hằng số module-level, cạnh `_EXTERN_METHOD_KEYS` có sẵn)**

```python
_EXTERN_PINVOKE_KEYS = {'name', 'dll', 'symbol', 'convention', 'params', 'returns'}
_EXTERN_PINVOKE_REQUIRED = {'name', 'dll', 'symbol', 'convention', 'returns'}
```

- [ ] **Step 2: Viết `_parse_extern_pinvoke_dict_literal(node)`** —
      NHÂN BẢN `_parse_extern_method_dict_literal` (đọc lại hàm gốc, copy
      cấu trúc: validate `node` là `ast.Dict`, key hợp lệ, giá trị
      `ast.Constant(str)` (riêng `params` là `ast.List` chuỗi), `params`
      mặc định `[]`, kiểm tra thiếu key bắt buộc) — CHỈ đổi tập key
      (`_EXTERN_PINVOKE_KEYS`/`_EXTERN_PINVOKE_REQUIRED`) và thông báo lỗi
      đổi tiền tố `__tkv_extern_method__:` thành `__tkv_extern_pinvoke__:`.

- [ ] **Step 3: Thêm `extern_pinvokes = []` cạnh `extern_methods = []`
      trong `_parse_program_ast`** (đọc dòng thật từ báo cáo Task 1).

- [ ] **Step 4: Thêm nhánh `elif` mới NGAY SAU nhánh `__tkv_extern_method__`
      hiện có** (trong `_parse_program_ast`):

```python
        elif isinstance(node, ast.Assign) and len(node.targets) == 1 and \
                isinstance(node.targets[0], ast.Name) and node.targets[0].id == '__tkv_extern_pinvoke__':
            # Pragma khai bao goi 1 ham trong DLL native qua P/Invoke
            # (Phase 2, 2026-08-17 - xem docs/superpowers/plans/2026-08-17-
            # extern-pinvoke.md): moi phan tu la 1 dict-literal shape co
            # dinh, chi PARSE SHAPE o day (validate nghiep vu + sinh
            # pinvokeimpl + dang ky dong builtin la Task 3, trong
            # compile_tkv_cli).
            v = node.value
            if not isinstance(v, ast.List):
                raise TranspileError("__tkv_extern_pinvoke__ phai la 1 list cac dict")
            for elt in v.elts:
                extern_pinvokes.append(_parse_extern_pinvoke_dict_literal(elt))
```

- [ ] **Step 5: Cập nhật TẤT CẢ điểm return/unpack tuple của
      `_parse_program_ast`/`extract_program`/`extract_program_file`/
      `compile_tkv_cli`/`transpile_program`/`transpile_file`** — thêm
      `extern_pinvokes` vào ĐÚNG vị trí tương tự `extern_methods` (Phase 1
      đã làm ở TẤT CẢ các điểm này — lặp lại CHÍNH XÁC quy trình đó, kể cả
      vòng đệ quy gộp `extern_pinvokes.extend(imp_extern_pinvokes)` trong
      `extract_program_file` khi xử lý `__tkv_import__`).

- [ ] **Step 6: Build test nhanh xác nhận không crash** — viết 1 file
      `.tkv` tạm (không commit) có `__tkv_extern_pinvoke__` hợp lệ theo
      shape mới, chạy `tkv.py build` (sẽ dừng ở lỗi KHÁC vì chưa đăng ký
      động — Task 3 mới làm phần đó, xác nhận lỗi là "không tìm thấy tên
      hàm" chứ KHÔNG PHẢI lỗi parse pragma).

- [ ] **Step 7: Chạy 2-3 test cũ (`while_test.py`, `dict_test.py`) xác
      nhận không regression. Commit.**

```bash
git add tkv_compile.py release/3.code/tkv_compile.tkv
git commit -m "feat(compiler): parse pragma __tkv_extern_pinvoke__ (Task 2/4, extern-pinvoke)"
```

---

### Task 3: Validate + sinh `pinvokeimpl` động + đăng ký builtin + sửa `codegen_call_stmt` cho `void`

**Files:**
- Modify: `tkv_compile.py`, mirror `.tkv`
- Modify: `compiler/il_features/file_io.py`, mirror `.tkv`

**Interfaces:**
- Consumes: `extern_pinvokes` (Task 2).
- Produces: builtin đăng ký động qua `register_expr_builtin` (bao gồm
  `returns='void'` → `register_expr_builtin(name, codegen_fn, None)`) +
  hidden `pinvokeimpl` method text ghép vào `il_text`.

- [ ] **Step 1: Viết `_EXTERN_CONVENTIONS = {'cdecl', 'stdcall'}`** (hằng
      số module-level).

- [ ] **Step 2: Viết `_validate_and_register_extern_pinvoke(decl,
      pinvoke_decl_lines_out)`** — 6 bước validate tuần tự (mỗi lỗi 1
      `TranspileError` message riêng, liệt kê giá trị sai + hợp lệ mong
      đợi):
      1. `dll` khớp regex `^[\w\-. ]+\.dll$` (chữ/số/gạch dưới/gạch
         ngang/dấu chấm/khoảng trắng, PHẢI kết thúc `.dll`, KHÔNG chứa
         `..`/`/`/`\`).
      2. `symbol` khớp regex identifier C (`^[A-Za-z_]\w*$`).
      3. `convention` nằm trong `_EXTERN_CONVENTIONS`.
      4. Mọi `params` nằm trong `_EXTERN_DTYPE_TO_IL`.
      5. `returns` là `'void'` HOẶC nằm trong `_EXTERN_DTYPE_TO_IL` (KHÁC
         Phase 1 — cho phép `void`).
      6. `name` là identifier Python hợp lệ (`str.isidentifier()`).
      Sau khi qua hết: sinh tên hidden method `f'__pinvoke_{name}'` (hoặc
      quy tắc Task 1 xác nhận), tính `il_ret_type` (`'void'` nếu
      `returns=='void'` else map qua bảng), `il_param_types`, APPEND 1
      dòng `pinvokeimpl` vào `pinvoke_decl_lines_out` (list truyền vào từ
      `compile_tkv_cli`, kiểu:
      `.method public hidebysig static pinvokeimpl("{dll}" as "{symbol}" {convention})\n    {il_ret_type} {hidden_name}({il_param_types_joined}) cil managed preservesig {{}}`),
      tạo `codegen_fn` qua `_make_extern_pinvoke_call_codegen(...)`, gọi
      `register_expr_builtin(name, codegen_fn, returns if returns != 'void' else None)`.

- [ ] **Step 3: Viết `_make_extern_pinvoke_call_codegen(hidden_name,
      param_dtypes, return_dtype)`** — factory TƯƠNG TỰ
      `_make_extern_static_call_codegen` (đọc lại làm mẫu): tính trước
      `il_param_types`/`il_ret_type` NGOÀI closure; trả về
      `_codegen(args, scope, out, dtype, ctx)`: check `len(args)==
      len(param_dtypes)` (sai → `SyntaxError` rõ); mỗi tham số ép theo
      dtype RIÊNG vị trí qua `zip`; emit
      `f'    call {il_ret_type} {_class_name(ctx)}::{hidden_name}({params_joined})'`
      (LƯU Ý: KHÁC Phase 1 — gọi method TRONG CHÍNH class chương trình
      hiện tại, không phải `[assembly]class` bên ngoài — dùng
      `ctx['class_name']`/hàm `_class_name(ctx)` tương tự cách
      `stdlib_cjson.py` làm, đọc lại file đó xác nhận đúng cách lấy tên
      class từ `ctx`).

- [ ] **Step 4: Chèn đoạn đăng ký động trong `compile_tkv_cli`** — CÙNG
      VỊ TRÍ với đăng ký `extern_methods` (đọc dòng thật từ báo cáo Task
      1), thêm vòng lặp riêng:

```python
    pinvoke_decl_lines = []
    registered_pinvoke_names = []
    try:
        for decl in extern_pinvokes:
            _validate_and_register_extern_pinvoke(decl, pinvoke_decl_lines)
            registered_pinvoke_names.append(decl['name'])
        # ... (noi tiep vao try/finally da co san cua extern_methods,
        # KHONG tao try/finally rieng thu 2 - gop chung 1 khoi voi
        # extern_methods, hoac long vao trong cung neu de doc hon - xac
        # nhan lai cach lam gon nhat luc doc code that o Task 1/luc code)
    finally:
        for nm in registered_pinvoke_names:
            EXPR_BUILTIN_CODEGEN.pop(nm, None)
            EXPR_BUILTIN_DTYPE.pop(nm, None)
```

  Và ghép `pinvoke_decl_lines` vào `il_text` TẠI ĐÚNG vị trí
  `cjson_decl_lines`/`sqlite_decl_lines` được ghép (đọc dòng thật từ báo
  cáo Task 1) — thêm `'\n'.join(pinvoke_decl_lines) + ('\n' if
  pinvoke_decl_lines else '')`.

- [ ] **Step 5: Sửa `codegen_call_stmt` (`compiler/il_features/file_io.py`)**
      — thêm 1 nhánh MỚI TRƯỚC nhánh `else` cuối cùng (đọc thứ tự thật từ
      báo cáo Task 1):

```python
    elif name in ctx.get('expr_builtin_codegen', {}):
        # Phase 2 (2026-08-17, __tkv_extern_pinvoke__) - sua tan goc gioi
        # han cu: builtin dang ky qua register_expr_builtin (Phase 1/2 cac
        # pragma extern) truoc day CHI goi duoc trong BIEU THUC, khong goi
        # duoc DANG LENH DOC LAP (vd ham tra ve void). Nhanh nay tra
        # EXPR_BUILTIN_CODEGEN KHI ten KHONG co trong bat ky bang builtin
        # void rieng nao o TREN (kiem tra thu tu code that, dam bao nhanh
        # nay dat DUNG vi tri - sau moi bang rieng, TRUOC nhanh else).
        codegen_fn = ctx['expr_builtin_codegen'][name]
        return_dtype = ctx.get('expr_builtin_dtype', {}).get(name)
        codegen_fn(call_args, scope, body, return_dtype, ctx)
        if return_dtype is not None:
            # builtin lo day gia tri len stack du duoc goi doc lap - pop
            # de khong lech stack IL (an toan 2 chieu, khong gia dinh
            # MOI builtin the loai nay deu la void that).
            body.append('    pop')
```

  **LƯU Ý CHO IMPLEMENTER**: xác nhận CHÍNH XÁC cách truy cập
  `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE` từ trong `file_io.py` — có
  thể là import trực tiếp từ `il_dispatch` (giống `il_codegen.py` đang
  làm) thay vì qua `ctx[...]` như code mẫu trên (code mẫu chỉ minh hoạ Ý
  TƯỞNG, không phải chữ ký chính xác — đọc lại `il_dispatch.py`/cách
  `il_codegen.py` import 2 dict này để dùng ĐÚNG cách, KHÔNG đoán qua
  `ctx`).

- [ ] **Step 6: Build test — dùng `__tkv_extern_pinvoke__` gọi 1 hàm
      THẬT trong `msvcrt.dll`** (vd `sqrt(double)->double`, có sẵn mọi
      máy Windows, không cần cài gì thêm) qua expression VÀ qua lệnh độc
      lập (nếu tìm được 1 hàm void thật dễ test, vd không có sẵn trong
      `msvcrt.dll` thì tạm dùng spike riêng không lưu file — xác nhận
      nhánh `void` hoạt động, việc viết test chính thức cho `void` để
      dành Task 4).

- [ ] **Step 7: Đồng bộ mirror `.tkv` cho cả `tkv_compile.py` VÀ
      `compiler/il_features/file_io.py`. Commit.**

```bash
git add tkv_compile.py release/3.code/tkv_compile.tkv compiler/il_features/file_io.py release/3.code/compiler/il_features/file_io.tkv
git commit -m "feat(compiler): validate + sinh pinvokeimpl dong + ho tro void trong codegen_call_stmt (Task 3/4, extern-pinvoke)"
```

---

### Task 4: Test + regression + docs + commit

**Files:**
- Create: `test/sample_extern_pinvoke.tkv`, `test/verify/extern_pinvoke_test.py`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: toàn bộ Task 1-3.

- [ ] **Step 1: Test tích cực `cdecl`** — hàm thật `msvcrt.dll::sqrt`
      (`f64->f64`), build qua `tkv.py build`, chạy `.exe`, so sánh với
      `math.sqrt(2.0)` CPython thật.

- [ ] **Step 2: Test tích cực `stdcall`** — tìm 1 hàm Windows API chuẩn
      dùng `stdcall` với tham số đơn giản (điều tra lúc implement, vd
      `kernel32.dll::GetCurrentProcessId` không tham số trả `i32`, hoặc
      tương đương) — build + chạy, xác nhận không crash/lỗi calling
      convention (nếu convention sai, Windows thường crash hoặc trả giá
      trị rác — xác nhận kết quả HỢP LÝ, không chỉ "không crash").

- [ ] **Step 3: Test `returns:"void"`** — 1 hàm native void thật gọi dạng
      lệnh độc lập, xác nhận `codegen_call_stmt`'s nhánh mới hoạt động,
      build+chạy không lỗi stack imbalance (ilasm sẽ báo lỗi RÕ nếu stack
      sai, dễ phát hiện).

- [ ] **Step 4: Test lỗi validate** (mỗi case 1 test, assert
      `TranspileError`): `dll` sai định dạng/path traversal, `symbol` sai
      regex, `convention` không phải cdecl/stdcall, dtype không hỗ trợ
      (params/returns), tên trùng builtin có sẵn (assert đúng loại
      exception thật — đối chiếu Phase 1's finding về `ValueError` từ
      guard `register_expr_builtin`, xác nhận lại có đúng vậy cho case
      này không).

- [ ] **Step 5: Test isolation** — gọi `compile_tkv_cli` 2 lần liên tiếp
      CÙNG process, 2 file khác nhau CÙNG tên builtin `extern_pinvoke` —
      lần 2 build thành công (xác nhận `finally`-pop hoạt động, giống bài
      test quan trọng nhất của Phase 1).

- [ ] **Step 6: Test tương thích `__tkv_extern_method__` (Phase 1) + P/Invoke
      viết tay (`cjson_*`/`db_*`) + `__tkv_extern_pinvoke__` (Phase 2)
      ĐỒNG THỜI trong CÙNG 1 file** — build+chạy PASS, không xung đột
      `extern_lines`/`cjson_decl_lines`/`sqlite_decl_lines`/
      `pinvoke_decl_lines` mới.

- [ ] **Step 7: Regression toàn bộ test suite hiện có** — đặc biệt mọi
      test dùng `cjson_*`/`db_*`/`net_pow` (Phase 1) — xác nhận không có
      gì bị ảnh hưởng bởi thay đổi `codegen_call_stmt`.

- [ ] **Step 8: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`'s mục "#1 Package
      ecosystem"** — thêm đoạn Phase 2 ĐÃ XONG (P/Invoke native tổng quát
      hoá qua `__tkv_extern_pinvoke__`, cdecl+stdcall, hỗ trợ void), liệt
      kê rõ phạm vi CHƯA làm (struct/callback/ref-out/tự dò export/C++
      mangling/charset marshaling tùy biến) — KHÔNG để đọc giả hiểu nhầm
      đây là giải pháp trọn vẹn.

- [ ] **Step 9: Commit.**

```bash
git commit -m "feat(compiler): __tkv_extern_pinvoke__ - P/Invoke DLL native tong quat hoa qua khai bao (Phase 2, package ecosystem)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
