# Context manager tuỳ biến (`__enter__`/`__exit__`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `with <ctor_call_hoac_bien_record> as v:` gọi `__enter__` lúc vào khối (bind vào `v`), gọi `__exit__` lúc RA khỏi khối (luôn chạy, kể cả có `return`/exception) — không suppress exception.

**Architecture:** Thêm 1 `LINE_PARSERS` entry MỚI (song song `with_open` đã có, không sửa nó) cho `with <expr> as v:` tổng quát, desugar thành stmt kind `with_ctx`. Codegen tái dùng khung `.try/finally` y hệt `codegen_with_open`, chỉ khác: gọi `__enter__`/`__exit__` qua `callvirt` thay vì `newobj`/`Dispose()`, và cần 1 hidden local giữ record GỐC (vì `v` nhận kết quả `__enter__`, có thể khác record gốc).

**Tech Stack:** Python compiler (`compiler/`), self-hosted `.tkv` mirror (`release/3.code/compiler/`), CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ CẢ 2 cây: `compiler/il_features/control_flow.py` (Python) VÀ mirror `.tkv` tương ứng trong `release/3.code/compiler/il_features/`.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
- KHÔNG sửa `_WITH_OPEN_RE`/`try_parse_with_open`/`codegen_with_open`/stmt kind `with_open` hiện có — đường xử lý hoàn toàn riêng biệt.
- Chỉ `with <ctor_call_record> as v:` HOẶC `with <bien_record_da_khai_bao> as v:` — không hỗ trợ biểu thức phức tạp, không hỗ trợ `with a, b:`.
- Record thiếu `__enter__` HOẶC `__exit__` (chỉ có 1 trong 2) → `SyntaxError` rõ.
- `__exit__` KHÔNG suppress exception — luôn chạy trong `finally`, giá trị trả về bị bỏ qua (`pop` nếu không phải void).

---

### Task 1: Parse + codegen `with <record> as v:`

**Files:**
- Modify: `compiler/il_features/control_flow.py` (thêm parser + first-pass-walk/prescan + codegen mới, KHÔNG sửa hàm `with_open` hiện có)
- Modify: file mirror `.tkv` tương ứng trong `release/3.code/compiler/il_features/` (tìm bằng grep `try_parse_with_open` trong thư mục đó)
- Create: `release/3.code/Testkit/context_manager_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (đánh dấu 6.6 đã xong)

**Interfaces:**
- Consumes: `ctx['records']`, `ctx['record_methods']`, `_method_owner_class(ctx, record_name, method_name)` (`record_feature.py`, không sửa), `is_record_ctor_rhs(rhs_node, records)` (`record_feature.py`, dùng để phát hiện `with Lock() as lk:` là gọi constructor — đọc chữ ký hàm này trước khi dùng), `ctx['il_type_str']`, `ctx['compile_expr']`, `ctx['store_var']`, `ctx['load_var_ref']`, `_contains_return`/`_stmts_end_in_return` (đã có sẵn trong `control_flow.py`, dùng lại y hệt `fpw_with_open`/`codegen_with_open`).
- Produces: stmt kind mới `'with_ctx'` — chỉ dùng nội bộ file này, không có consumer bên ngoài.

- [ ] **Step 1: Đọc lại toàn bộ khung `with_open` làm mẫu**

Đọc `compiler/il_features/control_flow.py` dòng 917-1071
(`_WITH_OPEN_RE`, `try_parse_with_open`, `fpw_with_open`,
`fpp_with_open`, `codegen_with_open`) — đây là MẪU DUY NHẤT trong
codebase cho "khối `with` desugar qua try/finally". Đọc kỹ đặc biệt:
- Cách `pos`/`indent_level`/`parse_block_fn` được dùng để parse thân
  khối (giống hệt `if`/`for`/`while`).
- Cách `fpw_with_open` khai báo biến MỚI vào `locals_decl`/`infer_scope`
  qua `ctx['TypeAnn']`, và cách nó phát hiện `_contains_return` để bật
  `ctx['needs_epilogue']`.
- Cách `codegen_with_open` dùng `ctx['label_counter']` để sinh nhãn
  DUY NHẤT, và cấu trúc `.try { } finally { }` chính xác (thụt lề,
  `leave`/`endfinally`).
- Cách quy ước đặt tên hidden local ẩn khác trong codebase (grep
  `__strtmp{id(`/`__dictiter{id(` trong `il_codegen.py`/các file
  `il_features/*.py` khác) để dùng ĐÚNG quy ước cho hidden local giữ
  record gốc ở task này (vd `f'__ctxmgr{id(stmt)}'`).

- [ ] **Step 2: Viết parser `with <expr> as v:` tổng quát**

Thêm regex MỚI (đặt CẠNH `_WITH_OPEN_RE`, không sửa nó):

```python
_WITH_CTX_RE = re.compile(r'^with\s+(.+?)\s+as\s+(\w+)\s*:\s*$')
```

Viết `try_parse_with_ctx(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn)`:

```python
def try_parse_with_ctx(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """'with <bieu_thuc_record> as v:' (6.6, context manager tuy bien,
    2026-08-13) - CHI ho tro (a) goi constructor truc tiep 'with Lock() as lk:'
    hoac (b) 1 bien DA khai bao kieu record 'with existing as lk:'. Dang ky
    SAU with_open trong LINE_PARSERS (khong sua with_open) - 'with open(...)'
    van di duong cu vi _WITH_OPEN_RE khop TRUOC (thu tu LINE_PARSERS o
    il_codegen.py). Xem docs/superpowers/specs/2026-08-13-context-manager-design.md."""
    m = _WITH_CTX_RE.match(line)
    if not m:
        return None
    expr_text, var_name = m.groups()
    if expr_text.strip().startswith('open('):
        # 'with open(...)' KHONG khop _WITH_OPEN_RE (vd thieu dau ngoac
        # dung, mode sai) se roi xuong day - bao loi RO thay vi hieu nham
        # thanh with_ctx (se that bai o buoc validate record ben duoi voi
        # thong bao khong lien quan).
        return None
    expr_node = parse_expr(expr_text.strip())
    pos += 1
    if pos >= len(lines) or lines[pos][0] <= indent_level:
        raise SyntaxError(
            f"il_codegen: 'with {expr_text} as {var_name}:' khong co than khoi (block rong)")
    body, pos = parse_block_fn(lines, pos, lines[pos][0], sig, known_shapes)
    return {'kind': 'with_ctx', 'expr_node': expr_node, 'var': var_name,
            'body': body}, pos
```

Lý do `if expr_text.strip().startswith('open(')`: `with open(x, "bad_mode")` (mode sai, không khớp `_WITH_OPEN_RE`) không được để rơi xuống parser mới này — nếu không, lỗi sẽ báo "record 'open' khong ton tai" (khó hiểu) thay vì lỗi mode rõ ràng mà `try_parse_with_open` đã có. Trả `None` ở đây khiến parser tổng thể tiếp tục thử các parser khác, cuối cùng rơi vào lỗi cú pháp chung — CHẤP NHẬN ĐƯỢC (không phải mục tiêu chính của task này, chỉ tránh nhầm lẫn).

- [ ] **Step 3: First-pass walk + prescan**

```python
def fpw_with_ctx(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['expr_node'])
    declared_names = ctx['declared_names']
    infer_scope = ctx['infer_scope']
    records = ctx.get('records') or {}
    record_methods = ctx.get('record_methods') or {}
    expr_node = stmt['expr_node']
    if expr_node[0] == 'call' and expr_node[1] in records:
        record_name = expr_node[1]
    elif expr_node[0] == 'var':
        _, _, var_ta = infer_scope[expr_node[1]]
        if var_ta.shape != 'record':
            raise SyntaxError(
                f"il_codegen: 'with {expr_node[1]} as {stmt['var']}:' - '{expr_node[1]}' "
                f"khong phai bien kieu record")
        record_name = var_ta.dtype
    else:
        raise SyntaxError(
            f"il_codegen: 'with <bieu_thuc> as {stmt['var']}:' - chi ho tro goi "
            f"constructor record truc tiep (vd 'with Lock() as lk:') hoac 1 bien "
            f"da khai bao kieu record, khong ho tro bieu thuc phuc tap khac")
    enter_m = record_methods.get(record_name, {}).get('__enter__')
    exit_m = record_methods.get(record_name, {}).get('__exit__')
    if enter_m is None or exit_m is None:
        raise SyntaxError(
            f"il_codegen: record '{record_name}' can dinh nghia CA __enter__ VA "
            f"__exit__ de dung trong 'with' (dang thieu: "
            f"{'__enter__' if enter_m is None else ''}"
            f"{'__exit__' if exit_m is None else ''})")
    if enter_m.params or enter_m.return_type is None:
        raise SyntaxError(
            f"il_codegen: record '{record_name}' co __enter__ nhung chu ky sai - "
            f"can dung 0 tham so va tra ve 1 kieu bat ky "
            f"('def __enter__(self) -> \"T\":')")
    if exit_m.params or exit_m.return_type is None:
        raise SyntaxError(
            f"il_codegen: record '{record_name}' co __exit__ nhung chu ky sai - "
            f"can dung 0 tham so va tra ve 1 kieu bat ky "
            f"('def __exit__(self) -> \"U\":')")
    stmt['_record_name'] = record_name
    stmt['_enter_ta'] = enter_m.return_type
    if stmt['var'] not in declared_names:
        declared_names.add(stmt['var'])
        ctx['locals_decl'].append((stmt['var'], enter_m.return_type))
        infer_scope.set(stmt['var'], enter_m.return_type)
    hidden = f"__ctxmgr{id(stmt)}"
    stmt['_hidden'] = hidden
    if hidden not in declared_names:
        declared_names.add(hidden)
        record_ta = ctx['TypeAnn'](record_name, 'record')
        ctx['locals_decl'].append((hidden, record_ta))
        infer_scope.set(hidden, record_ta)
    if _contains_return(stmt['body']):
        ctx['needs_epilogue'][0] = True
    ctx['walk_fn'](stmt['body'])


def fpp_with_ctx(stmt, ctx):
    ctx['prescan_fn'](stmt['body'])
```

Giải thích các điểm khác `fpw_with_open`:
- Phát hiện `record_name` theo ĐÚNG 2 dạng đã chốt trong spec (constructor
  call qua `records` dict, hoặc biến qua `infer_scope`).
- Validate `__enter__`/`__exit__` CẢ HAI cùng lúc, thông báo lỗi liệt
  kê chính xác cái nào thiếu.
- `v` được khai kiểu = `enter_m.return_type` (KHÔNG PHẢI kiểu record —
  đúng spec: `T` tuỳ ý).
- Hidden local `__ctxmgr{id(stmt)}` LUÔN kiểu record gốc (dù `T` là gì)
  — dùng quy ước `id(stmt)` giống `__strtmp{id(...)}` (duy nhất theo
  từng statement AST, không trùng giữa 2 khối `with` khác nhau trong
  cùng hàm).

- [ ] **Step 4: Codegen `with_ctx`**

```python
def codegen_with_ctx(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    var, hidden = stmt['var'], stmt['_hidden']
    record_name = stmt['_record_name']
    compile_expr = ctx['compile_expr']
    records = ctx.get('records') or {}
    record_ta = ctx['TypeAnn'](record_name, 'record')
    # Sinh record instance (constructor hoac load bien) roi giu 1 BAN SAO
    # vao hidden local - can THIET vi __exit__ phai goi tren RECORD GOC,
    # con 'var' nhan ket qua __enter__ (co the la KIEU KHAC).
    compile_expr(stmt['expr_node'], scope, body, record_name, ctx)
    ctx['store_var'](hidden, scope, body)
    from il_features.record_feature import _method_owner_class
    enter_owner = _method_owner_class(ctx, record_name, '__enter__')
    enter_il = ctx['il_type_str'](stmt['_enter_ta'], records)
    ctx['load_var_ref'](hidden, scope, body)
    body.append(f'    callvirt instance {enter_il} {enter_owner}::__enter__()')
    ctx['store_var'](var, scope, body)

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    end_lbl = f'{sig.name}_WithCtx{n}_end'
    body.append('    .try')
    body.append('    {')
    ctx['try_depth'] = ctx.get('try_depth', 0) + 1
    codegen_stmts_fn(stmt['body'], scope, body, body_dtype, ctx, sig)
    ctx['try_depth'] -= 1
    if not _stmts_end_in_return(stmt['body']):
        body.append(f'      leave {end_lbl}')
    body.append('    }')
    body.append('    finally')
    body.append('    {')
    record_methods = ctx.get('record_methods') or {}
    exit_m = record_methods[record_name]['__exit__']
    exit_owner = _method_owner_class(ctx, record_name, '__exit__')
    exit_il = ctx['il_type_str'](exit_m.return_type, records)
    ctx['load_var_ref'](hidden, scope, body)
    body.append(f'      callvirt instance {exit_il} {exit_owner}::__exit__()')
    if exit_il != 'void':
        body.append('      pop')
    body.append('      endfinally')
    body.append('    }')
    body.append(f'  {end_lbl}:')
```

Lưu ý: nếu `TypeAnn` (khi `return_type` không khai `->`) không map
thành `il_type_str == 'void'`, kiểm tra lại cách các record method
KHÔNG có `-> "T"` biểu diễn `return_type` trong codebase thật (đọc
`Signature`/`Param` class, hoặc cách `gen_il_function` xử lý hàm không
khai kiểu trả về) TRƯỚC KHI viết điều kiện `if exit_il != 'void':` —
nếu biểu diễn khác (vd `return_type is None` nghĩa là void, và spec đã
YÊU CẦU `__exit__` PHẢI khai `-> "U"` nên trường hợp None đã bị chặn ở
Step 3), có thể bỏ hẳn nhánh `if`/luôn `pop` (vì Step 3 đã đảm bảo
`exit_m.return_type is not None`).

- [ ] **Step 5: Đăng ký vào `il_dispatch`**

Thêm 3 dòng CẠNH các dòng đăng ký `with_open` hiện có (dòng ~1150,
1157 — xem Step 5.1 "Dang ky vao il_dispatch" cuối file
`control_flow.py`), KHÔNG XOÁ dòng cũ:

```python
register_line_parser('with_ctx', try_parse_with_ctx)
register_first_pass_walk('with_ctx', fpw_with_ctx)
register_first_pass_prescan('with_ctx', fpp_with_ctx)
```

Xác nhận thứ tự đăng ký: `register_line_parser('with_open', ...)`
PHẢI đứng TRƯỚC `register_line_parser('with_ctx', ...)` trong danh
sách (để `with open(...)` luôn được `_WITH_OPEN_RE` thử trước — dù
Step 2 đã có guard `expr_text.strip().startswith('open(')` phòng hờ,
thứ tự đúng vẫn là lớp bảo vệ chính).

Cũng cần đăng ký `codegen_with_ctx` vào bảng `STMT_CODEGEN` (tìm cách
`codegen_with_open` được đăng ký — có thể qua 1 dict riêng trong
`il_codegen.py`, không phải qua `il_dispatch.py` như các hàm khác; grep
`codegen_with_open` trong TOÀN BỘ repo để tìm đúng nơi đăng ký và làm
tương tự cho `codegen_with_ctx`/`'with_ctx'`).

- [ ] **Step 6: Viết test `release/3.code/Testkit/context_manager_test.tkv`**

Đọc `dunder_add_test.tkv`/`dunder_getitem_test.tkv` trước để khớp cú
pháp. Case bắt buộc:

1. Record `Res` có `__enter__(self) -> "Res": (in "enter"); return self`
   và `__exit__(self) -> "i32": (in "exit"); return 0` — `with Res() as r:`
   in thứ tự đúng `enter` → thân khối → `exit` (dùng log/print để xác
   nhận thứ tự, giống cách các test khác kiểm tra side-effect order).
2. Thân khối có `return` sớm (nếu cú pháp DSL cho phép `with` bên
   trong 1 hàm có return giữa chừng) — xác nhận `__exit__` VẪN chạy
   trước khi hàm thực sự return (giống cách `with_open` đã kiểm
   chứng qua `_contains_return`).
3. `__enter__` trả về KHÁC record gốc (vd trả `i32`) — xác nhận `v`
   nhận đúng kiểu đó, không phải kiểu record.
4. `with existing_var as v:` (dạng biến, không phải constructor) —
   xác nhận hoạt động giống dạng constructor.

Case lỗi (thiếu `__enter__`/`__exit__`) xác nhận bằng spike riêng ở
Step 8, không đưa vào test chính. In theo dạng `SUMMARY N/N`.

- [ ] **Step 7: Build và chạy test qua cây `.py`**

```bash
python tkv.py build "D:\Claude AI Project\TokenVector\release\3.code\Testkit\context_manager_test.tkv" --entry run --out "D:\Claude AI Project\TokenVector\release\3.code\Testkit\context_manager_test.exe"
"D:\Claude AI Project\TokenVector\release\3.code\Testkit\context_manager_test.exe"
```

Expected: build sạch, `SUMMARY N/N` đúng, thứ tự log đúng
`enter`/thân/`exit`.

- [ ] **Step 8: Spike xác nhận case lỗi (không đưa vào test chính)**

File `.tkv` tạm: record chỉ có `__enter__` (thiếu `__exit__`), thử
`with X() as v:` — xác nhận `SyntaxError` rõ có chữ `__exit__`. Tương
tự ngược lại (chỉ có `__exit__`, thiếu `__enter__`). Xoá spike sau khi
xác nhận.

- [ ] **Step 9: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

Đặc biệt: mọi test dùng `with open(...) as f:` hiện có (tìm bằng grep
`with open(` trong thư mục `Testkit`), và `try`/`finally`/`return`
trong khối lồng nhau (dùng chung hạ tầng `try_depth`/`needs_epilogue`)
— xác nhận KHÔNG regression (trừ lỗi pre-existing đã biết
`path_isfile_isdir_test` nếu còn).

- [ ] **Step 10: Mirror sang cây `.tkv` tự-host**

Sửa file mirror tương ứng trong `release/3.code/compiler/il_features/`
với logic TƯƠNG ĐƯƠNG Step 2-5, bám đúng convention/style hiện có của
file đó (đối chiếu đoạn `with_open` đã có sẵn trong cùng file để giữ
nhất quán phong cách).

- [ ] **Step 11: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đánh dấu mục 6.6 ĐÃ XONG, trỏ tới file spec này, ghi rõ giới hạn
"không suppress exception, không hỗ trợ `with a, b:`, không hỗ trợ chữ
ký `__exit__` 4 tham số" để phiên sau không hiểu nhầm là hỗ trợ đầy đủ
100% Python thật.

- [ ] **Step 12: Commit**

```bash
git add compiler/il_features/control_flow.py <duong-dan-file-mirror-that> release/3.code/Testkit/context_manager_test.tkv docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): context manager tuy bien __enter__/__exit__ (with <record> as v:) - 6.6"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
