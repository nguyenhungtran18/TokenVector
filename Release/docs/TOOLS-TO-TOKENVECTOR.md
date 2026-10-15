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

## Đo thời gian trong TokenVector — CÓ, dùng hệ `datetime*`

Đừng kết luận "không đo được giờ" chỉ vì một cái tên không tồn tại. TokenVector
**đo được thời gian trong tiến trình**:

```python
def do_gio() -> "i64":
    return datetime_ticks(datetime())

def main() -> "i32":
    a = do_gio()
    thread_sleep(300)
    b = do_gio()
    print(str(b - a))          # don vị tick
```

Kiểm chứng: `thread_sleep(300)` cho chênh lệch ~3.170.000 tick ≈ 0,317 s, tức
**10⁷ tick/giây** (chuẩn .NET, 100 ns/tick). Đo ổn định qua nhiều lần chạy.

Danh mục liên quan ở `REFERENCE.md` §2: `datetime()` (0 tham số = UtcNow),
`datetime_ticks(d)`, `datetime_diff(d1, d2)`, `datetime_add`, `datetime_sub`,
`datetime_strptime`, `thread_sleep(ms)`.

**Hai cái bẫy khi dò tên hàm:**

1. Gọi **không tham số** cho hàm cần tham số sẽ báo *"không tồn tại"* — đó là sai
   số tham số, không phải thiếu hàm. `thread_sleep()` (0 tham số) báo thiếu,
   `thread_sleep(300)` thì có. Kết luận "không có hàm đo giờ" là sai vì lý do này.
2. Đừng bịa tên rồi thử. Tôi từng viết `thoi_gian()` rồi kết luận TokenVector
   không đo được giờ — `thoi_gian` là tên tôi tự đặt, không phải builtin.
   Cách đúng: tra `REFERENCE.md` §2, hoặc probe với tên có thật.

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
phải bài toán chú ký kiểu.** Chỉ 2/21 lỗi là thiếu chú ký.

`py2tkv` giữ nguyên nội dung và báo cáo cả hai loại vướng, nhưng **chưa** gộp
import — việc đó cần nghĩ lại cấu trúc từng công cụ.

## Phiên bản 2: bỏ import + đổi chỗ gọi sang builtin

Thêm bảng chuyển đổi Python → builtin, và **xoá hẳn** dòng `import` cấp module:

| Python | TokenVector |
|---|---|
| `os.path.join(` | `path_join(` |
| `os.path.exists(` / `isfile(` / `isdir(` | `path_exists(` / `path_isfile(` / `path_isdir(` |
| `os.path.basename(` / `dirname(` / `abspath(` | `path_basename(` / `path_dirname(` / `path_abspath(` |
| `os.remove(` | `os_remove(` |
| `sys.argv` | `sys_argv()` |

Chạy lại: `tkvdev.py` giờ **không còn dòng import nào**, và
`os.path.dirname(os.path.dirname(os.path.abspath(__file__)))` đã thành
`path_dirname(path_dirname(path_abspath(__file__)))`.

## Ràng buộc còn lại — không tự động được

`.tkv sinh ra BIÊN DỊCH ĐƯỢC: 0/21`. Lý do **không còn là import**. Hai ràng
buộc cấu trúc của TokenVector:

1. **Biến cấp module phải là hằng đơn giản.** `ROOT = os.path.dirname(...)`
   bị từ chối (`gia tri khoi tao phai la 1 hang so/chuoi don gian`). Muốn giữ
   phải tính trong `main()` rồi gán local — thay đổi cấu trúc, không làm tự động.
2. **Không có `__file__`.**

`py2tkv` giờ **báo cáo** hai thứ này thay vì im lặng:

```
CHAN: __file__ tai dong 27 (TokenVector khong co)
CHAN: bien cap module khong co kieu tai dong 27: ROOT = os.path.dirname(...)
```

Cùng với `CHUA SUY` (hàm chưa suy được kiểu) và `CHUA QUY TAC` (module chưa có
bảng chuyển đổi: `subprocess`, `re`, `ast`, `json`, `argparse`, `shutil`).

**Kết luận thẳng:** công cụ này xong phần *tự động* — nó lo chú ký kiểu, bỏ
import, đổi chỗ gọi, gộp nhiều module, và **liệt kê chính xác những gì phải sửa
tay**. Phần còn lại cần viết lại từng công cụ; `tools/probe_ten.tkv` là ví dụ đã
làm xong tay.

## Chế độ `--flat`: gộp nhiều module

Đây là cách giải bài toán "import trở thành lời gọi". `cmp_python_builtins.py`
gọi `import gen_builtin_ref` — trong TokenVector phải nối nguồn lại:

```
build\py2tkv.exe --flat ra.tkv tools\gen_builtin_ref.py tools\cmp_python_builtins.py
  vao   : tools\gen_builtin_ref.py  (302 dong, 2 file, bo 9 dong import)
  ham   : 9
```

## Phân loại chính xác 21 lỗi còn lại

Không còn lỗi "import". Tất cả thuộc 4 nhóm, và **mọi nhóm đều được tool báo
trước khi ghi file**:

| Số lần | Nguyên nhân | Tool có báo? |
|---|---|---|
| **15** | biến cấp module tính bằng biểu thức | `CHAN: bien cap module khong co kieu` |
| **5** | hàm chưa suy được kiểu | `CHUA SUY: <tên>` |
| 1 | file không có entry `main` | — (tên entry khác) |
| 1 | truy cập thuộc tính `param.field` | — (giới hạn TokenVector khác) |

## Bug của chính tool, đã sửa

`doc_vao()` từng `.strip()` **mọi dòng**, xoá mất thụt đầu dòng. Hậu quả kép:
thân hàm bị dính vào cột 0, và bộ dò blocker báo nhầm các dòng **bên trong**
hàm là "biến cấp module". Sửa: giữ nguyên dòng gốc, chỉ dùng bản `strip()` để
kiểm tra `import`.

Bộ dò blocker cũng từng báo nhầm hằng literal (`END = '<!-- ... -->'`,
`FILES = []`) là phi pháp — thêm `la_hang_so()` để chỉ flag khi RHS thật sự là
biểu thức.

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

# Đã viết lại: `probe_ten` không gọi compiler lúc chạy

Bản cũ giữ đúng hành vi của `probe_name_exists.py`: mỗi tên là một lần gọi
`tkvc-tv.exe`. Hai bản cho kết quả phân loại giống hệt, nhưng đó là thiết kế
sai cho công cụ lúc chạy: compiler là công cụ build, không phải phụ thuộc của
mỗi câu tra cứu.

Bản mới chia trách nhiệm:

- `tools/danh_muc_ten_lib.tkv`: thư viện quét danh mục tĩnh, không có `main`.
  Mọi hàm/biến toàn cục đều có tiền tố `dm_` vì TokenVector gộp toàn bộ các
  module và báo lỗi nếu trùng tên hàm/class.
- `tools/tra_ten.tkv`: CLI mỏng, gọi thư viện.
- `tools/probe_ten.tkv`: CLI mỏng, gọi thư viện, **không còn `proc_run`,
  không tạo file `.tkv` tạm, không gọi compiler**.

Xây một lần:

```powershell
dist\tkvc-tv.exe tools\tra_ten.tkv build\tra_ten.exe main
dist\tkvc-tv.exe tools\probe_ten.tkv build\probe_ten.exe main
```

## Quy tắc rút tên và ý nghĩa phân loại

- `CHAC`: chỉ từ lệnh `register_x(reg, 'ten', ...)` có chuỗi literal ở tham số
  thứ hai. Bỏ qua dòng chú thích Python bắt đầu bằng `#`.
- `KHA`: chỉ từ khóa dict literal `'ten' : ...`. Đây là nguồn khả năng, có thể
  bao gồm khóa không phải tên đăng ký, nên báo riêng và **không gộp** với CHAC.
- `THIEU`: không thấy trong danh mục tĩnh.

Do đó `CHAC` là bằng chứng đăng ký trực tiếp, còn `KHA` chỉ là manh mối. Muốn
chứng minh một tên gọi được với bộ tham số cụ thể, vẫn cần biên dịch thử một
chương trình mẫu — nhưng đó là việc kiểm chứng một lần, không phải chi phí cho
mỗi câu tra cứu.

## So sánh công bằng: cùng workload, cùng quy tắc, không gọi compiler

Cả hai bản cùng:

- đọc `compiler_src/ds_gop.txt`
- đọc cùng 125 file nguồn
- áp dụng cùng quy tắc rút `CHAC`/`KHA`
- tra cứu cùng 60 tên trong cùng một file
- in cùng 64 dòng báo cáo

Kiểm tra đầu ra: **64/64 dòng giống hệt nhau**.

Đo 5 lần, bỏ qua chi phí in ra màn hình:

```text
TV_MS = 469, 462, 460, 460, 462   (min 460, median 462)
PY_MS = 877, 874, 868, 874, 872   (min 868, median 874)
```

Trên workload quét văn bản này, bản TokenVector nhanh hơn khoảng **1,89 lần**;
bản Python chậm hơn khoảng **89%**.

Kết luận này không chứng minh TokenVector luôn nhanh hơn. Nó chỉ chứng minh
đúng một việc đã đo: với cùng công việc quét/trích xuất văn bản và cùng đầu ra,
bản TokenVector hiện tại chạy nhanh hơn bản Python viết tương đương.

## Kiểm chứng chéo danh mục thiếu

19 tên `THIEU` trên bộ 60 đã được kiểm bằng bản probe thực nghiệm cũ
(mỗi tên một lần biên dịch, chỉ làm một lần để kiểm chứng, không phải thiết kế
chạy thường xuyên). Kết quả: cả 19 đều được compiler báo thiếu. Do đó danh mục
tĩnh không bỏ sót 19 tên này theo cách phân loại hiện tại.


## Dieu tra `BadImageFormatException` (2026-10-04, chua giai quyet)

`gom_cap_module()` (gom code cap module vao ham `__khoi_dong()`) lam binary
`py2tkv.exe` chet luc chay:

```text
Unhandled Exception: System.BadImageFormatException: An attempt was made to
load a program with an incorrect format. (0x8007000B)
   at TKVApp.gom_cap_module()
```

### Da biet - va day la diem quan trong nhat

1. **Khong phai forward reference.** Ban dau ham nam truoc `can_fold_module`;
   chuyen xuoi sau do va do lai - van cung loi.
2. **Khong phai gioi han bien cục bộ.** Probe voi 20 bien `i32` + 10 bien `str`
   + 4 list trong mot ham: chay tot.
3. **Khong phai nhieu list cục bộ, `continue`/`break` long nhau, hay goi phuong
   thuc tren ket qua phuong thuc** - ca ba deu co probe rieng, deu chay tot.
4. **Loi XAY RA O LUC NANG HAM (load-time), khong phai luc chay.** Khi file
   khong co code cap module nao thi `len(dau) == 0` va ham tra ve ngay - nhanh
   cho `return 0` truoc khi doan nghi van. VAY MA VAN CHET. Nghia la IL sinh
   ra sai ngay tu khi bien dich, va chi can **CO MAT** doan do trong than ham
   la du - kiem chung nhanh `return 0` co gi khong "an" duoc.
5. **Bisect da khoanh vung**: vong quet + kiem tra an toan -> sach. Phai them
   khoi *dung lai `DONG`* (tim `def main`, vong `while` co `for z in
   range(len(dau))` long nhau de cat theo khoi, roi `them_dong(ra)`) moi
   no. Chua tach duoc duong len bi lo trong khoi do.

### Hanh dong dung khi gap loi nay

Khi mot ham TokenVector chet luc chay voi `BadImageFormatException`, phai
**coi do la loi bien dich**, khong phai logic sai. Khong cach nao "chay thi
thay": dung co che return truoc khi doan nghi van **khong** loai duoc loi -
phai tach bo cac KHOI code ra cho den khi het, roi xem khoi nao la chet.
Bien dich cac khoi do lau mot cac du an va doc lap, de khong lam hong ban goc.

Chua sua duoc. `gom_cap_module()` hien dang **khong co trong `py2tkv.tkv`**
(commit 63d47ee) - 7 file con loi cap module van phai chan.

### Nhom loi cap module con lai (do la bang converter)

Khong phai moi loi cap module deu do compiler. Bao cao `CHAN cap module` da
chi ra tung thu, va nhieu thu la thuoc ve chinh py2tkv:

- `gen_builtin_ref.py`: `__file__` va `re.compile(...)` o cap module.
- `tol.py`: list comprehension `[float(...) for i in range(n*n)]` o cap module.