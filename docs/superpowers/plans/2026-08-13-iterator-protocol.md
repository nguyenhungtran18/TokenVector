# Iterator protocol tuỳ biến (`__iter__`/`__next__`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `for x in <bien_record>:` với record có `__iter__(self) -> "IterT"` và `IterT` có `__next__(self) -> "(T, i32)"` tự động chạy đúng vòng lặp (gán `x`=giá trị, dừng khi cờ về 0).

**Architecture:** Thêm 1 `LINE_PARSERS` entry MỚI cho `for <var> in <name>:` (bare identifier, KHÔNG phải `range(...)`) — vì macro text-level `for_in_list` (list/dict/set) chạy TRƯỚC AST parsing và đã rewrite mọi trường hợp list/dict/set thành `range(len())` rồi, bất kỳ `for x in <name>:` còn sót lại ở tầng `LINE_PARSERS` CHẮC CHẮN không phải list/dict/set — nên parser mới có thể chấp nhận LẠC QUAN, hoãn validate "có phải record hợp lệ không" sang first-pass-walk (giống cách task context-manager đã làm với `with`). Codegen tái dùng khung `while` (nhãn + `ctx['loop_stack']` cho `break`/`continue`), đọc kết quả `__next__` qua `ValueTuple<T,i32>.Item1/Item2` (hạ tầng đã có từ `tuple_type.py`).

**Tech Stack:** Python compiler (`compiler/`), self-hosted `.tkv` mirror (`release/3.code/compiler/`), CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ CẢ 2 cây: `compiler/il_features/control_flow.py` VÀ mirror `.tkv` tương ứng.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
- KHÔNG đụng macro `for_in_list` (`for x in <list/dict/set>:`) hiện có — đường xử lý HOÀN TOÀN riêng, phải giữ nguyên 100%.
- KHÔNG đụng `try_parse_for`/`_FOR_RANGE_RE`/`codegen_for` (`for x in range(...)`) hiện có.
- Chỉ `for x in <bien_record_da_khai_bao>:` — không constructor call, không biểu thức phức tạp.
- Record thiếu `__iter__`, hoặc `IterT` thiếu `__next__`, hoặc `__next__` không trả đúng `(T, i32)` → `SyntaxError` rõ.
- `break`/`continue` bên trong hoạt động đúng (tái dùng `ctx['loop_stack']`).

---

### Task 1: Parse + first-pass + codegen `for <var> in <record>:`

**Files:**
- Modify: `compiler/il_features/control_flow.py` (thêm parser + fpw + fpp + codegen mới, KHÔNG sửa `for_in_list`/`try_parse_for`/`codegen_for` hiện có)
- Modify: file mirror `.tkv` tương ứng trong `release/3.code/compiler/il_features/`
- Create: `release/3.code/Testkit/iterator_protocol_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (đánh dấu 6.7 đã xong)

**Interfaces:**
- Consumes: `ctx['records']`, `ctx['record_methods']`, `_method_owner_class` (`record_feature.py`), `ctx['il_type_str']`, `il_tupleN_type` (từ `il_features/tuple_type.py` — import cục bộ, xem cách `codegen_tuple_assign` đã import/dùng), `ctx['loop_stack']` (cơ chế break/continue có sẵn, xem `codegen_while`), `ctx['label_counter']`, `ctx['store_var']`/`ctx['load_var_ref']`/`ctx['compile_expr']`.
- Produces: stmt kind mới `'for_in_iter'` — chỉ nội bộ file này.

- [ ] **Step 1: Đọc lại các mẫu tham chiếu**

Đọc trong `compiler/il_features/control_flow.py`:
- `try_parse_for`/`_FOR_RANGE_RE` (dòng ~433-456) — mẫu parser `for`.
- `fpw_for`/`fpp_for`/`codegen_for` (dòng ~598-720+) — chú ý
  `declare_scalar_int` cho biến vòng lặp mặc định `i32` (ở đây biến
  vòng lặp `x` có kiểu TUỲ theo `T` của `__next__`, KHÔNG PHẢI luôn
  `i32` — không dùng `declare_scalar_int`, khai trực tiếp qua
  `ctx['locals_decl']`/`infer_scope.set` giống cách `fpw_with_ctx`
  (task context-manager trước) đã khai `v`).
- `codegen_while` (dòng ~721-737) — mẫu `.loop_stack`/nhãn
  `start_lbl`/`end_lbl`, ĐÂY LÀ KHUNG CHÍNH để tái dùng cho vòng lặp
  `for_in_iter` (không phải khung của `codegen_for`, vì không có biến
  đếm tăng dần).
- `codegen_tuple_assign` (`compiler/il_features/tuple_type.py`, dòng
  ~113-139) — mẫu ĐỌC 1 giá trị `ValueTuple<T1,T2>` trả về từ 1 lời
  gọi: lưu vào `stloc.s` 1 hidden local, rồi `ldloc.s` + `ldfld !i
  {tuple_type}::Item{i+1}` từng phần tử. Copy Y HỆT pattern này cho
  `__next__`'s kết quả.
- Đoạn `codegen_with_ctx`/`fpw_with_ctx` vừa thêm ở task trước (context
  manager, 6.6, cùng file) — mẫu GẦN NHẤT về validate 1 cặp method
  record + hidden local + `_method_owner_class`, dùng làm khuôn.

- [ ] **Step 2: Viết parser `for <var> in <name>:`**

```python
_FOR_IN_NAME_RE = re.compile(r'^for\s+(\w+)\s+in\s+(\w+)\s*:\s*$')


def try_parse_for_in_record(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """'for x in <bien_record>:' (6.7, iterator protocol tuy bien,
    2026-08-13) - CHI khop khi ve phai la 1 TEN don (khong 'range(...)').
    An toan LAC QUAN chap nhan o day: macro text-level 'for_in_list'
    (list/dict/set) da chay TRUOC va rewrite HET moi truong hop list/
    dict/set thanh 'for i in range(len(name)): x = name[i]' roi - bat ky
    'for x in <name>:' con SOT lai luc LINE_PARSERS chay CHAC CHAN
    khong phai list/dict/set. Validate that (co phai record hop le,
    co __iter__/__next__ hay khong) hoan toan HOAN sang first-pass-walk
    (fpw_for_in_iter), giong cach with_ctx (6.6) da lam. Xem
    docs/superpowers/specs/2026-08-13-iterator-protocol-design.md."""
    m = _FOR_IN_NAME_RE.match(line)
    if not m:
        return None
    var, record_var = m.groups()
    pos += 1
    if pos >= len(lines) or lines[pos][0] <= indent_level:
        raise SyntaxError(f"il_codegen: 'for {var} in {record_var}:' khong co than khoi (block rong)")
    body, pos = parse_block_fn(lines, pos, lines[pos][0], sig, known_shapes)
    return {'kind': 'for_in_iter', 'var': var, 'record_var': record_var, 'body': body}, pos
```

QUAN TRỌNG: đăng ký (Step 5) parser này SAU `'for'` (range) trong
`LINE_PARSERS` — dòng regex `_FOR_RANGE_RE` PHẢI thử trước (nó khớp cụ
thể `range(...)`, không khớp bare-name, nên thứ tự thực ra không xung
đột kỹ thuật, nhưng giữ thứ tự logic rõ ràng theo đúng comment).

- [ ] **Step 3: First-pass walk + prescan**

```python
def fpw_for_in_iter(stmt, ctx):
    var, record_var = stmt['var'], stmt['record_var']
    infer_scope = ctx['infer_scope']
    declared_names = ctx['declared_names']
    records = ctx.get('records') or {}
    record_methods = ctx.get('record_methods') or {}
    if record_var not in infer_scope._d:
        raise SyntaxError(
            f"il_codegen: 'for {var} in {record_var}:' - '{record_var}' chua duoc khai bao")
    _, _, record_ta = infer_scope[record_var]
    if record_ta.shape != 'record':
        raise SyntaxError(
            f"il_codegen: 'for {var} in {record_var}:' - '{record_var}' khong phai bien "
            f"kieu record (khong phai list/dict/set/range - cac dang do da duoc xu ly "
            f"o macro/parser rieng)")
    record_type = record_ta.dtype
    iter_m = record_methods.get(record_type, {}).get('__iter__')
    if iter_m is None or iter_m.params or iter_m.return_type is None:
        raise SyntaxError(
            f"il_codegen: record '{record_type}' can dinh nghia "
            f"'def __iter__(self) -> \"IterT\": ...' (0 tham so, co return type) "
            f"de dung trong 'for {var} in {record_var}:'")
    iter_ta = iter_m.return_type
    if iter_ta.shape != 'record' or iter_ta.dtype not in records:
        raise SyntaxError(
            f"il_codegen: record '{record_type}' co __iter__ nhung kieu tra ve "
            f"'{iter_ta.dtype}' khong phai 1 record hop le")
    next_m = record_methods.get(iter_ta.dtype, {}).get('__next__')
    if next_m is None or next_m.params or next_m.return_type is None or \
            next_m.return_type.shape != 'tuple' or \
            len(next_m.return_type.tuple_dtypes) != 2 or \
            next_m.return_type.tuple_dtypes[1] != 'i32':
        raise SyntaxError(
            f"il_codegen: record '{iter_ta.dtype}' can dinh nghia "
            f"'def __next__(self) -> \"(T, i32)\": ...' (0 tham so, tra ve tuple 2 "
            f"phan tu, phan tu thu 2 la i32 - co con/het) de dung trong "
            f"'for {var} in {record_var}:'")
    elem_dtype = next_m.return_type.tuple_dtypes[0]
    stmt['_iter_type'] = iter_ta.dtype
    stmt['_elem_dtype'] = elem_dtype
    if var not in declared_names:
        declared_names.add(var)
        elem_ta = ctx['TypeAnn'](elem_dtype, None)
        ctx['locals_decl'].append((var, elem_ta))
        infer_scope.set(var, elem_ta)
    iterobj = f"__iterobj{id(stmt)}"
    nexttmp = f"__iternext{id(stmt)}"
    stmt['_iterobj'] = iterobj
    stmt['_nexttmp'] = nexttmp
    if iterobj not in declared_names:
        declared_names.add(iterobj)
        iter_local_ta = ctx['TypeAnn'](iter_ta.dtype, 'record')
        ctx['locals_decl'].append((iterobj, iter_local_ta))
        infer_scope.set(iterobj, iter_local_ta)
    if nexttmp not in declared_names:
        declared_names.add(nexttmp)
        tuple_ta = ctx['TypeAnn'](elem_dtype, 'tuple', tuple_dtypes=[elem_dtype, 'i32'])
        ctx['locals_decl'].append((nexttmp, tuple_ta))
        infer_scope.set(nexttmp, tuple_ta)
    plan_str_accum(stmt, ctx)
    ctx['walk_fn'](stmt['body'])


def fpp_for_in_iter(stmt, ctx):
    ctx['prescan_fn'](stmt['body'])
```

Lưu ý: `ctx['TypeAnn'](elem_dtype, 'tuple', tuple_dtypes=[elem_dtype, 'i32'])`
— xác nhận CHỮ KÝ THẬT của `TypeAnn.__init__` (đã đọc ở
`compiler/typed_dsl_parser.py` dòng ~58: `tuple_dtypes` là keyword hợp
lệ) trước khi viết, đối chiếu cách `ctx['TypeAnn']` được các file
`il_features/*.py` khác gọi (grep `ctx\['TypeAnn'\](` để lấy ví dụ
thật, không đoán thứ tự tham số).

- [ ] **Step 4: Codegen `for_in_iter`**

```python
def codegen_for_in_iter(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    var, record_var = stmt['var'], stmt['record_var']
    iter_type, elem_dtype = stmt['_iter_type'], stmt['_elem_dtype']
    iterobj, nexttmp = stmt['_iterobj'], stmt['_nexttmp']
    records = ctx.get('records') or {}
    record_type = scope[record_var][2].dtype
    from il_features.record_feature import _method_owner_class
    from il_features.tuple_type import il_tupleN_type

    iter_owner = _method_owner_class(ctx, record_type, '__iter__')
    iter_il = ctx['il_type_str'](ctx['TypeAnn'](iter_type, 'record'), records)
    ctx['load_var_ref'](record_var, scope, body)
    body.append(f'    callvirt instance {iter_il} {iter_owner}::__iter__()')
    ctx['store_var'](iterobj, scope, body)

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl, end_lbl = f'{sig.name}_ForIter{n}_start', f'{sig.name}_ForIter{n}_end'
    tuple_type_il = il_tupleN_type([elem_dtype, 'i32'])
    next_owner = _method_owner_class(ctx, iter_type, '__next__')

    emit_sb_setup(stmt, scope, body, ctx)
    body.append(f'  {start_lbl}:')
    ctx['load_var_ref'](iterobj, scope, body)
    body.append(f'    callvirt instance {tuple_type_il} {next_owner}::__next__()')
    ctx['store_var'](nexttmp, scope, body)
    ctx['load_var_ref'](nexttmp, scope, body)
    body.append(f'    ldfld !1 {tuple_type_il}::Item2')
    body.append(f'    brfalse {end_lbl}')
    ctx['load_var_ref'](nexttmp, scope, body)
    body.append(f'    ldfld !0 {tuple_type_il}::Item1')
    ctx['store_var'](var, scope, body)
    ctx['loop_stack'].append((start_lbl, end_lbl))
    codegen_stmts_fn(stmt['body'], scope, body, body_dtype, ctx, sig)
    ctx['loop_stack'].pop()
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')
    emit_sb_flush(stmt, scope, body, ctx)
```

Đối chiếu KỸ với `codegen_while` (Step 1 đã đọc) để xác nhận
`ctx['load_var_ref']`/`ctx['store_var']` cho 1 LOCAL kiểu `tuple`
(value type `ValueTuple<T,i32>`) hoạt động đúng như với các local kiểu
khác — record/tuple đều là kiểu tham chiếu HOẶC giá trị khác nhau,
`store_var`/`load_var_ref` trong `il_codegen.py` PHẢI đã tổng quát hoá
theo `TypeAnn`, xác nhận bằng cách đọc định nghĩa 2 hàm đó (đã đọc
`_load_var_ref` ở dòng 858 từ trước — đối chiếu lại có tổng quát cho
tuple hay không, nếu không, tham khảo CHÍNH XÁC cách
`codegen_tuple_assign` nạp/lưu tuple local qua `stloc.s`/`ldloc.s`
TRỰC TIẾP bằng slot index (`scope[name]` trả `(?, slot_idx, ?)`) thay
vì qua `store_var`/`load_var_ref` tổng quát — NẾU `store_var` không hỗ
trợ tuple, đổi sang dùng slot index trực tiếp giống
`codegen_tuple_assign` đã làm (`_, tmp_idx, _ = scope[name]`, rồi
`stloc.s {tmp_idx}`/`ldloc.s {tmp_idx}`).

- [ ] **Step 5: Đăng ký vào `il_dispatch`**

Thêm cạnh các dòng đăng ký `for`/`for_in_list` hiện có, KHÔNG XOÁ
dòng cũ:

```python
register_line_parser('for_in_iter', try_parse_for_in_record)
register_first_pass_walk('for_in_iter', fpw_for_in_iter)
register_first_pass_prescan('for_in_iter', fpp_for_in_iter)
```

Đăng ký `codegen_for_in_iter` vào ĐÚNG cơ chế mà `codegen_with_ctx`
(task trước) đã dùng (`register_stmt_codegen`, theo báo cáo implementer
context-manager) cho stmt kind `'for_in_iter'`.

- [ ] **Step 6: Viết test `release/3.code/Testkit/iterator_protocol_test.tkv`**

Đọc `context_manager_test.tkv`/`dunder_getitem_test.tkv` trước để khớp
cú pháp. Case bắt buộc:

1. Record `Range3` (hoặc tên tương tự) có `__iter__(self) -> "Range3": return self`
   (chính nó là iterator, có field đếm nội bộ) và
   `__next__(self) -> "(i32, i32)": ...` — `for x in r:` in/tích luỹ
   đúng giá trị theo thứ tự, đúng số lần dừng.
2. `IterT` KHÁC record gốc — record `Bag` có `__iter__` trả về 1
   record `BagIter` RIÊNG (giữ tham chiếu tới `Bag` + chỉ số nội bộ),
   `BagIter.__next__` đọc dữ liệu từ `Bag`.
3. `break`/`continue` bên trong `for x in r:` — xác nhận dừng/nhảy
   đúng.
4. Record con kế thừa dùng `__iter__`/`__next__` của cha (không tự
   định nghĩa) — vẫn đúng qua `_method_owner_class`.

Case lỗi (thiếu `__iter__`/`__next__`, sai chữ ký `__next__`) xác nhận
bằng spike riêng ở Step 8, không đưa vào test chính.

- [ ] **Step 7: Build và chạy test qua cây `.py`**

```bash
python tkv.py build "D:\Claude AI Project\TokenVector\release\3.code\Testkit\iterator_protocol_test.tkv" --entry run --out "D:\Claude AI Project\TokenVector\release\3.code\Testkit\iterator_protocol_test.exe"
"D:\Claude AI Project\TokenVector\release\3.code\Testkit\iterator_protocol_test.exe"
```

Expected: build sạch, `SUMMARY N/N` đúng.

- [ ] **Step 8: Spike xác nhận case lỗi (không đưa vào test chính)**

File `.tkv` tạm: record thiếu `__iter__` → `for x in r:` raise
`SyntaxError` rõ. Record có `__iter__` nhưng `IterT` thiếu `__next__`
→ raise rõ. Record có `__next__` nhưng trả sai dạng (vd chỉ 1 giá trị,
không phải tuple 2 phần tử, hoặc phần tử thứ 2 không phải `i32`) →
raise rõ. Xoá spike sau khi xác nhận.

- [ ] **Step 9: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

Đặc biệt: MỌI test dùng `for x in <list/dict/set>:` (macro
`for_in_list`, tìm bằng grep) và `for x in range(...)` — xác nhận
KHÔNG regression (trừ lỗi pre-existing đã biết). Test có `break`/
`continue` trong `while`/`for range` khác (đảm bảo `ctx['loop_stack']`
dùng chung không bị lẫn lộn giữa loại vòng lặp).

- [ ] **Step 10: Mirror sang cây `.tkv` tự-host**

Sửa file mirror tương ứng trong `release/3.code/compiler/il_features/`
với logic TƯƠNG ĐƯƠNG Step 2-5.

- [ ] **Step 11: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đánh dấu mục 6.7 ĐÃ XONG, trỏ tới file spec này. Ghi chú lại: hạ tầng
này CÓ THỂ dùng lại cho `product()` (5.3 đã bỏ trước đó) trong 1
sub-project riêng SAU nếu cần, không tự động làm ở đây.

- [ ] **Step 12: Commit**

```bash
git add compiler/il_features/control_flow.py <duong-dan-file-mirror-that> release/3.code/Testkit/iterator_protocol_test.tkv docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): iterator protocol tuy bien __iter__/__next__ (for x in <record>:) - 6.7"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
