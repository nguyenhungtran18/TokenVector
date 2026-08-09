# Contributing to TokenVector (Open-Source & AI Agent Guide)

Cảm ơn bạn (và các AI Agents) đã quan tâm đến việc đóng góp cho dự án mã nguồn mở **TokenVector**.

---

## 🎯 NGUYÊN TẮC ĐÓNG GÓP (CONTRIBUTION PRINCIPLES)

1. **Bảo toàn Cú pháp Python tĩnh**:
   - Mọi tệp `.tkv` mới phải là mã Python hợp lệ 100% để có thể chạy đối chiếu dưới CPython.
2. **Nghiêm cấm commit File Tạm / Artifacts**:
   - Không commit các tệp `.exe`, `.il`, `__pycache__/`, tệp log tạm lên Git.
3. **Quy chuẩn Conventional Commits**:
   - Thông điệp commit tuân thủ dạng: `feat: ...`, `fix: ...`, `docs: ...`, `test: ...`.

---

## 🚀 HƯỚNG DẪN BIÊN DỊCH VÀ KIỂM THỬ

### 1. Biên dịch ứng dụng `.tkv` bằng `dist\tkvc.exe`:
```powershell
dist\tkvc.exe build examples\word_stats.tkv
```

### 2. Tự build lại trình biên dịch `tkvc.exe` (khi chỉnh sửa `compiler/`):
```powershell
powershell -File build_tkvc.ps1
```

### 3. Chạy bộ kiểm thử tự động:
```powershell
python test/run_tests.py
```
