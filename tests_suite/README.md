# tests_suite/ — bộ test TokenVector thuần, kiểu bảng dữ liệu

Đây là bộ test thứ hai, bên cạnh `tests/` (test tự chứa trong một file).

| | `../tests/` | `../tests_suite/` (thư mục này) |
|---|---|---|
| Dạng | mỗi file là **một chương trình `.tkv` tự so** kết quả | **bảng dữ liệu** `.ca` trỏ tới file mẫu dùng chung |
| Số lượng | 118 test + 31 negative | **154 bảng / 143 đạt**, dùng lại **203 file mẫu** |
| Chạy | `tools\testkit_gate.ps1` | `tests_suite\chay.exe` |
| So sánh | so trong chính code | so **stdout chính xác** + mã thoát |
| Song song | không | có, 4 luồng |

Hai bộ **bổ sung cho nhau**, không thay thế: `tests/` có 31 case negative mà
bộ này không có; bộ này tái sử dụng file mẫu nên thêm được ca mà không nhân
bản chương trình.

## Chạy

```powershell
cd D:\TokenVector
tests_suite\chay.exe                 # toàn bộ, ~1.5 phút
tests_suite\chay.exe bool_containers # lọc theo tên
```

Nếu `chay.exe` chưa có, biên dịch bằng **compiler TokenVector**:

```powershell
dist\tkvc-tv.exe tests_suite\chay.tkv tests_suite\chay.exe main
```

## Định dạng file `.ca`

Mỗi dòng là **một ca kiểm tra**, các trường tách bằng **TAB**:

```
đường_dẫn_nguồn ⇥ tên_entry ⇥ mã_thoát_mong_đợi ⇥ đối_số ⇥ stdout_mong_đợi
```

Ví dụ:

```
tests_suite\de_vao\sample_bool_containers.tkv	dict_vals	0		TrueFalse2\n]
```

- `stdout_mong_đợi` dùng ký tự thoát: `\n` xuống dòng, `\t` tab, `\\` backslash.
- Ca có thể cho **nhiều đối số** — runner sinh mỗi bộ đối số một tệp riêng.

## Ba điều đã phải sửa khi chuyển từ cây cũ

1. **Đường dẫn trong `.ca`.** File gốc trỏ `test\sample_X.tkv`; ở đây mẫu nằm ở
   `tests_suite\de_vao\`. Đã sửa **151/154 file** bằng script (chỉ đổi trường
   đầu, không đụng `stdout_mong_đợi`).
2. **File mẫu sinh ra.** `test\tkv_suite\src\*.tkv` (85 file) chưa có sẵn trong
   cây gốc — phải chép vào `de_vao\tkv_suite\src\`.
3. **11 ca còn trượt vì `.ca` chứa đường dẫn tuyệt đối của máy khác** — ví dụ
   `D:\Claude AI Project\TokenVector\test\csv_report_data.csv` và các thư mục
   tạm `C:\Users\NGUYEN~1\AppData\...`. Những ca này sẽ trượt trên **bất kỳ máy
   nào khác**, không chỉ ở đây. Cần sửa tay trong file `.ca`.

## Cổng kiểm liên quan

- `tools\testkit_gate.ps1` — bộ `tests/` (118 + 31 negative)
- `tools\vong.tkv` → `tools\vong.exe` — vòng tự-host: `g1 = tv2s(nguồn)`,
  `g2 = g1(nguồn)`, điểm bất động khi `g1.il == g2.il`
- `tools\diff_il.tkv` — đối chiếu IL giữa các thế hệ
