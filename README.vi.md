<p align="left">
  <a href="README.md">English</a> | <strong>Tiếng Việt</strong>
</p>

<p align="left">
  <img src="https://img.shields.io/badge/.NET%20Framework-4.8-purple.svg?style=flat-square" alt=".NET Framework 4.8">
  <img src="https://img.shields.io/badge/version-1.0.11-blue.svg?style=flat-square" alt="phiên bản 1.0.11">
  <img src="https://img.shields.io/badge/tests-135%2F135-brightgreen.svg?style=flat-square" alt="tests 134/134">
  <img src="https://img.shields.io/badge/builtins-423-orange.svg?style=flat-square" alt="builtins 423">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="Giấy phép: MIT">
</p>

# TokenVector (`.tkv`, `.tv`)

Ngôn ngữ kiểu tĩnh, biên dịch ra **.NET CIL** và liên kết thành một **`.exe`
độc lập**. Viết theo cú pháp giống Python; xuất ra nhị phân native — **không
interpreter, không Python, không cần gói runtime, không GIL**.

Gốc của repo này chỉ chứa **bản phát hành** và README này. Mọi thứ khác —
mã nguồn compiler, tài liệu, test, gate, ví dụ — nằm trong **`Release/`**.

---

## Bắt đầu nhanh (Windows, 3 bước)

### 1. Lấy bản phát hành

```powershell
git clone https://github.com/nguyenhungtran18/TokenVector.git
cd TokenVector
```

### 2. Viết một chương trình

Lưu thành `hello.tkv` (UTF-8 thuần, **không có BOM** — xem mục Hạn chế):

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

### 3. Biên dịch và chạy

```powershell
Release\dist\tkvc-tv.exe hello.tkv hello.exe run
.\hello.exe
```

Kết quả:

```text
mean = 2.5
```

CLI là **positional** — `tkvc-tv.exe <nguon.tkv> <ra.exe> <ham_entry>`.

File `hello.exe` có kích thước **9,5 KB** (một `print("hi")` tối thiểu là
**6 KB**) và chạy trên mọi máy có **.NET Framework 4.x**. Không có gì phải cài
thêm.

> **Yêu cầu:** bản thân compiler (`tkvc-tv.exe`) là PE Windows và cần
> .NET Framework 4.x trên máy *biên dịch*. Chương trình nó tạo ra cũng cần
> framework đó trên máy *chạy* — đó là phụ thuộc duy nhất.

---

## Bạn nhận được gì

| | |
|---|---|
| Đầu ra | một **`.exe` độc lập** (PE), **6 KB** cho `print` tối thiểu, 9,5 KB cho ví dụ trên |
| Kiểu dữ liệu | `i32` / `i64` / `f32` / `f64` / `str` không hộp, cùng `int` và `bool` |
| Runtime | .NET Framework 4.x — không interpreter, không GIL |
| Luồng | `thread_spawn` / `thread_join`, đa lõi thật, không có global lock |
| SIMD | `f32x4` → `System.Numerics.Vector4`; vòng lặp elementwise được tự động vector hóa (P6); `simd_gemm` chạy kernel native AVX2+FMA cho matmul f32/f64 |
| Interop | mọi assembly .NET/NuGet, P/Invoke, và C FFI trực tiếp |

---

## Vị trí trung thực — thắng ở đâu, thua ở đâu

Đo ngày 2026-11-04 với **CPython 3.14.7** và **NumPy 2.5.2**
(OpenBLAS 0.3.34, kernel Haswell). Phương pháp và checksum đầy đủ:
[`Release/benchmark/KETQUA.md`](Release/benchmark/KETQUA.md).

**Với CPython, TokenVector thắng trên mọi kernel trong harness:**

| kernel | TokenVector | CPython | nhanh hơn |
|---|---|---|---|
| fib(32) | 14,9 ms | 1169 ms | **78×** |
| sort | 1,51 ms | 37659 ms | **24989×** (thuật toán khác; xem ghi chú) |
| matmul32 (native) | 3,2 µs | 308 ms | **96250×** |
| add | 0,582 ms | 1540 ms | **2647×** |
| string | 5,28 ms | 337 ms | **64×** |

**Với NumPy thì có thắng có thua, và `string` giờ bị chặn ở `join` chứ
không phải do cấp phát từng ký tự:**

| kernel | TokenVector | NumPy 2.5.2 | nhanh hơn |
|---|---|---|---|
| matmul32 (`simd_gemm`, f64) | 3,3 µs | 5,2 µs | **TokenVector 1,58×** |
| matmul32 (đường IL f32x4) | 9,5 µs | 5,2 µs | NumPy 1,83× |
| add | 0,582 ms | 0,845 ms | **TokenVector 1,45×** |
| sort | 1,51 ms | 3,93 ms | **TokenVector 2,61×** (thuật toán khác; xem ghi chú) |
| string | 5,28 ms | 2,23 ms | NumPy 2,37× |
| string — hàng SIMD scan | 4,58 ms | 2,23 ms | NumPy 2,05× |

NumPy là mã native (BLAS/ufuncs), không phải runtime managed. Đường IL
không thể đua đều với BLAS; `simd_gemm` là đường native. Hàng sort dùng
kernel đếm 16-bit cho workload này và lùi về merge khi gặp số âm/ngoài
phạm vi, nên tỉ lệ đó đo thuật toán khác chứ không phải comparison sort
tổng quát.

### Các con số trên có được kiểm không?

Có — repo mang theo gate của chính nó, và bảng dưới là kết quả chúng thực sự
in ra. **Gate không xanh thì các tuyên bố trên không đứng.**

| Gate | Lệnh | Kết quả |
|---|---|---|
| Chấp nhận compiler | `powershell -File Release\tools\testkit_gate.ps1` | **134/134** đạt, **42/42** case âm bị từ chối đúng |
| Điểm bất động tự sinh | `Release\tools\vong.exe` | **IL_IDENTICAL** (133 file) |
| Hiệu năng | `powershell -File Release\tools\perf_gate.ps1` | 4 kernel, best-of-5, **có so checksum** |
| Tự kiểm luật lint | `powershell -File Release\tools\lint_rules_gate.ps1` | Bắt đủ 8 bẫy, 0 báo nhầm |
| Đăng ký | `Release\dist\tkvc-tv.exe Release\tools\dang_ky_gate.tkv Release\build\dk.exe run` | 0 vi phạm |

**Builtins đã đăng ký: 423.**

Bản thân compiler **tự sinh**: mã nguồn là 133 file `.tkv` trong
`Release/compiler_bootstrap/`. `Release\tools\vong.exe` gộp chúng, biên dịch
hai lần, và đòi hai bản IL phải giống nhau từng byte (`IL_IDENTICAL`).

---

## Cấu trúc repo

```
TokenVector/
├── README.md            file này
├── README.vi.md         bản tiếng Việt
├── LICENSE              MIT
└── Release/             toàn bộ bản phát hành
    ├── compiler_bootstrap/   133 file .tkv — compiler, viết bằng TokenVector
    ├── compiler_src/         manifest ds_gop.txt dùng để gộp chúng
    ├── dist/                 tkvc-tv.exe (compiler) + il_features/
    ├── tests/                135 test chấp nhận + 44 case âm
    ├── tests_suite/          154 case dữ liệu .ca + 203 mẫu đầu vào
    ├── tools/                gate + tkv_guide.tkv (trợ lý tra quy tắc)
    ├── projects/             19 công cụ thật viết bằng .tkv
    ├── examples/            chương trình mẫu + stdlib/
    ├── docs/                mọi tài liệu
    ├── packaging/           nuspec NuGet, MSBuild props/targets, pack.ps1
    └── assets/              sơ đồ, demo HTML, ảnh preview
```

Clone repo là có ngay bản phát hành — không cần tải thêm, không cần build.

---

## Tài liệu

| Tài liệu | Nội dung |
|---|---|
| [`Release/docs/REFERENCE.md`](Release/docs/REFERENCE.md) | **Một tài liệu để đọc.** Cú pháp, hành vi, và mọi khác biệt với Python theo từng builtin |
| [`Release/docs/HANDBOOK.md`](Release/docs/HANDBOOK.md) | Định hướng song ngữ + các quy tắc cạm bẫy nhất |
| [`Release/docs/HANDBOOK.vi.md`](Release/docs/HANDBOOK.vi.md) | Cẩm nang 10 chương (tiếng Việt) |
| [`Release/docs/TUTORIAL.md`](Release/docs/TUTORIAL.md) | Hướng dẫn lập trình theo chương |
| [`Release/docs/ARCHITECTURE.md`](Release/docs/ARCHITECTURE.md) | Pipeline compiler và registry file |
| [`Release/docs/COMPARISON-PYTHON.md`](Release/docs/COMPARISON-PYTHON.md) | TokenVector khác CPython ở đâu |
| [`Release/docs/PLAN.md`](Release/docs/PLAN.md) | Danh sách hạn chế, xếp theo độ khó |
| [`Release/docs/REPOSITORY-NOTES.md`](Release/docs/REPOSITORY-NOTES.md) | Nhật ký kỹ thuật: mọi bug đã gặp và cách chứng minh |
| [`Release/docs/ROADMAP.md`](Release/docs/ROADMAP.md) | Lộ trình sản phẩm |
| [`Release/docs/llms.txt`](Release/docs/llms.txt) | Tóm tắt gọn cho máy đọc |

### Hỏi tool, đừng hỏi bộ nhớ

`tkv_guide` viết **bằng TokenVector** và là nguồn duy nhất về quy tắc ngôn ngữ.
Build một lần rồi hỏi:

```powershell
powershell -File Release\tools\build_tkv_guide.ps1

Release\dist\bin\tkv_guide.exe rules               # những cạm bẫy thật sự cắn
Release\dist\bin\tkv_guide.exe find sorted         # cú pháp chính xác + khác Python thế nào
Release\dist\bin\tkv_guide.exe names iter          # builtin đã đăng ký, theo module
Release\dist\bin\tkv_guide.exe lint my_file.tkv    # bẫy mà compiler im lặng bỏ qua
Release\dist\bin\tkv_guide.exe verify my_file.tkv  # in ra 2 lệnh build+run chính xác
```

`verify` chỉ **in** hai lệnh — TokenVector chưa spawn được tiến trình nên tool
không build thay bạn. Chạy cả hai và đọc output.

> **Build xanh không có nghĩa là chương trình đúng.** Có bug biên dịch sạch
> rồi trả về *giá trị sai*. Luôn build **và chạy**.

---

## Những thứ sẽ làm người quen Python ngạc nhiên

Tất cả đều đã được thử, không suy đoán:

- **Biến cục bộ trong hàm không được ghi chú kiểu.** Viết `x = 1`, không phải
  `x: "i32" = 1`. Kiểu được suy từ vế phải.
- **`f"{n}"`, `f"{n:05d}"`, `f"{v:.2f}"`, `"{}".format(x)` và chuỗi ba nháy**
  đều chạy.
- **`str(x)` nhận mọi biểu thức**: `str(a + b)`, `str(len(xs) + 1)`. Chỉ
  `fmt_float(v, n)` đòi `v` phải là biến đơn thuần.
- **Builtin regex nhận input trước**: `re_search(pattern, s)`. Tên là
  `re_match` / `re_search` / `re_fullmatch` / `re_sub` / `re_split` /
  `re_findall`. `re_findall` trả toàn bộ match, không phải group.
- **`next(it, default)`** đòi `default` phải cùng kiểu phần tử.
- **`except RuntimeError:` cũng bắt `StopIteration`** — cả hai ánh xuống
  `System.InvalidOperationException`. Dùng `next(it, default)` để kiểm tra hết.
- **`hash()` là FNV-1a**, không như Python. Dùng làm khóa được, **không** so
  giá trị được.
- **Ép kiểu container xảy ra ở điểm gọi**, nên truyền list literal vào tham số
  `list[i32]` được.
- **`print` đi qua `Console::WriteLine`**; stdout khi redirect mặc định
  UTF-16LE, mà PowerShell 5.1 hiện ra `?`. Dùng `path_write_text` trong tool
  của bạn.
- **BOM UTF-8 trong file nguồn bị từ chối** (`U+FEFF`).
  `Set-Content -Encoding UTF8` của PowerShell 5.1 có ghi BOM — dùng
  `-Encoding utf8NoBOM` hoặc `[System.IO.File]::WriteAllText`.

## Hạn chế

Đã kiểm bằng probe; danh sách xếp theo độ khó ở
[`Release/docs/PLAN.md`](Release/docs/PLAN.md).

- **Không có `subprocess`** — chương trình không khởi động được tiến trình khác.
- **Bước cắt âm** — `a[::-1]` và `a[1:-1]` bị từ chối; bước dương thì chạy
  (`a[::2]`, `a[1:5:2]`).
- Không có `slice()` như hàm gọi được, không có tham số keyword-only hay
  positional-only.
- **Biểu thức điều kiện lệch kiểu nhánh** (`i32 if c else f64`) biên dịch được
  và trả về con trỏ rác. Hai nhánh phải cùng kiểu.
- Trường container của record nên khai `list[int]`, không phải `list[i32]`, khi
  nạp từ list literal.

## Interop

- **Mọi assembly .NET / NuGet** — `__tkv_extern_class__` cho constructor,
  method và property; `__tkv_extern_pinvoke__` cho P/Invoke; C FFI động qua
  `LoadLibraryA` / `GetProcAddress`.
- **Đa luồng** — `thread_spawn` / `thread_join` dùng .NET thread pool, không có
  global lock.
- **Import liên assembly** hỗ trợ qua `__tkv_extern_class__`.

## Build lại compiler

Không cần build gì để *dùng* bản phát hành. Nếu muốn làm việc trên compiler:

```powershell
cd Release
tools\vong.exe
```

Lệnh gộp `compiler_bootstrap/`, biên dịch hai lần, và in `IL_IDENTICAL` khi
điểm bất động đạt. `IL KHAC NHAU` nghĩa là compiler tự nâng cấp — chạy lại là
được. Sau đó:

```powershell
powershell -File tools\testkit_gate.ps1
```

---

## Hỗ trợ editor

- **VS Code** — [`TokenVector Language Support`](https://marketplace.visualstudio.com/items?itemName=nguyenhungtran18.tokenvector-syntax)
  (tô màu cú pháp, snippet `tkv-entry` / `tkv-func` / `tkv-class`).
  Mã nguồn: [nguyenhungtran18/tokenvector-grammar](https://github.com/nguyenhungtran18/tokenvector-grammar).
- **Language ID** `tokenvector`; phần mở rộng `.tkv`, `.tv`; scope
  `source.tokenvector`.
- **Hỏi chính repo** — một agent trỏ vào repo có thể chạy
  `Release\dist\bin\tkv_guide.exe rules` để lấy các quy tắc thật sự cạm bẫy.

## Giấy phép

[MIT](LICENSE) © 2026 TokenVector Project / Nguyen Hung Tran.

---

<sub>Lộ trình: [`Release/docs/ROADMAP.md`](Release/docs/ROADMAP.md) ·
Chiến lược: [`Release/docs/STRATEGY.md`](Release/docs/STRATEGY.md) ·
Lịch sử kỹ thuật: [`Release/docs/REPOSITORY-NOTES.md`](Release/docs/REPOSITORY-NOTES.md)</sub>
