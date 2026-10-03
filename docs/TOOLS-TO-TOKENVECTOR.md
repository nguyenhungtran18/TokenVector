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

---

# Công cụ đầu tiên đã chuyển xong: `tools/probe_ten.tkv`

Bản Python `tools/probe_name_exists.py` (76 dòng) → `tools/probe_ten.tkv`
(~160 dòng TokenVector), **biên dịch và chạy thật**: `build/probe_ten.exe` 16 KB.

## Bốn khác biệt bắt buộc khi chuyển

| Python | TokenVector |
|---|---|
| `import os, io, sys, subprocess` | không có; dùng builtin `path_*`, `read_file`, `write_file`, `sys_argv` |
| `subprocess.run(..., capture_output=True)` | `proc_run` — **thừa kế stdout**, phải redirect `> file` rồi `read_file` |
| `os.makedirs(WORK)` | **không có** `path_mkdir` → `proc_run("cmd.exe", "/c mkdir ...")` |
| `MISS_MARKERS = (...)` | tuple literal **không tồn tại** → `list` + `append` |
| `TKVC = dist/tkvc.exe build --out --entry` | `dist/tkvc-tv.exe <nguon> <ra> <entry>` (CLI vị trí, compiler **thật**) |

## Ba giới hạn TokenVector gặp phải (đều đã kiểm bằng probe, không đoán)

1. **Lát cắt trong subscript lồng bị từ chối.** `dong[i][j:j+1]` → lỗi
   `ky vong ']', gap ':'`. Còn `dong[i][j]` thì được. Sửa: gán `hang = dong[i]`
   trước rồi cắt trên `hang`.
2. **`path_read_text` / `path_write_text` được liệt kê trong `REFERENCE.md` §2
   nhưng CHƯA đăng ký thật** → `read_file` / `write_file`.
3. **Hàm phải định nghĩa trước khi dùng.** `nap_markers()` gọi `MARKERS_n()`
   định nghĩa sau → `ham 'MARKERS_n' khong ton tai`.

Ngoài ra: chú thích nằm lệch thụt so với lệnh sau sẽ phá IND/DED của lexer.

## Tool này đã tìm ra sai lệch thật trong tài liệu

Chạy nó lên **173 tên builtin** mà `REFERENCE.md` §7 liệt kê:

```
TON TAI (probe xac nhan)          :  40
THIEU - compiler bao "khong ton tai": 76
```

Kiểm chứng trực tiếp 4 tên bị báo thiếu:

```
format(3.14159, ".2f")  -> khong ton tai
int64(5)                -> khong ton tai
path_stem("a.txt")      -> khong ton tai
hash("a")               -> khong ton tai
len("a")                -> TON TAI
```

Nghĩa là **`REFERENCE.md` §7 liệt kê 173 tên nhưng ít nhất 76 tên không được
đăng ký thật** — kể cả `format` và `int64` mà `CLAUDE.md` khẳng định là hoạt
động. Tài liệu sai ở đúng chỗ mà cổng `gen_builtin_ref.py --check` không soi:
cổng đó so tên trong tài liệu với tên đã đăng ký theo **chiều một** (thiếu thì
báo), nên tên liệt kê thừa vẫn lọt.

Lưu ý về phương pháp: probe gọi `v = X("a")`, nên **tên là method** (`split`,
`lower`, `join`…) sẽ ra THIỀU một cách **đúng** — chúng không phải hàm độc lập.
Giới hạn này thừa kế từ bản Python gốc.

## Đề xuất

Sửa `gen_builtin_ref.py --check` để kiểm **chiều hai**: mọi tên liệt kê trong
§7 phải được probe xác nhận là tồn tại. Đó chính là `probe_ten.exe` — và nó
đã viết bằng TokenVector.
