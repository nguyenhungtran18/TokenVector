# Testkit — bộ kiểm thử CHUẨN cho TokenVector

**Mục đích**: chứng minh `tkvc.exe` biên dịch và **chạy đúng** các tính năng
ngôn ngữ. Đây là **cổng nghiệm thu** của dự án — mọi thay đổi compiler phải
làm nó xanh trước khi báo "xong".

## Chạy cổng (bắt buộc trước khi báo xong)

```powershell
cd D:\TokenVector\3.code
powershell -NoProfile -File tools\testkit_gate.ps1
```

Kết quả hiện tại: **117/117 PASS**, **31/31 negative** (các file trong
`negative/` phải **bị từ chối lúc biên dịch**). Gate ghi output ra TEMP nên
không rác repo, và **thoát với mã khác 0** nếu có bất kỳ lỗi nào.

## Các file trong thư mục này

| File | Vai trò |
|---|---|
| `*_test.tkv` (117 file) | Test của **chính compiler**. Mỗi file là 1 chương trình `.tkv` độc lập tự so kết quả với giá trị mong đợi. |
| `negative/*.tkv` (31 file) | Phải **bị từ chối lúc biên dịch** — bảo vệ các guard (sai kiểu, `iter` sai vị trí, `slice` âm, container chưa khởi tạo...). |
| `tkv_test_lib.tkv` | Thư viện dùng chung: `check()` (so 1 ca), `test_summary()` (in tổng kết **và trả mã thoát** chuẩn). Import qua `__tkv_import__ = "tkv_test_lib"`. |
| `example_lib.tkv` + `example_lib_test.tkv` | **Khuôn mẫu** — sao chép 2 file này khi bắt đầu viết thư viện `.tkv` mới. |

`__tkv_import__` **không** phải `import` của Python: nó chỉ là cách compiler
gộp thêm file `.tkv` vào cùng một assembly.

## Bốn ràng buộc cú pháp hay gặp (compiler sẽ báo lỗi rõ ràng)

1. **Local trong thân hàm không được annotate kiểu** — viết `x = 1`, không
   `x: "i32" = 1`. (Chỉ `g`/`d`/`list`/`func` mới được tường minh.)
2. **Cấp module không có biến** — chỉ `def`, `class`, hằng số và biến global
   có kiểu vô hướng (`counter: "i32" = 0`).
3. **Không `import re/json/os/...`** như Python — dùng thẳng builtin toàn cục
   (`re_search(...)`, `os_mkdir(...)`).
4. **Method chỉ gọi được trên biến**, và **method container là lệnh độc lập**
   (`xs.append(v)` một dòng; `y = xs.pop()` là lỗi biên dịch).

## Bắt lỗi sớm trước khi build

```powershell
cd D:\TokenVector\3.code
powershell -File tools\build_tkv_guide.ps1        # 1 lần / sau khi tool đổi
dist\tkv_guide.exe lint my_engine.tkv             # bắt lỗi biên dịch bỏ qua
dist\tkv_guide.exe rules                          # các ràng buộc hay cắn người viết
```

`lint` có **gate riêng** (`tools\lint_rules_gate.ps1`) chạy trên
`tools\lint_fixtures\{bad,ok}.tkv` — vì một luật lint không có test thì là luật
chưa viết.

## Bước bắt buộc: build **rồi chạy**

```powershell
dist\tkvc.exe build my_test.tkv --out %TEMP%\my_test.exe --entry run
& %TEMP%\my_test.exe        # exit 0 = PASS
```

Build xanh **không** có nghĩa là chạy đúng: đã có bug biên dịch thành công rồi
trả về **giá trị sai** mà không báo lỗi nào. `dist\tkv_guide.exe verify <file>`
in sẵn đúng 2 lệnh này.
