<p align="left">
  <a href="README.md">English</a> | <strong>Tiếng Việt</strong>
</p>

# TokenVector (`.tkv`, `.tv`)

Ngôn ngữ tĩnh kiểu biên dịch thẳng ra **.NET CIL**, rồi liên kết thành **tệp
`.exe` độc lập**. Không interpreter, không CPython lúc chạy, không GIL.

```python
# -*- coding: utf-8 -*-
def mean(xs: "list[f64]") -> "f64":
    if len(xs) == 0:
        return 0.0
    total = 0.0
    for x in xs:
        total = total + x
    return total / len(xs)

def run() -> "i32":
    data = [1.0, 2.5, 4.0]
    print("mean = " + str(mean(data)))
    return 0
```

```powershell
cd D:\TokenVector
dist\tkvc-tv.exe demo.tkv demo.exe run
.\demo.exe
```

Kết quả là một `.exe` khoảng **6 KB** (hello-world) chạy được trên mọi máy có
.NET Framework — **không Python, không bundle runtime, không venv**.

---

## 1. Tình trạng — đã kiểm chứng, không phải hứa hẹn

Mọi dòng dưới đây đều do một cổng trong repo này kiểm tra. Số liệu ngày
2026-10-02.

| Cổng | Lệnh | Kết quả |
|---|---|---|
| Nghiệm thu compiler | `powershell -File tools\testkit_gate.ps1` | **125/125** PASS, **31/31** negative bị từ chối đúng |
| Fixpoint tự biên dịch | `tools\vong.exe` | **IL_IDENTICAL** (132 file) |
| Hiệu năng | `powershell -File tools\perf_gate.ps1` | 4 kernel, best-of-5, **có so checksum** |
| Tự kiểm bộ luật lint | `powershell -File tools\lint_rules_gate.ps1` | Bắt đủ 8 bẫy, 0 báo nhầm |
| Đăng ký | `dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run` | 0 vi phạm |

**Đã đăng ký 420 builtin.**

> **Compiler thật sự là gì.** Mã nguồn compiler là **`compiler_bootstrap/`** —
> 132 file **thật sự là TokenVector**. `dist\tkvc-tv.exe` do `tools\vong.exe`
> sinh ra: nó gộp các file đó rồi biên dịch **hai lần**, và hai bản IL phải
> giống hệt nhau byte-for-byte (`IL_IDENTICAL`). Đó mới là "self-hosted".

> **Đừng tin claim nào không có cổng kiểm.** Số benchmark trong
> `docs/ROADMAP.md` là số đo có ngày; đối chiếu với CPython/NumPy nằm ở repo
> `TokenVector.TestOracle`, còn hiệu năng thì so với baseline của chính compiler
> (`tools/perf/baseline.txt`), không bao giờ so với binary dựng sẵn.

## 1b. TokenVector đấu ở đâu — và KHÔNG đấu ở đâu

Đo 2026-10-14 với **CPython 3.14.7** và **NumPy 2.5.2** (OpenBLAS 0.3.34,
kernel "Haswell") trên Intel Xeon E5-2695 v3. Tái lập:
`python D:\TokenVector.TestOracle\benchmark\run.py --self-host`.

**Với CPython, TokenVector thắng ở mọi kernel:**

| kernel | TokenVector | CPython | TokenVector nhanh hơn |
|---|---|---|---|
| fib | 11,4 ms | 933 ms | **82×** |
| sort | 15,7 ms | 1012 ms | **64×** |
| matmul32 | 147 µs | 8,87 ms | **60×** |
| add | 1,43 ms | 67,1 ms | **47×** |
| f32mm_vec | 33 µs | 1,48 ms | **45×** |
| f32mm | 141 µs | 1,49 ms | **11×** |
| string | 22,9 ms | 49,7 ms | **2,2×** |

Một `.exe` rỗng của TokenVector cũng khởi động trong **24,8 ms**, so với
**35,2 ms** của `CPython -c pass`.

**Với NumPy thì không — và cũng không nên giả vờ.** NumPy là CPython gọi **mã
máy native**, không phải runtime managed:

| kernel | TokenVector | NumPy | NumPy nhanh hơn |
|---|---|---|---|
| add | 1427 µs | 911 µs | **1,6×** |
| matmul32 | 147 µs | 5,7 µs | **26×** |

Khoảng cách đó **không** phải do thiếu một tối ưu, cũng **không** do thiếu đa
luồng. Đo với `OMP_NUM_THREADS=1` thì `np.dot` trên ma trận 32×32 chỉ chậm từ
5,73 µs lên 6,05 µs — OpenBLAS không chia nhỏ ma trận nhỏ thế. Còn lại là độ
rộng vector: AVX2 với FMA xử lý **4 `double`/lệnh**, trong khi runtime này chỉ
cho `Vector4` (128-bit) và lệnh vector thô bị JIT từ chối (xem §2 và
`docs/PLAN.md` mục 8).

Hai "đòn bẩy rẻ" đã đo và **cả hai đều chết**, nên chúng không phải câu trả
lời:

- **Strength reduction** của chỉ số vòng trong (`kk*n + j` → biến chuyển vị):
  **1,00×**. Chuỗi `mul.ovf`/`add.ovf`/`conv.ovf.i4` gần như miễn phí trên JIT.
- **Bộ nhớ native liền mạch** thay cho `List<double>`: **0,63×** — *chậm hơn*,
  vì `f32buf` phải trả `×4` byte offset cộng bounds check mỗi lần truy cập.

**Cập nhật 2026-10-18 — `simd_gemm` (kernel native AVX2+FMA).** Khoảng cách
trên là của đường IL/`Vector4`. `simd_gemm(a, b, r, n)` giờ gọi kernel C đi kèm
(`tkv_simd_native.dll`) cho matmul f32/f64 và nhanh hơn NumPy 2.5.2 ở mọi kích
thước đã thử (128–1024): ví dụ n=1024, 3,68 ms (f32) / 7,59 ms (f64) so với
3,867 ms / 9,921 ms.

**Vậy vị trí trung thực là: TokenVector là thay thế CPython.** Nó thắng
interpreter nó thay thế 2–82× và có SIMD f32 thật (4,25× so với chính nó trên
`f32mm_vec`). Đường IL thuần không thể đuổi tới hiệu năng BLAS `f64` trên .NET
Framework 4.8; `simd_gemm` thì có, qua một kernel native, mà không cần đổi
runtime.

## 2. TokenVector KHÔNG phải là gì

Nó **không** phải CPython có interpreter nhanh hơn. Nó là **transpiler sang
CIL**:

- **Mã nguồn compiler là TokenVector**, không phải Python. Dựng
  `tkvc-tv.exe` không cần CPython; chỉ cần `dist\tkvc-tv.exe` và
  `tools\vong.exe`.
- Cú pháp lấy cảm hứng từ Python, **không tương thích** Python. Các giới hạn
  đã biết nằm ở mục 6 và đều được kiểm, không phải giả định.

## 3. Nội dung repo

| Đường dẫn | Nội dung |
|---|---|
```
compiler_bootstrap/  compiler — 132 file .tkv (đây là nguồn TokenVector thật)
compiler_src/        manifest file (ds_gop.txt) dùng để gộp chúng lại
dist/                tkvc-tv.exe — compiler tự biên dịch
tests/               125 test nghi?m thu + 31 negative
tests_suite/         154 case .ca + 203 mẫu vào
tools/               các cổng kiểm + tkv_guide.tkv (tool hỏi đáp ngôn ngữ)
projects/            19 công cụ thật viết bằng .tkv
examples/            chương trình mẫu + stdlib/
docs/                toàn bộ tài liệu (xem bảng dưới)
packaging/           nuspec NuGet, MSBuild props/targets, pack.ps1
assets/              sơ đồ, demo HTML, ảnh xem trước
build/               thư mục sinh ra — không commit
```

| Tài liệu | Nội dung |
|---|---|
| `docs/REFERENCE.md` | **Tài liệu duy nhất.** Cú pháp + hành vi + khác biệt với Python cho từng builtin |
| `docs/HANDBOOK.md` | Sổ tay song ngữ + những ràng buộc hay cắn nhất |
| `docs/HANDBOOK.vi.md` | Sổ tay đầy đủ 10 chương (tiếng Việt) |
| `docs/TUTORIAL.md` | Hướng dẫn lập trình theo từng chương |
| `docs/ARCHITECTURE.md` | Quy trình compiler, sổ file hệ thống |
| `docs/COMPARISON-PYTHON.md` | Chỗ khác biệt với CPython |
| `docs/PLAN.md` | Danh sách gap, xếp theo độ khó |
| `docs/REPOSITORY-NOTES.md` | Nhật ký kỹ thuật: từng bug tìm ra và cách chứng minh |
| `docs/ROADMAP.md`, `docs/STRATEGY.md` | Roadmap sản phẩm và định vị |
| `docs/llms.txt` | Bản tóm tắt ngắn gọn cho máy đọc |

## 4. Dành cho agent và người mới: hỏi tool đừng nhớ

Chi tiết rất nhiều, và "tài liệu" trước đây đã từng sai. Tool viết **bằng
TokenVector** và là nguồn duy nhất cho các quy tắc ngôn ngữ:

```powershell
cd D:\TokenVector
powershell -File tools\build_tkv_guide.ps1

dist\bin\tkv_guide.exe rules              # những ràng buộc thật sự cắn người viết
dist\bin\tkv_guide.exe find sorted        # cú pháp + khác biệt với Python
dist\bin\tkv_guide.exe names iter         # builtin đã đăng ký, theo module
dist\bin\tkv_guide.exe lint my_file.tkv   # bẫy mà compiler bỏ qua khi biên dịch
dist\bin\tkv_guide.exe verify my_file.tkv # in đúng 2 lệnh build + chạy
```

`verify` chỉ **in** hai lệnh đó — TokenVector chưa khuởng được tiến trình khác
nên tool không tự build được. Hãy chạy cả hai rồi đọc kết quả.

> **Build xanh không có nghĩa chương trình đúng.** Đã có bug biên dịch thành
> công rồi trả về **giá trị sai** mà không báo lỗi. Luôn build **và chạy**.

## 5. Hành vi đáng chú ý (đều đã probe, không giả định)

- f-string `f"{n}"`, `f"{n:05d}"`, `f"{v:.2f}"`, `.format()` và chuỗi
  `"""ba nháy"""` **đều chạy được**.
- `str(x)` nhận **mọi biểu thức**: `str(a + b)`, `str(len(xs) + 1)`. Chỉ
  `fmt_float(v, n)` mới bắt buộc `v` là một biến đơn.
- Biến cục bộ trong thân hàm **không được** annotate kiểu (`x = 1`, không phải
  `x: "i32" = 1`); kiểu được suy ra từ vế phải.
- Regex nhận **đầu vào trước**: `re_search(pattern, s)`. Tên là `re_match` /
  `re_search` / `re_fullmatch` / `re_sub` / `re_split` / `re_findall`.
  `re_findall` trả về **cả match**, không phải group.
- `next(it, default)` đòi `default` cùng kiểu với phần tử.
- **`except RuntimeError:` cũng bắt `StopIteration`** — cả hai đều ánh xạ
  `System.InvalidOperationException`. Muốn kiểm tra đã hết dữ liệu thì dùng
  `next(it, default)`.
- `hash()` là FNV-1a, khác Python. Dùng làm khoá được, nhưng **không** cho ra
  cùng giá trị.
- Ép kiểu container xảy ra ở điểm gọi, nên truyền list literal cho tham số
  `list[i32]` vẫn chạy.
- `print` đi qua `Console::WriteLine`; khi redirect, .NET mặc định ghi
  **UTF-16LE**, PowerShell 5.1 hiện thành `?`. Dùng `--file out.txt` với
  `tkv_guide`, hoặc `path_write_text` trong tool của bạn.
- **BOM UTF-8 trong file nguồn bị từ chối** (`U+FEFF`). `Set-Content -Encoding
  UTF8` của PowerShell 5.1 có ghi BOM — hãy dùng `utf8NoBOM` hoặc
  `[System.IO.File]::WriteAllText`.

## 6. Giới hạn đã biết

Đã probe; danh sách xếp theo độ khó nằm ở `docs/PLAN.md`.

- **Không có `subprocess`** — chương trình không thể khởi chạy tiến trình khác.
  (Đây là lý do `tkv_guide verify` chỉ in lệnh.)
- **Bước slice âm** — `a[::-1]` và `a[1:-1]` bị từ chối; bước dương thì được
  (`a[::2]`, `a[1:5:2]`).
- Không có `slice()` dạng hàm, không có tham số keyword-only / positional-only.
- **Biểu thức điều kiện 2 nhánh khác kiểu** (`i32 if c else f64`) biên dịch
  được rồi trả về **con trỏ rác**. Cả hai nhánh phải cùng kiểu.
- Field container của record nên khai `list[int]` chứ không phải `list[i32]`
  khi nạp từ list literal.

## 7. Tương tác

- **Mọi assembly .NET / NuGet**: `__tkv_extern_class__` cho constructor, method
  và property; `__tkv_extern_pinvoke__` cho P/Invoke; FFI C động qua
  `LoadLibraryA`/`GetProcAddress`.
- **Đồng thời**: `thread_spawn` / `thread_join` dùng thread pool của .NET, không
  khoá toàn cục.
- **Import xuyên assembly** được hỗ trợ qua `__tkv_extern_class__`.

## 8. Build lại compiler

Không có gì để build. `dist\tkvc-tv.exe` **được sinh từ nguồn trong chính repo
này** và được tạo lại bởi vòng tự biên dịch:

```powershell
tools\vong.exe     # gộp compiler_bootstrap\ rồi biên dịch hai lần
                   # in IL_IDENTICAL khi fixpoint đóng
```

Sau khi sửa bất cứ thứ gì dưới `compiler_bootstrap/`, chạy `tools\vong.exe`
cho tới khi in `IL_IDENTICAL` (`IL KHAC NHAU` nghĩa là compiler đã tự nâng cấp
— chạy lại là đúng), rồi `tools\testkit_gate.ps1`.

---

*Giấy phép: xem `LICENSE`. Tài liệu roadmap và chiến lược nằm ở
`docs/ROADMAP.md` và `docs/STRATEGY.md`; lịch sử kỹ
thuật nằm ở `docs/REPOSITORY-NOTES.md`.*
