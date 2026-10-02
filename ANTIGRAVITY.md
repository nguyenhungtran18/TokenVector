# TokenVector — dùng tool, đừng nhớ từ đầu

Nguồn duy nhất cho mọi câu hỏi về cú pháp/tính năng TokenVector:

```powershell
python 3.code\tools\tkv_guide.py rules            # các luật THẬT sự gây lỗi
python 3.code\tools\tkv_guide.py find sorted      # cú pháp + tính năng thật
python 3.code\tools\tkv_guide.py names str        # tên đã đăng ký
python 3.code\tools\tkv_guide.py lint a.tkv       # bẫy tĩnh (ít báo động giả)
python 3.code\tools\tkv_guide.py verify a.tkv     # lint + build + chạy
```

`verify` là **bước bắt buộc** trước khi nói "xong": build xanh **không** có
nghĩa là chạy đúng — có bug biên dịch thành công rồi trả về **giá trị sai**.

Tài liệu đầy đủ (một file): `3.code/docs/REFERENCE.md`.
Mã nguồn compiler và cách build: `CLAUDE.md`.
