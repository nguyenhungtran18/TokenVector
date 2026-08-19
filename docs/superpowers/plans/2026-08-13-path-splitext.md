# os.path.splitext() Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm `path_splitext(p) -> (str, str)`, dùng được qua
`root, ext = path_splitext(p)`, đóng mục 4 batch 5.5b trong
`docs/PYTHON_GAP_CHECKLIST.md`.

**Architecture:** `path_splitext` (`compiler/il_features/stdlib_path.py`)
sinh `Path.GetExtension` + `Substring` tính `root`, trả `ValueTuple<string,
string>` qua `register_expr_builtin(..., return_ta=TypeAnn('str', 'tuple',
tuple_dtypes=['str','str']))`. Cơ chế giải nén `x, y = f(...)`
(`compiler/il_features/tuple_type.py`) hiện CHỈ nhận hàm người dùng (tra
`func_table`) — mở rộng thêm nhánh tra `EXPR_BUILTIN_RETURN_TA` khi
`call_node[1]` không phải hàm người dùng, tái dùng được cho builtin trả
tuple khác sau này.

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe` ở BẤT KỲ
  task nào trong plan này.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100% ở mọi task chạm code.
- Task 1 (mở rộng `tuple_assign` hỗ trợ builtin) PHẢI giữ NGUYÊN hành vi
  hiện có cho `x, y = f(...)` khi `f` là hàm người dùng — không regression.
- File bắt đầu bằng dấu chấm không extension khác (`.bashrc`) lệch
  Python (`.NET Path.GetExtension` coi toàn bộ là extension) — giới hạn
  CÓ CHỦ ĐÍCH, không xử lý riêng.
- Không refactor code không liên quan ngoài phạm vi 2 file
  `stdlib_path.py`/`tuple_type.py`.

---

### Task 1: Mở rộng `tuple_assign` nhận diện builtin trả tuple (core)

**Files:**
- Modify: `compiler/il_features/tuple_type.py` (223 dòng hiện tại —
  sửa `fpw_tuple_assign` dòng 182-202, `codegen_tuple_assign` dòng
  111-128)
- Modify: `release/3.code/compiler/il_features/tuple_type.tkv` (mirror,
  hiện byte-identical với `.py`)

**Interfaces:**
- Consumes: `EXPR_BUILTIN_RETURN_TA` (registry có sẵn trong
  `il_dispatch.py:88`, điền qua `register_expr_builtin`'s `return_ta`
  param — CHƯA từng dùng cho builtin `shape='tuple'` nhưng không giới
  hạn shape cụ thể nào).
- Produces: `x, y = some_builtin(...)` hoạt động cho MỌI builtin đăng ký
  `return_ta=TypeAnn(..., 'tuple', tuple_dtypes=[...])` — Task 2 dùng
  interface này cho `path_splitext`.

- [ ] **Step 1: Sửa `fpw_tuple_assign` — thêm nhánh tra
  `EXPR_BUILTIN_RETURN_TA`**

Thêm import ở đầu `compiler/il_features/tuple_type.py` (dòng 18, cạnh
các import `il_dispatch` có sẵn):
```python
from il_dispatch import (register_line_parser, register_stmt_codegen,
                          register_first_pass_walk, EXPR_BUILTIN_RETURN_TA)
```

Sửa nhánh `elif len(rhs_nodes) == 1:` trong `fpw_tuple_assign` (dòng
182-202 hiện tại):

```python
    elif len(rhs_nodes) == 1:
        # 'x, y, ... = f(...)' - f tra ve 1 tuple that. f co the la HAM
        # NGUOI DUNG (tra func_table, nhu truoc gio) HOAC 1 BUILTIN dang
        # ky return_ta shape='tuple' (batch 5.5b muc 4, 2026-08-13 - vd
        # path_splitext(p) -> (str,str)) - tra EXPR_BUILTIN_RETURN_TA
        # TRUOC, chi raise loi neu CA HAI deu khong khop.
        call_node = rhs_nodes[0]
        if call_node[0] != 'call':
            raise SyntaxError(
                f"il_codegen: '{', '.join(targets)} = ...' voi 1 gia tri ben phai "
                f"phai la 1 loi goi ham TRA VE TUPLE {len(targets)} phan tu "
                f"(vd 'x, y = f(...)')")
        builtin_name = call_node[1]
        if func_table and builtin_name in func_table:
            callee = func_table[builtin_name]
            if callee.return_type is None or callee.return_type.shape != 'tuple' or \
                    len(callee.return_type.tuple_dtypes) != len(targets):
                raise SyntaxError(
                    f"il_codegen: ham '{builtin_name}' khong tra ve tuple {len(targets)} "
                    f"phan tu (can '-> \"({', '.join(['dtype'] * len(targets))})\"' trong chu ky)")
            dtypes = callee.return_type.tuple_dtypes
        elif builtin_name in EXPR_BUILTIN_RETURN_TA and \
                EXPR_BUILTIN_RETURN_TA[builtin_name].shape == 'tuple':
            builtin_ta = EXPR_BUILTIN_RETURN_TA[builtin_name]
            if len(builtin_ta.tuple_dtypes) != len(targets):
                raise SyntaxError(
                    f"il_codegen: '{builtin_name}(...)' tra ve tuple "
                    f"{len(builtin_ta.tuple_dtypes)} phan tu, khong khop "
                    f"{len(targets)} target ben trai")
            dtypes = builtin_ta.tuple_dtypes
        else:
            raise SyntaxError(
                f"il_codegen: '{', '.join(targets)} = ...' voi 1 gia tri ben phai "
                f"phai la 1 loi goi ham TRA VE TUPLE {len(targets)} phan tu "
                f"(vd 'x, y = f(...)')")
        for t, d in zip(targets, dtypes):
            declare_named(t, TypeAnn(d, None))
        declare_named(f'__tupleassign{id(stmt)}_tmp',
                      TypeAnn(dtypes[0], 'tuple', tuple_dtypes=dtypes))
        for arg_node in call_node[2]:
            collect_ternary_temps(arg_node)
```

- [ ] **Step 2: Sửa `codegen_tuple_assign` — tương tự cho phần sinh IL**

Sửa nhánh `elif len(rhs_nodes) == 1:` trong `codegen_tuple_assign`
(dòng 111-128 hiện tại):

```python
    elif len(rhs_nodes) == 1:
        # 'x, y, ... = f(...)' - f co the la HAM NGUOI DUNG (func_table)
        # HOAC 1 BUILTIN dang ky return_ta shape='tuple' (xem
        # fpw_tuple_assign o tren, CUNG logic phan nhanh). f tra ve 1
        # ValueTuple<T1..TN> that - luu vao local tam TRUOC roi doc lai
        # N lan (ldfld doc truc tiep tren 1 gia tri value-type KHONG can
        # dia chi, nhung can nap lai MOI LAN vi ldfld 'tieu thu' instance
        # tren dinh stack - da xac minh THAT bang probe .il rieng, N=2
        # session truoc + N=3 probe_tuple3.il).
        call_node = rhs_nodes[0]
        builtin_name = call_node[1]
        if ctx.get('func_table') and builtin_name in ctx['func_table']:
            dtypes = ctx['func_table'][builtin_name].return_type.tuple_dtypes
        else:
            from il_dispatch import EXPR_BUILTIN_RETURN_TA as _EBRT
            dtypes = _EBRT[builtin_name].tuple_dtypes
        tuple_type = il_tupleN_type(dtypes)
        _, tmp_idx, _ = scope[f'__tupleassign{id(stmt)}_tmp']
        compile_expr(call_node, scope, body, dtypes[0], ctx)
        body.append(f'    stloc.s {tmp_idx}')
        for i, t in enumerate(targets):
            body.append(f'    ldloc.s {tmp_idx}')
            body.append(f'    ldfld !{i} {tuple_type}::Item{i + 1}')
            store_var(t, scope, body)
```

**LƯU Ý**: `codegen_tuple_assign` nhận `ctx` làm tham số (chữ ký hàm đã
có `def codegen_tuple_assign(stmt, scope, body, body_dtype, ctx, sig,
codegen_stmts_fn):`) — dùng `ctx['func_table']` thay vì biến `func_table`
module-level như trong `fpw_tuple_assign` (2 hàm có ngữ cảnh biến khác
nhau, đọc lại chữ ký từng hàm trước khi copy y nguyên).

- [ ] **Step 3: Mirror Step 1/2 sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/tuple_type.tkv` (hiện byte-identical
với `.py`, giữ nguyên tắc đó).

- [ ] **Step 4: Xác nhận KHÔNG regression trên `tuple_assign` hàm người
  dùng hiện có**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -l "= .*(.*).*#.*tuple\|, .* = [a-z_]*(" release/3.code/Testkit/*.tkv 2>/dev/null | head -5
```
Tìm ít nhất 1 file test hiện có dùng `x, y = f(...)` với `f` là hàm
người dùng (không phải builtin) — build+chạy thật, xác nhận PASS y hệt
trước khi sửa (không có cách build "trước" nữa vì Task 1 sửa trực tiếp
— dùng `git stash`/so sánh code review để xác nhận nhánh `func_table`
giữ nguyên logic, hoặc build tại đúng commit base TRƯỚC khi sửa để lấy
baseline output nếu nghi ngờ).

- [ ] **Step 5: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/tuple_type.py \
        release/3.code/compiler/il_features/tuple_type.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): tuple_assign nhan dien builtin tra tuple (khong chi func_table)

'x, y = f(...)' truoc gio CHI nhan f la ham NGUOI DUNG (tra func_table).
Them nhanh tra EXPR_BUILTIN_RETURN_TA khi f khong phai ham nguoi dung -
builtin dang ky return_ta shape='tuple' (vd path_splitext sap toi) giai
nen duoc qua CUNG co che. Giu nguyen hanh vi nhanh func_table cu, khong
regression.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `path_splitext(p)` + test + regression + docs

**Files:**
- Modify: `compiler/il_features/stdlib_path.py` (90 dòng hiện tại —
  thêm hàm mới cuối file, trước dòng `register_expr_builtin('path_join', ...)`)
- Modify: `release/3.code/compiler/il_features/stdlib_path.tkv`
  (mirror, hiện byte-identical với `.py`)
- Test: `release/3.code/Testkit/path_splitext_test.tkv` (MỚI)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `EXPR_BUILTIN_RETURN_TA`/`tuple_assign` mở rộng từ Task 1.
- Produces: không có interface mới cho task khác — task đóng gói cuối.

- [ ] **Step 1: Xác nhận chữ ký `Path.GetExtension`/`String.Substring(int,int)`
  đã có tiền lệ dùng trong codebase**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "GetExtension\|Substring(int32, int32)" compiler/il_features/*.py
```
`Substring(int32, int32)` đã có tiền lệ (xem `TkvStr::ReplaceCount`,
batch 5.5b mục 2). `Path.GetExtension` chưa từng dùng — xác nhận qua
PowerShell:
```bash
powershell -Command "[System.IO.Path].GetMethod('GetExtension')"
```
Expected: `System.String GetExtension(System.String)`.

- [ ] **Step 2: Viết `_splitext_temps`/`compile_path_splitext` trong
  `stdlib_path.py`**

Thêm vào cuối file (TRƯỚC khối `register_expr_builtin('path_join', ...)`
cuối cùng), và thêm import `TypeAnn` ở đầu file:

```python
from typed_dsl_parser import TypeAnn


def _splitext_temps(node, ctx):
    """FIRST PASS: khai 2 local an cho path_splitext(p) - 'p' (gia tri
    duong dan, giu de dung 2 lan: tinh ext VA tinh root), 'ext' (phan
    mo rong, giu de dua vao ca phep tru do dai VA gia tri tuple cuoi).
    Batch 5.5b muc 4, 2026-08-13."""
    args = node[2]
    if len(args) != 1:
        return
    TypeAnn_ = ctx['TypeAnn']
    ctx['declare_named'](f'__pse{id(args)}_p', TypeAnn_('str', None))
    ctx['declare_named'](f'__pse{id(args)}_ext', TypeAnn_('str', None))


def compile_path_splitext(args, scope, out, dtype, ctx):
    """path_splitext(p) -> (str, str) - Path.GetExtension(p) lay ext,
    root = p.Substring(0, p.Length - ext.Length). GIOI HAN DA BIET: file
    bat dau bang dau cham khong co extension khac (vd '.bashrc') -
    .NET Path.GetExtension coi TOAN BO la extension, khac Python (coi la
    KHONG co extension) - chap nhan duoc, xem spec 2026-08-13-path-
    splitext-design.md."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_splitext(p) chi nhan dung 1 tham so")
    compile_expr = ctx['compile_expr']
    p_idx = scope[f'__pse{id(args)}_p'][1]
    ext_idx = scope[f'__pse{id(args)}_ext'][1]

    compile_expr(args[0], scope, out, 'str', ctx)
    out.append(f'    stloc.s {p_idx}')

    out.append(f'    ldloc.s {p_idx}')
    out.append('    call string [mscorlib]System.IO.Path::GetExtension(string)')
    out.append(f'    stloc.s {ext_idx}')

    # root = p.Substring(0, p.Length - ext.Length)
    out.append(f'    ldloc.s {p_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    ldloc.s {p_idx}')
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append(f'    ldloc.s {ext_idx}')
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    sub')
    out.append('    callvirt instance string [mscorlib]System.String::Substring(int32, int32)')

    out.append(f'    ldloc.s {ext_idx}')
    out.append('    newobj instance void valuetype '
                '[mscorlib]System.ValueTuple`2<string, string>::.ctor(!0, !1)')
```

**LƯU Ý thứ tự operand `sub`**: `p.Length - ext.Length` — đẩy `p.Length`
TRƯỚC, `ext.Length` SAU, rồi `sub` (đối chiếu đúng thứ tự đã xác nhận ở
`TkvStr::ReplaceCount` batch 5.5b mục 2 — `sub` lấy `[value1] -
[value2]` với `value1` đẩy trước).

- [ ] **Step 3: Đăng ký `path_splitext`**

Sửa dòng cuối file, thêm SAU dòng đăng ký `path_isdir` hiện có:
```python
register_expr_builtin('path_splitext', compile_path_splitext, None,
                       temps_fn=_splitext_temps,
                       return_ta=TypeAnn('str', 'tuple', tuple_dtypes=['str', 'str']))
```

- [ ] **Step 4: Mirror Step 2/3 sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/stdlib_path.tkv`.

- [ ] **Step 5: Viết test mới `path_splitext_test.tkv`**

Tạo `release/3.code/Testkit/path_splitext_test.tkv`:

```python
__tkv_import__ = ["tkv_test_lib"]

def run() -> "i32":
    total = 0
    tested = 0

    p1 = "a/b/file.txt"
    root1, ext1 = path_splitext(p1)
    tested = tested + 1
    total = total + check("splitext_root", root1, "a/b/file")
    tested = tested + 1
    total = total + check("splitext_ext", ext1, ".txt")

    p2 = "noext"
    root2, ext2 = path_splitext(p2)
    tested = tested + 1
    total = total + check("splitext_no_ext_root", root2, "noext")
    tested = tested + 1
    total = total + check("splitext_no_ext_ext", ext2, "")

    p3 = "archive.tar.gz"
    root3, ext3 = path_splitext(p3)
    tested = tested + 1
    total = total + check("splitext_multi_dot_root", root3, "archive.tar")
    tested = tested + 1
    total = total + check("splitext_multi_dot_ext", ext3, ".gz")

    return test_summary("path_splitext_test", total, tested)
```

- [ ] **Step 6: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/path_splitext_test.tkv --entry run --out "$env:TEMP/pse_t2.exe"
"$env:TEMP/pse_t2.exe"
```
Expected: build PASS, `SUMMARY 6/6`.

- [ ] **Step 7: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/pse_reg_${base}.exe" > "$TEMP/pse_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/pse_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan).

- [ ] **Step 8: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đọc lại nội dung THẬT của dòng `5.5b batch nhỏ còn lại` (sau khi 3 mục
trước đã tách ra ở các plan trước, hiện còn `os.path.splitext()`,
`divmod()`, `set.remove()`). Tách `os.path.splitext()` thành dòng `[x]`
riêng, giữ 2 mục còn lại:

```
- [x] `os.path.splitext()` — **ĐÃ XONG (2026-08-13)**. `path_splitext(p)
      -> (str, str)` qua `Path.GetExtension` + `Substring`. Mở rộng cơ
      chế `tuple_assign` nhận diện builtin trả tuple (không chỉ hàm
      người dùng). Giới hạn: file bắt đầu bằng dấu chấm không extension
      khác lệch Python. Xem
      `docs/superpowers/specs/2026-08-13-path-splitext-design.md`.
- [ ] 5.5b batch nhỏ còn lại: `divmod()`, `set.remove()` phải ném lỗi
      khi thiếu phần tử
```

(Đọc lại nội dung THẬT của file trước khi sửa — không giả định đúng
format trên nếu khác thực tế.)

- [ ] **Step 9: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/stdlib_path.py \
        release/3.code/compiler/il_features/stdlib_path.tkv \
        release/3.code/Testkit/path_splitext_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): path_splitext(p) -> (str, str)

Path.GetExtension + Substring tinh root, tra ValueTuple<string,string>
qua return_ta shape='tuple' (dung co che tuple_assign moi mo rong o Task
1). Test moi xac nhan co extension/khong extension/nhieu dau cham. Gioi
han da biet: file bat dau bang dau cham lech Python. Regression toan bo
Testkit/*.tkv - khong hoi quy moi. Danh dau os.path.splitext() xong
trong checklist 5.5b.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
