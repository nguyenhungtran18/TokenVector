# TOKENVECTOR COMPILER PLATFORM - RELEASE BẢN QUYỀN

Chào mừng bạn đến với Bản phát hành Chính thức của Trình biên dịch & Ngôn ngữ Lập trình **TokenVector** (AOT Native CIL Compiler).

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT VÀ SỬ DỤNG NHANH (QUICKSTART GUIDE)

### 1. Yêu cầu Hệ thống (System Requirements)
- **Hệ điều hành**: Windows 10 / Windows 11 (x64) hoặc Linux / macOS với .NET Framework 4.0+ hoặc Mono.
- **Trình biên dịch ILASM**: Đã được tích hợp sẵn hoặc đi kèm trong hệ điều hành Windows (`ilasm.exe`).

### 2. Cấu hình Môi trường (Environment Setup)
1. Giải nén thư mục `release/` vào ổ đĩa.
2. Thêm đường dẫn `release/3.code/dist/` vào biến môi trường `PATH` để gọi lệnh `tkvc` từ bất kỳ đâu:
   ```cmd
   set PATH=%PATH%;C:\path\to\release\3.code\dist
   ```

### 3. Biên dịch & Chạy ứng dụng TokenVector đầu tiên
Tạo tệp `hello.tkv`:
```python
def run() -> "str":
    print("Hello TokenVector AOT Native Engine!")
    return "SUCCESS"
```

Biên dịch ra file `.exe` độc lập bằng `tkvc`:
```cmd
tkvc build hello.tkv --out hello.exe --entry run
```

Chạy chương trình:
```cmd
hello.exe
```

---

## 📂 CẤU TRÚC BỘ PHÁT HÀNH (RELEASE STRUCTURE)

- `1.media/`: Tài sản hình ảnh, sơ đồ kiến trúc và đa phương tiện.
- `2.UI/`: Mẫu giao diện và báo cáo hiệu năng interactive (`benchmark_results.html`).
- `3.code/`:
  - `dist/tkvc.exe`: File thực thi standalone của Trình biên dịch TokenVector.
  - `tkv_compile.py`: Nhân biên dịch Python/AST -> CIL Assembly.
  - `compiler/`: Thư viện xử lý tính năng CIL (`control_flow.py`, `int_type.py`, `generator_lazy.py`, `ffi_feature.py`, `stdlib_bcl.py`, `pycapi_shim.py`).
  - `docs/`: Sách hướng dẫn lập trình TokenVector (`SACH_HUONG_DAN_LAP_TRINH_TOKENVECTOR.md`) và Bảng so sánh kỹ thuật.
  - `test/verify/`: Bộ kiểm thử hồi quy 97 bài test quy chuẩn.

---

## 📄 BẢO HÀNH & BẢN QUYỀN
Hệ thống được thiết kế và bảo chứng bởi Antigravity AI Team.
