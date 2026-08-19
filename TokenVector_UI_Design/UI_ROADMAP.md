# 🖥️ TOKENVECTOR UI FRAMEWORK ROADMAP v2.0
### Kế hoạch Phát triển Giao diện Chuyên nghiệp — Thuần TokenVector Native AOT

**Phiên bản**: v2.0 — 2026-08-09  
**Nguyên tắc cốt lõi**: TokenVector là ngôn ngữ độc lập hoàn toàn — **KHÔNG dính dáng Python, không dùng pip, không dùng venv**.  
**Mục tiêu**: Từ cú pháp `.tkv` → biên dịch AOT → file binary Native chạy được trên Windows / Linux / macOS.

---

## 🏗️ KIẾN TRÚC KỸ THUẬT HIỆN TẠI VÀ HƯỚNG MỞ RỘNG

```
                     ┌─────────────────────────────────────────────────────┐
                     │          TOKENVECTOR COMPILER PIPELINE              │
                     │                                                     │
  file.tkv           │  AST Parser   →   CIL Codegen   →   ilasm.exe      │
  (Mã nguồn)  ──────►│  (tkv_compile)    (il_codegen)      (.NET MSIL)    │─────► file.exe (Windows PE)
                     │                                                     │
                     │  VẤN ĐỀ HIỆN TẠI: ilasm.exe chỉ chạy trên Windows │
                     └─────────────────────────────────────────────────────┘

  MỤC TIÊU MỞ RỘNG:
  file.tkv ──► AST Parser ──► CIL Codegen ──► .NET 8 SDK (cross-platform) ──► ELF (Linux) / Mach-O (macOS)
  file.tkv ──► AST Parser ──► LLVM IR     ──► LLVM Backend               ──► Native binary mọi nền tảng
```

---

## 📊 TỔNG QUAN 4 GIAI ĐOẠN

| Giai Đoạn | Tên | Kết Quả Đạt Được | Thời Gian | Ưu Tiên |
|---|---|---|---|---|
| **Phase 1** | TUI Console Native | Terminal UI có màu ANSI, menu tương tác | 2-3 tuần | 🔴 Rất cao |
| **Phase 2** | Web UI Bridge Native | App giao diện HTML5 chạy trong WebView2 | 4-6 tuần | 🟠 Cao |
| **Phase 3** | Cross-Platform Compiler | `tkvc` chạy được trên Linux & macOS | 6-10 tuần | 🟡 Trung bình |
| **Phase 4** | LLVM Native Backend | Biên dịch ra ELF/Mach-O không cần .NET | 12-20 tuần | 🟢 Dài hạn |

---

## 🚀 PHASE 1: TERMINAL UI (TUI) — Thuần CIL/OS Call
> **Làm ngay được — Viết module `.tkv` gọi trực tiếp ANSI Escape Code qua Console API**

**Mục tiêu**: Tạo giao diện dòng lệnh có màu, menu cuộn, progress bar bằng mã `.tkv` thuần túy.

### Cơ chế kỹ thuật:
- TokenVector gọi trực tiếp `System.Console` của .NET CIL để xuất ký tự ANSI ESC `\x1b[` điều khiển màu sắc và cursor.
- **Không cần thư viện ngoài, không cần hệ điều hành phụ trợ.**

### Module cần xây dựng vào `stdlib/`:
| Module | File | Chức năng |
|---|---|---|
| `tkv_console` | `stdlib/tkv_console.tkv` | `print_color()`, `clear()`, `cursor_move(x, y)` |
| `tkv_menu` | `stdlib/tkv_menu.tkv` | Menu cuộn lên/xuống bằng phím mũi tên |
| `tkv_progress` | `stdlib/tkv_progress.tkv` | Thanh tiến trình `[████░░░░] 60%` |
| `tkv_table` | `stdlib/tkv_table.tkv` | In bảng dữ liệu có viền ASCII/Unicode |

### Code đích sau Phase 1:
```tkv
# -*- coding: utf-8 -*-
import tkv_console
import tkv_menu
import tkv_table

def main() -> "i32":
    tkv_console.clear()
    tkv_console.print_color("=== TOKENVECTOR DASHBOARD ===", "cyan")
    choice = tkv_menu.select(["Compile Project", "Run Tests", "Deploy", "Exit"])
    tkv_console.print_color("Selected: " + choice, "green")
    return 1
```

### Danh sách Task:
- [ ] **TKV-UI-001**: Viết `stdlib/tkv_console.tkv` — gọi `System.Console.Write` với ANSI ESC codes
- [ ] **TKV-UI-002**: Viết `stdlib/tkv_menu.tkv` — đọc phím mũi tên qua `System.Console.ReadKey()`
- [ ] **TKV-UI-003**: Viết `stdlib/tkv_progress.tkv` — cập nhật thanh tiến trình in-place
- [ ] **TKV-UI-004**: Viết `stdlib/tkv_table.tkv` — in bảng có viền Unicode box-drawing chars
- [ ] **TKV-UI-005**: Test E2E tổng hợp toàn bộ module trên Windows Terminal

**Thời gian**: 2-3 tuần | **Độ khó**: ⭐⭐

---

## 🌐 PHASE 2: WEB UI BRIDGE — TokenVector + WebView2
> **Chiến lược nhất hiện tại — Không cần xây GUI Engine từ đầu**

**Mục tiêu**: TokenVector làm Backend AOT tốc độ cao, giao diện HTML5/CSS3 nhúng trong WebView2.

### Cơ chế kỹ thuật:
- TokenVector gọi `System.Net.HttpListener` qua CIL FFI để tạo HTTP Server nội bộ.
- Nhúng `Microsoft.Web.WebView2` vào cửa sổ WinForms để hiển thị trang web `localhost`.
- Hai chiều giao tiếp JSON qua `postMessage` / REST API.

### Kiến trúc:
```
┌─────────────────────────┐        JSON/REST        ┌──────────────────────────┐
│  TokenVector .exe        │ ◄──────────────────────► │  WebView2 (HTML5/CSS3)   │
│  (Backend AOT ~35KB)     │                          │  (Giao diện đẹp, đa dạng)│
│                          │                          │                          │
│  - Xử lý logic nghiệp vụ │                          │  - CSS Glassmorphism     │
│  - Tính toán tốc độ cao  │                          │  - Animations & Charts   │
│  - Đọc/ghi file hệ thống │                          │  - Responsive Layout     │
└─────────────────────────┘                          └──────────────────────────┘
```

### Module cần xây dựng:
| Module | File | Chức năng |
|---|---|---|
| `tkv_http` | `stdlib/tkv_http.tkv` | HTTP Server nội bộ, router GET/POST, JSON response |
| `tkv_webview` | `stdlib/tkv_webview.tkv` | Nhúng WebView2, mở cửa sổ Desktop với URL |
| `tkv_json` | `stdlib/tkv_json.tkv` | Serialize/Deserialize JSON thuần TokenVector |

### Code đích sau Phase 2:
```tkv
# -*- coding: utf-8 -*-
import tkv_http
import tkv_webview
import tkv_json

def handle_request(route: "str", body: "str") -> "str":
    if route == "/api/info":
        return tkv_json.encode("name", "TokenVector App", "version", "2026.1.0")
    return tkv_json.encode("error", "not found")

def main() -> "i32":
    tkv_http.serve(port=8080, handler=handle_request)
    tkv_webview.open("http://localhost:8080", title="TokenVector Desktop App", w=1280, h=800)
    return 1
```

### Danh sách Task:
- [ ] **TKV-UI-006**: Viết `stdlib/tkv_http.tkv` — `System.Net.HttpListener` qua CIL P/Invoke
- [ ] **TKV-UI-007**: Viết `stdlib/tkv_webview.tkv` — Microsoft WebView2 COM Interop qua CIL
- [ ] **TKV-UI-008**: Viết `stdlib/tkv_json.tkv` — JSON encoder/decoder không phụ thuộc ngoài
- [ ] **TKV-UI-009**: Tạo bộ HTML Template khởi đầu (Dark Dashboard, DataTable, Settings Page)
- [ ] **TKV-UI-010**: Test E2E ứng dụng quản lý dữ liệu đầy đủ

**Thời gian**: 4-6 tuần | **Độ khó**: ⭐⭐⭐

---

## 🔀 PHASE 3: CROSS-PLATFORM COMPILER — tkvc chạy được trên Linux & macOS
> **Đây là bước then chốt để TokenVector thực sự độc lập với Windows**

**Mục tiêu**: Biên dịch được file `.tkv` ngay trên Linux và macOS mà không cần Windows hay Wine.

### Vấn đề cốt lõi hiện tại:
```
HIỆN TẠI:   file.tkv ──► tkvc.exe (Windows only) ──► ilasm.exe (Windows only) ──► file.exe (Windows PE)
MỤC TIÊU:   file.tkv ──► tkvc     (Cross-platform) ──► .NET 8 SDK ilasm        ──► ELF (Linux) / Mach-O (macOS)
```

### 2 Hướng tiếp cận kỹ thuật:

#### Hướng A: Dùng .NET 8 SDK Cross-Platform (Nhanh hơn, 6-8 tuần)
- Viết lại phần gọi `ilasm.exe` trong trình biên dịch để thay bằng `dotnet publish --self-contained` của .NET 8 SDK.
- .NET 8 SDK có sẵn trên Linux và macOS — chạy được mà không cần Windows.
- Output: File `.dll` hoặc self-contained executable cho từng nền tảng.

#### Hướng B: Tự phát sinh mã máy (Khó hơn, 15-20 tuần)
- Thêm backend phát sinh mã assembly x86-64 trực tiếp trong `il_codegen.tkv`.
- Dùng trình liên kết `ld` (Linux) / `lld` (macOS) để tạo binary ELF/Mach-O.
- Hoàn toàn độc lập với .NET runtime.

### Danh sách Task (Hướng A — ưu tiên):
- [ ] **TKV-CP-001**: Thay `ilasm.exe` bằng `dotnet ilasm` trong `tokenvector_compile.tkv`
- [ ] **TKV-CP-002**: Thêm flag `tkvc build file.tkv --target linux-x64`
- [ ] **TKV-CP-003**: Thêm flag `tkvc build file.tkv --target macos-arm64`
- [ ] **TKV-CP-004**: Đóng gói `tkvc` thành self-contained binary cho từng nền tảng
- [ ] **TKV-CP-005**: Thiết lập GitHub Actions CI test tự động trên Ubuntu 22.04 + macOS ARM

**Thời gian**: 6-10 tuần | **Độ khó**: ⭐⭐⭐⭐

---

## ⚡ PHASE 4: LLVM NATIVE BACKEND — Biên dịch ra mã máy thực sự
> **Dài hạn — TokenVector phát sinh machine code thực sự, không phụ thuộc .NET**

**Mục tiêu**: TokenVector trở thành trình biên dịch phát sinh mã máy x86-64/ARM64 thực sự, như GCC hay Clang.

### Kiến trúc mới:
```
file.tkv
   │
   ▼
AST Parser (tkv_compile.tkv)
   │
   ▼
IR Generator — phát sinh LLVM IR (.ll file)  ◄── BƯỚC MỚI CẦN THÊM VÀO il_codegen.tkv
   │
   ▼
LLVM Backend (llc / lld)
   │
   ├──► x86-64 ELF   (Linux)
   ├──► x86-64 PE    (Windows)
   └──► ARM64 Mach-O (macOS Apple Silicon)
```

### Lợi ích khi hoàn thành:
- **File binary siêu nhỏ**: Không còn phụ thuộc .NET CLR — file `.exe` có thể nhỏ hơn cả hiện tại.
- **Tốc độ tối đa**: LLVM tối ưu hóa mã máy ở mức tương đương C++.
- **Đa kiến trúc**: x86-64, ARM64, RISC-V, WebAssembly.

### Danh sách Task:
- [ ] **TKV-LLVM-001**: Nghiên cứu và thiết kế LLVM IR spec cho kiểu dữ liệu TokenVector (`i32`, `f64`, `str`)
- [ ] **TKV-LLVM-002**: Viết `compiler/llvm_codegen.tkv` — phát sinh LLVM IR từ TokenVector AST
- [ ] **TKV-LLVM-003**: Thêm flag `tkvc build file.tkv --backend llvm`
- [ ] **TKV-LLVM-004**: Liên kết `llc` + `lld` để tạo ELF/Mach-O/PE
- [ ] **TKV-LLVM-005**: Kiểm thử hiệu năng so sánh CIL backend vs LLVM backend

**Thời gian**: 12-20 tuần | **Độ khó**: ⭐⭐⭐⭐⭐

---

## 📌 NGUYÊN TẮC THIẾT KẾ BẤT BIẾN

> **1. TokenVector KHÔNG phụ thuộc Python** — Không dùng `pip`, `venv`, `setuptools` hay bất kỳ runtime Python nào.

> **2. Mọi module stdlib phải được viết bằng `.tkv`** — Các thư viện chuẩn `tkv_console`, `tkv_http`, `tkv_gui` đều phải là file `.tkv` biên dịch được bằng `tkvc.exe`.

> **3. File output phải là binary độc lập** — Người dùng cuối không cần cài bất cứ thứ gì ngoài file `.exe` / ELF / Mach-O đầu ra.
