# .format() keyword args Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm hỗ trợ `.format(name=value, ...)` và placeholder `{name}`
vào macro `.format()`, đóng mục thứ 3 của batch 5.5b trong
`docs/PYTHON_GAP_CHECKLIST.md`.

**Architecture:** `.format()` là macro TEXT-LEVEL (chạy trước parser AST
chung) — tự xử lý `name=value` CHỈ RIÊNG bên trong `.format(...)`, không
đổi cú pháp gọi hàm DSL nói chung. `_split_top_level_args` trả về
`(positional, kwargs)` thay vì chỉ `list`, `_PLACEHOLDER_RE` mở rộng
nhận `{name}`, `_format_content_to_concat_expr` tra `kwargs` khi
placeholder không phải số.

**Tech Stack:** Python 3 (compiler), macro text-rewrite (không sinh IL
trực tiếp — `.format()` viết lại thành biểu thức nối chuỗi rồi để
pipeline `str()`/`fmt_float()` hiện có xử lý).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe` ở BẤT KỲ
  task nào trong plan này.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100% (hiện `string_format.py`/`.tkv` byte-identical,
  177 dòng — giữ nguyên tắc đó).
- `{}`/`{N}`/`{N:.Mf}` (placeholder theo chỉ số) PHẢI giữ NGUYÊN hành vi
  cũ — không được có regression trên `string_format_test.tkv` hiện có.
- Regex tách `name=value` PHẢI tránh khớp nhầm `==`/`>=`/`<=`/`!=` bên
  trong biểu thức đối số.
- Chỉ nhận dạng `"literal".format(...)` — KHÔNG mở rộng sang `s.format(...)`
  với `s` là biến (giới hạn cũ giữ nguyên, ngoài phạm vi).
- Không refactor code không liên quan ngoài phạm vi `.format()`.

---

### Task 1: `.format()` keyword args — macro + test + regression + docs

**Files:**
- Modify: `compiler/il_features/string_format.py` (177 dòng hiện tại —
  sửa `_split_top_level_args` dòng 31-61, `_PLACEHOLDER_RE` dòng 28,
  `_format_content_to_concat_expr` dòng 90-123, `try_expand_format`
  dòng 149-155 nơi gọi `_split_top_level_args`)
- Modify: `release/3.code/compiler/il_features/string_format.tkv`
  (mirror, hiện byte-identical với `.py`)
- Test: `release/3.code/Testkit/string_format_test.tkv` (mở rộng file
  có sẵn)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: không phụ thuộc gì mới ngoài `re` module (đã import sẵn).
- Produces: không có interface mới cho task khác — đây là mục batch độc
  lập, đóng gói trong 1 task duy nhất (đủ nhỏ để không cần tách 2 task
  như 2 batch item trước).

- [ ] **Step 1: Viết test THẤT BẠI trước (TDD) — mở rộng
  `string_format_test.tkv`**

Sửa `release/3.code/Testkit/string_format_test.tkv`, chèn TRƯỚC dòng
`return test_summary(...)`:

```python
    tested = tested + 1
    total = total + check("format_kwargs_only",
                           "Hello, {name}! You are {age}.".format(name="Alice", age=str(30)),
                           "Hello, Alice! You are 30.")

    tested = tested + 1
    total = total + check("format_mixed_positional_kwargs",
                           "{0} says hi to {name}".format("Bob", name="Carol"),
                           "Bob says hi to Carol")
```

**LƯU Ý**: `age=str(30)` dùng `str(30)` thay vì số nguyên trực tiếp vì
`format_args`/`kwargs` trong macro là biểu thức DẠNG CHUỖI VĂN BẢN được
nối bằng `str(...)` ở `_format_content_to_concat_expr` — kiểm tra lại
cách test hiện có (`format_auto_index` dùng biến `name` kiểu `str`) để
biết đúng quy ước trước khi quyết định dùng nguyên `30` hay `str(30)`
(macro tự bọc `str(arg_expr)` nên truyền `30` trực tiếp cũng hợp lệ —
ưu tiên dùng `30` trực tiếp cho đơn giản NẾU macro xử lý đúng, chỉ dùng
`str(30)` nếu build báo lỗi type).

- [ ] **Step 2: Chạy build, xác nhận THẤT BẠI đúng cách (macro chưa hỗ
  trợ `{name}`/`name=value`)**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/string_format_test.tkv --entry run --out "$env:TEMP/fmt_kw_before.exe"
```
Expected: build LỖI (hoặc build thành công nhưng sinh sai — macro hiện
tại không nhận diện `name=value` là kwarg, `_split_top_level_args` coi
nguyên `name="Alice"` là 1 phần tử positional dạng text `name="Alice"`,
`_PLACEHOLDER_RE` không khớp `{name}` nên để nguyên `{name}` trong chuỗi
kết quả — quan sát THỰC TẾ lỗi/kết quả sai là gì trước khi sang Step 3,
không giả định).

- [ ] **Step 3: Sửa `_PLACEHOLDER_RE` nhận placeholder dạng tên**

Sửa dòng 28 trong `compiler/il_features/string_format.py`:
```python
_PLACEHOLDER_RE = re.compile(r'\{(\d*)(:\.(\d+)f)?\}')
```
thành:
```python
_PLACEHOLDER_RE = re.compile(r'\{(\w*)(:\.(\d+)f)?\}')
```
(`\w*` thay `\d*` — khớp CẢ rỗng/số/tên trong 1 nhóm, phân biệt ở bước
xử lý sau bằng `int()`/`except ValueError`.)

- [ ] **Step 4: Sửa `_split_top_level_args` trả về `(positional, kwargs)`**

Thay TOÀN BỘ hàm (dòng 31-61) trong `compiler/il_features/string_format.py`:

```python
_KWARG_RE = re.compile(r'^(\w+)\s*=(?!=)(.*)$', re.DOTALL)


def _split_top_level_args(s: str):
    """Tach 's' (noi dung ben trong '(...)') thanh (positional, kwargs)
    theo dau phay O MUC NGOAI CUNG - bo qua dau phay nam trong ngoac/
    chuoi con long ben trong (vd 'f(a, b)' hay '"a, b"' la 1 tham so,
    khong phai 2). Rong -> ([], {}) (ham .format() khong tham so).
    Moi phan tach duoc PHAN LOAI positional/keyword bang _KWARG_RE
    ('name=value', dau '=' KHONG theo sau boi '=' khac - tranh kop nham
    '=='/'>='/'<='/'!=' ben trong bieu thuc doi so) - batch 5.5b muc 3,
    2026-08-13."""
    s = s.strip()
    if not s:
        return [], {}
    raw_parts = []
    depth = 0
    quote = None
    start = 0
    i = 0
    n = len(s)
    while i < n:
        ch = s[i]
        if quote:
            if ch == quote:
                quote = None
        elif ch in ('"', "'"):
            quote = ch
        elif ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        elif ch == ',' and depth == 0:
            raw_parts.append(s[start:i].strip())
            start = i + 1
        i += 1
    raw_parts.append(s[start:].strip())

    positional = []
    kwargs = {}
    for part in raw_parts:
        m = _KWARG_RE.match(part)
        if m:
            kwargs[m.group(1)] = m.group(2).strip()
        else:
            positional.append(part)
    return positional, kwargs
```

- [ ] **Step 5: Sửa `_format_content_to_concat_expr` nhận thêm `kwargs`,
  tra cứu theo tên**

Thay TOÀN BỘ hàm (dòng 90-123) trong `compiler/il_features/string_format.py`:

```python
def _format_content_to_concat_expr(content: str, format_args, kwargs) -> str:
    """'content' la noi dung BEN TRONG dau nhay cua chuoi format (khong
    kem dau nhay), 'format_args' la danh sach bieu thuc POSITIONAL,
    'kwargs' la dict TEN -> bieu thuc KEYWORD (batch 5.5b muc 3,
    2026-08-13). Tra ve bieu thuc noi chuoi tuong duong, CUNG khuon voi
    fstring.py's _fstring_to_concat_expr."""
    pieces = _PLACEHOLDER_RE.split(content)
    parts = []
    auto_idx = 0
    i = 0
    while i < len(pieces):
        literal = pieces[i]
        if literal:
            parts.append(f'"{literal}"')
        if i + 1 >= len(pieces):
            break
        idx_str, _full_spec, precision = pieces[i + 1], pieces[i + 2], pieces[i + 3]
        if idx_str == '':
            arg_expr = format_args[auto_idx] if auto_idx < len(format_args) else None
            if arg_expr is None:
                raise SyntaxError(
                    f"il_codegen: .format() thieu tham so cho placeholder tu dong "
                    f"chi so {auto_idx} (chi truyen {len(format_args)} tham so positional)")
            auto_idx += 1
        else:
            try:
                idx = int(idx_str)
            except ValueError:
                if idx_str not in kwargs:
                    raise SyntaxError(
                        f"il_codegen: .format() thieu tham so keyword '{idx_str}'")
                arg_expr = kwargs[idx_str]
            else:
                if idx >= len(format_args):
                    raise SyntaxError(
                        f"il_codegen: .format() thieu tham so cho placeholder chi so {idx} "
                        f"(chi truyen {len(format_args)} tham so positional)")
                arg_expr = format_args[idx]
        if precision is not None:
            parts.append(f'fmt_float({arg_expr}, {precision})')
        else:
            parts.append(f'str({arg_expr})')
        i += 4
    if not parts:
        return '""'
    return '(' + ' + '.join(parts) + ')'
```

- [ ] **Step 6: Cập nhật điểm gọi trong `try_expand_format`**

Sửa dòng 153-155 trong `compiler/il_features/string_format.py`:
```python
                    args_str = line[open_idx + 1:close_idx]
                    format_args = _split_top_level_args(args_str)
                    out.append(_format_content_to_concat_expr(content, format_args))
```
thành:
```python
                    args_str = line[open_idx + 1:close_idx]
                    format_args, format_kwargs = _split_top_level_args(args_str)
                    out.append(_format_content_to_concat_expr(content, format_args, format_kwargs))
```

- [ ] **Step 7: Build lại, xác nhận test PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/string_format_test.tkv --entry run --out "$env:TEMP/fmt_kw_after.exe"
"$env:TEMP/fmt_kw_after.exe"
```
Expected: build PASS, `SUMMARY 7/7` (5 test cũ + 2 test mới
`format_kwargs_only`/`format_mixed_positional_kwargs`).

- [ ] **Step 8: Mirror TOÀN BỘ Step 3-6 sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/string_format.tkv` (file hiện
byte-identical với `.py`, giữ nguyên tắc đó).

- [ ] **Step 9: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/fmtkw_reg_${base}.exe" > "$TEMP/fmtkw_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/fmtkw_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan). ĐẶC BIỆT chú ý mọi file khác có dùng
`.format(` (tìm bằng `grep -l "\.format(" release/3.code/Testkit/*.tkv`)
— xác nhận không hồi quy.

- [ ] **Step 10: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đọc lại dòng hiện tại của `5.5b batch nhỏ còn lại` (sau khi 2 mục
`re.findall/split` và `.replace(...,count)` đã tách ra ở các plan
trước, hiện còn `.format() kwargs`, `os.path.splitext()`, `divmod()`,
`set.remove()`). Tách `.format() kwargs` thành dòng `[x]` riêng, giữ 3
mục còn lại:

```
- [x] `.format()` keyword args — **ĐÃ XONG (2026-08-13)**. `{name}`
      placeholder + `.format(name=value)` — macro text-level tự phân
      loại positional/keyword qua regex `name=value` (tránh khớp nhầm
      `==`/`>=`/`<=`/`!=`), positional+keyword trộn lẫn được. Xem
      `docs/superpowers/specs/2026-08-13-format-kwargs-design.md`.
- [ ] 5.5b batch nhỏ còn lại: `os.path.splitext()`, `divmod()`,
      `set.remove()` phải ném lỗi khi thiếu phần tử
```

(Đọc lại nội dung THẬT của file trước khi sửa — không giả định đúng
format trên nếu khác thực tế.)

- [ ] **Step 11: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/string_format.py \
        release/3.code/compiler/il_features/string_format.tkv \
        release/3.code/Testkit/string_format_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): .format() keyword args - {name} + .format(name=value)

Macro text-level tu phan loai positional/keyword trong .format(...) qua
regex name=value (khong khop nham ==/>=/<=/!=), khong doi cu phap goi
ham DSL noi chung. _PLACEHOLDER_RE mo rong nhan {name} canh {}/{N} cu.
Positional+keyword tron lan duoc, khop Python that. Test moi xac nhan
kwargs-only + mixed positional/keyword. Regression toan bo Testkit/*.tkv
- khong hoi quy moi.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
