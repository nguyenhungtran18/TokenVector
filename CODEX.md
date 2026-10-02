# TokenVector — dùng tool, đừng nhớ từ đầu

Nguồn duy nhất cho mọi câu hỏi về cú pháp/tính năng TokenVector.
Tool viết bằng chính TokenVector, nguồn: `tools/tkv_guide.tkv`.

```powershell
cd D:\TokenVector
powershell -File tools\build_tkv_guide.ps1      # chỉ cần 1 lần / sau khi tool đổi

dist\tkv_guide.exe rules                       # các luật THẬT sự gây lỗi
dist\tkv_guide.exe find sorted                 # cú pháp + tính năng thật
dist\tkv_guide.exe names str                   # builtin đã đăng ký
dist\tkv_guide.exe lint a.tkv                  # bẫy tĩnh (ít báo động giả)
dist\tkv_guide.exe verify a.tkv                # in đúng 2 lệnh build + chạy
```

Thêm `--file out.txt` vào cuối bất kỳ lệnh nào để nhận kết quả UTF-8.

**`verify` chỉ in lệnh chứ không tự build** (TokenVector chưa có `subprocess`).
Phải chạy **cả hai** lệnh nó in ra rồi đọc exit code + output. Đây là bước bắt
buộc trước khi nói "xong": build xanh **không** có nghĩa là chạy đúng — có bug
biên dịch thành công rồi trả về **giá trị sai**.

**Cổng nghiệm thu:** `powershell -File tools\testkit_gate.ps1` (117 test + 31
negative). Chạy trước khi commit thay đổi compiler.

Tài liệu đầy đủ (một file): `docs/REFERENCE.md`.
Cấu trúc repo + cách build: `CLAUDE.md` và `docs/ARCHITECTURE.md`.