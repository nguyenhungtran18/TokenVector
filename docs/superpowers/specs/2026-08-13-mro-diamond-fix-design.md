# MRO đa base — sửa lỗi thứ tự override — Design

## Bối cảnh: BUG ĐÃ XÁC NHẬN THẬT (không còn "chưa xác nhận")

Spike trực tiếp (không cần subagent, so sánh với CPython thật qua
PowerShell `python -c ...`):

```python
class Animal:
    def speak(self): return "..."
class Flyer(Animal):
    def speak(self): return "flyer-speak"
class Swimmer(Animal):
    def speak(self): return "swimmer-speak"
class Duck(Flyer, Swimmer):
    pass
```

- **CPython thật**: `Duck().speak()` → `"flyer-speak"` (base ĐẦU TIÊN
  liệt kê thắng — đúng MRO/C3 linearization đơn giản hoá cho trường
  hợp không hợp tác `super()`).
- **TokenVector**: → `"swimmer-speak"` (base CUỐI thắng — SAI).

Field kế thừa kim cương ĐƠN GIẢN (field tên khác nhau, không trùng)
đã kiểm chứng CHẠY ĐÚNG (không duplicate, không lỗi) — bug CHỈ lộ khi
≥2 base override CÙNG 1 method kế thừa từ tổ tiên chung.

## Nguyên nhân (đã đọc code xác nhận, 2 vị trí)

**`tkv_compile.py`'s `_build_record_methods`, dòng ~1230-1242**: với
record đa-base (`class Duck(Flyer, Swimmer):`, `bases = ['Flyer',
'Swimmer']`), vòng lặp CHỈ xử lý `bases[1:]` (tức `['Swimmer']`) —
comment gốc coi đây là "@interface base, đóng góp method mặc định",
nhưng THỰC TẾ `bases[1:]` CÓ THỂ là RECORD THẬT (không chỉ interface,
xem `tkv_compile.py:569-587`'s `record_bases_found`). Method của
`Swimmer` (bases[1]) được COPY THẲNG vào `record_methods_own['Duck']`
(vì `'speak' not in own_names` — Duck tự nó không định nghĩa `speak`).
`Flyer` (bases[0]) KHÔNG được copy tương tự — nó lẽ ra dựa vào CIL
`extends Flyer` (kế thừa THẬT qua CLR) để tự động có `speak()`, NHƯNG
`_method_owner_class` (`record_feature.py:81-92`) có:
```python
base = record_bases.get(record_name)
if isinstance(base, str) and base:   # <-- False khi base la LIST!
```
Khi `base` là LIST (đa-base), điều kiện `isinstance(base, str)` LUÔN
`False` → hàm rơi thẳng `return record_name` (tức `'Duck'`) mà KHÔNG
BAO GIỜ thử tra cứu method của `Flyer`. Nhưng vì Swimmer's `speak()`
ĐÃ được copy thẳng vào `record_methods_own['Duck']` bởi bug thứ nhất,
`_method_owner_class` tìm thấy `'speak'` trong `mdict` (dòng 84) và
trả về `'Duck'` — với IL thật của `speak()` chính là body của
`Swimmer`. Đây là lý do CHÍNH XÁC "base cuối thắng": chỉ có
`bases[1:]` (không bao gồm base[0]) được copy chủ động, nên với đúng
2 base, chỉ base thứ 2 "thắng" một cách tình cờ — KHÔNG PHẢI do thiết
kế "base cuối ưu tiên" có chủ đích, mà do base ĐẦU bị bỏ sót hoàn
toàn khỏi cơ chế copy.

## Mục tiêu

`class D(B1, B2, ...):` — khi 1 method (không tự định nghĩa lại ở
`D`) tồn tại ở NHIỀU base, `D` PHẢI dùng đúng bản của base được liệt
kê ĐẦU TIÊN có định nghĩa method đó (duyệt trái sang phải theo đúng
thứ tự khai báo `class D(B1, B2, ...)`) — khớp hành vi CPython thật
cho trường hợp không dùng `super()` hợp tác (cooperative), đây là
TOÀN BỘ những gì DSL cần hỗ trợ (không cần C3 linearization đầy đủ
cho các trường hợp MRO phức tạp hơn — ngoài phạm vi, ghi rõ).

## Kiến trúc

Sửa vòng lặp `bases[1:]` (`tkv_compile.py`, hàm `_build_record_methods`,
dòng ~1230-1242) THÀNH duyệt **TOÀN BỘ `bases`** (kể cả `bases[0]`)
theo ĐÚNG THỨ TỰ liệt kê, với `own_names` bắt đầu từ method riêng của
chính `D` (giữ nguyên) — với MỖI base theo thứ tự, method nào CHƯA có
trong `own_names` thì copy vào (giữ nguyên logic "base ĐẦU xử lý
trước sẽ THẮNG vì nó điền vào `own_names` trước, base sau thấy tên đã
có thì bỏ qua" — ĐÚNG NGỮ NGHĨA "base đầu ưu tiên" chỉ cần đảo đúng
THỨ TỰ vòng lặp, KHÔNG cần đổi logic `if m_sig.name not in own_names`).

Đồng thời sửa `_method_owner_class` (`record_feature.py:81-92`) VÀ
`_field_owner_class` (dòng ~42-78, xác nhận có cùng lỗi
`isinstance(base, str)` hay không — đọc lại kỹ) để XỬ LÝ ĐÚNG khi
`base` là LIST: duyệt list THEO THỨ TỰ, trả về base ĐẦU TIÊN có định
nghĩa method/field đó — dù sau khi sửa `tkv_compile.py` ở trên,
`record_methods_own['D']` đã CHỨA SẴN bản đúng của mọi method kế thừa
(kể cả từ base[0]), nên nhánh `mdict = record_methods_own.get(record_name,
{})` (dòng 82-85) THỰC RA đã đủ để trả đúng `record_name` chính nó
(vì method giờ luôn được copy vào `D` bất kể base nào) — XÁC NHẬN LẠI
bằng build+test THẬT liệu có còn cần sửa `_method_owner_class` nữa
không sau khi vá `tkv_compile.py`, hay bug đã biến mất hoàn toàn chỉ
với 1 chỗ sửa (rất có thể — vì owner LUÔN LÀ chính `D` một khi method
đã được copy vào `own_names`/`record_methods_own['D']`).

## Phạm vi

- CHỈ sửa thứ tự ưu tiên khi method/field TRÙNG TÊN xuất hiện ở NHIỀU
  base không cùng nhánh thừa kế trực tiếp — KHÔNG triển khai C3
  linearization đầy đủ (super() hợp tác đa kế thừa) — ngoài phạm vi,
  DSL này không có `super()`.
- Field: xác nhận lại (test riêng) xem field trùng TÊN giữa 2 base
  (khác nhánh) có bị lỗi tương tự hay không — NẾU CÓ, áp dụng cùng
  nguyên tắc "base đầu thắng". Field trùng tên giữa 2 base là tình
  huống HIẾM (Python thật cũng coi là lỗi thiết kế), nhưng vẫn cần xử
  lý AN TOÀN (không lặng lẽ sai) — nếu phát hiện field bị duplicate
  hoặc lỗi ctor tham số khi trùng tên, báo lỗi biên dịch rõ ràng thay
  vì để sai lặng lẽ (khác method — Python thật CHO PHÉP field trùng
  tên đa kế thừa, chỉ có 1 giá trị theo MRO, nhưng cơ chế ctor
  positional-params của DSL này có thể không biểu diễn được đúng ngữ
  nghĩa đó — CẦN QUYẾT ĐỊNH THIẾT KẾ RIÊNG nếu phát hiện, KHÔNG tự ý
  chọn).

## Kiểm chứng

- Test lại CHÍNH XÁC case đã dùng để xác nhận bug (`Duck(Flyer,
  Swimmer)` cả 2 override `speak()`) — sau khi sửa, `d.speak()` phải
  trả `"flyer-speak"` (khớp CPython thật, đã xác nhận qua PowerShell).
- Test kim cương field/method KHÔNG trùng tên (case đã chạy đúng
  trước khi sửa) — xác nhận VẪN đúng sau khi sửa (không regression).
- Test 3+ base cùng override 1 method — base ĐẦU TIÊN trong danh sách
  luôn thắng.
- Regression toàn bộ `Testkit/*.tkv` — đặc biệt mọi test kế thừa/đa
  kế thừa/interface hiện có (`inheritance_py_tree_test` và tương tự).
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
