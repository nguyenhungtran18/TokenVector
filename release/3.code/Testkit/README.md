# Testkit — quy trình test CHUẨN cho file `.tkv` thư viện/engine

**Mục đích**: kiểm tra 1 file `.tkv` (bạn sắp viết làm thư viện/engine)
xem có lỗi gì không **trước khi build**, và kiểm tra `.exe` sau khi build
có chạy đúng không — **không phải để test chính `tkvc.exe`**.

## Các file trong thư mục này

| File | Vai trò |
|---|---|
| `tkv_test_lib.tkv` | Thư viện dùng chung: `check()` (so sánh 1 ca), `test_summary()` (in tổng kết + trả mã thoát chuẩn). Import vào MỌI file test qua `__tkv_import__`. |
| `native_test_suite.tkv` | Bộ 16 test cho các tính năng ngôn ngữ (kế thừa, closure, thread...) — ví dụ THẬT dùng `tkv_test_lib`. |
| `check_file.tkv`-entry (trong `native_test_suite.tkv`) | Phân tích tĩnh 1 file `.tkv` bất kỳ, cảnh báo pattern hay gây lỗi. |
| `example_lib.tkv` + `example_lib_test.tkv` | **Khuôn mẫu** — sao chép 2 file này khi bắt đầu viết thư viện mới. |

## Quy trình 4 bước cho 1 file `.tkv` mới

### Bước 0 — Build sẵn 2 công cụ (chỉ cần làm 1 lần, hoặc sau khi sửa `tkvc.exe`)
```powershell
..\dist\tkvc.exe build native_test_suite.tkv --entry run --out native_test_suite.exe
..\dist\tkvc.exe build native_test_suite.tkv --entry check_file --out check_file.exe
```

### Bước 1 — Viết file thư viện (vd `my_engine.tkv`)
Viết bình thường, chỉ cần nhớ 4 ràng buộc cú pháp `check_file.exe` sẽ dò:
mọi `class` phải có ≥1 field, không `import re/json/os/random/datetime/hashlib`
(dùng thẳng builtin toàn cục), không `from X import Y` (dùng `__tkv_import__`),
không annotation kiểu cho biến cục bộ trong thân hàm.

### Bước 2 — Dò lỗi TĨNH trước khi build
```powershell
.\check_file.exe my_engine.tkv
```
0 cảnh báo → an toàn để sang bước 3. Có cảnh báo → sửa theo gợi ý, chạy lại.

### Bước 3 — Viết file test đi kèm (vd `my_engine_test.tkv`, xem `example_lib_test.tkv`)
```tkv
__tkv_import__ = ["tkv_test_lib", "my_engine"]

def run() -> "i32":
    total = 0
    tested = 0

    tested = tested + 1
    total = total + check("ten_ca_1", str(ham_cua_ban(...)), "gia_tri_dung")

    # ... them cac ca khac ...

    return test_summary("my_engine_test", total, tested)
```
Dò lỗi tĩnh file test này luôn: `.\check_file.exe my_engine_test.tkv`

### Bước 4 — Build thật + chạy xem PASS/FAIL
```powershell
..\dist\tkvc.exe build my_engine_test.tkv --entry run --out my_engine_test.exe
.\my_engine_test.exe
```
Mã thoát `0` = PASS hết (dùng được cho script/CI tự động), khác `0` = có FAIL.

## Ví dụ chạy thật (đã xác nhận hoạt động)
```powershell
.\check_file.exe example_lib.tkv          # 0 canh bao
.\check_file.exe example_lib_test.tkv     # 0 canh bao
..\dist\tkvc.exe build example_lib_test.tkv --entry run --out example_lib_test.exe
.\example_lib_test.exe                     # 4/4 PASS, exit 0
```
