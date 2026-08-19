# Duck-typing qua Type-Inference Tĩnh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho phép tham số hàm top-level KHÔNG khai annotation kiểu —
compiler tự suy "interface ẩn" từ cách dùng trực tiếp trong thân hàm
(field/method/toán tử), rồi tại mỗi call-site kiểm tra kiểu đối số thật có
thỏa mãn không, sinh 1 bản CIL riêng (monomorphization) cho mỗi tổ hợp
`(hàm, kiểu cụ thể)` — zero runtime cost, không interface .NET, không
reflection.

**Architecture:** 4 giai đoạn tuần tự trong pipeline biên dịch hiện có:
(1) nới lỏng parse chữ ký hàm top-level cho phép thiếu annotation
(`tkv_compile.py:97-160` `_params_with_defaults`/`_extract_signature_line`);
(2) pass mới quét thân hàm thu thập ràng buộc (field/method/toán tử) cho
mỗi tham số `dtype='inferred'`; (3) tại mỗi call-site (trong
`_expr_call`/first-pass hiện có), kiểm tra kiểu đối số thật thỏa ràng buộc,
tra/tạo cache `(func_name, tuple_kiểu_cụ_thể) -> tên_method_CIL_đã_sinh`;
(4) sinh bản CIL riêng bằng cách chạy LẠI pipeline compile hàm hiện có với
`dtype='inferred'` thay bằng kiểu cụ thể.

**Tech Stack:** Python (`ast` module cho parse top-level, tái dùng toàn bộ
hạ tầng codegen/dtype-inference hiện có của compiler — KHÔNG viết type
checker mới từ đầu).

## Global Constraints

- CHỈ hàm **top-level** (`ast.FunctionDef` không lồng `ast.ClassDef`,
  không nested-def) được phép thiếu annotation tham số. Method-trong-class
  và nested-def VẪN bắt buộc annotation như hiện tại — KHÔNG mở rộng.
- KHÔNG lan truyền suy kiểu xuyên lời gọi hàm/method khác (kể cả tự-đệ-quy)
  — tham số `inferred` truyền vào 1 lời gọi KHÁC là lỗi biên dịch RÕ RÀNG,
  không phải crash nội bộ.
- KHÔNG hỗ trợ index/slice, container ops (`in`/`len()`/`for...in`), gán
  lại rồi dùng biến thay thế trên tham số `inferred`.
- Toán tử: kiểu đối số PHẢI là scalar hỗ trợ toán tử đó tự nhiên, HOẶC
  record định nghĩa dunder tương ứng — TÁI DÙNG NGUYÊN cơ chế dunder có
  sẵn (6.5, `compiler/il_features/operators.py`), KHÔNG viết logic toán tử
  mới.
- Field/method required: TÁI DÙNG `_field_owner_class`/`_method_owner_class`
  (`compiler/il_features/record_feature.py`) để hỗ trợ kế thừa — KHÔNG
  viết lại logic resolve owner.
- Return type hàm VẪN phải khai tường minh — không đổi.
- Cache `(func_name, tuple kiểu cụ thể)` PHẢI tránh sinh trùng bản CIL khi
  nhiều call-site cùng tổ hợp kiểu.
- Cả 2 cây `tkv_compile.py`/`.tkv`, `compiler/il_codegen.py`/`.tkv` sửa
  đồng bộ. KHÔNG rebuild `release/3.code/dist/tkvc.exe`.

---

### Task 1: Điều tra — pipeline compile hàm, điểm chèn monomorphization, tương tác `syntax_baseline.py`

**Files:**
- Create: báo cáo điều tra `.superpowers/sdd/task-1-report.md` (READ-ONLY).
- Read: `tkv_compile.py` (dòng 97-170 `_params_with_defaults`/
  `_extract_signature_line`, và TOÀN BỘ đoạn `compile_tkv_cli` xử lý
  `pairs`/gọi `gen_il_program` — tìm chính xác nơi mỗi hàm top-level được
  biên dịch thành CIL, để biết điểm chèn "biên dịch thêm 1 bản
  monomorphize"), `compiler/il_codegen.py` (`gen_il_function` dòng ~3734,
  và `_expr_call` — nơi 1 lời gọi hàm được biên dịch, để biết điểm chèn
  "tra cache monomorphize, phát sinh bản mới nếu cần TRƯỚC KHI emit lời
  gọi"), `compiler/il_features/record_feature.py`
  (`_field_owner_class`/`_method_owner_class`, dòng 42/81), `compiler/
  il_features/operators.py` (cơ chế dunder `__add__`/so sánh `__eq__`, đối
  chiếu cách `compile_binop`/`compile_compare` hiện tại dispatch dunder),
  `compiler/syntax_baseline.py` (whitelist hiện có — XÁC NHẬN tham số
  thiếu annotation có đang bị linter coi là lỗi cú pháp hay không, và nếu
  có thì đúng chỗ nào).

**Interfaces:**
- Produces: báo cáo gồm (1) dòng thật của mọi điểm parse/validate chữ ký
  hàm; (2) mô tả CHÍNH XÁC cấu trúc dữ liệu `pairs`/`sig_body_pairs` dùng
  xuyên suốt `compile_tkv_cli` (tuple gồm những gì, tại sao); (3) điểm
  CHÍNH XÁC trong `_expr_call` nơi 1 lời gọi hàm được biên dịch (để biết
  chèn logic "nếu hàm này có tham số inferred, resolve/monomorphize
  TRƯỚC"); (4) xác nhận `syntax_baseline.py` CÓ chặn tham số thiếu
  annotation ở top-level hay không (nếu Task 1's báo cáo cũ của plan
  `syntax-baseline-linter` không phủ trường hợp này — tìm bằng cách đọc
  code thật, KHÔNG suy đoán); (5) đề xuất CỤ THỂ tên hàm/module mới cần
  viết cho Task 2-4 (không bắt buộc theo đúng tên trong plan này nếu tên
  khác hợp lý hơn, nhưng phải NHẤT QUÁN xuyên các Task sau).

- [ ] **Step 1: Đọc `_params_with_defaults`/`_extract_signature_line`
      (`tkv_compile.py:97-170`)** — xác nhận CHÍNH XÁC logic raise lỗi
      thiếu annotation, và cách phân biệt hàm top-level vs method-trong-
      class vs nested-def được gọi từ đâu (3 điểm gọi khác nhau — dòng
      128/320/379/472/1178 theo grep sơ bộ, xác nhận lại số dòng thật và
      NGỮ CẢNH gọi của từng điểm, để biết CHÍNH XÁC điểm nào là "hàm
      top-level" cần nới lỏng, điểm nào PHẢI giữ nguyên bắt buộc
      annotation).

- [ ] **Step 2: Đọc `compile_tkv_cli` toàn bộ đoạn xử lý `pairs`** — mô tả
      cấu trúc `pairs` (list tuple gì), cách mỗi phần tử được biên dịch
      qua `gen_il_function`, và cách kết quả (`method_lines`) được ghép
      vào `il_text` cuối cùng — đây là chỗ Task 4 cần chèn thêm logic
      "với mỗi bản monomorphize đã cache, cũng sinh `method_lines` tương
      ứng và ghép vào".

- [ ] **Step 3: Đọc `_expr_call` (`il_codegen.py`)** — mô tả luồng hiện
      tại: tra `func_table` (hàm user-defined) → biết sig/dtype trả về →
      emit `call`. Xác nhận CHÍNH XÁC nơi có thể chèn: "nếu hàm được gọi
      có tham số `inferred`, trước khi emit `call`, resolve kiểu đối số
      thật tại điểm gọi này (đã có sẵn qua `_infer_dtype` hiện có), kiểm
      tra ràng buộc, tra/tạo bản monomorphize, emit `call` tới TÊN
      method đã mangle của bản đó thay vì tên gốc".

- [ ] **Step 4: Đọc dunder mechanism** (`operators.py::compile_binop`/
      `compile_compare`) — xác nhận CHÍNH XÁC cách hiện tại kiểm tra
      "record có `__add__`/`__eq__` hay không" (dùng `record_methods`
      dict nào, qua hàm nào) — để Task 3 tái dùng ĐÚNG cùng cơ chế khi
      kiểm tra ràng buộc toán tử lúc collect + lúc resolve call-site.

- [ ] **Step 5: Đọc `syntax_baseline.py`** — grep tìm chỗ liên quan tới
      annotation tham số hàm (nếu có) — xác nhận linter KHÔNG/CÓ chặn cú
      pháp `def f(x):` (thiếu annotation) ở top-level. Nếu CÓ chặn, ghi rõ
      để Task 2 biết cần nới whitelist linter luôn (giống bài học từ
      `extern_pinvoke` Task 2 — quên nới whitelist linter cho pragma mới,
      phát hiện và sửa kịp lúc).

- [ ] **Step 6: Viết báo cáo hoàn chỉnh** theo format mục "Interfaces".

---

### Task 2: Parse — cho phép tham số hàm top-level thiếu annotation

**Files:**
- Modify: `tkv_compile.py`, mirror `.tkv`.
- Modify: `compiler/syntax_baseline.py`, mirror `.tkv` (NẾU Task 1 xác
  nhận cần).

**Interfaces:**
- Consumes: báo cáo Task 1.
- Produces: `Signature`/cấu trúc chữ ký hàm (đọc lại tên kiểu dữ liệu
  thật dùng trong codebase, có thể là namedtuple/dataclass `Signature`
  nhắc tới ở `gen_il_function(sig: Signature, ...)`) mang thêm thông tin
  "tham số nào là `inferred`" — Task 3/4 tiêu thụ trực tiếp.

- [ ] **Step 1: Sửa `_params_with_defaults`** — thêm tham số `allow_inferred`
      (mặc định `False`, giữ nguyên hành vi hiện tại cho mọi điểm gọi
      KHÁC). Khi `allow_inferred=True` VÀ `a.annotation is None`: KHÔNG
      raise lỗi — thay vào đó gán dtype đặc biệt (hằng số mới, vd
      `INFERRED_DTYPE_MARKER = 'inferred'`, đặt ở module-level gần
      `_EXTERN_DTYPE_TO_IL` hoặc vị trí Task 1 đề xuất) cho tham số đó.

- [ ] **Step 2: Sửa lời gọi `_params_with_defaults` TỪ `_extract_signature_line`
      (hàm top-level, dòng ~128 theo Task 1 xác nhận lại)** — truyền
      `allow_inferred=True`. TẤT CẢ lời gọi KHÁC (method-trong-class,
      nested-def — dòng 320/379/472 theo Task 1 xác nhận) GIỮ NGUYÊN
      `allow_inferred=False` (mặc định, không cần sửa).

- [ ] **Step 3: Đảm bảo cấu trúc `Signature`/tuple chữ ký hàm mang được
      thông tin dtype `'inferred'` xuyên suốt pipeline hiện có** — đọc lại
      `Signature` (hoặc cấu trúc tương đương) để xác nhận nó CHỈ CẦN lưu
      dtype string như bình thường (không cần trường mới, vì `'inferred'`
      chỉ là 1 giá trị dtype đặc biệt trong cùng field hiện có) — NẾU cần
      sửa thêm để không vỡ chỗ khác (vd `il_type_str('inferred', ...)`
      raise lỗi vì không nhận diện được), XÁC NHẬN qua build thử (Step 5)
      chứ không sửa phòng thủ trước khi thấy lỗi thật.

- [ ] **Step 4: NẾU Task 1 xác nhận `syntax_baseline.py` chặn cú pháp
      thiếu annotation ở top-level** — nới whitelist ĐÚNG chỗ (đọc lại
      code thật để biết sửa `visit_XXX` nào, không đoán).

- [ ] **Step 5: Build test — viết 1 hàm top-level thiếu annotation 1 tham
      số** (file `.tkv` tạm, KHÔNG commit), chạy `tkv.py build` — xác
      nhận KHÔNG còn báo lỗi "thieu annotation" (sẽ dừng ở lỗi KHÁC vì
      Task 3/4 chưa xử lý usage — CHẤP NHẬN ĐƯỢC, miễn không phải lỗi
      parse chữ ký).

- [ ] **Step 6: Chạy 2-3 test cũ xác nhận không regression. Commit.**

```bash
git add tkv_compile.py release/3.code/tkv_compile.tkv
git commit -m "feat(compiler): cho phep tham so ham top-level thieu annotation (Task 2/5, duck-typing-inference)"
```

---

### Task 3: Thu thập ràng buộc ("interface ẩn") từ thân hàm

**Files:**
- Create: `compiler/il_features/duck_typing_infer.py` (hoặc tên Task 1
  đề xuất — GIỮ NHẤT QUÁN với báo cáo).
- Modify: mirror `.tkv` tương ứng.

**Interfaces:**
- Consumes: chữ ký hàm mang dtype `'inferred'` (Task 2), AST/text thân
  hàm (đọc lại CHÍNH XÁC cấu trúc `body_lines`/AST node thân hàm dùng ở
  đâu trong pipeline — line-parser dựa regex theo kiến trúc đã biết từ
  Task 1 của `syntax-baseline-linter`, KHÔNG phải `ast.expr` chuẩn bên
  trong thân hàm).
- Produces: hàm `collect_inferred_constraints(func_node_or_body, param_names)
  -> dict[param_name, Constraint]` — `Constraint` gồm ít nhất: `fields:
  set[str]`, `methods: dict[str, int]` (tên → arity), `operators:
  set[str]` (tên toán tử, vd `'+'`/`'=='`). Task 4 tiêu thụ dict này.

- [ ] **Step 1: Viết dataclass/namedtuple `InferredConstraint`** — 3
      trường `fields`/`methods`/`operators` như mô tả ở "Interfaces".

- [ ] **Step 2: Viết `collect_inferred_constraints`** — quét CÁC DÒNG
      trong thân hàm (dùng CHÍNH XÁC cơ chế duyệt Task 1 xác nhận — có
      thể cần parse lại biểu thức từng dòng qua `_tokenize_expr`/
      `_ExprParser` của `il_core.py`, KHÔNG phải `ast` chuẩn), với MỖI
      tham số `inferred`: tìm mọi node dạng `('attr', ('name', param), field)`
      (đọc cấu trúc node tuple THẬT của `_ExprParser` — tên chính xác của
      shape này, KHÔNG đoán, đối chiếu báo cáo Task 1 của plan
      `syntax-baseline-linter` cũ đã có sẵn về cấu trúc node `il_core.py`
      nếu còn giữ được, hoặc đọc lại trực tiếp `il_core.py::_ExprParser`)
      → thêm vào `fields`; `('method_call', ('name', param), method, args)`
      → thêm vào `methods` với arity; `('binop', op, ('name', param), other)`
      HOẶC `('binop', op, other, ('name', param))` → thêm `op` vào
      `operators`. NẾU gặp `('name', param)` xuất hiện trong 1 node KHÔNG
      thuộc 3 shape trên (vd làm argument của `('call', ...)` khác) → raise
      `TranspileError` NGAY LẬP TỨC tại bước collect (đúng thiết kế "không
      lan truyền").

- [ ] **Step 3: Build test — viết 3 file `.tkv` tạm (không commit)**: 1
      dùng `.field`, 1 dùng `.method()`, 1 dùng toán tử `+` — gọi trực
      tiếp `collect_inferred_constraints` qua Python script nhỏ (không
      qua toàn bộ pipeline `tkv.py build`, vì Task 4 chưa nối) để xác nhận
      kết quả `InferredConstraint` đúng.

- [ ] **Step 4: Build test case LỖI** — 1 file dùng tham số `inferred`
      truyền vào lời gọi hàm khác — xác nhận `collect_inferred_constraints`
      raise lỗi đúng như thiết kế.

- [ ] **Step 5: Đồng bộ mirror `.tkv`. Commit.**

```bash
git commit -m "feat(compiler): thu thap rang buoc interface an tu than ham (Task 3/5, duck-typing-inference)"
```

---

### Task 4: Resolve call-site + monomorphization + cache + tích hợp codegen

**Files:**
- Modify: `compiler/il_codegen.py` (`_expr_call`), `tkv_compile.py`
  (`compile_tkv_cli`), mirror `.tkv` cả 2.

**Interfaces:**
- Consumes: `InferredConstraint` dict (Task 3), `_field_owner_class`/
  `_method_owner_class` (có sẵn), cơ chế dunder có sẵn (`operators.py`).
- Produces: cache `(func_name, tuple_kiểu_cụ_thể) -> mangled_method_name`
  dùng chung xuyên `compile_tkv_cli` (1 lượt compile) — Task 4 chịu trách
  nhiệm khởi tạo/dọn cache đúng vòng đời (KHÔNG rò rỉ process-global giữa
  2 lần gọi `compile_tkv_cli` liên tiếp — áp dụng ĐÚNG bài học từ
  `__tkv_extern_method__`/`__tkv_extern_pinvoke__`, dù cache này có thể
  là biến LOCAL trong `compile_tkv_cli` thay vì module-level dict như 2
  tính năng kia, nếu kiến trúc hàm cho phép — XÁC NHẬN lúc implement,
  ưu tiên biến cục bộ nếu khả thi để TỰ ĐỘNG không rò rỉ, không cần
  `finally`-pop thủ công).

- [ ] **Step 1: Viết hàm `_resolve_inferred_call(func_name, concrete_arg_types,
      constraints, ctx)` trong `il_codegen.py` (hoặc module mới Task 1 đề
      xuất)** — với mỗi tham số `inferred` tương ứng 1 kiểu cụ thể trong
      `concrete_arg_types`: kiểm tra `constraints[param].fields` ⊆ field
      của kiểu đó (qua `_field_owner_class`); `constraints[param].methods`
      ⊆ method của kiểu đó ĐÚNG arity (qua `_method_owner_class`);
      `constraints[param].operators` — mỗi toán tử: kiểu là scalar hỗ trợ
      TỰ NHIÊN (tra bảng toán tử scalar có sẵn) HOẶC record có dunder
      tương ứng (tra `record_methods` giống cách `compile_binop` làm, xác
      nhận đúng theo Task 1). MỘT ràng buộc không thỏa → raise
      `TranspileError` liệt kê đủ thông tin (tên hàm/tham số/ràng buộc
      thiếu/vị trí định nghĩa VÀ vị trí gọi — `ctx` cần mang đủ 2 vị trí
      này, xác nhận cách lấy vị trí gọi hiện tại trong `_expr_call`).

- [ ] **Step 2: Viết cơ chế mangle tên** — `f'{func_name}__T{"_".join(concrete_arg_types)}'`
      (hoặc quy tắc Task 1 đề xuất) — đủ để tránh trùng tên với hàm người
      dùng khác (kiểm tra bằng cách thêm 1 ký tự không hợp lệ trong tên
      hàm DSL thật, vd `__`, để tránh người dùng tự đặt tên trùng — xác
      nhận DSL có cho phép `__` trong tên hàm hay không, nếu có cần tiền
      tố/hậu tố khác đảm bảo an toàn hơn).

- [ ] **Step 3: Chèn logic vào `_expr_call`** — TRƯỚC khi emit `call`
      hiện có: nếu tên hàm được gọi có trong bảng "hàm có tham số
      inferred" (populate từ Task 2/3's kết quả, truyền qua `ctx` hoặc
      biến toàn cục tương tự `func_table`), gọi `_resolve_inferred_call`,
      tra cache theo `(func_name, concrete_arg_types)` — CÓ trong cache
      thì dùng tên đã mangle, CHƯA CÓ thì: (a) thêm vào cache NGAY (tránh
      đệ quy vô hạn nếu hàm gọi chính nó — dù thiết kế đã CHẶN truyền
      tham số inferred vào lời gọi khác kể cả tự-đệ-quy ở Task 3, vẫn nên
      có guard phòng thủ ở đây); (b) biên dịch 1 bản CIL MỚI bằng cách
      gọi LẠI `gen_il_function` với chữ ký đã thay `'inferred'` bằng kiểu
      cụ thể (tái dùng pipeline hiện có, KHÔNG viết codegen riêng); (c)
      lưu `method_lines` sinh ra vào 1 danh sách tích lũy (Task 1's Step 2
      xác nhận cách `pairs`'s `method_lines` được ghép vào `il_text` cuối
      — bản monomorphize PHẢI ghép vào ĐÚNG CÙNG vị trí đó); (d) emit
      `call` tới tên đã mangle.

- [ ] **Step 4: Ghép các bản monomorphize đã tích lũy vào `il_text`
      trong `compile_tkv_cli`** — ĐÚNG vị trí Task 1's Step 2 xác nhận
      (cùng khu vực `method_lines` của `pairs` gốc).

- [ ] **Step 5: Build test end-to-end đầu tiên** — hàm top-level nhận 1
      tham số inferred dùng `.field`, gọi với 1 record thật, build+chạy
      qua `tkv.py build` — xác nhận output đúng.

- [ ] **Step 6: Build test 2 kiểu khác nhau cùng 1 hàm** — xác nhận sinh
      2 bản CIL riêng (đếm `.method` trong `.il` sinh ra), cả 2 chạy đúng.

- [ ] **Step 7: Build test cache — gọi CÙNG hàm CÙNG kiểu ở 2 call-site**
      — xác nhận CHỈ 1 bản CIL (không sinh trùng).

- [ ] **Step 8: Build test lỗi — kiểu thiếu field/method/toán tử cần
      thiết** — xác nhận `TranspileError` rõ ràng, không crash nội bộ.

- [ ] **Step 9: Đồng bộ mirror `.tkv` cho `il_codegen.py`/`tkv_compile.py`.
      Commit.**

```bash
git commit -m "feat(compiler): monomorphization + resolve call-site cho tham so inferred (Task 4/5, duck-typing-inference)"
```

---

### Task 5: Test + regression + docs + commit

**Files:**
- Create: `test/sample_duck_typing.tkv`, `test/verify/duck_typing_infer_test.py`.
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`.

**Interfaces:**
- Consumes: toàn bộ Task 1-4.

- [ ] **Step 1: Test tích cực field** — hàm top-level nhận tham số
      inferred dùng `.field`, gọi với 2 record KHÁC NHAU không kế thừa
      chung cùng có field đó — build+chạy, so sánh output với 1 kịch bản
      Python thuần tương đương (mô phỏng semantics).

- [ ] **Step 2: Test tích cực method** — tương tự với `.method()`.

- [ ] **Step 3: Test tích cực toán tử** — hàm `def add_them(a, b): return a + b`
      gọi với `(i32, i32)` VÀ `(RecordCóDunderAdd, RecordCóDunderAdd)` —
      qua CÙNG 1 định nghĩa nguồn, cả 2 kiểu compile+chạy đúng.

- [ ] **Step 4: Test kế thừa** — field/method required nằm ở LỚP CHA của
      record truyền vào — xác nhận vẫn thỏa mãn.

- [ ] **Step 5: Test lỗi ràng buộc** — kiểu thiếu field/method/toán tử →
      `TranspileError` đúng, kiểm tra message chứa đủ thông tin.

- [ ] **Step 6: Test giới hạn "không lan truyền"** — tham số inferred
      truyền tiếp vào hàm khác → lỗi biên dịch đúng thiết kế.

- [ ] **Step 7: Test cache** — đếm số `.method` trong `.il` sinh ra để
      xác nhận không sinh trùng khi nhiều call-site cùng kiểu.

- [ ] **Step 8: Regression toàn bộ test suite hiện có** — đặc biệt mọi
      hàm CÓ khai annotation tường minh vẫn hoạt động y hệt (không bị
      ảnh hưởng bởi thay đổi `_params_with_defaults`/`_expr_call`).

- [ ] **Step 9: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`'s mục "#2
      eval/exec/metaclass/duck-typing"** — đánh dấu phần duck-typing ĐÃ
      XONG (monomorphization qua type-inference tĩnh, KHÔNG phải duck-
      typing runtime đầy đủ), liệt kê rõ phạm vi CHƯA làm (lan truyền qua
      lời gọi khác, index/slice, method-trong-class/nested-def, container
      ops) — `eval`/`exec` VẪN non-goal vĩnh viễn, monkey-patch/metaclass
      VẪN chưa làm (sub-project riêng).

- [ ] **Step 10: Commit.**

```bash
git commit -m "feat(compiler): duck-typing qua type-inference tinh - monomorphization tham so ham top-level khong annotation (#2 phan 1/2)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
