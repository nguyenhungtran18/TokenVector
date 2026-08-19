# `bytearray` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ba = bytearray()` + `.append(x)` (narrow `i32`→`byte`), đọc `ba[i]`/`len(ba)`/`for b in ba:` giống `list[i32]`.

**Architecture:** Thêm `shape='bytearray'` — container CIL `List<uint8>` (khác `List<int32>` của `list[i32]` chỉ ở KÍCH THƯỚC phần tử). Đọc (`get_Item(int32)` trả `!0` = `uint8`, CIL evaluation-stack TỰ ĐỘNG chuẩn hoá kiểu số nguyên nhỏ hơn `int32` thành `int32` khi đẩy lên stack theo ECMA-335 — nghĩa là các hàm ĐỌC hiện có của `list` CÓ THỂ tái dùng gần như nguyên vẹn nếu chỉ cần dạy `il_type_str`/`il_list_type` trả đúng `List<uint8>` cho shape này). Ghi (`.append`) CẦN sửa: `Add(!0)` trên `List<uint8>` đòi hỏi giá trị `uint8` THẬT trên stack — phải chèn `conv.u1` trước khi gọi, khác `list[i32]` không cần narrow.

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror, CIL/`ilasm`.

## Global Constraints

- Sửa đồng bộ cả 2 cây. KHÔNG rebuild `tkvc.exe`.
- Chỉ `bytearray()` rỗng + `.append(x)` — không `bytearray(n)`, không `bytearray(list)`, không literal.
- KHÔNG validate `0-255` lúc chạy (tràn bị `conv.u1` cắt lặng lẽ — có ý thức).
- `list[i32]` thường không đổi hành vi.

---

### Task 1: `bytearray` — constructor, `.append()`, đọc (index/len/for-in)

**Files:**
- Create: `compiler/il_features/bytearray_type.py`
- Modify: `compiler/il_codegen.py` (điểm dispatch `_expr_index`/`len()`, `il_type_str` — thêm nhánh `shape == 'bytearray'`)
- Modify: `compiler/il_features/control_flow.py` (macro `for_in_list` — mở rộng nhận `known_shapes[name] == 'bytearray'` giống `'list'`)
- Modify: mirror `.tkv` của các file trên
- Create: `release/3.code/Testkit/bytearray_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `il_list_elem_ilstr`/`find_first_append_dtype` (`list_type.py`, có thể tái dùng NẾU logic không giả định cứng `int32` — đọc kỹ trước).
- Produces: `shape='bytearray'` — dùng nội bộ.

- [ ] **Step 1: Điều tra TRƯỚC KHI VIẾT** — đọc `list_type.py`'s `try_rhs_list_new`/`codegen_assign_list_new`/append parser/codegen, VÀ `il_codegen.py`'s `_expr_index`'s nhánh `shape == 'list'` (dòng ~1594 khu vực `get_Item(int32)`), VÀ `len()`'s nhánh `list`. Xác nhận GIẢ THUYẾT trong phần Architecture ở trên bằng cách đọc code THẬT: `get_Item`/`Add` có tham số hoá qua `!0`/generic hay hardcode `int32` ở đâu đó? Nếu logic đọc (`_expr_index`, `len()`) THỰC SỰ không phân biệt dtype cụ thể (chỉ dùng `col_type`/`!0` chung), có thể tái dùng bằng cách thêm `'bytearray'` vào các điều kiện `shape == 'list'` liên quan tới ĐỌC — NẾU KHÔNG, viết code ĐỌC riêng cho `bytearray` (không ép tái dùng sai).

- [ ] **Step 2: `il_bytearray_type()`** trong `bytearray_type.py`: `'class [mscorlib]System.Collections.Generic.List`1<unsigned int8>'`.

- [ ] **Step 3: Constructor** — `try_rhs_bytearray_new` (regex `^bytearray\(\)\s*$`), `known_shapes[name] = 'bytearray'`, `codegen_assign_bytearray_new`: `newobj instance void {il_bytearray_type()}::.ctor()`.

- [ ] **Step 4: `.append(x)`** — `LINE_PARSERS` entry MỚI (regex `^(\w+)\.append\((.+)\)\s*$`, CHỈ khớp khi `known_shapes.get(name) == 'bytearray'` — giống cách các `.append`/`.add` khác đã loại trừ nhau bằng `known_shapes`, đăng ký TRƯỚC `list.append`/`method_call_stmt` tổng quát). Codegen: `compile_expr(value_node, ..., 'i32', ctx)`, THÊM `conv.u1`, rồi `callvirt instance void {il_bytearray_type()}::Add(!0)`.

- [ ] **Step 5: Đọc (index/len/for-in)** — theo kết luận Step 1: hoặc mở rộng nhánh `list` hiện có để nhận `shape in ('list', 'bytearray')` (nếu logic đã tổng quát qua `col_type`), hoặc viết nhánh riêng gọi `il_bytearray_type()` — trong CẢ HAI TRƯỜNG HỢP, PHẢI xác nhận giá trị đọc ra là `i32` hợp lệ trên stack (không cần widen thêm, theo ECMA-335 — nhưng XÁC NHẬN THẬT bằng build+chạy test thay vì chỉ tin lý thuyết). Mở rộng macro `for_in_list` (`control_flow.py`) nhận `'bytearray'` giống cách `frozenset` đã mở rộng nhận diện ở task trước.

- [ ] **Step 6: Test + build + regression** — `bytearray()` + `.append(65)`/`.append(66)` → `len==2`, `ba[0]==65`, `ba[1]==66`, `for b in ba:` đúng. Case tràn: `.append(300)` → đọc lại bằng `44` (300 mod 256), GHI RÕ trong test đây là hành vi có ý thức không phải bug. Regression toàn bộ `Testkit/*.tkv`, đặc biệt mọi test dùng `list[i32]`.

- [ ] **Step 7: Mirror `.tkv`, cập nhật checklist, commit.**

```bash
git commit -m "feat(compiler): bytearray() + .append() qua List<byte> (6.8, 3/4)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
