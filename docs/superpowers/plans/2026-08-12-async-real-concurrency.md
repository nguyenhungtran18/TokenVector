# Async Real Concurrency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `async def` (top-level function AND record method) chạy THẬT song
song trên ThreadPool qua `Task.Factory.StartNew<T>`, thay cho vỏ đồng bộ hiện
tại (`Task.FromResult`). `await` giữ nguyên (blocking join thật trên Task
thật).

**Architecture:** Port `threading_feature.py` (thread_spawn/join/sleep) từ cây
`.tkv` sang cây `.py` (gap thật, chép nguyên văn). Tái cấu trúc
`gen_il_function` trong `il_codegen.py`: khi `sig.is_async` là `True`, KHÔNG
còn parse+codegen thân hàm trực tiếp vào chính method đó nữa — thay vào đó
sinh 1 class closure `{name}__AsyncBody` (field = self + mọi tham số, TÁI
DÙNG `_gen_closure_class_il` đã có sẵn cho nested-def) chứa method
`Invoke()->T` (thân hàm THẬT, không bọc Task). Method public `{name}(...)`
trở thành 1 wrapper mỏng: dựng closure instance, bind `Func<T>` qua
`ldftn`+`newobj`, gọi `TaskFactory.StartNew<T>(Func<T>)`, `ret`.

**Tech Stack:** Python 3 (compiler), CIL text lắp ráp qua `ilasm.exe`
(`.NET Framework mscorlib v4.0.30319` — KHÔNG có `Task.Run`, dùng
`Task.Factory.StartNew`).

## Global Constraints

- Sửa CẢ 2 cây (`compiler/` gốc VÀ `release/3.code/compiler/`, đuôi `.tkv`)
  đồng bộ, đúng tiền lệ dự án — KHÔNG chỉ sửa 1 cây.
- Dùng `Task.Factory.StartNew<T>(Func<T>)`, KHÔNG dùng `Task.Run<T>()` —
  `ilasm.exe` của project lắp ráp đối với mscorlib v4.0.30319, chưa có
  `Task.Run` (chỉ có từ .NET 4.5). Đã xác nhận thật trong
  `threading_feature.tkv`'s `compile_thread_spawn`.
- Phạm vi: top-level `async def` VÀ record method `async def self`. KHÔNG
  hỗ trợ nested `async def`.
- `await` (`compiler/il_features/async_await.py`) KHÔNG đổi — vẫn
  `callvirt instance !0 class Task\`1<T>::get_Result()`.
- Mọi thay đổi codegen phải xác nhận qua build+chạy THẬT (`python tkv.py
  build ... && ./out.exe`), không chỉ đọc code — theo đúng kỷ luật dự án
  ("KHÔNG giả định, xác minh qua ilasm.exe/reflection thật").
- Spec đầy đủ: `docs/superpowers/specs/2026-08-12-async-real-concurrency-design.md`.
- **NHỚ (đừng quên lại)**: `release/3.code/dist/tkvc.exe` đã tách kiến trúc
  core+plugin (2026-08-12, xem `release/3.code/build_tkvc.ps1` dòng 1-15 +
  `docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md`) —
  bản thân `tkvc.exe` CHỈ chứa 12 module CORE, ~75 module LIBRARY nạp ĐỘNG
  từ `dist/il_features/*.py` cạnh file exe, CHỈ khi `tkvc.exe` biên dịch 1
  chương trình `.tkv` của người dùng (không phải lúc build chính `tkvc.exe`).
  Theo yêu cầu người dùng (2026-08-12): **Task 4 của plan này KHÔNG rebuild
  `tkvc.exe`** — chỉ regression qua cây `.py` (`python tkv.py build`), không
  chạy `build_tkvc.ps1`. Lưu ý: `TokenVector/build_tkvc.ps1` (thư mục gốc,
  KHÁC `release/3.code/build_tkvc.ps1`) vẫn là bản CŨ, monolithic
  (`--collect-submodules il_features`), CHƯA được áp dụng phần tách
  core+plugin này — 2 file `build_tkvc.ps1` là 2 script độc lập, đừng nhầm.

---

### Task 0: Port `threading_feature.py` (thread_spawn/thread_join/thread_sleep) sang cây `.py`

**Files:**
- Create: `compiler/il_features/threading_feature.py`
- Reference (đọc, KHÔNG sửa): `release/3.code/compiler/il_features/threading_feature.tkv`
- Test: `release/3.code/Testkit/threading_feature_py_tree_test.tkv` (mới)

**Interfaces:**
- Produces: `thread_spawn(fn_name)` (expr builtin, dtype `'thread'`),
  `thread_join(thread_var)` (expr builtin, dtype mặc định `'i64'`),
  `thread_sleep(ms)` (expr builtin, dtype `'i32'`) — dùng lại ở Task 3 cho
  test đo thời gian song song.

- [ ] **Step 1: Chép nguyên văn nội dung `.tkv` sang file `.py` mới**

Đọc toàn bộ `release/3.code/compiler/il_features/threading_feature.tkv`
(85 dòng, đã xem ở spec — 3 hàm `compile_thread_spawn`/`compile_thread_join`/
`compile_thread_sleep`, dùng `Task.Factory.StartNew<T>` KHÔNG phải
`Task.Run`). Ghi y hệt nội dung đó vào `compiler/il_features/threading_feature.py`
(không đổi 1 dòng code — chỉ là chép nguyên văn qua biên giới `.tkv`/`.py`,
2 cây dùng chung cú pháp Python).

- [ ] **Step 2: Viết test build+run xác nhận `thread_spawn`/`thread_join`/`thread_sleep` chạy đúng qua cây `.py`**

Tạo `release/3.code/Testkit/threading_feature_py_tree_test.tkv`:

```python
def worker_task() -> "i64":
    total: "i64" = 0
    for i in range(1000000):
        total = total + i
    return total


def check(name: "str", got: "str", want: "str") -> "i32":
    if got == want:
        print("PASS " + name)
        return 1
    print("FAIL " + name + " got=" + got + " want=" + want)
    return 0


def run() -> "i32":
    tested: "i32" = 0
    total: "i32" = 0

    t1 = thread_spawn(worker_task)
    t2 = thread_spawn(worker_task)
    r1 = thread_join(t1)
    r2 = thread_join(t2)
    tested = tested + 1
    total = total + check("thread_join_value", str(r1 + r2), "999999000000")

    before: "i32" = thread_sleep(10)
    tested = tested + 1
    total = total + check("thread_sleep_returns_0", str(before), "0")

    print("SUMMARY " + str(total) + "/" + str(tested))
    return 0
```

Chạy: `cd "D:\Claude AI Project\TokenVector" && python tkv.py build release/3.code/Testkit/threading_feature_py_tree_test.tkv --entry run --out /tmp/t0_test.exe`

Expected: build PASS, `/tmp/t0_test.exe` in ra `SUMMARY 2/2`.

- [ ] **Step 3: Đăng ký test vào Testkit suite (nếu suite có 1 file danh sách trung tâm) hoặc để độc lập trong `Testkit/`**

Xác nhận file mới nằm trong `Testkit/*.tkv` (glob tự động của mọi script
regression trong dự án quét theo pattern này, xem
`.superpowers/sdd/task-13-brief.md` Step 1/2 — không cần đăng ký thủ công ở
đâu khác).

- [ ] **Step 4: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/threading_feature.py release/3.code/Testkit/threading_feature_py_tree_test.tkv
git commit -m "feat(compiler): port threading_feature (thread_spawn/join/sleep) tu cay .tkv sang .py

Gap thuc su - cay .py hoan toan chua co thread_spawn/thread_join/
thread_sleep, cay .tkv da co san (Moc 22, 2026-08-09), dung
Task.Factory.StartNew<T> (khong phai Task.Run - ilasm.exe target
mscorlib v4.0 chua co Task.Run). Chep nguyen van, khong doi API/hanh vi.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 1: Xóa nhánh `is_async` cũ trong `codegen_return` (dọn đường cho Task 2)

**Files:**
- Modify: `compiler/il_features/control_flow.py:893-926` (hàm `codegen_return`)
- Modify: `release/3.code/compiler/il_features/control_flow.tkv` (đoạn tương ứng)

**Interfaces:**
- Consumes: không còn gì — hàm `Invoke()`/thân async (Task 2) sẽ LUÔN chạy
  qua `codegen_return` với `ctx.get('is_async')` là `False` (vì `is_async_fn`
  chỉ áp cho method public wrapper, KHÔNG áp cho `Invoke()` — xem Task 2).
- Produces: `codegen_return` không còn phụ thuộc `ctx['is_async']` — hàm nào
  cũng trả `T` thô, không bọc `Task.FromResult`.

- [ ] **Step 1: Xóa 2 khối `if ctx.get('is_async'):` trong `codegen_return`**

Mở `compiler/il_features/control_flow.py`, hàm `codegen_return` (dòng
893-926 theo bản hiện tại). Thay toàn bộ hàm bằng:

```python
def codegen_return(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    compile_expr, store_var = ctx['compile_expr'], ctx['store_var']
    if sig.return_type is None:
        raise SyntaxError(
            f"il_codegen: ham '{sig.name}' khong khai bao return type (vd thieu "
            f"'-> f32') nhung than ham co 'return {stmt['expr_text']}' - CIL khong "
            f"cho phep 'ret' mang gia tri tu ham void. Them '-> <type>' vao chu ky.")
    if ctx.get('try_depth', 0) > 0:
        compile_expr(stmt['expr_node'], scope, body, body_dtype, ctx)
        store_var(ctx['ret_tmp_name'], scope, body)
        body.append(f'    leave {ctx["epilogue_lbl"]}')
    else:
        compile_expr(stmt['expr_node'], scope, body, body_dtype, ctx)
        body.append('    ret')
```

(Giữ nguyên docstring/comment phía trên hàm nếu có phần không liên quan tới
`is_async`; chỉ xóa 2 khối `if ctx.get('is_async'):` và dòng gọi
`Task.FromResult<T>` bên trong.)

Áp dụng ĐÚNG NHƯ VẬY cho `release/3.code/compiler/il_features/control_flow.tkv`
(tìm hàm `codegen_return` tương ứng, xóa cùng 2 khối).

- [ ] **Step 2: Xác nhận build compiler chính nó không lỗi cú pháp Python (chưa chạy test — `is_async_fn` trong `il_codegen.py` vẫn còn set `ctx['is_async']`, chỉ là không còn ai đọc field đó nữa, vô hại)**

```bash
cd "D:\Claude AI Project\TokenVector"
python -c "import sys; sys.path.insert(0, 'compiler'); import il_codegen"
```

Expected: không có `ImportError`/`SyntaxError`.

- [ ] **Step 3: Commit**

```bash
git add compiler/il_features/control_flow.py release/3.code/compiler/il_features/control_flow.tkv
git commit -m "refactor(compiler): xoa Task.FromResult wrapping cu trong codegen_return

Chuan bi cho Task 2 (async closure-wrapper that): than ham async se
khong con la chinh method public nua (se la Invoke() cua 1 closure
rieng, xem Task 2) - method do LUON tra ve T tho, khong con can bo
Task<T> o day. ctx['is_async'] van con duoc set o il_codegen.py nhung
khong con ai doc - se don dep hoan toan o Task 2.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: `gen_il_function` — sinh closure-wrapper thật cho `async def` (top-level, chưa có `self`)

**Files:**
- Modify: `compiler/il_codegen.py` — thêm hàm mới `_gen_async_def` (đặt ngay
  TRƯỚC `gen_il_function`, khoảng dòng 3436), sửa `gen_il_function` thêm 1
  nhánh rẽ sớm.
- Modify: `release/3.code/compiler/il_codegen.tkv` — đoạn tương ứng.

**Interfaces:**
- Consumes: `_gen_closure_class_il(closure_class, captures, nested_sig,
  nested_stmts, ctx)` từ `compiler/il_features/closures.py` (đã có sẵn,
  KHÔNG sửa) — `captures: list[(ten, TypeAnn, cell_class_hoac_None, mode)]`,
  `mode` là `'boxed'` hoặc `'direct'`. `ctx['gen_il_function']` (đã được
  "tiêm" vào mọi `ctx`, trỏ lại chính `gen_il_function`).
- Produces: khi `sig.is_async` là `True`, `gen_il_function` trả về CÙNG
  KIỂU (`list[str]`, 1 `.method` hoàn chỉnh) như trước — không đổi contract
  với caller (`gen_il_program` ở dòng 4024/4096/4117 không cần sửa).

- [ ] **Step 1: Đọc lại `_gen_closure_class_il` và `codegen_nested_def` (đã có sẵn, KHÔNG sửa) để đối chiếu khi viết `_gen_async_def`**

File tham chiếu: `compiler/il_features/closures.py` dòng 201-297. Xác nhận
lại chữ ký:
```python
def _gen_closure_class_il(closure_class, captures, nested_sig, nested_stmts, ctx):
    ...  # tra ve list[str] = toan bo '.class ... { ... }'
```
`captures` mỗi phần tử `(ten_bien, TypeAnn, cell_class_hoac_None, mode)` —
với `mode='direct'` thì `cell_class` luôn `None` (không cần cell/boxed cho
tham số async — bản sao giá trị tại thời điểm gọi, không chia sẻ qua tham
chiếu ra ngoài closure).

- [ ] **Step 2: Viết `_gen_async_def` trong `il_codegen.py`, đặt ngay trước `def gen_il_function`**

```python
def _gen_async_def(sig, body_lines, class_name, records, record_methods,
                    record_methods_own, record_bases, self_type_ann,
                    module_consts, module_globals, extra_classes, emitted_types):
    """Sinh wrapper THAT cho 1 'async def' (top-level hoac record method) -
    body THAT chay tren 1 class closure rieng ({prefix}__AsyncBody), qua
    Task.Factory.StartNew<T> (KHONG phai Task.Run - ilasm.exe target
    mscorlib v4.0 chua co Task.Run, xem threading_feature.py). Tai dung
    NGUYEN VAN ha tang closure cua closures.py (_gen_closure_class_il) -
    'self' (neu la record method) VA moi tham so deu tro thanh 1 capture
    mode='direct' (ban sao gia tri, khong can cell/boxed)."""
    from il_features.closures import _gen_closure_class_il

    known_shapes = {p.name: p.type_ann.shape for p in sig.params if p.type_ann.shape is not None}
    lines = _strip_lines([_rename_reserved_identifiers(l) for l in _expand_macros(body_lines)])
    base_indent = lines[0][0] if lines else 0
    stmts, end_pos = _parse_block(lines, 0, base_indent, sig, known_shapes)
    if end_pos != len(lines):
        bad_indent, bad_line = lines[end_pos]
        raise SyntaxError(f'il_codegen: indent khong hop le tai dong {bad_line!r} '
                           f'(indent={bad_indent}, ky vong {base_indent})')

    captures = []
    if self_type_ann is not None:
        captures.append(('self', self_type_ann, None, 'direct'))
    for p in sig.params:
        captures.append((p.name, p.type_ann, None, 'direct'))

    prefix = f'{self_type_ann.dtype}__' if self_type_ann is not None else ''
    closure_class = f'{prefix}{sig.name}__AsyncBody'
    invoke_sig = Signature('Invoke', [], sig.return_type, 'block', None, is_async=False)

    ctx_stub = {
        'gen_il_function': gen_il_function, 'il_type_str': il_type_str,
        'class_name': class_name, 'records': records or {},
        'record_methods': record_methods or {}, 'record_methods_own': record_methods_own or {},
        'record_bases': record_bases or {}, 'func_table': {},
        'extra_classes': extra_classes, 'emitted_types': emitted_types,
    }
    if closure_class not in emitted_types:
        emitted_types.add(closure_class)
        extra_classes.extend(_gen_closure_class_il(closure_class, captures, invoke_sig, stmts, ctx_stub))

    raw_ret = il_type_str(sig.return_type)
    scope = _Scope()
    scope.class_name = class_name or 'Program'
    param_idx_base = 0
    if self_type_ann is not None:
        scope.add_self('self', self_type_ann)
        param_idx_base = 1
    for idx, p in enumerate(sig.params):
        scope.add_arg(p.name, idx + param_idx_base, p.type_ann)

    ctor_params_il = ', '.join(il_type_str(ta) for _, ta, _, _ in captures)
    body = []
    body.append('    call class [mscorlib]System.Threading.Tasks.TaskFactory '
                 '[mscorlib]System.Threading.Tasks.Task::get_Factory()')
    for cname, _, _, _ in captures:
        _load_var_ref(cname, scope, body)
    body.append(f'    newobj instance void {closure_class}::.ctor({ctor_params_il})')
    body.append(f'    ldftn instance {raw_ret} {closure_class}::Invoke()')
    body.append(f'    newobj instance void class [mscorlib]System.Func`1<{raw_ret}>::.ctor(object, native int)')
    body.append(f'    callvirt instance class [mscorlib]System.Threading.Tasks.Task`1<!!0> '
                 f'[mscorlib]System.Threading.Tasks.TaskFactory::StartNew<{raw_ret}>('
                 f'class [mscorlib]System.Func`1<!!0>)')
    body.append('    ret')

    params_il = ', '.join(f'{il_type_str(p.type_ann)} {_il_ident(p.name)}' for p in sig.params)
    ret_type = f'class [mscorlib]System.Threading.Tasks.Task`1<{raw_ret}>'
    lines_out = []
    if self_type_ann is not None:
        lines_out.append(f'  .method public hidebysig instance {ret_type} {_il_ident(sig.name)}({params_il}) cil managed')
    else:
        lines_out.append(f'  .method public static {ret_type} {_il_ident(sig.name)}({params_il}) cil managed')
    lines_out.append('  {')
    lines_out.append(f'    .maxstack {_max_stack_for(body)}')
    lines_out.extend(body)
    lines_out.append('  }')
    return lines_out
```

- [ ] **Step 3: Thêm nhánh rẽ sớm trong `gen_il_function`**

Trong `def gen_il_function(...)` (dòng 3436), NGAY SAU dòng
`if sig.return_type: body_dtype = ...` (khối tính `body_dtype`, dòng
3474-3484), chèn:

```python
    if getattr(sig, 'is_async', False) and not is_closure_method:
        return _gen_async_def(sig, body_lines, class_name, records, record_methods,
                               record_methods_own, record_bases, self_type_ann,
                               module_consts, module_globals, extra_classes if extra_classes is not None else [],
                               emitted_types if emitted_types is not None else set())
```

(Điều kiện `not is_closure_method` đảm bảo lời gọi ĐỆ QUY bên trong
`_gen_async_def`'s `_gen_closure_class_il` — sinh `Invoke()` với
`invoke_sig.is_async=False` — KHÔNG bao giờ tự gọi lại `_gen_async_def`,
tránh đệ quy vô hạn; đây thực ra chỉ là hàng rào an toàn vì
`invoke_sig.is_async` đã luôn `False`.)

Xóa đoạn code CŨ đã bị thay thế (dòng 3573-3583 bản hiện tại — khối
`is_async_fn = getattr(sig, 'is_async', False)` và `if is_async_fn: ret_type
= ...`), thay bằng:
```python
    ret_type = il_type_str(sig.return_type) if sig.return_type else 'void'
```
Xóa dòng `'is_async': is_async_fn,` khỏi dict `ctx` (không còn ai đọc field
này, xem Task 1).

- [ ] **Step 4: Áp dụng cùng thay đổi cho `release/3.code/compiler/il_codegen.tkv`**

Tìm đúng vị trí tương ứng (`gen_il_function`, `body_dtype` block,
`is_async_fn` block) trong file `.tkv`, áp y hệt Step 2/3 (cú pháp Python
giống hệt, chỉ khác đuôi file).

- [ ] **Step 5: Viết test build+run cho top-level `async def` có tham số**

Tạo `release/3.code/Testkit/async_concurrency_py_tree_test.tkv`:

```python
async def slow_double(x: "i32") -> "i32":
    thread_sleep(300)
    return x * 2


def check(name: "str", got: "str", want: "str") -> "i32":
    if got == want:
        print("PASS " + name)
        return 1
    print("FAIL " + name + " got=" + got + " want=" + want)
    return 0


async def run() -> "i32":
    tested: "i32" = 0
    total: "i32" = 0

    t1 = slow_double(5)
    t2 = slow_double(7)
    r1: "i32" = await t1
    r2: "i32" = await t2
    tested = tested + 1
    total = total + check("async_params_parallel", str(r1) + "," + str(r2), "10,14")

    print("SUMMARY " + str(total) + "/" + str(tested))
    return 0
```

Chạy:
```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/async_concurrency_py_tree_test.tkv --entry run --out /tmp/t2_test.exe
/tmp/t2_test.exe
```

Expected: build PASS (không lỗi `ilasm`), output `SUMMARY 1/1`. Nếu `ilasm`
báo lỗi cú pháp IL (token/overload sai) — đọc thông báo lỗi, đối chiếu lại
với pattern THẬT trong `threading_feature.py` (Task 0, đã xác nhận
`Task.Factory.StartNew`/`Func\`1` chạy đúng) và `closures.py`'s
`_gen_closure_class_il`/`codegen_nested_def` (đã xác nhận `ldftn instance`/
`newobj Func` chạy đúng cho closure instance) — sửa `_gen_async_def` cho
khớp, KHÔNG đoán.

- [ ] **Step 6: Đo thời gian song song thật (bằng chứng regression-guard chính, theo đúng spec mục Kiểm chứng)**

Viết script Python tạm (KHÔNG commit vào repo, chỉ chạy tay để xác nhận, ghi
kết quả vào report) đo `time.time()` bao quanh `/tmp/t2_test.exe`. Vì
`run()` gọi 2 `slow_double` KHÔNG `await` ngay rồi mới `await` cả 2 — tổng
thời gian chạy PHẢI gần 300ms (song song thật), KHÔNG PHẢI ~600ms (2 lần
sleep cộng dồn nếu vẫn giả-đồng-bộ). Ghi lại số đo thật vào report của
task, không chỉ khẳng định lý thuyết.

- [ ] **Step 7: Regression toàn bộ `Testkit/*.tkv` qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "/tmp/t2_reg_${base}.exe" > "/tmp/t2_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("/tmp/t2_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` (trừ `path_isfile_isdir_test`, đã xác nhận
pre-existing) — đặc biệt `native_test_suite.tkv` (dùng `async_worker`,
`thread_spawn`/`thread_join`) phải KHÔNG đổi kết quả.

- [ ] **Step 8: Commit**

```bash
git add compiler/il_codegen.py release/3.code/compiler/il_codegen.tkv \
        release/3.code/Testkit/async_concurrency_py_tree_test.tkv
git commit -m "feat(compiler): async def top-level chay THAT song song qua Task.Factory.StartNew

gen_il_function re nhanh som khi sig.is_async: sinh 1 class closure
{name}__AsyncBody (field = moi tham so, mode='direct', tai dung
_gen_closure_class_il cua closures.py khong doi 1 dong) chua Invoke()
la than ham THAT (tra T tho, khong con Task.FromResult - xem Task 1).
Method public {name}(...) tro thanh wrapper mong: dung closure instance,
bind Func<T> qua ldftn+newobj, goi TaskFactory.StartNew<T> (KHONG phai
Task.Run - ilasm.exe target mscorlib v4.0 chua co Task.Run, xem
threading_feature.py Task 0), ret Task<T> that. Do thuc te: 2 loi goi
async khong await ngay chay song song ~300ms (khong phai ~600ms nhu
gia-dong-bo cu).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Mở rộng `async def` cho record method (capture `self`)

**Files:**
- Modify: `compiler/il_codegen.py` — xác nhận đường gọi `gen_il_function`
  cho record method (dòng ~4088-4097, `self_type_ann=self_ta`) đã tự động đi
  qua nhánh `_gen_async_def` mới (Task 2 Step 3) mà KHÔNG cần sửa thêm gì ở
  đây — `self_type_ann` đã được truyền sẵn làm tham số của
  `gen_il_function`, `_gen_async_def` đã nhận `self_type_ann` (Task 2 Step
  2) và tự thêm capture `'self'` khi khác `None`.
- Modify: `release/3.code/compiler/il_codegen.tkv` — đối chiếu tương ứng.

**Interfaces:**
- Consumes: `_gen_async_def` từ Task 2 (đã hỗ trợ `self_type_ann` KHÔNG
  `None` — không cần sửa thêm).

- [ ] **Step 1: Đọc lại đường gọi `gen_il_function` cho record method để xác nhận không cần sửa gì**

Đọc `compiler/il_codegen.py` dòng 4088-4097 (nơi `self_type_ann=self_ta`
được truyền vào `gen_il_function` cho từng method của 1 record). Xác nhận
`sig` truyền vào đây (`Signature` của method) đã có `is_async` đúng giá trị
(từ parse chữ ký `async def <method>(self, ...) -> T:` — kiểm tra
`tkv_compile.py`'s hàm parse chữ ký record method có forward `is_async` hay
không; NẾU CHƯA, đây là 1 bug cần sửa TRƯỚC — thêm `is_async=...` vào lời
gọi `Signature(...)` tương ứng trong `tkv_compile.py`).

- [ ] **Step 2: Viết test record method async (chứng minh `self.field` đọc đúng qua closure capture)**

Tạo `release/3.code/Testkit/async_method_py_tree_test.tkv`:

```python
class Doubler:
    factor: "i32"

    def __init__(self, factor: "i32"):
        self.factor = factor

    async def compute(self, x: "i32") -> "i32":
        thread_sleep(50)
        return x * self.factor


def check(name: "str", got: "str", want: "str") -> "i32":
    if got == want:
        print("PASS " + name)
        return 1
    print("FAIL " + name + " got=" + got + " want=" + want)
    return 0


async def run() -> "i32":
    tested: "i32" = 0
    total: "i32" = 0

    d = Doubler(3)
    t = d.compute(10)
    r: "i32" = await t
    tested = tested + 1
    total = total + check("async_method_self_capture", str(r), "30")

    print("SUMMARY " + str(total) + "/" + str(tested))
    return 0
```

Chạy:
```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/async_method_py_tree_test.tkv --entry run --out /tmp/t3_test.exe
/tmp/t3_test.exe
```

Expected: build PASS, output `SUMMARY 1/1`. Nếu lỗi liên quan tới field
`self` trong closure (`KeyError 'self'`/sai `il_type_str` cho
`self_type_ann` kiểu record) — đối chiếu `closures.py`'s xử lý
`closure_field`/`closure_field_direct` (dòng 3517-3527 `il_codegen.py`, đã
đọc ở Task 2 Step 1) để sửa `_gen_async_def`'s cách xây `captures`.

- [ ] **Step 3: Regression lại toàn bộ Testkit (như Task 2 Step 7) + xác nhận record-method non-async khác không đổi**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "/tmp/t3_reg_${base}.exe" > "/tmp/t3_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("/tmp/t3_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` (trừ `path_isfile_isdir_test` pre-existing).

- [ ] **Step 4: Commit**

```bash
git add compiler/il_codegen.py release/3.code/compiler/il_codegen.tkv \
        compiler/tkv_compile.py release/3.code/compiler/tkv_compile.tkv \
        release/3.code/Testkit/async_method_py_tree_test.tkv
git commit -m "feat(compiler): async def method tren record chay that song song, capture self

_gen_async_def (Task 2) da ho tro self_type_ann tu truoc - task nay xac
nhan duong goi gen_il_function cho record method forward dung
sig.is_async (sua tkv_compile.py neu thieu) + test that self.field doc
dung qua closure_field_direct trong Invoke().

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Build lại `tkvc.exe` thật, regression cuối cùng qua cả 2 cây, cập nhật docs

**Files:**
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (mục "🧭 Chiến lược Loại 2", đánh
  dấu `#3 Concurrency` xong thật, không còn "vỏ đồng bộ").
- Không sửa code nào khác — task thuần kiểm chứng + docs, giống mẫu Task 13
  của plan `2026-08-12-tkvc-plugin-architecture.md`.

**Interfaces:** không có (task cuối).

- [ ] **Step 1: Rebuild `tkvc.exe` thật qua `build_tkvc.ps1`**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
powershell -File build_tkvc.ps1
```

Expected: build thành công, không lỗi liên quan `threading_feature`/
`async`/closure mới.

- [ ] **Step 2: Regression toàn bộ `Testkit/*.tkv` qua `tkvc.exe` MỚI (bao gồm 3 file test mới từ Task 0/2/3)**

```bash
cd "D:\Claude AI Project\TokenVector\release\3.code"
for f in Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  ./dist/tkvc.exe build "$f" --entry run --out "/tmp/t4_tkvc_${base}.exe" > "/tmp/t4_tkvcbuild_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL(tkvc) $base"; continue; fi
  res=$("/tmp/t4_tkvc_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base (tkvc) ==="; echo "$res" | tail -5; } || echo "OK(tkvc) $base"
done
```

Expected: kết quả GIỐNG HỆT `.py` tree (mọi dòng `OK(tkvc)`, trừ
`path_isfile_isdir_test`).

- [ ] **Step 3: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Trong mục `## 🧭 Chiến lược Loại 2`, sửa dòng:
```
- [x] **#3 Concurrency — LÀM TRƯỚC.** .NET IL có thread/Task OS thật,
      không GIL (khác CPython) — `async`/`await` hiện chỉ là vỏ đồng bộ
      (`Task.FromResult`), sửa bằng dịch thẳng sang `async Task<T>` C#
      thật. Effort thấp (hạ tầng .NET có sẵn), có thể thành lợi thế cạnh
      tranh (TokenVector không GIL, Python có).
```
thành:
```
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
```
Cập nhật dòng 141-153 (`## Thứ tự ưu tiên tổng hợp`) mục 10, gạch bỏ phần
Concurrency (giữ nguyên phần Debug PDB #5 chưa làm).

- [ ] **Step 4: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add docs/PYTHON_GAP_CHECKLIST.md
git commit -m "docs: xac nhan hoan thanh Concurrency that (#3 Loai 2)

Regression toan dien qua .py tree va tkvc.exe (rebuild that) cho ket
qua giong het nhau tren toan bo Testkit/*.tkv, ke ca 3 test moi
(threading_feature, async_concurrency, async_method). Xem chi tiet o
docs/superpowers/specs/2026-08-12-async-real-concurrency-design.md va
docs/superpowers/plans/2026-08-12-async-real-concurrency.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review (đã thực hiện khi viết plan này)

**1. Spec coverage**: Port `threading_feature.py` (spec mục "Task 0") →
Task 0. Closure-wrapper cho hàm 0/N tham số → Task 2 (đơn giản hóa CÓ Ý
THỨC so với spec: dùng THỐNG NHẤT 1 đường closure-class cho MỌI trường hợp,
kể cả 0 tham số/không `self` — thay vì 2 đường riêng như spec mô tả ban đầu
— captures rỗng vẫn hoạt động đúng qua `_gen_closure_class_il` sẵn có
[ctor 0 tham số], giảm code mới cần viết, HÀNH VI QUAN SÁT ĐƯỢC không đổi
so với spec: vẫn `Task.Factory.StartNew<T>` thật, vẫn API `{name}(...)`
không đổi chữ ký tại điểm gọi). `codegen_return`'s `is_async` branch xóa →
Task 1. `await` giữ nguyên → không có task nào đụng tới
`async_await.py` (đúng ý spec "GIỮ NGUYÊN"). Record method `self` capture →
Task 3. Kiểm chứng đo thời gian song song thật → Task 2 Step 6. Regression
2 cây + `tkvc.exe` → Task 4.

**2. Placeholder scan**: không còn "TBD"/"tương tự Task N không viết code"
— mọi step code đều có code đầy đủ (kể cả `_gen_async_def` toàn văn ở Task
2 Step 2). Task 2 Step 5's ghi chú "nếu lỗi ilasm thì sửa cho khớp" KHÔNG
phải placeholder mơ hồ — đây là hướng dẫn debug cụ thể (đối chiếu 2 file
tham chiếu đã xác nhận chạy đúng), đúng thực tế dự án này luôn cần build
thật để xác nhận cú pháp IL (không ai viết IL đúng 100% từ đầu không cần
build thử, xem lịch sử mọi Phase trước).

**3. Type consistency**: `_gen_async_def(sig, body_lines, class_name,
records, record_methods, record_methods_own, record_bases, self_type_ann,
module_consts, module_globals, extra_classes, emitted_types)` — chữ ký
dùng NHẤT QUÁN ở Task 2 Step 2 (định nghĩa) và Step 3 (lời gọi). `captures:
list[(ten, TypeAnn, None, 'direct')]` khớp định dạng
`_gen_closure_class_il` đã xác nhận đọc ở Task 2 Step 1 (không tự chế định
dạng mới).

## Execution Handoff

Plan hoàn chỉnh, lưu tại
`docs/superpowers/plans/2026-08-12-async-real-concurrency.md`.

Hai lựa chọn thực thi:

**1. Subagent-Driven (khuyến nghị)** - giao mỗi Task cho 1 subagent mới,
review giữa các Task, lặp nhanh.

**2. Inline Execution** - thực thi trong phiên này qua executing-plans,
chạy theo lô có checkpoint để bạn review.

Bạn muốn dùng cách nào?
