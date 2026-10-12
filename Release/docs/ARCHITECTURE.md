# Kiến trúc TokenVector — bản Release

Tài liệu này mô tả **đúng** cấu trúc thư mục `Release/` này.

> **Lịch sử:** bản trước của file này mô tả một gói phát hành cũ (tháng 8/2026)
> và gọi `dist/tkvc.exe` là "native TokenVector compiler". Câu đó **sai** —
> `tkvc.exe` là compiler **Python** đóng băng bằng PyInstaller, không phải
> TokenVector. Bản phát hành này không chứa `tkvc.exe`.

## 0. Một câu tóm tắt

`Release/` là **bộ công cụ phát triển ngôn ngữ TokenVector**, thuần TokenVector:
compiler tự-host, nguồn của nó, bộ test và công cụ. Không có file `.py` nào.

## 1. Cây thư mục

| Thư mục | Số file | Vai trò |
|---|---:|---|
| `compiler_bootstrap/` | 132 | **Nguồn compiler tự-host.** 132 file TokenVector thuần |
| `compiler_src/` | 10 | `ds_gop.txt` (manifest 132 dòng) + `feature_can.txt` + 8 file seed lịch sử (**không ai biên dịch**) |
| `dist/` | 2 | `tkvc-tv.exe` (compiler) + `bin/tkv_guide.exe` |
| `tests/` | 162 | 119 test chấp nhận + 31 test âm + `tkv_test_lib.tkv` |
| `tests_suite/` | 445 | 154 case `.ca` + 203 mẫu vào |
| `tools/` | 19 | Cổng + gate (mục 4) |
| `examples/`, `projects/` | 27 | Chương trình TokenVector ví dụ / thực tế |
| `docs/` | 6 | Tài liệu (mục 5) |

## 2. Compiler tự-host

### Cách nó tự dựng lại

```
compiler_src/ds_gop.txt      manifest: 132 đường dẫn
        │
        ▼
tools/vong.tkv   gộp 132 file thành MỘT nguồn
        │
        ├─ g1 = dist/tkvc-tv.exe biên dịch nguồn đó
        └─ g2 = g1 biên dịch LẠI chính nó
                │
                └── g1.il == g2.il  →  IL_IDENTICAL
```

`IL_IDENTICAL` nghĩa là compiler sinh ra một bản giống hệt nó: đây là **điểm
cố định của thế hệ biên dịch**, không phải so sánh "bản cũ" với "bản mới".

> `IL KHAC NHAU` **không phải lỗi** — đó là *tiến hóa*. Thế hệ mới biên dịch
> khác thế hệ cũ, `vong` tự nâng cấp và yêu cầu chạy lại cho tới khi đồng.

### CLI

```
dist\tkvc-tv.exe <nguon.tkv> <ra.exe> <ten_entry>
```

Positional, không subcommand. `run()` trả `"i32"`/`"i64"` thì **giá trị đó là exit
code của process** (qua `Environment::Exit`); entry trả `"str"` hoặc tuple thì in ra.

## 3. Nguồn TokenVector là thật

- **132/132** file trong manifest là TokenVector, không có ngoại lệ.
- 2026-10-12 đã **xoá sạch** 320 dòng code CPython cùng cơ chế
  `if __tkv_chi_cpython__:` (shim `os`/`pathlib`/`subprocess`, hàm
  `extract_program`/`transpile_file`/...). Cơ chế đó chỉ tồn tại để một file
  `.tkv` chạy được trên hai thế giới; nay phía CPython đã ở repo khác.
- Còn `@__tkv_cpython_only__` (27 hàm) — đánh dấu hàm chỉ chạy dưới CPython.
- `dist/tkvc-tv.exe` là PE độc lập ~1,5 MB. Grep binary: **0** lần
  `python3` / `CPython` / `PyObject` / `site-packages`.

## 4. Cổng và gate

Chạy từ gốc `Release/`, **không cần Python, không cần repo khác**:

| Cổng | Lệnh | Kết quả |
|---|---|---|
| Gate chính | `.\tools\testkit_gate.ps1` | 119 test + 31 test âm |
| Vòng tự-host | `.\tools\vong.exe` | `IL_IDENTICAL` (132 file) |
| Quy tắc con | `.\tools\lint_rules_gate.ps1` | 8/8, 0 báo nhầm |
| Đăng ký hàm | `.\dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run` | 0 vi phạm |
| Danh mục tên | `.\dist\tkvc-tv.exe tools\gen_builtin_ref.tkv build\gr.exe run` | sinh §7 của `REFERENCE.md` |
| Quét container | `.\dist\tkvc-tv.exe tools\scan_container.tkv build\sc.exe run <thư mục>` | field container chưa gán |
| Phân cụm lỗi | `.\tools\testkit_cluster.ps1` | phân cụm lỗi của compiler |

Hướng dẫn cú pháp: `.\tools\build_tkv_guide.ps1` → `.\dist\bin\tkv_guide.exe`

### Không có trong bản này

| Cổng | Vì sao |
|---|---|
| `ext_smoke.ps1` | Biên dịch `D:\TokenVector.Inference` + `D:\TokenVector.Data` bằng compiler **Python** |
| `py2tkv_gate.ps1` | Fixture `.py` nằm ở repo `TokenVector.TestOracle` |
| `py2tkv_corpus.ps1` | Công đo chính file Python |

## 5. Tài liệu

| File | Nội dung |
|---|---|
| `REFERENCE.md` | **Tài liệu tham chiếu duy nhất.** §2 mọi builtin kèm cú pháp + khác biệt Python; §7 danh mục tên sinh tự động |
| `HANDBOOK.vi.md` | Cẩm nang lập trình (tiếng Việt) |
| `CLAUDE.md` | Quy tắc cho trợ giúp AI khi làm việc trong repo này |
| `llms.txt` | Cùng nội dung, dạng dành cho LLM |
| `ARCHITECTURE.md` | File này |

## 6. Điểm cần biết

**Compiler không ổn định theo đường dẫn.** `AccessViolationException` (không phải
lỗi báo lỗi sạch) khi biên dịch nguồn gộp ở một số đường dẫn. Đã tái lập,
**không đơn điệu theo độ dài** — `...Relea` (20) crash còn `...Releas` (21) chạy.
Nếu `vong.exe` báo `LOI dich bang ... (ma -1073741819)`, **đổi tên thư mục cho
ngắn hơn rồi chạy lại**. Lỗi chưa xác định nguyên nhân gốc.