# Chuyển công cụ phụ trợ sang TokenVector

Chủ đề của tài liệu này: **mọi công cụ phục vụ TokenVector phải viết bằng TokenVector.**

## Vì sao cần `py2tkv`

TokenVector là **một phần của Python**, nên `dist/tkvc-tv.exe` biên dịch được
file `.py` ngay — tên tệp không quan trọng. Điều duy nhất chặn một file `.py` là:

```
ham 'tong': thieu return-type annotation (vd -> "f32":).
Chi ham KHONG tra ve gia tri moi duoc bo qua annotation nay.
```

Nên `.py` → `.tkv` về bản chất là **chèn chú ký kiểu**, không phải dịch ngôn ngữ.

## Cách dùng

```powershell
dist\tkvc-tv.exe tools\py2tkv.tkv build\py2tkv.exe main

build\py2tkv.exe <vao.py> <ra.tkv>     # chuyển và ghi
build\py2tkv.exe <vao.py> --biet        # chỉ liệt kê hàm chưa suy được
build\py2tkv.exe <vao.py> --do          # in bảng số liệu
```

## Nguyên tắc: KHÔNG ĐOÁN

Hàm nào suy không ra thì tool **báo tên ra**, không ghi một kiểu bừa. Lý do:

- ghi sai kiểu → **biên dịch được rồi chạy sai**, lỗi hiện ra ở chỗ khác
- không ghi → compiler báo ngay tên hàm, một giây sau khi biên dịch

Kiểu đoán được lấy từ, theo thứ tự:

1. chú ký sẵn có
2. giá trị mặc định (`0`→`i32`, `0.0`→`f64`, `""`→`str`, `[]`→`list[i32]`)
3. bảng kiểu trả về của method (`.join`→`str`, `.split`→`list[str]`,
   `.find`→`i32`, `.startswith`→`bool`)
4. điểm bất động qua đồ thị gọi (lặp tới 12 vòng)
5. tên biến tiếng Anh (`i`/`n`→`i32`, `s`/`ten`→`str`, `x`/`val`→`f64`)

Hàm không có `return <giá trị>` nào là hàm `void` → **không cần chú ký**, hợp lệ.

## Đo thật trên 21 file `.py` của chính repo

```
file .py                        : 21
suy hết (0 CHUA SUY)            :  7
còn hàm chưa suy được            : 14
.tkv sinh ra BIÊN DỊCH ĐƯỢC     :  0 / 21     <-- xem dưới
```

## Vì sao 0/21 — và đó là phát hiện quan trọng nhất

Gần như mọi lỗi đều **giống hệt nhau**:

```
Chi ho tro dinh nghia ham/class-record top-level, HANG SO cap module,
bien global co kieu, (va '__tkv_import__') trong 1 file TokenVector
```

Tức là: **`import` ở cấp module không được phép trong một file TokenVector.**
Phải dùng `__tkv_import__` và nối nguồn lại. `tkvdev.py` có 5 dòng import:

```
IMPORT cap module (dong 21): import importlib.abc
IMPORT cap module (dong 22): import importlib.machinery
IMPORT cap module (dong 23): import importlib.util
IMPORT cap module (dong 24): import os
IMPORT cap module (dong 25): import sys
```

**Chuyển công cụ Python sang TokenVector phần lớn là bài toán GỘP IMPORT, không
phải bài toán chú ký kiểu.** Chỉ 2/21 lỗi là thiếu chú ký (`sorted_keys`, `load`).

`py2tkv` giữ nguyên nội dung và báo cáo cả hai loại vướng, nhưng **chưa** gộp
import — việc đó cần nghĩ lại cấu trúc từng công cụ.

## Bẫy: `tkvc-tv.exe` LUÔN exit code 0

Đo đầu tiên của tôi báo "21/21 biên dịch OK" — **sai hoàn toàn**:

```
A: file HONG  -> exit code = 0, stdout co "[tkvc] loi", exe KHONG ton tai
B: file DUNG  -> exit code = 0, exe TON TAI
```

Không được tin exit code. Hai tín hiệu thành công duy nhất:

1. stdout **không** chứa `[tkvc] loi`
2. file `.exe` đầu ra **tồn tại**

`tools/vong.tkv` làm đúng: xoá sản phẩm cũ trước rồi kiểm tra file có ra không.
Mọi kịch bản kiểm phải làm y vậy, nếu không sẽ "luôn xanh".

## Kiểm kê công cụ phụ trợ

| | file | dòng |
|---|---|---|
| TokenVector | 16 | 1.824 |
| Python | 21 | 2.967 |

Còn lại (Python, theo thứ tự nên chuyển):

| file | dòng | vì sao chuyển được |
|---|---|---|
| `tools/dang_ky_gate.py` | 144 | chỉ đọc AST — cần bộ phân tích cú pháp TokenVector |
| `tools/probe_name_exists.py` | 76 | gọi compiler, tự nhiên dùng `proc_ra` |
| `tools/gen_builtin_ref.py` | 242 | đọc file, ghi markdown — gần như thuần TokenVector |
| `tools/cmp_python_builtins.py` | 59 | như trên |
| `tools/scan_uninit_container_fields.py` | 86 | cần AST |
| `tools/parity_probe/cmp_py.py` | 429 | phải chạy CPython để so → cần `proc_ra` |
| `tools/tkv_bind/*.py` | 971 | sinh C# → cần thay bằng sinh TokenVector |
| `benchmark/*.py` | 603 | cần đo thời gian; TokenVector có `time_*`? cần kiểm |

Bước kế: `proc_ra` cho phép chạy tiến trình con, đó là mấu chốt để parity probe
và benchmark chuyển sang TokenVector mà vẫn so được với CPython.
