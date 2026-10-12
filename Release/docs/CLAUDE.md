# TokenVector Release — quy tắc làm việc

Bản này mô tả **thư mục `Release/`**. Nếu bạn đọc bản ở gốc repo, layout
khác (có `compiler_py/`, `benchmark/`, `packaging/`…) — ở đây không có.

## Đây là gì

Bộ công cụ phát triển **ngôn ngữ TokenVector**: compiler tự-host, nguồn của
nó, bộ test và cổng. **Không có file `.py` nào.**

| Đường dẫn | Số file | Vai trò |
|---|---:|---|
| `compiler_bootstrap/` | 132 | **Nguồn compiler tự-host** — 132 file TokenVector thuần |
| `compiler_src/` | 10 | `ds_gop.txt` (manifest 132 dòng) + `feature_can.txt` + 8 file seed cũ (không ai biên dịch) |
| `dist/` | 2 | `tkvc-tv.exe` (compiler) + `bin/tkv_guide.exe` |
| `tests/` | 162 | 119 test chấp nhận + 31 test âm + `tkv_test_lib.tkv` |
| `tests_suite/` | 445 | 154 case `.ca` + 203 mẫu |
| `tools/` | 19 | Cổng + gate |
| `examples/`, `projects/` | 27 | Chương trình TokenVector |
| `docs/` | 6 | Tài liệu |

## Không có gì ở đây

| Thiếu | Vì sao |
|---|---|
| `dist/tkvc.exe` | Đó là compiler **Python** (PyInstaller). Nguồn nó ở repo `TokenVector.CompilerPy` |
| `compiler_py/` | Submodule — tách riêng 2026-10-12 |
| `benchmark/` | Cần baseline CPython/NumPy → repo `TokenVector.TestOracle` |
| `tools/parity_probe/` | Oracle CPython → repo `TokenVector.TestOracle` |
| `tools/ext_smoke.ps1` | Biên dịch project ngoài bằng compiler Python |
| `packaging/`, `assets/` | Không thuộc bộ công cụ ngôn ngữ |

## Quy tắc cứng

- **Đừng mô tả compiler là "viết bằng TokenVector" một cách mơ hồ.** `compiler_bootstrap/`
  **là** TokenVector thật, và nó tự biên dịch chính nó. Đây là điều đã được
  kiểm chứng bằng gate, không phải suông. (Nguồn trước đây ghi ngược lại —
  đừng tin bản cũ.)
- **`run()` trả về = exit code.** Ham entry trả `"i32"`/`"i64"` thì giá trị đó
  thành exit code của process. Trả `"str"` hoặc tuple thì in ra.
- **Đừng sửa `compiler_bootstrap/` mà không chạy gate.** Gate đo sản phẩm
  thật; đổi mà không build lại thì đang đo compiler cũ.
- **Hỏi `tkv_guide`, đừng nhớ từ đầu.** `docs/REFERENCE.md` là nguồn duy nhất
  cho chữ ký. Nhiều claim đã trôi lệch vì đoán thay vì tra cứu.

## Lệnh

```powershell
# Build lai cong tu nguon bang compiler tu-host (CLI positional, KHONG co 'build')
dist\tkvc-tv.exe tools\vong.tkv        tools\vong.exe  main
.\tools\vong.exe                                  # -> IL_IDENTICAL

# Bien dich 1 file .tkv
dist\tkvc-tv.exe <nguon.tkv> <ra.exe> <entry>

# Gate
.\tools\testkit_gate.ps1                 # 119 test + 31 test am
.\tools\lint_rules_gate.ps1              # 8/8
.\dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run
.\build\dk.exe

# Tra cuu nhanh
powershell -File tools\build_tkv_guide.ps1
.\dist\bin\tkv_guide.exe rules
.\dist\bin\tkv_guide.exe find <ten>
.\dist\bin\tkv_guide.exe lint <file.tkv>
```

### Bẫy đường dẫn (quan trọng)

Compiler **crash `AccessViolationException`** khi biên dịch nguồn gộp ở một số
đường dẫn — không phải lỗi báo lỗi sạch. Nếu `vong.exe` báo
`LOI dich bang ... (ma -1073741819)`, **đổi tên thư mục cho ngắn hơn rồi chạy
lại**. Chưa xác định được nguyên nhân gốc.

## Quy ước viết `.tkv`

- Dòng đầu `# -*- coding: utf-8 -*-`.
- **Chú thích kiểu bắt buộc** trên mọi chữ ký hàm: `def f(x: "i32") -> "str":`
  (`"bool"` là bí danh của `"i32"`, chỉ dùng làm chú thích).
- Chuỗi: **chỉ dấu nháy kép**. f-string, `.format()`, chuỗi ba dấu nháy đều
  chạy — nhưng **không** gọi method trên biểu thức: `"a,b".split(",")` lỗi,
  phải gán ra biến trước.
- Biến cục bộ **không** chú thích kiểu; compiler suy từ vế phải.
- Module cấp: chỉ nhận hàm/class, **hằng số**, và biến có kiểu
  (`counter: "i32" = 0` — cần `global` để đọc/ghi từ hàm khác).
- Method phải **thụt lề trong thân class**. Dunder đặt ở cấp module sẽ **không
  được đăng ký** → so sánh rơi về so sánh tham chiếu.

Chi tiết: `docs/REFERENCE.md`.

## Tài liệu

| File | Nội dung |
|---|---|
| `docs/REFERENCE.md` | **Tham chiếu duy nhất.** §2 mọi builtin; §7 danh mục tên sinh tự động |
| `docs/ARCHITECTURE.md` | Cấu trúc + cách compiler tự dựng |
| `docs/HANDBOOK.vi.md` | Cẩm nang lập trình (tiếng Việt) |
| `docs/llms.txt` | Bản rút gọn dành cho LLM |
| `docs/CLAUDE.md` | File này |