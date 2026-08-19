# Chặn field trùng tên giữa các base đa kế thừa — Design

## Bối cảnh

`_extract_record_def` (`tkv_compile.py`, dòng ~594-599) gộp field từ
TẤT CẢ base trong `record_bases_found` (đa kế thừa record thật, sau
fix 6.10):
```python
base_fields = []
for b in record_bases_found:
    sec_f = known_records.get(b, [])
    for f_tuple in sec_f:
        if f_tuple not in base_fields:
            base_fields.append(f_tuple)
```
`f_tuple = (field_name, dtype)` — dedup CHỈ khớp khi CẢ TÊN VÀ DTYPE
giống hệt nhau. Nếu 2 base khai field CÙNG TÊN KHÁC dtype (hoặc thậm
chí cùng dtype nhưng là 2 field độc lập về mặt thiết kế, chỉ trùng
tên tình cờ), CẢ 2 entry đều lọt vào `fields` — record con
(`class Combo(BaseA, BaseB):`) có 2 field cùng tên `val` trong danh
sách flatten. `gen_record_types` (`il_codegen.py`) sinh CIL field
theo TÊN THÔ (không mangle theo class sở hữu) — ctor/field-access
sau đó KHÔNG PHÂN BIỆT được 2 field trùng tên, dẫn tới
`System.MissingFieldException: Field not found: 'Combo.val'` LÚC
CHẠY (biên dịch OK, sai lặng lẽ tới runtime — nguy hiểm hơn lỗi biên
dịch rõ ràng). Phát hiện khi làm 6.10 (fix MRO đa-base), escalate
riêng vì ngoài phạm vi method-MRO của task đó.

## Mục tiêu

`class Combo(BaseA, BaseB):` — nếu ≥2 base (không nằm trên CÙNG 1
nhánh thừa kế trực tiếp — vd `BaseA`/`BaseB` không phải tổ tiên-hậu
duệ của nhau) khai field TRÙNG TÊN → `TranspileError` RÕ RÀNG ngay
lúc parse class, thay vì để lọt qua biên dịch rồi crash runtime.

## Kiến trúc

Sau vòng lặp gộp `base_fields` (dòng ~594-599), thêm bước kiểm tra:
đếm SỐ LẦN mỗi `field_name` (không kể dtype) xuất hiện trong
`base_fields` — nếu tên nào xuất hiện ≥2 lần, đây LÀ collision thật
(không phải trường hợp field kế thừa hợp lệ qua 1 nhánh duy nhất, vì
`known_records[b]` của MỖI base `b` đã tự flatten field của TỔ TIÊN
RIÊNG nó rồi — nếu 2 base có tổ tiên CHUNG với field CHUNG tên, field
đó xuất hiện trong CẢ 2 `sec_f`, nhưng dedup theo `f_tuple` giống hệt
đã loại bỏ trường hợp NÀY đúng — chỉ còn lại case THẬT collision là
2 field ĐỘC LẬP, khác dtype hoặc khác nguồn gốc, trùng tên tình cờ).
Raise `TranspileError` liệt kê rõ: tên field trùng, base nào khai
báo, gợi ý đổi tên.

## Phạm vi

- CHỈ chặn — KHÔNG tự động đổi tên/mangle (đó là hướng (b) phức tạp
  hơn, không làm ở batch này, đúng quyết định người dùng đã chọn).
- Field trùng tên do CÙNG 1 tổ tiên chung (kim cương hợp lệ, dedup
  đúng theo `f_tuple` giống hệt) KHÔNG bị chặn — chỉ chặn khi field
  THỰC SỰ độc lập (khác dtype, hoặc cùng dtype nhưng khai ở 2 base
  không có quan hệ tổ tiên chung cho field đó).

## Kiểm chứng

- Test: `Combo(BaseA, BaseB)` với `BaseA.val: i32`, `BaseB.val: str`
  (khác dtype, collision RÕ) → `TranspileError` rõ lúc biên dịch,
  KHÔNG còn crash runtime.
- Test: kim cương hợp lệ (2 base CÙNG kế thừa 1 tổ tiên chung, field
  chung tên qua tổ tiên đó) — KHÔNG bị chặn nhầm, biên dịch/chạy đúng
  như trước (regression, dùng lại case `mro_diamond_test.tkv` đã có
  nếu áp dụng được, hoặc viết case tương tự).
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
