# MRO đa base — sửa lỗi thứ tự override Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `class D(B1, B2, ...):` — khi 1 method trùng tên override ở nhiều base, `D` dùng đúng bản của base ĐẦU TIÊN có định nghĩa (khớp CPython thật) thay vì base CUỐI (bug hiện tại).

**Architecture:** Sửa vòng lặp `bases[1:]` trong `tkv_compile.py`'s `_build_record_methods` (dòng ~1230-1242) thành duyệt TOÀN BỘ `bases` theo đúng thứ tự (giữ nguyên logic `if not in own_names`, chỉ đổi phạm vi lặp). Kiểm tra lại `_method_owner_class`/`_field_owner_class` (`record_feature.py`) xem còn cần sửa `isinstance(base, str)` guard hay không SAU KHI vá điểm chính (rất có thể KHÔNG cần, vì method giờ luôn được copy thẳng vào `D`).

**Tech Stack:** Python compiler, self-hosted `.tkv` mirror.

## Global Constraints

- Sửa đồng bộ cả 2 cây. KHÔNG rebuild `tkvc.exe`.
- `d.speak()` trong case `Duck(Flyer, Swimmer)` (cả 2 override `speak`) PHẢI trả `"flyer-speak"` sau khi sửa (khớp CPython thật đã xác nhận).
- Kim cương field/method KHÔNG trùng tên (đã chạy đúng trước khi sửa) KHÔNG được regression.
- Không triển khai C3 linearization đầy đủ / `super()` — chỉ "base đầu ưu tiên" đơn giản.

---

### Task 1: Sửa thứ tự ưu tiên method đa-base + verify field

**Files:**
- Modify: `tkv_compile.py` (`_build_record_methods`, dòng ~1230-1242)
- Modify: `record_feature.py` (`_method_owner_class`/`_field_owner_class` — CHỈ NẾU Step 1 xác nhận vẫn cần sau khi vá `tkv_compile.py`)
- Modify: mirror `.tkv` của các file trên
- Create: `release/3.code/Testkit/mro_diamond_test.tkv`
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: cấu trúc `record_bases`/`record_methods_own`/`record_method_bodies` hiện có trong `tkv_compile.py`.
- Produces: không có API mới — sửa hành vi 1 vòng lặp hiện có.

- [ ] **Step 1: Tái tạo bug làm baseline TRƯỚC khi sửa** — viết file `.tkv` tạm (trong `release/3.code/Testkit/` luôn, sẽ trở thành `mro_diamond_test.tkv` chính thức sau) tái tạo ĐÚNG case đã xác nhận trong spec (`Animal`→`Flyer`/`Swimmer` (cả 2 override `speak`)→`Duck(Flyer, Swimmer)`), build+chạy XÁC NHẬN LẠI bug (`"swimmer-speak"` sai) TRƯỚC khi đụng code — đảm bảo bạn đang sửa ĐÚNG bug, không phải bug khác đã tự hết.

- [ ] **Step 2: Đọc kỹ `_build_record_methods`** (`tkv_compile.py`, tìm bằng grep `def _build_record_methods`) — xác nhận số dòng chính xác của đoạn `for sec in bases[1:]:` (dòng ~1237, có thể lệch nhẹ). Đọc TOÀN BỘ hàm để hiểu `own_names`/`record_method_bodies`/`record_methods_own` được khởi tạo/dùng thế nào TRƯỚC đoạn này (đặc biệt: `own_names` phải PHẢN ÁNH ĐÚNG method riêng của `rname` TRƯỚC khi vòng lặp base bắt đầu — xác nhận không đổi phần này).

- [ ] **Step 3: Sửa vòng lặp** — đổi `for sec in bases[1:]:` thành `for sec in bases:` (duyệt CẢ base[0]) — GIỮ NGUYÊN toàn bộ thân vòng lặp (`if m_sig.name not in own_names: ... own_names.add(...)`). Đọc lại comment gốc dòng 1230-1235 (nói "bases[1:] là @interface") — SỬA LẠI comment cho đúng thực tế: bases[1:] CÓ THỂ là record thật (không chỉ interface), và giờ bases[0] cũng cần cùng cơ chế vì kế thừa CIL đơn (`extends`) không đủ để giải quyết đúng thứ tự ưu tiên khi có xung đột đa-base.

- [ ] **Step 4: Build lại + verify bug ĐÃ HẾT** — build+chạy LẠI CHÍNH XÁC file test ở Step 1, xác nhận `d.speak()` giờ trả `"flyer-speak"` (khớp CPython).

- [ ] **Step 5: Kiểm tra `_method_owner_class`/`_field_owner_class` còn cần sửa không** — sau Step 3, `record_methods_own['Duck']` giờ CHỨA method đúng (kể cả kế thừa từ `bases[0]`) — đọc lại `_method_owner_class` (dòng 81-92): nhánh ĐẦU (`mdict = record_methods_own.get(record_name, {})`, dòng 82-85) sẽ tìm thấy method NGAY trong `record_name` chính nó (vì đã được copy vào), trả về `record_name` — XÁC NHẬN bằng cách đọc kỹ có case nào KHÔNG đi qua đường này hay không (vd method chỉ tồn tại ở tổ tiên xa hơn 1 cấp qua base[0] mà KHÔNG bị copy — kiểm tra bằng 1 test kế thừa 3 tầng qua nhánh đa-base, vd `GrandChild(Mid1, Mid2)` với `Mid1(Base1)` — method của `Base1` có được propagate đúng tới `Duck`-tương-đương hay không). NẾU phát hiện case còn thiếu, sửa `isinstance(base, str)` để xử lý LIST (duyệt theo thứ tự, base đầu có định nghĩa thắng) — NẾU KHÔNG, bỏ qua, ghi rõ lý do trong báo cáo.

- [ ] **Step 6: Verify field trùng tên (Phạm vi phụ trong spec)** — viết 1 spike RIÊNG (không đưa vào test chính) với 2 base cùng khai field TRÙNG TÊN (khác dtype hoặc cùng dtype) — xác nhận hành vi hiện tại: lỗi biên dịch RÕ RÀNG (chấp nhận được), HAY sinh sai lặng lẽ (cần escalate, KHÔNG tự sửa nếu đây là vấn đề thiết kế lớn hơn phạm vi Task này — báo cáo lại, không tự quyết định thiết kế mới). Xoá spike sau khi xác nhận.

- [ ] **Step 7: Hoàn thiện `mro_diamond_test.tkv` chính thức** — bao gồm: case Step 1 (2 base override cùng method, base đầu thắng), case kim cương field/method KHÔNG trùng tên (regression, đã chạy đúng trước đó — giữ lại xác nhận vẫn đúng), case 3+ base cùng override method (base đầu tiên trong 3 luôn thắng). `SUMMARY N/N`.

- [ ] **Step 8: Regression toàn bộ `Testkit/*.tkv`** — đặc biệt mọi test kế thừa/interface/đa-base hiện có (`inheritance_py_tree_test` và tương tự — liệt kê bằng grep `class.*\(.*,.*\)` trong `Testkit/*.tkv` để tìm hết các file có đa-base).

- [ ] **Step 9: Mirror `.tkv`, cập nhật checklist (6.10 XONG, ghi rõ bug đã sửa + case field trùng tên nếu Step 6 phát hiện gì), commit.**

```bash
git commit -m "fix(compiler): MRO da-base - base DAU tien uu tien khi trung ten method (6.10)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
