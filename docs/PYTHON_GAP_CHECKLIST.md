# TokenVector vs Python — Checklist gap (rà soát mã nguồn trực tiếp)

## 🎯 MỤC TIÊU TỐI THƯỢNG
- TokenVector thay thế Python **HOÀN TOÀN**.
- Slogan: **"Coding dễ như Python và chạy nhanh như C++"**

## ⛔ Nguyên tắc bắt buộc: CHÉP/CONVERT, KHÔNG SÁNG TẠO THÊM
- Với mọi gap tính năng (mục A/B/C), bước đầu tiên bắt buộc: kiểm tra cây
  `.tkv` tự-host (`release/3.code/...`) đã có sẵn thiết kế chưa — rẻ nhất,
  đã áp dụng thành công cho `async`/`await`, class inheritance/`super()`.
- Đã kiểm tra (2026-08-11) cho các gap đang mở — **KHÔNG có gì để chép**,
  cả 2 cây đều thiếu như nhau: `global`, `*args`/`**kwargs` (cây `.tkv`
  chủ động raise lỗi từ chối), `raise` trần, dunder method, `frozenset`.
  → các mục này phải thiết kế mới thật sự.
- Gap CHƯA kiểm tra `.tkv` (còn lại ở B/C): `sys`, `input()`, context
  manager, iterator protocol, `bytes`/`bytearray`, MRO kim cương — **phải
  kiểm tra `.tkv` trước khi code**, chưa làm, để dành phiên code thật.

## ⚠ Phạm vi thật của "thay Python" — Loại 1 vs Loại 2
- **Loại 1 — gap tính năng** (mục A/B/C): đóng dần bằng code, có lộ trình.
- **Loại 2 — giới hạn kiến trúc** (không đóng bằng 1 tính năng lẻ):
  - [ ] Không hệ sinh thái package (`pip install X`)
  - [ ] Không `eval()`/`exec()` tổng quát, metaclass, monkey-patch, duck-typing tự do
  - [x] Concurrency thật — **KHÔNG PHẢI giới hạn kiến trúc** (xem nghiên cứu bên dưới)
  - [ ] Không tương thích 100% mọi phiên bản cú pháp Python
  - [x] Không debug tương tác sau build (`pdb`) — checkbox lỗi thời: #5 Debug
    ĐÃ XONG THẬT từ 2026-08-12 (xem dòng "#5 Debug" bên dưới) — `--debug`
    sinh Windows PDB cổ điển, breakpoint được qua debugger native. Xác
    nhận lại 2026-08-17 khi rà soát checklist cuối phiên.
- Kết luận phạm vi: xong Phase 5+6+checklist → TokenVector thay Python
  **cho đúng lớp bài toán 5 sách tham chiếu** (procedural + OOP cơ bản +
  stdlib thông dụng, không cần package ngoài/concurrency-dynamic thật) —
  KHÔNG phải thay Python cho mọi use-case (data science/web framework).

## 🧭 Chiến lược Loại 2 (Qwen3/Groq, `qwen/qwen3.6-27b`, 2026-08-11 —
nghiên cứu đầy đủ 2 lượt, đã QUYẾT thứ tự theo mục tiêu tối thượng: ưu
tiên thắng nhanh/rẻ trước để giữ đà, dồn lực cho blocker khó nhất sau)

- [x] **#3 Concurrency — ĐÃ XONG THẬT (2026-08-12)**, xem
      `docs/superpowers/plans/2026-08-12-async-real-concurrency.md`.
      `async def` (top-level + record method) giờ chạy THẬT song song qua
      `Task.Factory.StartNew<T>` (KHÔNG phải `Task.Run` — `ilasm.exe` của
      project target mscorlib v4.0.30319, chưa có `Task.Run`, chỉ từ .NET
      4.5) — thân hàm thật nằm trong 1 class closure `{name}__AsyncBody`
      (field = self + tham số, tái dùng nguyên hạ tầng `closures.py` của
      nested-def), method public gốc chỉ còn là wrapper dựng closure +
      bind `Func<T>` + gọi `StartNew`. Đo THẬT: 2 lệnh gọi async không
      `await` ngay chạy song song ~300ms thay vì ~600ms (bằng chứng
      concurrency thật, không phải lý thuyết). Port kèm
      `threading_feature.py` (`thread_spawn`/`thread_join`/`thread_sleep`)
      từ cây `.tkv` sang `.py` (gap thật, thiếu hoàn toàn trước đó).
      **Kiểm chứng (2026-08-12):** regression toàn bộ `Testkit/*.tkv` qua
      cây `.py` (`tkv.py build ... --entry run`) — mọi test PASS, kể cả 3
      test mới (`threading_feature`, `async_concurrency`, `async_method`)
      và `async_await` sẵn có; `native_test_suite` (lỗi parse `yield from`
      từ trước) và `path_isfile_isdir_test` (3/4 PASS từ trước) không đổi
      so với baseline. **Rebuild + regression qua `tkvc.exe`/
      `dist/il_features/*.py` KHÔNG nằm trong lượt kiểm chứng này** — đây
      là bước riêng, do người dùng chủ động kiểm soát thời điểm thực hiện,
      không tự động hoá theo plan này.
- [x] **#5 Debug — ĐÃ XONG THẬT (2026-08-12)**, xem
      `docs/superpowers/plans/2026-08-12-debug-pdb.md`. Cờ `--debug` (mặc
      định TẮT) trên `tkv build` sinh Windows PDB CỔ ĐIỂN (KHÔNG phải
      Portable PDB — xác minh thật qua `ilasm.exe /debug`, chữ ký
      `"Microsoft C/C++ MSF 7.00"`; Source Link KHÔNG áp dụng, đó là cơ
      chế .NET Core/Portable PDB, không phải toolchain Framework của
      project này) — breakpoint được trên từng dòng source `.tkv`/`.py`
      gốc qua debugger native (Visual Studio; VS Code cần cấu hình
      `cppvsdbg`, không phải debug adapter C#/.NET Core mặc định).
      `.line` sinh tại 1 điểm dispatch trung tâm (`_codegen_stmts`),
      KHÔNG cần sửa ~50 file `il_features/*.py`. Giới hạn đã biết: chỉ
      statement TOP-LEVEL của thân hàm có `.line` (chưa hỗ trợ thân
      `for`/`if` lồng nhau — để dành); thân generator (`MoveNext()`)
      ngoài phạm vi.
- [x] **#4 Tương thích cú pháp — ĐÃ XONG (2026-08-17)**, xem
      `docs/superpowers/plans/2026-08-17-syntax-baseline-linter.md` +
      `docs/superpowers/specs/2026-08-17-syntax-baseline-linter-design.md`.
      Pre-flight linter `compiler/syntax_baseline.py` — AST walker ĐỘC LẬP
      dùng `ast.parse` chuẩn của Python (đọc-only, KHÔNG đụng compiler
      pipeline thật), whitelist construct suy ra từ đọc THẬT source code
      compiler (`il_core.py`/`il_codegen.py`/`il_features/*.py`) — tích
      hợp vào `tkv.py build` (mặc định BẬT, chạy trước khi vào
      `compile_tkv_cli`; cờ `--no-lint` để tắt khi cần debug linter báo
      sai). Regression 177 file `.tkv` thật (`test/*.tkv` + `release/3.code/
      Testkit/*.tkv`) — quét CHỈ 2 thư mục chứa chương trình test người
      dùng, KHÔNG quét `release/3.code/compiler/**/*.tkv` (mirror source
      code compiler tự-host, không phải input người dùng, ngoài phạm vi
      linter này) — 0 finding sau khi vá 4 nhóm false-positive phát hiện
      qua build+chạy THẬT (`tkv_compile.compile_tkv_cli`, không chỉ đoán
      qua AST tĩnh): list/dict/set comprehension, f-string đơn giản
      (`{ident}`/`{ident:.Nf}`), nested attribute 2 tầng làm đối tượng
      nhận của method-call/chỉ số (`obj.a.b(...)`/`obj.a.b[...]`), và
      tuple-unpack for-loop qua `enumerate()`/`zip()`/biến đã gán từ
      `.items()` — tất cả đều là macro TEXT-LEVEL chạy TRƯỚC parser cấp
      thấp mà điều tra ban đầu (`il_core.py`) bỏ sót. Mirror `.tkv` tự-host
      đồng bộ: `release/3.code/tkv.tkv` (cập nhật, thêm `--no-lint`) +
      `release/3.code/compiler/syntax_baseline.tkv` (mới) — KHÔNG rebuild
      `tkvc.exe`.
      **PHẠM VI**: chỉ kiểm tra cú pháp Ở MỨC AST-SHAPE (construct nào
      compiler KHÔNG parse/codegen được), KHÔNG kiểm tra dtype/logic
      nghiệp vụ. Construct chính bị chặn đúng (xác nhận: compiler THẬT
      cũng từ chối): list/dict/set comprehension lồng nhau hoặc dùng sai
      shape, f-string biểu thức phức tạp (`{x+1}`/`{obj.field}`), walrus
      `:=`, `match`/`case`, gán đa mục tiêu (`a = b = c`), ternary Python
      chuẩn (`a if cond else b` — dùng `cond ? a : b` của DSL), nested
      attribute 3+ tầng hoặc đọc field thuần túy không qua method-call/chỉ
      số, lambda inline trong `map`/`filter`/`reduce`/`sort(key=)`, dict/set
      literal có nội dung, slice có bước nhảy, decorator xếp chồng/có tham
      số, starred expression, nested class, `*args`/`**kwargs` trong chữ ký
      method của class, keyword-only argument, số dạng mũ/hex/underscore.
- [ ] **#1 Package ecosystem — BLOCKER LỚN NHẤT.** **Phase 1 ĐÃ XONG
      (2026-08-17, `__tkv_extern_method__`, xem `docs/superpowers/plans/
      2026-08-14-extern-method.md` + `docs/superpowers/specs/2026-08-14-
      extern-method-design.md`)**: pragma `__tkv_extern_method__` cho code
      `.tkv` TỰ KHAI BÁO gọi 1 **static method .NET NGOÀI** (chữ ký CIL đã
      biết trước, vd `System.Math::Pow`), compiler đăng ký ĐỘNG thành
      builtin gọi được qua `register_expr_builtin` — **KHÔNG cần sửa file
      compiler** cho mỗi method mới. Đăng ký RIÊNG theo từng lượt
      `compile_tkv_cli`, tự gỡ (`finally`-pop `EXPR_BUILTIN_CODEGEN`/
      `EXPR_BUILTIN_DTYPE`) sau khi build xong — không rò rỉ giữa các lần
      compile trong cùng process. Đã test: tích cực (`System.Math::Pow`,
      đối chiếu CPython thật), dtype khác nhau theo TỪNG VỊ TRÍ tham số
      (`System.Math::Round(f64,i32)->f64`, ép đúng khai báo chứ không theo
      biểu thức nguồn — xác nhận qua đọc lại `.il` sinh ra), 6 case lỗi
      validate (assembly chưa khai/dtype không hỗ trợ ở params hoặc
      returns/tên trùng builtin có sẵn — đúng `ValueError` từ guard sẵn có
      của `register_expr_builtin`, không phải `TranspileError`/class hoặc
      method sai regex), isolation (gọi `compile_tkv_cli` 2 lần liên tiếp
      cùng process, 2 file khác nhau cùng tên builtin — lần 2 build
      thành công), tương thích P/Invoke sẵn có (`db_*`/sqlite3.dll dùng
      đồng thời trong cùng 1 file). Xem `test/verify/extern_method_test.py`
      + `test/sample_extern_method.tkv`.
      **CHƯA làm (ngoài phạm vi Phase 1, KHÔNG phải giải pháp trọn vẹn cho
      "package ecosystem")**: instance method (chỉ static), constructor,
      property/field, generic method, tham số/kiểu trả về dạng container
      (list/dict/record...) — chỉ scalar cơ bản (`i32/i64/f32/f64/str`),
      gọi method .NET kiểu `void` (statement-only) — Phase 1 CHỈ hỗ trợ hàm
      CÓ giá trị trả về dùng trong biểu thức, khai `returns:"void"` bị chặn
      ngay ở validate (xem review finding I1), overload resolution (1 tên khai báo = đúng 1 chữ ký, không
      tự chọn overload theo kiểu tham số thật), `ref`/`out`/`params
      object[]`, P/Invoke TỔNG QUÁT HOÁ qua khai báo (P/Invoke hiện tại
      vẫn viết tay từng hàm như `stdlib_cjson.py`/`stdlib_sqlite.py`,
      pragma mới KHÔNG đụng tới đường P/Invoke), không tự dò chữ ký qua
      reflection (người dùng phải tự biết đúng chữ ký CIL, khai sai thì
      build OK nhưng chạy ném `MissingMethodException`/tương tự — không
      dịch riêng exception .NET, lan truyền như exception thường).

      **Phase 2 ĐÃ XONG (2026-08-17, `__tkv_extern_pinvoke__`, xem
      `docs/superpowers/plans/2026-08-17-extern-pinvoke.md` + `docs/
      superpowers/specs/2026-08-17-extern-pinvoke-design.md`)**: pragma
      `__tkv_extern_pinvoke__` cho code `.tkv` TỰ KHAI BÁO gọi 1 hàm
      **P/Invoke DLL native TỔNG QUÁT HOÁ** (`dll`/`symbol`/`convention`
      `cdecl`|`stdcall`/`params`/`returns`) — compiler tự sinh 1 hidden
      method `.method ... pinvokeimpl("dll" as "symbol" convention)` ĐỘNG
      cho mỗi khai báo và đăng ký builtin gọi được qua
      `register_expr_builtin`, khác hẳn P/Invoke viết tay cố định
      (`cjson_*`/`db_*` trong `stdlib_cjson.py`/`stdlib_sqlite.py`) —
      **KHÔNG cần sửa file compiler** cho mỗi hàm DLL mới. Hỗ trợ CẢ
      `returns:"void"` gọi dạng lệnh độc lập (Phase 1 chặn cứng void;
      Phase 2 là trường hợp ĐẦU TIÊN cho phép, qua nhánh mới trong
      `codegen_call_stmt` + tập `EXTERN_VOID_BUILTIN_NAMES` đánh dấu RIÊNG
      builtin THẬT SỰ void — không dùng heuristic `return_dtype is None`
      vì trùng với ~27 builtin có sẵn (`pow`/`sorted`/`random`/`min`/
      `max`/...) cũng đăng ký `return_dtype=None` nhưng vì lý do "không
      suy được dtype từ chính nó", ý nghĩa khác hẳn — xem fix Critical
      commit `79d6424`). Đã test THẬT: tích cực `cdecl`
      (`msvcrt.dll::sqrt`, đối chiếu `math.sqrt` CPython), tích cực
      `stdcall` (`kernel32.dll::GetCurrentProcessId`, xác nhận PID hợp lý
      chứ không chỉ "không crash"), `returns:"void"` gọi dạng lệnh độc lập
      (`msvcrt.dll::srand`, không lỗi mất cân bằng ngăn xếp), 6 case lỗi
      validate (`dll` sai định dạng/path traversal, `symbol` sai regex,
      `convention` không hợp lệ, dtype không hỗ trợ ở params/returns, tên
      trùng builtin có sẵn — đúng `ValueError`, còn lại `TranspileError`),
      isolation (gọi `compile_tkv_cli` 2 lần liên tiếp cùng process, 2
      file khác nhau cùng tên builtin `extern_pinvoke` — lần 2 build thành
      công), tương thích `__tkv_extern_method__` (Phase 1) + P/Invoke viết
      tay (`db_*`) + `__tkv_extern_pinvoke__` (Phase 2) ĐỒNG THỜI trong
      CÙNG 1 file. Xem `test/verify/extern_pinvoke_test.py` +
      `test/sample_extern_pinvoke.tkv`.
      **CHƯA làm (ngoài phạm vi Phase 2, KHÔNG phải giải pháp trọn vẹn cho
      "package ecosystem")**: `struct`/kiểu dữ liệu phức hợp truyền qua
      P/Invoke (chỉ scalar `i32/i64/f32/f64/str` + `void` cho `returns`),
      callback/function pointer truyền vào hàm native, `ref`/`out`
      (tham số con trỏ đầu ra), tự dò export của DLL (người dùng phải tự
      biết đúng `symbol` + chữ ký — khai sai build OK nhưng chạy crash/kết
      quả rác, không có safety net), C++ name mangling (chỉ symbol C
      thuần, `extern "C"`), charset marshaling tùy biến (không có tuỳ chọn
      `CharSet.Ansi`/`Unicode` khác mặc định), `thiscall`/`fastcall` (chỉ
      `cdecl`/`stdcall`), không hỗ trợ struct-by-value/array marshaling.

      **Phase 3 ĐÃ XONG (2026-08-18, `__tkv_extern_class__`, xem
      `docs/superpowers/plans/2026-08-18-extern-class.md` + `docs/
      superpowers/specs/2026-08-18-extern-class-design.md`)**: pragma
      `__tkv_extern_class__` cho code `.tkv` TỰ KHAI BÁO 1 **handle-type
      .NET NGOÀI** (constructor + danh sách instance method, chữ ký CIL
      đã biết trước, vd `System.Text.StringBuilder`) — compiler tích hợp
      tên khai báo thành 1 kiểu (`TypeAnn.shape == 'extern_class'`) dùng
      được ở annotation tham số/return hàm top-level, sinh `newobj` cho
      lời gọi constructor và `callvirt` cho lời gọi instance method (kể cả
      method trả về CHÍNH handle-type đó — fluent chaining, `s.Append("b").
      ToString()`) — **KHÔNG cần sửa file compiler** cho mỗi class .NET
      mới. Đăng ký ĐỘNG theo từng lượt `compile_tkv_cli` qua biến
      module-level `il_codegen._EXTERN_CLASS_DEFS` + registry
      `EXPR_METHOD_CODEGEN` (khoá `('extern_class', method_name)`, resolve
      lớp cụ thể THEO RECEIVER THỰC TẾ tại codegen-time — nhiều
      extern-class khác nhau cùng khai method trùng tên là hợp lệ), tự gỡ
      (`finally`-pop) sau khi build xong. Đã test: tích cực (constructor +
      method scalar-return + method chaining-return + `is None` trên biến
      handle), 2 extern-class khác nhau cùng khai method trùng tên khác
      chữ ký (dispatch đúng theo receiver), tương thích ĐỒNG THỜI với
      Phase 1 (`__tkv_extern_method__`) VÀ Phase 2 (`__tkv_extern_pinvoke__`)
      trong CÙNG 1 file, isolation (gọi `compile_tkv_cli` 2 lần liên tiếp
      cùng process, cùng tên handle-type khác class — lần 2 build thành
      công), toàn bộ case lỗi validate (tên/assembly/class-regex/dtype
      ctor và method không hợp lệ, trùng tên builtin/record có sẵn), và
      **duck-typing (#2) từ chối handle-type làm tham số suy kiểu
      `inferred`** — raise `TranspileError` rõ ràng ngay tại
      `collect_inferred_constraints`'s constraint-check
      (`compiler/il_features/duck_typing.py`), không lọt qua để sinh CIL
      sai. Xem `test/verify/extern_class_parse_test.py` (Task 1, parse
      pragma), `extern_class_typesystem_test.py` (Task 2, type-system),
      `extern_class_ctor_test.py` (Task 3, `newobj`),
      `extern_class_method_test.py` (Task 4, `callvirt` + chaining),
      `extern_class_test.py` (Task 5, test tổng hợp + duck-typing-reject)
      + `test/sample_extern_class.tkv`.
      **CHƯA làm (ngoài phạm vi Phase 3, copy nguyên từ spec — "Giới hạn
      KHÔNG làm")**: property/field trên handle-type (chỉ method + `is
      None`, không đọc/ghi trực tiếp thuộc tính .NET), generic
      class/method (`List<T>` dạng khai báo qua pragma này — container có
      sẵn `list[(K,V)]` là cơ chế RIÊNG, không liên quan), handle-type làm
      phần tử của container (list/dict chứa extern_class), static field
      trên handle-type (chỉ static METHOD qua Phase 1, field thì không),
      method trả `void` (như Phase 1, `returns:"void"` bị chặn ở validate —
      giới hạn scope có ý thức, không phải bug), đa constructor overload
      (1 khai báo `ctor:` = đúng 1 chữ ký, không tự chọn overload theo
      kiểu tham số thật), duck-typing/suy kiểu 'inferred' KHÔNG tham gia
      (chặn tường minh — phải khai annotation rõ ràng cho tham số kiểu
      handle-type).

      **Phase 4 ĐÃ XONG (2026-08-18, `__tkv_extern_class__` property, xem
      `docs/superpowers/plans/2026-08-18-extern-class.md` +
      `.superpowers/sdd/task-{1,2,3,4}-brief.md`/`task-{1,2,3,4}-report.md`)**:
      thêm key `"properties"` vào khai báo pragma — mỗi property khai
      `{"name", "dtype", "readonly"}` (mặc định `readonly: True`), cho phép
      **đọc** (`x.Prop` qua `get_X` — tái dùng CÙNG cơ chế `compile_attr`
      của record field access) và **ghi** (`x.Prop = v` qua `set_X`, chỉ khi
      `readonly: False` — ghi vào property có `readonly: True` raise
      `TranspileError` tường minh) trên handle-type ngoài, đều dịch thành
      `callvirt` tới getter/setter thật của .NET — tái dùng NGUYÊN VẸN cơ
      chế đăng ký động/dispatch-theo-receiver/`finally`-pop của Phase 3, chỉ
      thêm 1 vòng đăng ký `get_X`/`set_X` song song vòng đăng ký `methods`.
      Xác nhận: **duck-typing (#2) đã chặn property của handle-type làm
      tham số suy kiểu `inferred` TỰ ĐỘNG, không cần code mới** — `x.Prop`
      đi qua CÙNG `compile_attr` với record field nên constraint-collector
      coi nó là `FieldConstraint` giống hệt field record, guard sẵn có ở
      `compiler/il_features/duck_typing.py::_check_constraint` (từ plan
      duck-typing trước) bắt đúng ngay lần chạy đầu, KHÔNG phải sửa gì; và
      `obj.Prop += x` (compound-assign) cũng hoạt động đúng TỰ ĐỘNG qua macro
      text-level `try_expand_compound_attr`
      (`compiler/il_features/record_feature.py`) vốn không phân biệt record
      field với extern-class property. Test:
      `test/verify/extern_class_property_parse_test.py` (Task 1, parse key
      `properties`), `extern_class_property_test.py` (Task 2/3, đọc/ghi/
      readonly-reject/round-trip/isolation), `extern_class_test.py` (Task 4,
      duck-typing-reject property + compound-assign — thêm vào Step E).
      **CHƯA làm (copy nguyên từ spec — "Giới hạn KHÔNG làm", giống Phase
      3)**: static property (chỉ instance), indexer (`obj[i]`), property có
      dtype container (`list`/`dict`/record — chỉ dtype scalar), reflection
      auto-detect chữ ký (phải khai tường minh `dtype`/`readonly`).

      **Mirror tree (`release/3.code/build/pyinstaller_src/`) VẪN CHƯA đồng
      bộ Phase 1-4** (kế thừa nguyên trạng từ Phase 3, không phải gap mới
      của Phase 4): xác nhận qua grep trực tiếp (2026-08-18) — hoàn toàn
      không có dấu vết `__tkv_extern_method__`/`__tkv_extern_pinvoke__`/
      `__tkv_extern_class__` trong `tkv_compile.py`/`compiler/il_codegen.py`
      của cây mirror (dù `EXPR_METHOD_CODEGEN`/`il_dispatch.py` — hạ tầng
      registry chung — vẫn tồn tại). Theo đúng tiền lệ đã ghi nhận ở
      project memory (`tokenvector-release-session-2026-08-11`: cây `.tkv`
      tự-host/mirror có drift đáng kể so với cây gốc `.py`), Task 5 KHÔNG
      cố ép port Phase 3 lên nền chưa có Phase 1/2 — cần port riêng
      Phase 1+2 trước (việc RIÊNG, ngoài phạm vi plan `extern-class`) nếu
      muốn mirror tree bắt kịp.

      **Phase 5 ĐÃ XONG (2026-08-18, `__tkv_extern_class__` container
      `list[T]`, xem `.superpowers/sdd/task-{1,2,3}-brief.md`/
      `task-{1,2,3}-report.md`)**: cho phép dtype `list[T]` (T là scalar
      HOẶC 1 handle-type extern-class khác) làm kiểu ctor param, method
      param, method return, và property (VALIDATE ở Task 1, CODEGEN
      `List<T>` CIL thật ở Task 2, test tổng hợp thật ở Task 3). **Đã
      làm**:
      - Validate: parse `list[T]` qua `parse_type_ann_str`, từ chối tường
        minh `list[list[T]]` (container-của-container) tại cả 4 điểm khai
        báo (ctor/method-param/method-return/property), tái dùng 1 helper
        chung `_validate_extern_class_container_dtype`.
      - Codegen ctor/method param nhận `list[T]`: `_il_ctor_param_type`
        (`compiler/il_codegen.py`) sinh `class
        [mscorlib]System.Collections.Generic.List\`1<...>` đúng, tái dùng
        `il_list_elem_ilstr`/`il_list_type` đã mở rộng nhận
        `extern_class_defs`.
      - Codegen method trả `list[T]`: `_make_extern_class_method_return_ta`
        (`tkv_compile.py`) parse đúng shape `'list'` cho `TypeAnn` trả về.
      - `list[HandleType]` (T là handle-type khác, không phải scalar): local
        variable, `.append()`, index đọc/ghi, `for x in lst:` (cả macro mở
        rộng `for idx in range(len()): x = lst[idx]` LẪN literal `for x in
        lst:` trực tiếp) đều hoạt động đúng — gọi được method/đọc property
        TRÊN TỪNG phần tử lấy ra. Đã fix 3 bug thật qua review (không phải
        thiết kế mới): (a) `il_type_str`'s nhánh `shape=='list'` thiếu
        `extern_class_defs` khi gọi `il_list_type` (Task 2 review fix,
        commit `f4445da`), (b) hơn 10 call site trực tiếp
        `il_list_type(dtype, records)` trong `il_features/*.py` (remove/
        insert/clear/copy/index/count/sort/extend/reverse/pop/to_list) đổi
        sang dùng dispatcher đệ quy `ctx['il_type_str']` để thừa hưởng fix
        (a) thay vì thread thêm tham số qua từng nơi (cùng commit), (c)
        **Task 3 review fix** (`compiler/il_codegen.py`, 2 điểm —
        `declare_scalar` dòng ~2947 và `_fpp_assign_scalar` dòng ~3357):
        khi 1 local được gán từ việc INDEX 1 list[HandleType]
        (`item = items[idx]`, kể cả khi cú pháp nguồn là `for item in
        items:` rồi bị macro `try_expand_for_in_list` viết lại thành dạng
        trên) — dtype phần tử suy đúng ('Sb') nhưng SHAPE bị bỏ sót
        (mặc định `None` thay vì `'extern_class'`) vì nhánh 'index' của
        `_infer_dtype` trả THẲNG dtype chuỗi, không phải TypeAnn đầy đủ —
        gây `KeyError` tại `il_type_str`'s nhánh `shape is None`
        (`IL_SCALAR['Sb']` không tồn tại) VÀ khiến `item.Method()`/
        `item.Prop` sau đó tra cứu SAI shape. Tái hiện được lỗi thật qua
        `for item in items: print(item.ToString())` với `items` là
        `list[Sb]` (Sb = extern-class), đã sửa: khi dtype suy được nằm
        trong `_EXTERN_CLASS_DEFS`, gán `shape='extern_class'` (đối xứng
        với nhánh `shape='record'` sẵn có ngay cạnh).
      - API/fixture THẬT đã dùng cho test (KHÔNG xác minh reflection .NET —
        quy ước dự án từ Phase 1, compiler này KHÔNG BAO GIỜ đối chiếu chữ
        ký khai báo với .NET thật, người dùng tự chịu trách nhiệm chữ ký
        đúng): `System.Text.StringBuilder` (`mscorlib`), khai báo `ctor`/
        `methods`/`properties` TỰ CHỌN (không phải chữ ký .NET thật) —
        dùng để đối chiếu CIL type-string/marshaling đúng ở tầng codegen,
        không đối chiếu giá trị runtime "thật" của StringBuilder (build
        thành công nhưng có thể `MissingMethodException` lúc CHẠY nếu chữ
        ký khai báo không khớp .NET thật — hành vi CHẤP NHẬN/đã tài liệu
        hóa, giống mọi Phase 1-4). Case `list[HandleType]` (Case 3,
        `test/verify/extern_class_list_test.py`) build+CHẠY THẬT, đối
        chiếu output đúng — không bị giới hạn bởi API không tồn tại vì
        các method/property dùng (`ToString`, `Length`) là chữ ký THẬT của
        `StringBuilder`.
      - Test: `test/verify/extern_class_list_parse_test.py` (Task 1, parse/
        validate `list[T]`), `extern_class_list_codegen_gap_test.py`
        (Task 2, tái hiện gap + xác nhận đóng gap qua 3 case: ctor nhận
        `list[i32]`, method trả `list[i32]`, `list[Sb]` end-to-end),
        `extern_class_list_test.py` (Task 3, test tổng hợp theo mẫu
        `extern_class_property_test.py` — 3 case: method trả `list[i32]`
        + lặp qua bằng `list[...]` DSL, method NHẬN `list[i32]` làm THAM
        SỐ (1 biến `list[i32]` DSL bình thường, KHÔNG qua extern-class,
        truyền thẳng vào), `list[Sb]` end-to-end lặp `for` + gọi
        method/đọc property trên từng phần tử lấy ra).
      **CHƯA làm (giới hạn KHÔNG làm, copy nguyên từ spec)**: CHỈ
      `List<T>` cụ thể — **cảnh báo RÕ rủi ro `InvalidCastException`/
      `MissingMethodException` nếu API thật trả về 1 INTERFACE
      (`IList<T>`/`IEnumerable<T>`) thay vì `List<T>` cụ thể, hoặc chữ ký
      khai báo không khớp .NET thật** (không tự xác minh); KHÔNG
      `Dictionary`/`dict[K,V]` làm dtype ctor/method/property của
      extern-class (dtype container khác `list` chưa được validate/codegen
      cho extern-class); KHÔNG container-của-container (`list[list[T]]`
      bị chặn tường minh ở validate); KHÔNG generic tự khai khác
      (`List<T>` là container CỐ ĐỊNH duy nhất được hỗ trợ, không hỗ trợ
      generic .NET tuỳ ý khác qua pragma này).

      Nhánh `list-of-record` (không phải extern-class, container chứa
      RECORD tự định nghĩa của TokenVector) vốn đã hoạt động từ trước
      (không liên quan Phase 5) — Phase 5 CHỈ mở rộng cho phần tử là
      handle-type .NET ngoài.

      Hướng còn lại cho Phase 4+ giữ nguyên: NuGet interop (Math.NET/ML.NET
      thay numpy/pandas) + viết lại thư viện thuần logic bằng C#. Effort
      cực cao, cần chiến lược nhiều giai đoạn — bắt đầu bằng viết lại
      stdlib chuẩn, rồi bridge .NET lib, rồi cộng đồng đóng góp.
- [x] **#2 eval/exec/metaclass/duck-typing — ĐÃ CHỐT XONG cả 3 nhánh** (1 nhánh
      xây dựng thật — duck-typing; 2 nhánh còn lại xác nhận NON-GOAL vĩnh viễn,
      không phải "chưa làm", quyết định 2026-08-18).
  - [x] **duck-typing → ĐÃ XONG qua type-inference TĨNH** (plan
        `docs/superpowers/plans/2026-08-17-duck-typing-inference.md`, spec
        `docs/superpowers/specs/2026-08-17-duck-typing-inference-design.md`,
        5/5 task hoàn tất, commit cuối
        `feat(compiler): duck-typing qua type-inference tinh - monomorphization
        tham so ham top-level khong annotation (#2 phan 1/2)`). **LƯU Ý QUAN
        TRỌNG**: đây là monomorphization qua suy kiểu TĨNH tại compile-time
        (giống C++ template/Rust generic), **KHÔNG PHẢI** duck-typing runtime
        đầy đủ kiểu Python thật (không có dispatch động, không có `__getattr__`
        fallback, không sửa được hành vi lúc chạy).
    - **Đã làm**: tham số hàm **top-level** (không phải method-trong-class,
      không phải nested-def) thiếu annotation kiểu được suy `dtype='inferred'`;
      quét thân hàm suy trực tiếp field (`param.field`)/method
      (`param.method(...)`)/toán tử nhị nguyên-so sánh (`param + x`,
      `param == x`) tham số đó dùng; monomorphize (sinh 1 bản `.method` CIL
      RIÊNG, tên mangle `func$T$Kieu1$Kieu2...`) cho TỪNG tổ hợp kiểu cụ thể
      tại TỪNG call-site; cache theo `(tên hàm, tổ hợp kiểu)` — nhiều
      call-site cùng kiểu KHÔNG sinh trùng `.method`; hỗ trợ kế thừa (field/
      method ở lớp cha vẫn thỏa constraint); hỗ trợ generator gọi hàm
      inferred (sau khi fix Critical 1); vòng lặp fixpoint xử lý monomorphize
      lồng nhau nhiều tầng (hàm monomorphize A, khi compile thân A phát sinh
      thêm nhu cầu monomorphize hàm B khác — xử lý qua nhiều vòng
      `pending_monomorphize` tại `tkv_compile.py`'s `compile_tkv_cli`, giới
      hạn an toàn 1000 vòng).
    - **CHƯA làm (phạm vi MVP có ý thức)**:
      - **KHÔNG lan truyền qua lời gọi khác** — tham số `inferred` truyền
        TIẾP làm argument cho 1 hàm/method KHÁC (kể cả tự-đệ-quy) là lỗi biên
        dịch rõ ràng ngay lúc thu thập ràng buộc, KHÔNG cố suy bắc cầu.
      - **KHÔNG hỗ trợ index/slice/container-ops** trên tham số `inferred`
        (`param[i]`, `param[a:b]`, `len(param)`, `param in x`,...).
      - **CHỈ hàm top-level** — method-trong-class và nested-def (hàm lồng
        trong hàm) KHÔNG được hỗ trợ, tham số thiếu annotation ở 2 vị trí đó
        vẫn raise lỗi thiếu annotation như trước.
      - **KHÔNG hỗ trợ gán lại tham số** (`param = x`) rồi dùng biến mới thay
        thế, cũng KHÔNG hỗ trợ augassign trực tiếp trên tham số.
      - **So sánh thứ tự trên record bị chặn** — `<`/`<=`/`>`/`>=` trên tham
        số `inferred` kiểu record LUÔN raise lỗi rõ ràng (compiler hiện không
        có cơ chế dunder nào cho 4 toán tử này trên record); chỉ `==`/`!=`
        hoạt động (qua `__eq__` nếu có, fallback so sánh tham chiếu nếu
        không).
      - **`async def` gọi hàm inferred** — CHƯA hỗ trợ đầy đủ như generator
        (generator đã fix ở Critical 1 của task4-critical-fix-report.md),
        báo lỗi rõ ràng thay vì crash nội bộ (xem `docs/BUGS_TODO.md` — 2
        điểm follow-up nhỏ về chất lượng thông báo lỗi cho nhánh `async`/
        `for...in generator`, KHÔNG chặn việc đóng plan).
      - Return type của hàm `inferred` **KHÔNG** được suy đặc biệt theo tổ
        hợp kiểu cụ thể — vẫn phải khai báo tường minh 1 kiểu CỐ ĐỊNH áp dụng
        cho MỌI tổ hợp kiểu (vd hàm toán tử dùng chung cho cả scalar VÀ record
        phải khai return type nhất quán giữa các bản monomorphize — xem
        `test/sample_duck_typing.tkv`'s `add_them`).
  - [x] Monkey-patch/metaclass → **non-goal vĩnh viễn** (quyết định 2026-08-18,
        cùng lý do với `eval()`/`exec()`). Cả 2 đều đòi hỏi khả năng sửa đổi
        type/class object lúc **runtime** (metaclass: can thiệp quá trình
        tạo class động; monkey-patch: gán thêm/ghi đè method-field vào class
        có sẵn sau khi định nghĩa) — TokenVector AOT tĩnh không có, và không
        nên có, khái niệm "class object" tồn tại lúc chạy để sửa (không
        reflection, không vtable động, không boxing toàn bộ). Đã cân nhắc
        hướng "Source Generator compile-time-only" (metaclass logic chạy lúc
        compile bằng Python thật để sinh code CIL tương đương, không có class
        object động lúc runtime) — QUYẾT ĐỊNH KHÔNG LÀM: pattern đó đã được
        phủ bởi 2 cơ chế sẵn có (decorator `@deco` cho tùy biến sinh code lúc
        compile-time; duck-typing/monomorphization cho tùy biến theo kiểu
        dùng thật) — làm thêm 1 nhánh "metaclass giả lập" riêng sẽ trùng lặp
        năng lực, tăng bề mặt bảo trì mà không mở khoá use-case mới thật sự.
  - [x] `eval()`/`exec()` tổng quát — **non-goal vĩnh viễn** (phá vỡ AOT).

Không còn hướng nào của mục #2 cần code thêm — đã chốt dứt điểm. Bản nghiên
cứu đầy đủ (không rút gọn, tham khảo lịch sử quyết định):
`docs/_qwen3_architecture_gap_research_full.md`.

## Ký hiệu
`[ ]` chưa làm · `[x]` đã xác nhận đúng · `⚠` nghi ngờ, cần verify code

---

## A. Gap mới phát hiện (chưa có ở Phase 5/6) — đã xác minh 2026-08-11
- [x] `global` statement — checkbox lỗi thời, ĐÃ XONG THẬT từ 2026-08-11 (xem mục "Thứ tự ưu tiên tổng hợp" #2 cuối file) — biến module-level ghi được qua static field, `tkv_compile.py:975-991`, `il_codegen.py:870-1012`. Xác nhận lại 2026-08-13 khi rà soát checklist cuối phiên.
- [x] `sum()`/`min()`/`max()` variadic-scalar + `sum(lst, start)` — ĐÃ XONG (2026-08-12). `min(a,b,c,...)`/`max(a,b,c,...)` N-ary: mở rộng macro `min(a,b)`/`max(a,b)` cũ (ternary text-level) sang gấp trái→phải qua N tham số (`try_expand_minmax_2arg` trong `stdlib_aggregates.py`), vẫn nhân bản văn bản (không tác dụng phụ trong DSL này, đúng tiền lệ). `sum(xs, start)`: `push_sum` nhận tối đa 2 tham số, tham số 2 (bất kỳ biểu thức) thay cho hằng số 0 mặc định. Không có gì để chép ở `.tkv` tree cho phần này (cùng gap). **2 bug thật phát hiện + sửa dọc đường** (không phải do tính năng variadic, mà do đây là lần ĐẦU TIÊN có test thật cho `min`/`max`/`sum` — trước đó hoàn toàn chưa có test nào, kể cả bản 2-arg cũ): (1) `collect_ternary_temps` (`il_codegen.py`) khai bao local ẩn `__ternN` LUÔN theo `body_dtype` (dtype ngữ cảnh bao quanh, vd `str` khi ternary nằm trong `str(...)`) thay vì dtype THẬT của toán hạng ternary — gây type-confusion IL thật (local khai `string` nhưng lưu giá trị `TkvInt` — struct nhiều field) khi `min`/`max` áp dụng cho biến kiểu `int` mặc định, kết quả sai âm thầm (`got=0`) chứ không crash. Phát hiện `.tkv` tree ĐÃ CÓ 1 phần fix này (dùng `_infer_dtype(tern_node,...)` thay vì `body_dtype`) — port về `.py` tree, rồi PHÁT HIỆN THÊM 1 lỗ hổng chung cho cả 2 cây: `_infer_dtype` trả `None` cho hằng số trần (`min(4,2,8,1)` toàn literal, tag `'num'` không có dtype cố định) → vẫn rơi về `body_dtype` sai — thêm tầng fallback 2 dùng `_infer_literal_dtype` (đã có sẵn, dùng ở `declare_scalar`) cho cả 2 cây. (2) `_agg_elem_dtype` (`EXPR_BUILTIN_DTYPE_FN` cho sum/min/max/sorted) chỉ chấp nhận đúng 1 tham số — `sum(xs, start)` 2 tham số khiến `infer_dtype` trả `None`, kéo theo `compile_str_builtin`'s nhánh `__strtmp` khai sai dtype (tương tự lỗi (1) nhưng qua đường khác) → `NullReferenceException` thật lúc chạy. Sửa: nới điều kiện xuống `len(args) < 1` (chỉ xét `args[0]`). Test mới `aggregates_variadic_py_tree_test.tkv` (5/5 PASS qua `.py` tree VÀ `tkvc.exe` thật, rebuild qua `build_tkvc.ps1`). Regression 19 file khác qua `.py` tree (input/native_test_suite/path_isfile fail đã xác nhận PRE-EXISTING, không liên quan) + 7 file trọng điểm re-test qua `tkvc.exe` thật không đổi.
- [x] `reduce()` — KHÔNG phải bug: `reduce(fn, lst, init)` bắt buộc đúng 3 args nhất quán (`push_reduce` unpack 3, `register_expr_builtin` cùng khớp) — chỉ là chưa hỗ trợ dạng 2-arg không init, không phải arity lỗi
- [x] `re.findall`/`split`/`compile` — checkbox lỗi thời: `re_findall`/`re_split` ĐÃ XONG (batch 5.5b, 2026-08-13, `stdlib_re.py`'s `compile_re_findall`/`compile_re_split`, đăng ký qua `register_expr_builtin`). `re.compile()` (compiled-regex-object) QUYẾT ĐỊNH KHÔNG LÀM — đã chốt ngoài phạm vi ở sub-project 5.5b (không có khái niệm "compiled pattern object" tái sử dụng trong DSL tĩnh kiểu này, mỗi lần gọi `re_findall`/`re_split` tự biên dịch pattern tại chỗ qua `Regex` — đủ dùng cho lớp bài toán mục tiêu).
- [x] `json_get_str` **xung đột thật, ĐÃ SỬA** — grep đầu tiên chỉ quét `compiler/` nên bỏ sót: `tkv_compile.py` (gốc, cả `.py`/`.tkv`) import `stdlib_cjson` trực tiếp ở dòng 48, SAU khi `il_codegen` (dòng 42) đã đăng ký `json_get_str` bản chuỗi-thô từ `stdlib_json_get.py` — `register_expr_builtin` gán thẳng dict không cảnh báo trùng tên, nên cjson **âm thầm đè** lên bản đúng. Bug thật, không phải mã chết. **Đã sửa**: đổi tên 4 hàm cjson thành tiền tố `cjson_*` (`cjson_parse/cjson_get_obj/cjson_get_str/cjson_delete`), cả 2 cây, build+test qua `tkv.py` xác nhận PASS, không có test nào dùng tên cũ nên không cần sửa test.
- [x] 2 module JSON — không trùng, mỗi module 1 vai trò riêng: `stdlib_json.py` (`json_dumps`), `stdlib_json_get.py` (`json_get_str` bản chuỗi-thô), `stdlib_cjson.py` (P/Invoke C-native, nay đổi tên `cjson_*` để không tranh chấp)
- [x] `str.join` KHÔNG xung đột — 2 đường tách biệt CÓ CHỦ ĐÍCH: `string_join.py` cho biến string thường (qua `register_expr_method`), `string_methods_batch2.py`'s `STR_METHODS['join']` chỉ dùng trong `record_feature.py` cho thuộc tính record kiểu str
- [x] `set.remove()` — **gap thật, xác nhận**: map thẳng .NET `HashSet.Remove(T)` (trả `bool`, giá trị bị **cố ý bỏ qua** theo comment trong code) — im lặng khi phần tử không tồn tại, khác Python (phải ném `KeyError`)
- [x] `list.sort()` `key=`/`reverse=` kwargs — ĐÃ XONG (2026-08-12). `reverse=True/False`: rẻ, chỉ `Sort()` rồi `Reverse()` (có sẵn, xác nhận thật qua reflection ở `list_methods_batch3.py`'s `list.reverse()`). `key=g`: tái dùng hạ tầng "first-class function value" đã có (`func(T)->K` qua `map`/`filter`/`reduce`, `_resolve_func_ta`/`compile_funcref_arg`) — thuật toán decorate-sort-undecorate qua `List<ValueTuple<K,T>>` (`pairs = [(g(x), x) for x in lst]`, `pairs.Sort()` dùng `Comparer<ValueTuple<K,T>>.Default` CÓ SẴN so sánh Item1 trước — chạy được vì MỌI dtype DSL này hỗ trợ đều đã `IComparable` từ trước, kể cả `int`/`TkvInt`), rồi ghi lại `lst[i] = pairs[i].Item2` — KHÔNG cần dựng `Comparison<T>` delegate tùy biến mới, tái dùng nguyên cơ chế `list[(K,V)]` (tiền lệ `most_common(c,n)` ở `counter_type.py`). Giới hạn có ý thức: sắp xếp **không ổn định** (not stable) khi trùng key — khác Python thật (giữ nguyên thứ tự gốc cho phần tử trùng key), đánh đổi để tránh viết delegate mới hoàn toàn. `key` CHỈ nhận 1 TÊN (biến kiểu `func` đã khai báo HOẶC tên 1 hàm top-level) — không nhận lambda/biểu thức phức tạp tại chỗ, giống giới hạn `map`/`filter`/`reduce`. **1 bug thật phát hiện + sửa dọc đường** (hạ tầng dùng chung, không riêng sort): `_resolve_func_ta` (`stdlib_functional.py`) trước đây `try/except KeyError` để phát hiện tên KHÔNG phải biến kiểu `func` (rồi rơi xuống nhánh tra `func_table` cho tên hàm top-level) — hoạt động đúng ở first-pass (`infer_scope`/`_DtypeOnlyScope` ném `KeyError`) nhưng **CHƯA TỪNG được test qua codegen pass 2 thật** (`_Scope` thật ném `SyntaxError`, không phải `KeyError`) vì mọi test `map`/`filter`/`reduce` trước đây chỉ truyền biến kiểu `func` (không truyền thẳng TÊN 1 hàm top-level) — lỗi này ẩn từ Phase 3.3 tới giờ, lộ ra ngay lần đầu `sort(key=<tên hàm top-level>)` được test thật. Sửa: bắt cả `(KeyError, SyntaxError)`. Test mới `list_sort_kwargs_py_tree_test.tkv` (4/4 PASS qua `.py` tree VÀ `tkvc.exe` thật, rebuild qua `build_tkvc.ps1`). Regression 25 file khác qua `.py` tree (path_isfile fail đã xác nhận PRE-EXISTING) + 4 file trọng điểm dùng func-value re-test qua `tkvc.exe` thật không đổi.
- [x] `.strip()`/`.lstrip()`/`.rstrip()` không nhận tham số `chars` — ĐÃ XONG PHẦN `.lstrip()`/`.rstrip()` (2026-08-13). `.strip(chars)` đã hỗ trợ từ trước (`compile_str_method_strip`, `string_methods_batch2.py`); task này mirror ĐÚNG pattern đó sang `compile_str_method_lstrip`/`compile_str_method_rstrip` (`string_methods_batch3.py`, cả `.py` và `.tkv` tree): `'chars'.ToCharArray()` rồi gọi `TrimStart(char[])`/`TrimEnd(char[])` khi có 1 tham số, giữ nguyên nhánh `ldnull` cũ khi 0 tham số. Test mới `Testkit/lstrip_rstrip_chars_test.tkv` (4/4 PASS, gồm cả 2 case chars và regression case 0-tham-số). Regression: `find_strip_extend_test.tkv` (5/5 PASS) + `test/verify/str_ext_test.py` (đối chiếu CPython thật, PASS) không đổi hành vi.
- [x] `win32_gui_window.py` chỉ chạy Windows — XÁC NHẬN KHÔNG PHẢI GAP (2026-08-13): toàn bộ toolchain compiler dựa trên `ilasm.exe` (.NET Framework, Windows-only — KHÔNG phải `dotnet`/mono cross-platform, xác nhận qua grep `ilasm.exe` xuất hiện xuyên suốt `tkv_compile.py`), nên cả dự án vốn dĩ chỉ chạy Windows từ gốc — không có "cross-platform" nào để guard cho riêng 1 file GUI.

## B. Kế thừa Phase 5 (chi tiết xem `PYTHON_GAP_IMPLEMENTATION_PLAN.md`)
- [x] 5.1 `*args`/`**kwargs` — ĐÃ XONG MỘT PHẦN (2026-08-11). Thiết kế: chỉ ham TOP-LEVEL (không decorator/method), `*name: T`/`**name: T` cuối danh sách tham số, đồng nhất kiểu T. `*args` → gói các đối số vị trí dư vào `list[T]` ngay trên stack tại điểm gọi (newobj+dup+Add lặp, tái dùng pattern list-literal có sẵn) — HOẠT ĐỘNG ĐẦY ĐỦ, test thật. `**kwargs` → tham số được khai báo và sinh `.field`/`dict[str,T]` đúng kiểu, NHƯNG bộ phân tích biểu thức gọi hàm (`_expr_call`, node dạng `('call', name, args)`) hiện CHỈ nhận đối số vị trí — hoàn toàn KHÔNG có cú pháp `f(x=1)` ở tầng parser biểu thức (khác tầng chữ ký hàm) → kwargs tại điểm gọi LUÔN nhận dict RỖNG (giống Python khi không truyền keyword nào), CHƯA thể truyền giá trị thật vào kwargs. Muốn kwargs dùng được thật cần thêm cú pháp keyword-argument cho TOÀN BỘ bộ phân tích lời gọi hàm (việc lớn hơn, tách riêng). Đã kiểm tra `.tkv` trước — không có gì để chép, áp dụng cho cả 2 cây. Test mới `varargs_py_tree_test.tkv` (5/5 PASS qua `.py` tree và `tkvc.exe` thật), regression 13 file khác (gồm `native_test_suite` 16/16) không đổi.
- [x] 5.2 `namedtuple`/`Counter`/`defaultdict` — ĐÃ XONG
- [x] 5.3 `itertools` dạng biểu thức độc lập — ĐÃ XONG MỘT PHẦN (2026-08-12). Không có gì để chép ở `.tkv` tree (cùng gap, macro-only). `enumerate(x)`/`zip(a,b)` (2-ary) giờ dùng được ở VỊ TRÍ BIỂU THỨC (không chỉ header `for`), tận dụng cơ chế `list[(K,V)]` có sẵn (tiền lệ `most_common(c,n)` ở `counter_type.py`) — bắt buộc khai báo tường minh `ten: "list[(K,V)]" = enumerate(x)/zip(a,b)`. Giới hạn có ý thức: phần tử nguồn CHỈ nhận dtype cố định `i32/i64/f32/f64/str` — **CHẶN rõ ràng** dtype `int` (số nguyên vô hạn chữ số mặc định của list literal không annotation, vd `xs = [1,2,3]`) vì layout IL (TkvInt struct) không khớp với tuple đích khai báo `i32` → nếu không chặn sẽ sinh IL type-confusion ÂM THẦM (xác nhận qua thử nghiệm thật: đọc nhầm field, giá trị sai hoàn toàn, không phải lý thuyết) — nguồn phải là list kiểu cố định thật (vd qua tham số hàm `xs: "list[i32]"`). Test mới `itertools_expr_py_tree_test.tkv` (2/2 PASS qua `.py` tree và `tkvc.exe` thật). Regression 15 file khác + `native_test_suite` (16/16) không đổi.
  - **Update (2026-08-12, cùng phiên)**: thêm `chain(a, b, ...)` (macro `for`-header N-ary, tái dùng ternary lồng nhau giống `zip`'s `_min_len_expr`) — **XONG, hoạt động đầy đủ**. Phát hiện + sửa 1 bug thật trong lúc viết: điều kiện so sánh ban đầu dùng sai biến (idx gốc thay vì offset đã dịch ở từng cấp đệ quy) → `ArgumentOutOfRangeException` thật với ≥3 list (xác nhận qua test 3-list, không chỉ lý thuyết) — đã sửa. `product(a, b)` **THỬ NHƯNG BỎ**: phát hiện giới hạn kiến trúc thật của cơ chế macro text-level hiện tại — nó chỉ thay thế ĐÚNG 1 dòng `for` bị khớp, thân vòng lặp gốc (các dòng sau, giữ nguyên indent cũ) không được dịch chuyển theo cấu trúc lồng mới → 2 vòng `for` lồng nhau thật (cần cho product) sẽ đặt thân gốc SAI cấp (lọt ra ngoài vòng trong thay vì nằm trong nó) — phát hiện qua phân tích cấu trúc trước khi chạy thử, không cần test để biết sai. Giải pháp đúng (dịch chuyển indent) cần sửa `_expand_macros_once` ở tầng framework, ngoài phạm vi 1 macro đơn lẻ — để dành. Người dùng viết 2 vòng `for` lồng nhau thật thay thế (đã hỗ trợ sẵn, không cần macro). Test mới `itertools_chain_py_tree_test.tkv` (2/2 PASS qua `.py` tree và `tkvc.exe` thật, 2-ary và 3-ary). Regression 17 file khác + `native_test_suite` (16/16) không đổi.
  - **5.3 coi như XONG** cho phạm vi đã định (enumerate/zip ở vị trí biểu thức + chain N-ary ở for-header). `product()` là gap kiến trúc riêng, không phải thiếu sót nhỏ — để dành cùng nhóm với các cải tiến framework macro khác nếu cần.
  - **Nghiên cứu Qwen3(Groq), creative+critical layer (2026-08-12, xem `docs/_qwen3_product_macro_research.md`)**: đề xuất 8 hướng, khuyến nghị cuối cùng là TIẾP TỤC ĐỂ DÀNH — sửa chung `_expand_macros_once` để hỗ trợ "dịch chuyển indent" có nguy cơ PHÁ VỠ `enumerate`/`zip`/`chain` đang ổn định (phải thêm logic phân biệt macro nào cần dịch indent ngay trong hàm dùng chung); cách an toàn hơn (tách hàm riêng, chạy trước `_expand_macros_once`) khả thi nhưng ROI thấp so với giải pháp thay thế đã có sẵn (viết tay 2 vòng `for` lồng nhau).
  - **Insight quan trọng (từ việc so sánh với Python thật)**: Python KHÔNG desugar `for x,y in product(a,b):` thành 2 vòng lồng nhau trong mã nguồn — nó vẫn là 1 vòng `for` DUY NHẤT, vì MỌI iterable trong Python chỉ cần thỏa 1 giao thức chung (`iter()`/`__next__()`); logic 2-chỉ-số của `product` nằm ẨN bên trong implementation của chính `itertools.product`, không phải trong cấu trúc code gọi nó. TokenVector hiện chưa có khái niệm iterator tổng quát cho `for` (mỗi `for x in lst:` biên dịch cứng theo `range(len(lst))`), nên `product()` buộc phải "bung" cấu trúc lồng nhau ra ngay tại macro — đó chính là chỗ vỡ (không dịch chuyển được indent thân vòng lặp gốc).
  - **=> `product()` PHỤ THUỘC vào 6.7 (Iterator protocol tùy biến `__iter__`/`__next__`), KHÔNG PHẢI việc độc lập của 5.3.** Nếu 6.7 được làm (class nội bộ giữ state + `MoveNext()`/`Current`, `for` biên dịch qua giao thức đó thay vì cứng theo `range(len())`), thì `product()`/`chain()`/mọi custom iterator khác đều dùng lại được CÙNG cơ chế đó — không cần macro text-level riêng, không đụng tới `_expand_macros_once`, không rủi ro phá `enumerate`/`zip`. Ghi chú này liên kết 5.3↔6.7 để phiên sau không phải nghiên cứu lại từ đầu.
- [x] 5.4 `sys.argv`/`sys.exit` — ĐÃ XONG (2026-08-12). TokenVector không có khái niệm namespace object thật (mọi `import` gộp phẳng tên) nên ánh xạ thành 2 tên FLAT riêng, đúng quy ước `os.path.X` → `path_X` đã dùng trước: `sys_argv()` (gọi NHƯ 1 HÀM — không phải thuộc tính `sys.argv` truy cập trực tiếp, giới hạn có ý thức) trả `list[str]`, `sys_exit(code)` (hàm VOID, dùng như 1 lệnh độc lập, dispatch qua `SYS_STMT_CODEGEN` giống `log_X`/`pickle_dump_X`). `sys_argv()` ánh xạ `Environment.GetCommandLineArgs()` (xác nhận thật qua PowerShell reflection trước khi viết) — mảng này CÓ CẢ đường dẫn .exe ở phần tử 0, khớp đúng quy ước Python thật (`sys.argv[0]` = tên script), khác tham số `args` của chính `Main(string[] args)` (không có tên file, dùng riêng cho CLI tự động bind tham số entry). `sys_exit(code)` ánh xạ `Environment.Exit(int32)` (xác nhận thật qua reflection) — test thật xác nhận exit code đúng (`sys_exit(42)` → process thoát với code 42). `sys.path`: KHÔNG làm — chương trình đã AOT-compile thành `.exe` tĩnh, không có dynamic import runtime nào để "đường tìm module" còn ý nghĩa (cùng lý do đã bỏ qua `pdb`/`turtle`). Không có gì để chép ở `.tkv` tree (cùng gap, genuinely mới) — riêng `file_io.py` (nơi dispatch `call_stmt`) đã PHÂN KỲ SẴN giữa 2 cây (bản `.tkv` có thêm nhánh fallback `EXPR_BUILTIN_DTYPE` mà `.py` tree chưa có) — chỉ áp patch tương ứng vào đúng vị trí, không đụng phần khác biệt sẵn có. Test mới `sys_module_py_tree_test.tkv` (2/2 PASS qua `.py` tree VÀ `tkvc.exe` thật cho `sys_argv()`) + kiểm tra riêng `sys_exit(42)` qua exit code thật (không nằm trong suite chính vì lệnh này chấm dứt tiến trình, phá vỡ luồng `check()`/`test_summary()` — xác nhận thủ công qua 1 file `.tkv` độc lập, PASS cả 2 cây). Regression 29 file khác qua `.py` tree (path_isfile fail đã xác nhận PRE-EXISTING) không đổi.
- [x] 5.5a `random.shuffle/sample/seed` — ĐÃ XONG (2026-08-12), xem
      `docs/superpowers/plans/2026-08-12-random-shuffle-sample-seed.md`.
      `TkvRandom` static helper class (tái dùng mẫu `TkvLogging`) giữ 1
      `System.Random` dùng chung cả chương trình, khởi tạo lười —
      `seed(n)` giờ THẬT SỰ có tác dụng (trước đây mỗi lời gọi tạo
      Random mới, không có gì để seed). `shuffle(lst)` Fisher-Yates tại
      chỗ, `sample(lst, k)` trả list mới không mutate nguồn — CẢ 2 sinh
      IL inline tại điểm gọi (KHÔNG dùng generic method tự viết — probe
      thật qua `ilasm.exe` phát hiện generic method tự định nghĩa gây
      `MissingMethodException` lúc chạy dù assemble không lỗi, xem spec).
      Tác dụng phụ có lợi: sửa luôn 1 bug cũ (2 lời gọi random() liên
      tiếp có thể trùng giá trị do TickCount seed trùng nhau).
- [x] `re.findall`/`re.split` — **ĐÃ XONG (2026-08-12)**. `re_findall`
      (MatchCollection → vòng lặp trích `.Value`), `re_split`
      (`Regex.Split` → `List<string>` trực tiếp). `re.compile()` KHÔNG
      làm có chủ đích — DSL không có kiểu "compiled regex object", xem
      `docs/superpowers/specs/2026-08-12-re-findall-split-design.md`.
- [x] `.replace(old,new,count)` — **ĐÃ XONG (2026-08-13)**. Tham số thứ
      3 optional qua `TkvStr::ReplaceCount` — count<0 thay hết, old=""
      chèn trước tối đa count ký tự đầu, old!="" vòng lặp IndexOf tìm
      tối đa count khớp. Xem
      `docs/superpowers/specs/2026-08-13-replace-count-design.md`.
- [x] `.format()` keyword args — **ĐÃ XONG (2026-08-13)**. `{name}`
      placeholder + `.format(name=value)` — macro text-level tự phân
      loại positional/keyword qua regex `name=value` (tránh khớp nhầm
      `==`/`>=`/`<=`/`!=`), positional+keyword trộn lẫn được. Xem
      `docs/superpowers/specs/2026-08-13-format-kwargs-design.md`.
- [x] `os.path.splitext()` — **ĐÃ XONG (2026-08-13)**. `path_splitext(p)
      -> (str, str)` qua `Path.GetExtension` + `Substring`. Mở rộng cơ
      chế `tuple_assign` nhận diện builtin trả tuple (không chỉ hàm
      người dùng). Giới hạn: file bắt đầu bằng dấu chấm không extension
      khác lệch Python. Xem
      `docs/superpowers/specs/2026-08-13-path-splitext-design.md`.
- [x] `divmod(a, b)` — **ĐÃ XONG (2026-08-13)**. `divmod(a,b) ->
      (i32,i32)/(i64,i64)` qua vòng lặp floor-adjust (viết lại logic đã
      có của `//`/`%`). Mở rộng `register_expr_builtin` thêm
      `return_ta_fn` động (dtype phụ thuộc tham số). Giới hạn: chỉ
      i32/i64, tham số đầu phải là 1 biến đơn. Xem
      `docs/superpowers/specs/2026-08-13-divmod-design.md`.
- [x] `set.remove(x)` ném lỗi khi thiếu phần tử — **ĐÃ XONG
      (2026-08-13)**. Kiểm tra bool trả về của `HashSet<T>::Remove`,
      ném `KeyNotFoundException` nếu thiếu (khớp `except KeyError:` có
      sẵn trong DSL). `discard()` giữ nguyên hành vi im lặng. Xem
      `docs/superpowers/specs/2026-08-13-set-remove-error-design.md`.
      **Batch 5.5b HOÀN TẤT — toàn bộ 7 mục đã xong.**
- [x] `divmod` — xác nhận Phase 5 ĐÚNG: `_DIVMOD_POW_HELPER` trong `int_type.py` CHỈ là helper nội bộ cho toán tử `//`/`%`/`**`, KHÔNG phải hàm `divmod()` built-in trả tuple — gap thật, giữ nguyên

## C. Kế thừa Phase 6 (chi tiết xem `PYTHON_GAP_IMPLEMENTATION_PLAN.md`)
- [x] 6.1 `global` — **ĐÃ XONG (2026-08-11)**. Thiết kế: khai báo biến
      module-level ghi được qua `NAME: "dtype" = literal` (AnnAssign,
      phân biệt hằng số cũ `NAME = literal` không annotation) → sinh
      `.field private static` thật trên class chương trình, khởi tạo
      trong `Main()` (không dùng `.cctor`, theo tiền lệ `logging_feature.py`).
      `global x` trong hàm → đọc/ghi qua `ldsfld`/`stsfld`. Thu hẹp phạm vi
      có ý thức: (1) chỉ kiểu vô hướng i32/i64/f32/f64/str, không container;
      (2) CẢ đọc lẫn ghi đều bắt buộc khai báo `global x` (khác Python thật
      — Python chỉ bắt buộc `global` khi GHI, đọc thì không cần — thu hẹp
      để tránh phải sửa fallback resolve tên ở mọi nơi trong codebase);
      (3) chỉ hỗ trợ hàm top-level, KHÔNG hỗ trợ trong nested closure/record
      method. Đã kiểm tra `.tkv` trước (theo nguyên tắc bắt buộc) — xác
      nhận KHÔNG có gì để chép, thiết kế mới thật sự, áp dụng cho cả 2 cây.
      Test mới `global_py_tree_test.tkv` (4/4 PASS qua cả `.py` tree và
      `tkvc.exe` thật), regression 12 file khác (gồm `native_test_suite`
      16/16) không đổi qua `tkvc.exe` thật.
- [x] 6.2 Multi-file module system — ĐÃ XONG (2026-08-12). Phát hiện quan trọng: `.tkv` tree (self-host) ĐÃ CÓ SẴN cơ chế mạnh hơn `__tkv_import__` — `import X`/`from X import a,b` THẬT được `_parse_program_ast` nhận diện, resolve qua `_find_module_path` (tìm `.tkv` rồi `.py`, qua thư mục file/`stdlib/`/`vendor/`/`sys.path`), lỗi rõ ràng nếu không tìm thấy — port thẳng sang cây `.py` root (đúng nguyên tắc chép/convert, đã tự sửa sau khi phát hiện thiết kế riêng ban đầu bị trùng/kém hơn). Bù đắp cho gap CPython-runnability: `__tkv_import__` (biến tự chế) KHÔNG chạy được dưới CPython thật; `import X`/`from X import a,b` (cú pháp Python chuẩn) THÌ CÓ, nhưng cần 1 dòng `import tkv_import_hook` (file mới `tkv_import_hook.py`, đăng ký FileFinder path_hook cho đuôi `.tkv`) ở đầu file .tkv nào cần cross-file import chạy đúng khi gọi trực tiếp `python file.tkv` — marker này được trình biên dịch loại trừ đặc biệt (không coi là module cần resolve). Giới hạn có ý thức: CHỈ hỗ trợ `from X import a,b,c` (gộp phẳng tên vào namespace hiện tại) — `import X` (bare) VẪN gộp phẳng giống `from`, KHÔNG có qualified access `X.ten()` thật (TokenVector không có khái niệm namespace object). `__tkv_import__` cũ vẫn hoạt động (backward-compat), không cần migrate test cũ. Test mới `import_py_tree_test.tkv` (2/2 PASS qua `.py` tree, `tkvc.exe` thật, VÀ xác nhận chạy đúng dưới CPython thật qua `runpy.run_path`) + `import_lib_mod.tkv` (module phụ). Regression 13 file khác + `native_test_suite` (16/16) không đổi.
- [x] 6.3 `raise` trần — ĐÃ XONG (2026-08-12, xem thêm `raise X from Y` bên dưới). `raise` trần (không tên lỗi) → `rethrow` IL, CHỈ hợp lệ trực tiếp bên trong 1 khối `except` (báo lỗi rõ ràng nếu dùng ngoài). Không có gì để chép ở `.tkv` tree (cùng gap) — port ngược từ `.py` tree sang `.tkv` tree lần này (hiếm, thường ngược lại). Phát hiện + sửa kèm 1 bug thật: `_stmts_end_in_return` chưa coi `raise` là điểm kết thúc khối → 1 `leave` thừa được sinh NGAY SAU `rethrow`/`throw`, gây `AccessViolationException` thật lúc chạy (xác nhận qua tkvc.exe thật, không chỉ lý thuyết) — đã sửa cho CẢ raise thường lẫn raise trần, cả 2 cây. Bonus: phát hiện `.tkv` tree đã có sẵn `except BuiltinType as e:` hoạt động (mục 6.9) mà `.py` tree thiếu hoàn toàn — đã port sang (`fpw_try` khai báo kiểu sentinel `Exception`, `il_type_str`/`str(e)` xử lý theo, xem `il_codegen.py`/`string_feature.py`) — 6.9 coi như XONG luôn. Test mới `bare_raise_py_tree_test.tkv` (1/1 PASS qua `.py` tree và `tkvc.exe` thật). Regression 14 file khác + `native_test_suite` (16/16) không đổi.
- [x] `raise X(...) from Y` (exception chaining) — ĐÃ XONG (2026-08-12). Mở rộng `_RAISE_RE` nhận hậu tố `from <ten>` tùy chọn; codegen dùng overload `.ctor(string, Exception)` (CÓ TRÊN MỌI class trong `_EXC_TYPE_MAP` — xác minh THẬT qua PowerShell reflection `GetConstructor([Type[]]@([string],[System.Exception]))` trên cả 6 class trước khi viết code, không giả định) thay vì `.ctor(string)` khi có `from`, nạp thêm biến `Y` (biến kiểu Exception-tương-thích: sentinel `Exception` từ `except ... as e:` HOẶC record tự định nghĩa kế thừa `Exception`) làm inner exception. Message rỗng (`raise X() from Y`) dùng `ldstr ""` thay vì gọi `.ctor()` 0-tham-số (giữ luôn đường 2-tham-số để nạp inner exception). Không có gì để chép ở `.tkv` tree (cùng gap). Giới hạn có ý thức: KHÔNG hỗ trợ `raise X from None` (suppress chaining, hiếm gặp, ngoài phạm vi); không có cách đọc `InnerException` lại trong DSL (chỉ `str(e)` đọc `.Message` của exception NGOÀI, không đọc được exception lồng bên trong) — test chỉ xác nhận ctor 2-tham-số chạy đúng (không crash, Message khớp), không xác nhận được `InnerException` link qua DSL (đọc `InnerException` không nằm trong yêu cầu "raise X from Y" cơ bản, để dành nếu cần sau). Test mới `raise_from_py_tree_test.tkv` (2/2 PASS qua `.py` tree VÀ `tkvc.exe` thật, rebuild qua `build_tkvc.ps1`, cả 2 trường hợp có/không message). Regression 27 file khác qua `.py` tree (path_isfile fail đã xác nhận PRE-EXISTING) + 3 file trọng điểm re-test qua `tkvc.exe` thật không đổi.
- [x] 6.4 `input()` — ĐÃ XONG (2026-08-12). Không có gì để chép ở `.tkv` tree (cùng gap, genuinely mới). `input()`/`input(prompt: str)` → `Console.Write(prompt)` (nếu có) + `Console.ReadLine()`, ánh xạ `null` (EOF thật) → `""` thay vì ném lỗi CLR riêng (giới hạn có ý thức — không định nghĩa `EOFError` riêng, hiếm gặp trong code AOT-compile). Test mới `input_py_tree_test.tkv` (2/2 PASS qua `.py` tree, `tkvc.exe` thật, cả trường hợp có/không prompt, xác nhận EOF không crash). Regression 14 file khác + `native_test_suite` (16/16) không đổi.
- [x] 6.5 Dunder method overload (`__eq__`/`__len__`/`__getitem__`/`__add__`/`__str__`) — **ĐÃ XONG HOÀN TOÀN 5/5 (2026-08-13)**, xem `docs/superpowers/specs/2026-08-13-dunder-str-design.md`, `docs/superpowers/specs/2026-08-13-dunder-eq-design.md`, `docs/superpowers/specs/2026-08-13-dunder-len-design.md`, `docs/superpowers/specs/2026-08-13-dunder-getitem-design.md`, `docs/superpowers/specs/2026-08-13-dunder-add-design.md`. `str(r)`/`print(r)` tự động gọi `__str__` của record qua điểm dispatch chung `emit_to_str`, hỗ trợ kế thừa. `==`/`!=` giữa 2 record cùng kiểu (hoặc cùng cây kế thừa) tự động gọi `__eq__` qua `compile_compare`, hỗ trợ kế thừa; record không có `__eq__` giữ nguyên hành vi so sánh reference cũ. `len(r)` (biến đơn, `r` kiểu record có `def __len__(self) -> "i32": ...`) tự động gọi `__len__` qua `callvirt`, hỗ trợ kế thừa; record không có `__len__` báo lỗi biên dịch rõ ràng (không phải crash nội bộ). `r[i]` (biến đơn record có `def __getitem__(self, i) -> "T": ...`, `i` bắt buộc `i32` scalar, `T` tuỳ ý — KHÔNG bị ép `i32` như `__len__`) tự động gọi `__getitem__` qua `callvirt` trong `_expr_index`, hỗ trợ kế thừa qua `_method_owner_class`; record không có `__getitem__` hoặc chữ ký sai báo lỗi biên dịch rõ ràng. Sửa kèm 1 bug thật trong `_infer_dtype`'s nhánh `'index'` (dùng chung cho `list`/record trước đây) — với record nó trả nhầm `TypeAnn.dtype` (tên class) thay vì dtype trả về của `__getitem__`, gây `KeyError` khi sinh `locals_sig` cho biến tạm. `a + b` giữa 2 record cùng kiểu (hoặc cùng cây kế thừa) có `def __add__(self, other) -> "T": ...` tự động gọi `callvirt` trong `compile_binop`, `T` tuỳ ý (record khác hoặc scalar, không bị ép kiểu cụ thể), hỗ trợ kế thừa qua `_method_owner_class`; record không có `__add__` LUÔN báo `SyntaxError` rõ ràng (khác `__eq__` — không có fallback mặc định hợp lệ cho `+` trên 2 tham chiếu object).
- [x] 6.6 Context manager tùy biến (`__enter__`/`__exit__`) — ĐÃ XONG (2026-08-13), xem `docs/superpowers/plans/2026-08-13-context-manager.md`. `with <ctor_call_record> as v:` HOẶC `with <biến_record_đã_khai_báo> as v:` desugar thành stmt kind `with_ctx` mới (song song `with_open` đã có, KHÔNG đụng vào) — tái dùng khung `.try/finally` y hệt `codegen_with_open`, gọi `__enter__` qua `callvirt` lúc vào khối (kết quả bind vào `v`, kiểu = return type của `__enter__`, có thể KHÁC kiểu record gốc), gọi `__exit__` qua `callvirt` trong `finally` (luôn chạy, kể cả có `return`/exception, giá trị trả về bị `pop`). Cần 1 hidden local (`__ctxmgr{id(stmt)}`, quy ước giống `__strtmp{id(...)}`) giữ record GỐC vì `v` có thể nhận kiểu khác. Record thiếu `__enter__` HOẶC `__exit__` (chỉ 1 trong 2) → `SyntaxError` rõ liệt kê tên đang thiếu. Giới hạn có ý thức: **KHÔNG suppress exception** (không có ý nghĩa "nuốt lỗi" như Python thật — `__exit__` luôn chạy nhưng giá trị trả về bị bỏ qua hoàn toàn); **KHÔNG hỗ trợ `with a, b:`** (nhiều context manager cùng lúc); **KHÔNG hỗ trợ chữ ký `__exit__` 4 tham số** (`self, exc_type, exc_val, exc_tb` kiểu Python thật) — `__enter__`/`__exit__` ở đây CHỈ nhận `self` (0 tham số khác), không có exception info truyền vào `__exit__`. Test mới `release/3.code/Testkit/context_manager_test.tkv` (5/5 PASS qua cây `.py`) — xác nhận thứ tự `enter`→thân→`exit`, dạng biến đã khai báo, `__enter__` trả kiểu khác record gốc, và `__exit__` vẫn chạy khi thân khối có `return` sớm. Case lỗi thiếu `__enter__`/`__exit__` xác nhận qua spike tạm (đã xoá sau khi xác nhận thông báo lỗi đúng). Đồng bộ mirror `.tkv` tự-host (`release/3.code/compiler/il_features/control_flow.tkv`) — KHÔNG rebuild `tkvc.exe`. Regression 53 file `Testkit/*.tkv` qua cây `.py` không đổi (3 build-fail pre-existing là file thư viện không có `run()`: `example_lib`/`import_lib_mod`/`tkv_test_lib`; `native_test_suite` build-fail pre-existing do lỗi ternary khác, không liên quan; `path_isfile_isdir_test` 3/4 và `input_py_tree_test` 0/2 là pre-existing đã biết — không phải regression từ task này). `with open(...) as f:` (test `test/sample_with_open.tkv`) xác nhận chạy đúng không đổi sau thay đổi.
- [x] 6.7 Iterator protocol tùy biến (`__iter__`/`__next__`) — ĐÃ XONG (2026-08-13), xem `docs/superpowers/plans/2026-08-13-iterator-protocol.md`. `for x in <biến_record_đã_khai_báo>:` (chỉ tên biến trần, không constructor call/biểu thức phức tạp) desugar thành stmt kind `for_in_iter` mới, hoàn toàn tách khỏi macro `for_in_list` (list/dict/set) và `try_parse_for`/`codegen_for` (`range(...)`) hiện có — không đụng cả hai. Codegen tái dùng khung nhãn/`ctx['loop_stack']` của `codegen_while` (không phải `codegen_for`, vì không có biến đếm), đọc kết quả `__next__` (trả `ValueTuple<T,i32>` — phần tử 2 là cờ "còn/hết") qua `ldfld Item1/Item2` y hệt mẫu `codegen_tuple_assign` (`tuple_type.py`). Record thiếu `__iter__`, hoặc kiểu trả về của `__iter__` thiếu `__next__`, hoặc `__next__` không đúng dạng `(T, i32)` → `SyntaxError` rõ (xác nhận bằng spike riêng, đã xoá sau khi xác nhận). Hỗ trợ `IterT` khác record gốc (record tách riêng giữ state lặp) và kế thừa (`_method_owner_class`). `break`/`continue` hoạt động đúng qua `ctx['loop_stack']` dùng chung.
  - **Sai lệch quan trọng so với plan gốc (phát hiện lúc code, không phải đoán)**: macro text-level `try_expand_for_in_list` (`_FOR_IN_LIST_RE`) khớp **BẤT KỲ** `for x in <tên>:` (không phân biệt list/dict/set/record — chạy TRƯỚC toàn bộ line-parser ở tầng macro-expansion, dựa thuần văn bản) và viết lại **VÔ ĐIỀU KIỆN** thành `for i in range(len(name)): x = name[i]` — nếu không chặn, mọi `for x in <record>:` sẽ bị macro này "cướp" trước khi line-parser `for_in_iter` mới kịp chạy, phá vỡ hoàn toàn tính năng (lỗi mơ hồ từ `len()`/index trên record thay vì thông báo `__iter__`/`__next__` rõ ràng). Plan gốc giả định macro chỉ đụng list/dict/set nhưng thực tế regex không phân biệt kiểu. Đã vá bằng cơ chế quét-trước tương tự `_known_dict_vars` có sẵn: thêm `_known_record_vars`/`set_known_record_vars` trong `control_flow.py` (và mirror `.tkv`), populate trong `_expand_macros` (`il_codegen.py`, thêm 2 tham số tuỳ chọn `records`/`sig`, mặc định `None` để không phá các điểm gọi cũ) từ (a) tham số hàm kiểu record, (b) local gán trực tiếp từ constructor record (`r = Res(...)`) — cả 3 điểm gọi `_expand_macros` (`gen_il_function`/`_gen_async_def`/`gen_il_generator_function`) đã cập nhật truyền `records=records, sig=sig`. `try_expand_for_in_list` giờ trả `None` (bỏ qua, nhường cho line-parser) khi container nằm trong `_known_record_vars`.
  - `codegen_for_in_iter` KHÔNG dùng `ctx['TypeAnn']` (khác gợi ý trong plan) — ctx của second-pass/codegen (khác first-pass) KHÔNG có key `'TypeAnn'` (xác nhận bằng lỗi `KeyError` thật lúc build), nên dùng thẳng `TypeAnn` import module-level (giống `codegen_with_ctx` không hề gọi `ctx['TypeAnn']`).
  - Giới hạn có ý thức (theo đúng ràng buộc plan): chỉ hỗ trợ biến record đã khai báo (không constructor call trực tiếp `for x in Foo():`, không biểu thức phức tạp `for x in a.b:`), không hỗ trợ nested attribute chain trong `__next__` body (giới hạn CHUNG của toàn bộ compiler — `obj.field` chỉ 1 tầng, không phải giới hạn riêng của 6.7).
  - Test mới `release/3.code/Testkit/iterator_protocol_test.tkv` (5/5 PASS qua cây `.py`): tổng bằng vòng lặp cơ bản, `IterT` khác record gốc (`Bag`→`BagIter`), `break`, `continue`, record con kế thừa `__iter__`/`__next__` từ cha không tự định nghĩa. 3 case lỗi (thiếu `__iter__`, `IterT` thiếu `__next__`, `__next__` sai chữ ký) xác nhận qua spike tạm trong scratchpad — đã xoá.
  - Đồng bộ mirror `.tkv` tự-host: `release/3.code/compiler/il_features/control_flow.tkv` + `release/3.code/compiler/il_codegen.tkv` — KHÔNG rebuild `tkvc.exe`.
  - Regression 54 file `Testkit/*.tkv` qua cây `.py` không đổi so với baseline đã biết (đối chiếu bằng `git stash` cô lập thay đổi rồi build lại `native_test_suite` — xác nhận build-fail đó là pre-existing, không liên quan): `example_lib`/`import_lib_mod`/`tkv_test_lib` build-fail pre-existing (file thư viện không có `run()`); `native_test_suite` build-fail pre-existing do lỗi ternary/yield khác (`from sub_numbers()`), không liên quan; `path_isfile_isdir_test` 3/4 và `input_py_tree_test` 0/2 pre-existing đã biết (phụ thuộc cwd/stdin khi chạy qua harness). Đặc biệt: mọi test dùng `for x in <list/dict/set>:` (macro `for_in_list` — `lambda_capture_test`, `random_shuffle_sample_py_tree_test`, `varargs_py_tree_test`) và `for x in range(...)` PASS y hệt trước; `break`/`continue` trong `while`/`for range` khác (dùng chung `ctx['loop_stack']`) không bị ảnh hưởng.
  - Hạ tầng này CÓ THỂ tái dùng cho `product()` (5.3, xem ghi chú ở mục A/5.3) trong 1 sub-project riêng SAU nếu cần — CHƯA tự động làm ở đây, chỉ mở khoá khả năng.
- [x] 6.8 `frozenset`/`bytes`/`bytearray`/`complex` — **XONG HOÀN TOÀN (4/4, 2026-08-13)**. `frozenset` XONG (1/4), `complex` XONG (2/4), `bytearray` XONG (3/4), `bytes` XONG (4/4, xem `docs/superpowers/plans/2026-08-13-bytes.md`).

  **`bytes` (4/4)**: `data = b"AB"` (literal ASCII, BẤT BIẾN) — tái dùng 100% hạ tầng `List<uint8>` của `bytearray` (shape mới `'bytes'`, `il_bytearray_type()` dùng chung) cho cả kiểu IL LẪN đọc (`index`/`len()`/`for-in`), CHỈ khác ở cách TẠO (unroll N giá trị hằng số biết trước lúc compile-time — `newobj` + N lần `dup`/`ldc.i4`/`conv.u1`/`Add(!0)`, KHÔNG vòng lặp runtime) và ở việc `.append()`/mutate BỊ CHẶN (`SyntaxError` bất biến). Token `BYTES` (`(?P<BYTES>b"(?:[^"\\]|\\.)*")`) thêm vào `_EXPR_TOKEN_RE` (`il_core.py`) **ĐẶT TRƯỚC** `STR` (xác nhận qua test tokenize thật: `b"AB"` → 1 token `BYTES`, không bị tách `ID('b')`+`STR`). AST node `('bytes_lit', v)` trong `_parse_factor_primary`.

  **Sai lệch so với kế hoạch gốc (phát hiện lúc Điều tra Step 1)**: plan đề xuất mở rộng `declare_scalar` (`il_codegen.py`, dòng ~2734) với 1 nhánh `bytes_lit`. Điều tra THẬT cho thấy `declare_scalar` CHỈ là fallback CUỐI CÙNG của đường gán biến (`_lp_assign`) — mọi container literal (`list_literal`, `bytearray()`) đi theo đường RIÊNG qua `ASSIGN_RHS_PARSERS`/`FIRST_PASS_WALK`/`STMT_CODEGEN` (đăng ký bởi `list_type.py`/`bytearray_type.py`), KHÔNG BAO GIỜ chạm `declare_scalar`. File mới `il_features/bytes_type.py` đi THEO ĐÚNG kiến trúc thật (giống hệt `bytearray_type.py`) thay vì thêm nhánh vào `declare_scalar` — `try_rhs_bytes_literal` đăng ký vào `ASSIGN_RHS_PARSERS`.

  Cũng KHÔNG có sẵn 1 hàm unescape `str_lit` riêng để tái dùng như plan giả định — `str_lit` (STR token) GIỮ NGUYÊN cả escape thô, chuyển THẲNG cho `ldstr` (IL tự giải mã escape lúc runtime), phía Python KHÔNG BAO GIỜ giải mã thành giá trị ký tự thật. Vì bytes cần GIÁ TRỊ BYTE THẬT (`ord()`) lúc compile-time, `bytes_type.py` tự viết 1 hàm unescape TỐI THIỂU (`\\`, `"`, `\n`, `\t`, `\r`, `\0`, `\xHH`) — ký tự bất kỳ (kể cả sau escape/`\xHH`) mã > 127 → `SyntaxError` rõ ("bytes literal chi ho tro ASCII").

  `.append()`/mutate trên `bytes` → line-parser mới `try_parse_bytes_append_blocked` (đăng ký TRƯỚC — nhưng thực ra không cần thứ tự, vì `try_parse_list_append` (`list_type.py`) đã được nới loại trừ `known_shapes in ('bytearray', 'bytes')` thay vì chỉ `'bytearray'`, và `try_parse_bytearray_append` vốn đã chỉ khớp `== 'bytearray'` nên tự động loại trừ `'bytes'`) nem `SyntaxError` bất biến rõ ràng NGAY tại parser, không rơi vào nhánh `bytearray.append` hợp lệ.

  Đọc (`il_type_str`, `_expr_index`, `len()` cả 2 nhánh — biểu thức và biến đơn) mở rộng `shape == 'bytearray'` → `shape in ('bytearray', 'bytes')` tại 4 điểm trong `il_codegen.py` (tái dùng 100%, không viết hàm đọc riêng). `for b in data:` — KHÔNG cần sửa gì thêm (macro `try_expand_for_in_list` thuần văn bản, tự động hoạt động qua `len()`/`index` đã mở rộng, giống hệt `bytearray`).

  Test mới `release/3.code/Testkit/bytes_test.tkv` (6/6 PASS): `len()==2`, `[0]==65`/`[1]==66`, `for b in data:` (tổng + đếm), `b""` rỗng → `len()==0`. Spike riêng (không lưu file): ký tự ASCII ngoài phạm vi (`\xff` = 255) → `SyntaxError` rõ; `.append()` trên biến `bytes` → `SyntaxError` bất biến rõ ("la kieu 'bytes' (bat bien...) - KHONG the .append()/mutate"). Đồng bộ mirror `.tkv` tự-host (`il_core.tkv`, `il_codegen.tkv`, `il_features/list_type.tkv`, `il_features/bytes_type.tkv` [mới]) — KHÔNG rebuild `tkvc.exe`. Regression toàn bộ `Testkit/*.tkv` hiện có (53 file `*_test.tkv`, kể cả file mới): TẤT CẢ COMPILE THÀNH CÔNG, 52/53 chạy PASS 100% test con — `input_py_tree_test` 0/2 PASS nhưng đây là do cần stdin thật (môi trường không có), KHÔNG liên quan đến thay đổi này. `bytearray_test` (6/6), `string_test`/`tkv_compile_test`/`list_test` (`test/verify/`, đối chiếu CPython thật) và `bytearray_remove_insert_guard_test` đều PASS y hệt trước — xác nhận thêm token `BYTES` KHÔNG phá tokenizer cho `"..."` thường.

  ~~`frozenset` (1/4)~~, xem `docs/superpowers/plans/2026-08-13-bytearray.md` cho lịch sử `bytearray`/`complex`/`frozenset`: `ba = bytearray()` (RỖNG) + `ba.append(x)` → `List<uint8>` (file mới `il_features/bytearray_type.py`, shape mới `'bytearray'` — KHÔNG tái dùng shape `'list'` vì `.append()` cần codegen RIÊNG: chèn `conv.u1` trước `Add(!0)` để narrow `i32`→byte thật trên stack, còn List<i32> của `list[i32]` không cần bước này). **Xác nhận Điều tra Step 1 (giả thuyết trong plan là ĐÚNG, đã kiểm chứng qua đọc code + build/chạy test thật, không chỉ tin lý thuyết)**: `_list_compile_index_list` (`list_type.py`) và nhánh `len()` của `list` trong `il_codegen.py` đều CHỈ dùng `ctx['il_type_str'](type_ann,...)` (đổi `List<i32>`→`List<uint8>` khi shape='bytearray') + `callvirt instance !0 ...::get_Item(int32)`/`get_Count()` — hoàn toàn tổng quát qua placeholder generic `!0`, KHÔNG hardcode `int32`. Nên: đọc (`index`/`len()`, cả 2 điểm — nhánh `_compile_len_of_expr` VÀ nhánh `len(<biến>)` riêng trong `_expr_call`) TÁI DÙNG NGUYÊN VẸN bằng cách mở `shape == 'list'` → `shape in ('list', 'bytearray')` tại 3 điểm trong `il_codegen.py`, KHÔNG viết hàm đọc riêng. `for b in ba:` — **KHÔNG cần sửa `control_flow.py`** (sai lệch so với plan gốc, phát hiện lúc điều tra: macro `for_in_list`/`try_expand_for_in_list` là thuần VĂN BẢN, viết lại `for x in <tên_biến>:` thành `for i in range(len(<tên>)): x = <tên>[i]` cho MỌI tên biến KHÔNG nằm trong `_known_dict_vars`/`_known_record_vars` — `frozenset` trước đó (`d47359d`) thực ra KHÔNG hề đụng file này, ghi chú trong plan "giống cách frozenset đã thêm ở task trước" không khớp thực tế; `bytearray` tự động rơi vào nhánh generic sẵn có, không cần đăng ký gì thêm). `.append(x)` — LINE_PARSERS entry mới `try_parse_bytearray_append` (`bytearray_type.py`) CHỈ khớp khi `known_shapes.get(name)=='bytearray'`; ĐỒNG THỜI phải sửa `try_parse_list_append` (`list_type.py`) loại trừ `known_shapes=='bytearray'` (giống hệt cách `try_parse_list_remove` loại trừ `set`/`frozenset`) — vì `list_type.py` được import/đăng ký TRƯỚC `bytearray_type.py` trong `il_codegen.py` (LINE_PARSERS thử theo thứ tự đăng ký), nếu không loại trừ thì `ba.append(x)` bị nhánh `list` "cướp" mất, compile ra `Add(!0)` KHÔNG có `conv.u1` (bug thật sẽ bị phát hiện muộn lúc chạy — `List<uint8>.Add` nhận `i32` thô là lỗi kiểu CIL). Constructor `bytearray()` khai báo local qua `declare_named` (KHÔNG cần suy dtype từ `.append()` đầu tiên như `declare_list`, vì phần tử LUÔN là 1 kiểu cố định). KHÔNG validate `0-255` lúc chạy — tràn (`.append(300)`) bị `conv.u1` CẮT ÂM THẦM còn `300 mod 256 = 44` — HÀNH VI CÓ Ý THỨC (đúng ngữ nghĩa CIL/`List<uint8>`), đã XÁC NHẬN qua test thật, không phải bug cần sửa. Test mới `release/3.code/Testkit/bytearray_test.tkv` (6/6 PASS): `len()`, `[0]`/`[1]` sau 2 lần `.append()`, `for b in ba:` (tổng + đếm), case tràn `.append(300)` đọc lại `44` (ghi rõ trong test là có ý thức). Đồng bộ mirror `.tkv` tự-host (`il_codegen.tkv`, `il_features/list_type.tkv`, `il_features/bytearray_type.tkv` [mới]) — KHÔNG rebuild `tkvc.exe`. Regression 56 file `Testkit/*.tkv` (bao gồm file mới): 52 PASS (kể cả toàn bộ test liên quan `list[i32]` — hành vi list KHÔNG đổi), 4 build-fail pre-existing KHÔNG liên quan (giống hệt trước: `example_lib`/`import_lib_mod`/`tkv_test_lib` là file thư viện không có `run()`; `native_test_suite` lỗi ternary/yield `from sub_numbers()` — đã xác nhận lỗi này tồn tại TRƯỚC cả khi áp code bytearray, qua `git stash`). `c = complex(re, im)` (2 tham số `f64`) → `System.Numerics.Complex` (struct BCL sẵn có, `.assembly extern System.Numerics` đã tồn tại không điều kiện, không cần sửa `tkv_compile.py`). Thêm `'complex'` vào `DTYPES` (`typed_dsl_parser.py`) và `IL_SCALAR['complex']` (file mới `il_features/complex_type.py`, đăng ký qua `register_expr_builtin` giống mẫu `divmod_builtin.py`). `+`/`-`/`*`/`/` giữa 2 `complex` → gọi thẳng static `Add`/`Subtract`/`Multiply`/`Divide` sẵn có trên BCL (không tự viết lại như `TkvInt`, vì `Complex` không có vấn đề tràn/đường-nhanh cần tối ưu). `.real`/`.imag`/`.magnitude` đọc qua `ctx['load_var_addr']` (tái dùng cơ chế đã có cho `dict_kvpair`'s `.key`/`.val`, KHÔNG hardcode tên slot IL). `str(c)`: vì `ToString()` là instance method trên value type cần ĐỊA CHỈ trong khi `emit_to_str` nhận GIÁ TRỊ đã nằm trên stack (giao ước chung, không có `scope`) — thêm 1 local nhập (`__tkvcplx_str`) khai báo VÔ ĐIỀU KIỆN trong mọi hàm (mirror `int_type.py`'s `SCRATCH_*`, xem `il_codegen.py`'s `_first_pass_collect_locals`) để "đổ" giá trị tạm vào rồi lấy địa chỉ. Test mới `release/3.code/Testkit/complex_test.tkv` (13/13 PASS): `.real`/`.imag`/`.magnitude` (tam giác 3-4-5), `+`/`-`/`*`/`/` verify qua `.real`/`.imag` (tính tay), `str(c)` không crash. Đồng bộ mirror `.tkv` tự-host (`typed_dsl_parser.tkv`, `il_codegen.tkv`, `il_features/complex_type.tkv` [mới], `il_features/operators.tkv`, `il_features/record_feature.tkv`, `il_features/tkvstr.tkv`, `il_features/string_builtin.tkv`) — KHÔNG rebuild `tkvc.exe`. `fs = frozenset(<biến_list_đơn>)` — chỉ nhận 1 biến list đơn đã khai báo/biết dtype TRƯỚC dòng đó trong văn bản nguồn (không rỗng, không biểu thức phức tạp) — tái dùng TOÀN BỘ hạ tầng `HashSet<T>` sẵn có của `set` (`il_set_type`), dựng qua ctor `HashSet<T>(IEnumerable<T>)` (xác nhận THẬT qua PowerShell reflection) nên phần tử trùng lặp trong list nguồn tự bị loại. Đọc (`in`, `len()`, thông báo lỗi index, `il_type_str`, `sum`/`min`/`max`/`sorted`/`any`/`all` qua `stdlib_aggregates.py`) mở rộng `shape == 'set'` → `shape in ('set', 'frozenset')` tại 5 điểm trong `il_codegen.py` + 3 điểm trong `stdlib_aggregates.py`. `.add()`/`.remove()`/`.discard()` trên `frozenset` → `SyntaxError` rõ ("la frozenset (bat bien) - khong the .<method>()") — case lỗi xác nhận qua spike riêng (đã xoá). **Sai lệch/bổ sung so với plan gốc (phát hiện lúc code)**: (1) line-parser `set_remove`/`set_discard` (`set_methods_batch2.py`) chỉ khởi động khi `known_shapes==  'set'` — phải nới thành `('set', 'frozenset')` để câu lệnh `.remove()`/`.discard()` trên `frozenset` được NHẬN DIỆN rồi mới chặn được ở codegen (không thì rơi vào nhánh khác im lặng); (2) `list_type.py`'s `try_parse_list_remove` loại trừ `known_shapes=='set'` để nhường `set.remove()` — phải nới thêm `'frozenset'`, nếu không `fs.remove(x)` bị "cướp" nhầm thành `list.remove()` và biên dịch/chạy được (bug thật phát hiện qua spike: `fs.remove(1)` compile OK trước khi vá, đúng ra phải báo lỗi bất biến); (3) đăng ký thêm `register_expr_method('frozenset', 'to_list', ...)` (dùng chung `compile_set_to_list`, `set_to_list.py`) vì `for x in fs:` cần đường `fs.to_list()` giống hệt `set` (registry khoá CHÍNH XÁC theo shape string, không tự suy rộng). Test mới `release/3.code/Testkit/frozenset_test.tkv` (4/4 PASS): dedup độ dài, `in` đúng/sai, `to_list()` + `for` tính tổng. Đồng bộ mirror `.tkv` tự-host (`set_type.tkv`, `set_methods_batch2.tkv`, `set_to_list.tkv`, `list_type.tkv`, `il_codegen.tkv`, `stdlib_aggregates.tkv`) — KHÔNG rebuild `tkvc.exe`. Regression 55 file `Testkit/*.tkv`: 51 PASS, 4 build-fail pre-existing không liên quan (`example_lib`/`import_lib_mod`/`tkv_test_lib` là file thư viện không có `run()`; `native_test_suite` lỗi ternary/yield khác `from sub_numbers()`) — `set_remove_error_test` (set thường) PASS y hệt trước.
- [x] 6.9 `except BuiltinType as e` không lấy được message — ĐÃ XONG (2026-08-12, xem mục 6.3 — port kèm khi làm bare `raise`, phát hiện `.tkv` tree đã có sẵn thiết kế này).
- [x] 6.10 MRO đa kế thừa dạng kim cương — ĐÃ XONG (2026-08-13, xem `docs/superpowers/plans/2026-08-13-mro-diamond-fix.md`; sửa lại 2026-08-13 sau code review — xem `docs/superpowers/specs/2026-08-13-mro-diamond-fix-design.md`). Bug XÁC NHẬN THẬT qua spike so sánh CPython thật: `class D(B1, B2):` khi B1 VÀ B2 cùng override 1 method trùng tên, CPython dùng bản B1 (base ĐẦU thắng theo MRO) nhưng TokenVector cũ lại dùng bản B2 (base CUỐI thắng — sai). Nguyên nhân: `_build_record_methods` (`tkv_compile.py`) vòng lặp `for sec in bases[1:]:` chỉ copy method RIÊNG từ base[1:] vào `record_methods_own[rname]`, bỏ sót hoàn toàn base[0] — base cuối "thắng" một cách tình cờ vì chỉ nó được copy chủ động. Sửa ĐÚNG theo plan gốc (fix 1 dòng): đổi thành `for sec in bases:` (duyệt CẢ base[0]), thân vòng lặp GIỮ NGUYÊN dùng `record_method_bodies.get(sec, [])` thô — KHÔNG cần hàm đệ quy bổ sung nào cho case 3 tầng đa-base. (Ghi chú review: một bản sửa tạm thời từng thêm hàm đệ quy `_resolve_effective_method_bodies` để "xử lý" case `GrandChild(Mid1, Mid2)` với `Mid1(Base1)` không override còn `Mid2(Base1)` có override, kèm test kỳ vọng sai `expected="base1-greet"` — đã XÁC NHẬN SAI bằng CPython 3.12 thật: `GrandChild().greet()` phải trả `"mid2-greet"` (C3 linearization đẩy tổ tiên chung `Base1` xuống SAU `Mid2`), không phải `"base1-greet"`. Spec đã minh thị loại trừ C3 linearization đầy đủ khỏi phạm vi task này. Hàm đệ quy đó đã bị GỠ BỎ khỏi `tkv_compile.py` VÀ mirror `release/3.code/tkv_compile.tkv` — fix 1 dòng đơn giản tự nhiên cho ra đúng kết quả `mid2-greet` cho case 3 tầng này, vì vòng lặp `for sec in bases:` với `sec=Mid1` không có method riêng nên bỏ qua, `sec=Mid2` có method riêng `greet` nên thắng — khớp CPython.) Test `three_tier_multi_base_propagation` trong `mro_diamond_test.tkv` đã sửa `expected` thành `"mid2-greet"`. Step 5 (`_method_owner_class`/`_field_owner_class`, `record_feature.py`): xác nhận KHÔNG cần sửa. Step 6 (field trùng tên đa-base, PHẠM VI PHỤ — chỉ điều tra, KHÔNG tự sửa): spike riêng (`BaseA.val: i32` + `BaseB.val: str` → `Combo(BaseA, BaseB)`) xác nhận đây là **sinh sai LẶNG LẼ** (không phải lỗi biên dịch rõ ràng) — compile qua trót lọt (ilasm chấp nhận IL sinh ra dù có field trùng tên `val` với 2 kiểu khác nhau trên cùng `.class Combo`), CHỈ crash lúc CHẠY THẬT với `System.MissingFieldException: Field not found: 'Combo.val'` (constructor chọn nhầm field). **ESCALATE — ĐÃ XỬ LÝ (2026-08-13, xem `docs/superpowers/plans/2026-08-13-multibase-field-collision.md`)**: đã thêm validate compile-time trong `_extract_record_def` (`tkv_compile.py` + mirror `release/3.code/tkv_compile.tkv`) — gộp field theo (tên, base sở hữu) qua toàn bộ `record_bases_found`, nếu cùng 1 tên field mà `f_tuple` (tên, dtype) KHÁC NHAU giữa các base độc lập → raise `TranspileError` rõ ràng ngay lúc compile, thay vì crash `MissingFieldException` lúc chạy. Field kim cương hợp lệ (2 base cùng 1 tổ tiên chung, field đến từ tổ tiên đó — `f_tuple` giống hệt nhau giữa các base) KHÔNG bị chặn nhầm — đã xác nhận qua test thật (`multibase_field_collision_test.tkv`, case `Duck(Flyer, Swimmer)` cùng kế thừa `name: str` từ `Animal`, build+chạy PASS). Case collision thật (`BaseA.val: i32` + `BaseB.val: str`) xác nhận raise đúng qua spike riêng. Regression: toàn bộ `Testkit/*.tkv` (kể cả `mro_diamond_test.tkv` 4/4 PASS) build+chạy sạch, không bị chặn nhầm. Test `release/3.code/Testkit/mro_diamond_test.tkv` (4/4 PASS): 2-base override trực tiếp (base đầu thắng), kim cương field/method KHÔNG trùng tên (regression, vẫn đúng), 3+ base cùng override (base đầu tiên luôn thắng), 3 tầng qua nhánh đa-base (`mid2-greet` đúng CPython). Đồng bộ mirror `.tkv` tự-host (`release/3.code/tkv_compile.tkv`) — KHÔNG rebuild `tkvc.exe`. Regression `inheritance_py_tree_test.tkv` (3/3 PASS), `typecheck_py_tree_test.tkv` (10/10 PASS) — sạch, không breakage.

## D. Đã xác nhận ĐÚNG (không phải gap)
- [x] `pickle_dump_i32/i64/f64/str` — CÓ (dict được populate qua vòng lặp, verify bằng grep)
- [x] ternary, `assert`, exception tự định nghĩa kế thừa, nhiều `except` đúng thứ tự, `finally`
- [x] `int` là arbitrary-precision thật (`TkvInt`), KHÔNG overflow âm thầm — chỉ `i32`/`i64` mới giới hạn
- [x] `tkvc.exe` đã tách kiến trúc core+plugin (2026-08-12, xem
  `docs/superpowers/plans/2026-08-12-tkvc-plugin-architecture.md`, 13
  task): `il_codegen.py`/`.tkv` không còn import cứng ~54 module thư
  viện, thay bằng `plugin_loader.load_plugins()` quét thư mục lúc chạy.
  `build_tkvc.ps1` chỉ đóng gói 12 module CORE vào `tkvc.exe`
  (7,769,825 → 7,527,651 bytes, giảm ~3.1% — mức giảm khiêm tốn vì
  PyInstaller vẫn tự truy vết import động), 75 module LIBRARY nạp động
  từ `dist/il_features/*.py` cạnh file exe. Regression toàn diện cuối
  cùng (Task 13): `.py` tree và `tkvc.exe` build lại từ chính nó cho
  kết quả GIỐNG HỆT nhau trên toàn bộ `Testkit/*.tkv` (32 file, trừ
  `path_isfile_isdir_test` 3/4 pre-existing không liên quan). Phát sinh
  + đã sửa trong quá trình: bug thứ tự nạp cross-import tĩnh giữa các
  module thư viện ở chế độ đóng gói (`plugin_loader.py` đổi sang 2-pass
  retry loader), và 1 bug trùng đăng ký `round()` giữa `float_builtin.tkv`/
  `stdlib_math.tkv` (chỉ tồn tại ở cây `.tkv` tự-host, đã xoá bản trùng).

## Thứ tự ưu tiên tổng hợp (A+B+C, theo mục tiêu tối thượng)
1. ~~Xác minh nhanh (không code): json duplicate, `str.join` 2 đường, `reduce()` arity, `set.remove()`, `divmod`~~ — XONG (2026-08-11): `json_get_str` xung đột thật đã sửa (đổi tên `cjson_*`), còn lại đều không phải gap thật (trừ `set.remove()` xác nhận là gap thật, ghi ở mục A).
2. ~~`global`~~ — XONG (2026-08-11).
3. ~~`*args`/`**kwargs`~~ — XONG MỘT PHẦN (2026-08-11, xem mục B 5.1) — `*args` dùng thật được, `**kwargs` chưa nhận giá trị thật do thiếu cú pháp keyword-call. Còn lại: multi-file module (6.2, ảnh hưởng rộng nhất tới mục tiêu) + cú pháp keyword-call cho **kwargs (nếu cần) + bare `raise`/`input()` (6.3/6.4).
3. ~~`raise` trần~~ — XONG MỘT PHẦN (2026-08-12, xem 6.3) — kèm 6.9 luôn.
4. ~~`input()`~~ — XONG (2026-08-12, xem 6.4).
5. ~~5.3 `itertools` biểu thức độc lập + `chain`~~ — XONG (2026-08-12, xem 5.3). `product()` bỏ (giới hạn kiến trúc macro, không phải thiếu sót nhỏ). Còn lại: Phase 5.4-5.5, 6.5-6.8, 6.10.
6. ~~`sum/min/max` variadic~~ — XONG (2026-08-12, xem mục A) — kèm 2 bug thật về khai báo dtype local ẩn `__ternN`/`__strtmp` (xem chi tiết ở mục A).
7. ~~`list.sort` key/reverse~~ — XONG (2026-08-12, xem mục A) — kèm 1 bug thật ở `_resolve_func_ta` dùng chung với `map`/`filter`/`reduce` (xem chi tiết ở mục A).
8. ~~`raise X from Y`~~ — XONG (2026-08-12, xem mục C/6.3).
9. ~~5.4 `sys.argv`/`sys.exit`~~ — XONG (2026-08-12, xem mục B). `sys.path` bỏ (không có ý nghĩa với .exe AOT-compile tĩnh).
10. ~~Concurrency thật (#3 Loại 2)~~ — XONG (2026-08-12, xem mục #3 ở trên; kiểm chứng qua cây `.py`, `tkvc.exe` rebuild là bước riêng do người dùng chủ động). ~~Debug PDB (#5 Loại 2)~~ — XONG (2026-08-12, xem mục #5 ở trên; regression toàn bộ `Testkit/*.tkv` cả 2 chế độ có/không `--debug` qua cây `.py`; `tkvc.exe` rebuild là bước riêng do người dùng chủ động).
11. Phần còn lại 5.5/6.5-6.10 theo thứ tự đã ghi ở Phase 5/6 gốc.
12. Package ecosystem (#1 Loại 2) — blocker lớn nhất, bắt đầu khi đã có đà từ các bước trên.
