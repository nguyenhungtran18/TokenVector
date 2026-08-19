# `.lstrip(chars)`/`.rstrip(chars)` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `.lstrip(chars)`/`.rstrip(chars)` hoạt động giống `.strip(chars)` đã có — nhận tham số ký tự tuỳ chọn.

**Architecture:** Mirror ĐÚNG pattern `compile_str_method_strip` (`string_methods_batch2.py`) sang `compile_str_method_lstrip`/`compile_str_method_rstrip` (`string_methods_batch3.py`).

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror.

## Global Constraints

- Sửa đồng bộ cả 2 cây. KHÔNG rebuild `tkvc.exe`.
- Dạng 0-tham-số hiện có không đổi hành vi.

---

### Task 1: Thêm tham số `chars` cho `.lstrip()`/`.rstrip()`

**Files:**
- Modify: `compiler/il_features/string_methods_batch3.py` (dòng ~101-124)
- Modify: mirror `.tkv` tương ứng
- Create: `release/3.code/Testkit/lstrip_rstrip_chars_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

- [ ] **Step 1: Đọc mẫu `compile_str_method_strip`** (`string_methods_batch2.py:35-51`) làm khuôn chính xác.

- [ ] **Step 2: Sửa `compile_str_method_lstrip`**:
```python
def compile_str_method_lstrip(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) not in (0, 1):
        raise SyntaxError("il_codegen: s.lstrip() hoac s.lstrip(chars) can 0 hoac 1 tham so")
    _validate_str_method_caller(obj_name, scope)
    ctx['load_var_ref'](obj_name, scope, out)
    if len(args) == 1:
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    callvirt instance char[] [mscorlib]System.String::ToCharArray()')
    else:
        out.append('    ldnull')
    out.append('    callvirt instance string [mscorlib]System.String::TrimStart(char[])')
```
  Tương tự cho `compile_str_method_rstrip` (đổi `TrimStart`→`TrimEnd`).

- [ ] **Step 3: Test** — `"  xxHello Worldxx  ".lstrip(" x")` → `"Hello Worldxx  "`; `.rstrip(" x")` → `"  xxHello World"`; dạng 0-tham-số cũ vẫn PASS.

- [ ] **Step 4: Build + regression** — chạy test mới + toàn bộ `Testkit/*.tkv`, đặc biệt mọi test dùng `.strip()`/`.lstrip()`/`.rstrip()` hiện có.

- [ ] **Step 5: Mirror `.tkv`, cập nhật checklist, commit.**

```bash
git commit -m "feat(compiler): .lstrip(chars)/.rstrip(chars) - mirror .strip(chars) da co"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
