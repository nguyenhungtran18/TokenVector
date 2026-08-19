# Chặn field trùng tên đa-base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `class Combo(BaseA, BaseB):` — field trùng tên THẬT giữa 2 base (không qua tổ tiên chung) → `TranspileError` rõ lúc parse, thay vì `MissingFieldException` lúc chạy.

**Architecture:** Sau vòng lặp gộp `base_fields` trong `_extract_record_def` (`tkv_compile.py`, dòng ~594-599), đếm số lần mỗi field_name xuất hiện — ≥2 lần (sau dedup theo `f_tuple` giống hệt) là collision thật, raise lỗi rõ.

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror.

## Global Constraints

- Sửa đồng bộ cả 2 cây. KHÔNG rebuild `tkvc.exe`.
- KHÔNG chặn nhầm field kim cương hợp lệ (chung tổ tiên, dedup đúng theo `f_tuple` giống hệt).
- Regression: `mro_diamond_test.tkv` và mọi test kế thừa hiện có không đổi hành vi.

---

### Task 1: Validate + chặn field trùng tên

**Files:**
- Modify: `tkv_compile.py` (`_extract_record_def`, dòng ~594-600)
- Modify: mirror `release/3.code/tkv_compile.tkv`
- Create: `release/3.code/Testkit/multibase_field_collision_test.tkv` (case hợp lệ — collision case xác nhận qua spike riêng, KHÔNG đưa vào test chính vì phải raise lỗi ngăn build)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (xoá/cập nhật ghi chú escalation ở mục 6.10, đánh dấu đã xử lý)

**Interfaces:**
- Consumes: `base_fields` (list `(field_name, dtype)` đã gộp), `record_bases_found`.
- Produces: không API mới — thêm 1 validate step.

- [ ] **Step 1: Đọc lại đoạn code chính xác** — `tkv_compile.py` dòng ~587-600, xác nhận số dòng thật (có thể lệch do các commit trước). Đọc lại `TranspileError` (class/hàm dùng để raise lỗi transpile hiện có trong file này — dùng ĐÚNG cùng loại lỗi, không tự tạo loại mới).

- [ ] **Step 2: Thêm validate sau vòng lặp gộp `base_fields`**:
```python
_field_owners = {}
for b in record_bases_found:
    for fn, fd in known_records.get(b, []):
        _field_owners.setdefault(fn, []).append(b)
_collisions = {fn: owners for fn, owners in _field_owners.items() if len(set(owners)) > 1}
if _collisions:
    details = '; '.join(f"'{fn}' o {sorted(set(owners))}" for fn, owners in _collisions.items())
    raise TranspileError(
        f"class '{class_node.name}': field trung ten giua nhieu base da ke thua ({details}) - "
        f"CIL sinh field theo ten tho, khong phan biet duoc field trung ten tu base khac nhau "
        f"(se crash MissingFieldException luc chay neu khong chan o day). Doi ten field o 1 "
        f"trong cac base de tranh trung.")
```
  LƯU Ý: dùng `_field_owners` (map tên field → DANH SÁCH base khai báo nó, qua chính `known_records[b]`, KHÔNG dùng lại biến `base_fields` đã dedup — vì sau dedup theo `f_tuple`, thông tin "base nào khai báo" đã mất). Kiểm tra dùng `set(owners)` (không phải `len(owners)`) để tránh báo sai nếu 1 base xuất hiện lặp trong `record_bases_found` (không nên xảy ra nhưng an toàn hơn). Field kim cương hợp lệ (2 base cùng tổ tiên, field từ tổ tiên chung) — field đó sẽ xuất hiện trong `known_records[b1]` VÀ `known_records[b2]` NHƯNG với CÙNG `fn`, nên `_field_owners[fn] = [b1, b2]` (2 owners khác nhau) — **XÁC NHẬN LẠI bằng test thật**: đây có bị chặn NHẦM không? Nếu bị chặn nhầm, cần sửa logic: chỉ coi là collision khi field đó KHÔNG đến từ cùng 1 tổ tiên chung (so sánh `f_tuple` giống hệt giữa các owner — nếu `known_records[b1]` và `known_records[b2]` chứa CÙNG `f_tuple` cho field đó, đây là kế thừa hợp lệ qua tổ tiên chung, KHÔNG phải collision; chỉ khi `f_tuple` KHÁC NHAU giữa 2 owner mới là collision thật) — điều chỉnh điều kiện cho đúng, TỰ TEST để xác nhận, không đoán.

- [ ] **Step 3: Test case collision** — spike riêng (KHÔNG đưa vào test chính): `BaseA.val: i32`, `BaseB.val: str`, `Combo(BaseA, BaseB)` → build phải raise `TranspileError` rõ. Xoá sau khi xác nhận.

- [ ] **Step 4: Test case hợp lệ (không bị chặn nhầm)** — `multibase_field_collision_test.tkv`: case kim cương field CHUNG qua tổ tiên (dùng lại cấu trúc tương tự `mro_diamond_test.tkv` nếu có sẵn field chung tổ tiên, hoặc viết case mới `Animal.name`→`Flyer(Animal)`+`Swimmer(Animal)`→`Duck(Flyer,Swimmer)` — `name` đến từ tổ tiên chung `Animal`, KHÔNG phải collision) — build+chạy PASS bình thường, xác nhận KHÔNG bị chặn nhầm.

- [ ] **Step 5: Regression** — build lại `mro_diamond_test.tkv` (từ 6.10) và toàn bộ `Testkit/*.tkv`, đặc biệt mọi test đa-base/kế thừa hiện có — xác nhận không có gì bị chặn nhầm, không regression khác.

- [ ] **Step 6: Mirror `.tkv`, cập nhật checklist (xoá/đóng ghi chú escalation ở 6.10), commit.**

```bash
git commit -m "fix(compiler): chan field trung ten giua cac base da ke thua (TranspileError ro thay vi MissingFieldException luc chay)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
