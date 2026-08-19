# `frozenset` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `fs = frozenset(a_list)` tạo `HashSet<T>` điền sẵn (bất biến — `.add`/`.remove`/`.discard` bị chặn compile-time), đọc (`in`/`len`/`for`) hoạt động y hệt `set`.

**Architecture:** Thêm `shape='frozenset'` — 1 `ASSIGN_RHS_PARSERS` entry mới nhận list nguồn, dùng ctor `HashSet<T>(IEnumerable<T>)` của BCL. Mở rộng các điểm ĐỌC hiện có (`shape == 'set'` → `shape in ('set', 'frozenset')`), thêm guard chặn ở các điểm MUTATE (`.add`/`.remove`/`.discard`).

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror, CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ cả 2 cây. KHÔNG rebuild `tkvc.exe`.
- Chỉ `frozenset(<bien_list_don>)` — không rỗng, không biểu thức phức tạp.
- `.add()`/`.remove()`/`.discard()` trên `frozenset` → `SyntaxError` rõ.
- KHÔNG đổi hành vi `set` thường hiện có.

---

### Task 1: `frozenset` — constructor + đọc + chặn mutate

**Files:**
- Modify: `compiler/il_features/set_type.py` (constructor mới, `il_set_type` dùng chung)
- Modify: `compiler/il_codegen.py` (5 điểm `shape == 'set'` đọc — dòng ~123, 1152, 1254, 1531, 1714, đọc lại từng điểm để xác nhận điểm nào là ĐỌC vs điểm nào không liên quan trước khi sửa)
- Modify: `compiler/il_features/set_methods_batch2.py`/nơi codegen `.add()`/`.remove()`/`.discard()` thật (grep `_SET_ADD_RE`/tương đương cho remove/discard — có thể nằm ở `set_type.py` và `set_methods_batch2.py` cả hai)
- Modify: mirror `.tkv` tương ứng của các file trên
- Create: `release/3.code/Testkit/frozenset_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `il_set_type`, `ctx['records']`, `scope`/`known_shapes` (cơ chế `ASSIGN_RHS_PARSERS` có sẵn, xem `try_rhs_set_new` làm mẫu).
- Produces: `shape='frozenset'` — dùng nội bộ, không API mới cho task khác.

- [ ] **Step 1: Đọc mẫu `try_rhs_set_new`/`codegen_assign_set_new`** (`set_type.py` dòng ~46-69) và xác nhận `HashSet<T>(IEnumerable<T>)` ctor tồn tại thật qua PowerShell reflection (giống kỷ luật đã dùng cho `List<T>(IEnumerable<T>)` ở `random.sample()`):
  ```powershell
  [System.Collections.Generic.HashSet[int]].GetConstructors() | ForEach-Object { $_.ToString() }
  ```
  Xác nhận có overload nhận `IEnumerable<T>`.

- [ ] **Step 2: Viết `try_rhs_frozenset_new`** (song song `try_rhs_set_new`) — regex `^frozenset\((\w+)\)\s*$`, tra `known_shapes`/`scope` xác nhận nguồn là `list` (nếu chưa biết dtype, báo lỗi rõ — list nguồn PHẢI đã khai báo TRƯỚC dòng này trong văn bản, giống giới hạn thứ tự khai báo quen thuộc của dự án), dtype phần tử = dtype của list nguồn, gắn `known_shapes[name] = 'frozenset'`.

- [ ] **Step 3: Viết `codegen_assign_frozenset_new`** — `load_var_ref(list_nguon)`, `newobj instance void {hashset_type}::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable\`1<T>)`, `store_var`.

- [ ] **Step 4: Mở rộng các điểm ĐỌC** — đọc lại từng điểm `shape == 'set'` trong `il_codegen.py`/`stdlib_aggregates.py`, đổi thành `shape in ('set', 'frozenset')` CHỈ ở những điểm xử lý đọc (`in`, `len()`, index-error-message, `il_type_str`). Điểm nào liên quan riêng tới `set()` rỗng/`.add()` (vd `set_type.py:93` `declare_set`) KHÔNG sửa — `frozenset` không đi qua đường đó.

- [ ] **Step 5: Chặn mutate** — thêm guard đầu `codegen_set_add`/hàm tương đương cho `.remove()`/`.discard()`: `if ta.shape == 'frozenset': raise SyntaxError(f"il_codegen: '{{name}}' la frozenset (bat bien) - khong the .{{method}}()")`.

- [ ] **Step 6: Test + build + regression** — case: `fs = frozenset(lst)`, `x in fs` cả 2 chiều, `len(fs)`, `for x in fs:`, phần tử trùng lặp trong `lst` bị loại đúng. Spike lỗi riêng cho `.add()`/`.remove()`/`.discard()` trên `frozenset`. Regression toàn bộ `Testkit/*.tkv`, đặc biệt mọi test dùng `set` thường.

- [ ] **Step 7: Mirror `.tkv`, cập nhật checklist, commit.**

```bash
git commit -m "feat(compiler): frozenset(list) - bat bien, dung chung ha tang set (6.8, 1/4)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
