# compiler_tkv — compiler viết bằng TokenVector THẬT

Đây là phần compiler **không phải Python**. Mọi thứ còn lại trong repo
(`tkv_compile.tkv`, `compiler/*.tkv`) là Python mang đuôi `.tkv` — đọc
`CLAUDE.md` mục *"What the Compiler Actually Is"* trước khi đụng vào.

## Vì sao thư mục này tồn tại

Đích: `tkvc.exe` phải được viết bằng TokenVector, không còn `.py` nào. Ba rào
cản đã đo:

| # | Rào cản | Trạng thái |
|---|---|---|
| ① | Không khởi chạy được tiến trình khác (compiler cần gọi `ilasm.exe`) | ✅ **Đã gỡ** — xem dưới |
| ② | `ast.parse` của Python × 23 chỗ — phải tự viết lexer + parser | 🚧 **đang làm** — thư mục này |
| ③ | Vòng tròn bootstrap: cần một compiler để tạo ra compiler đầu tiên | ✅ đã chốt — compiler Python hiện tại làm bootstrap **một lần**, sản phẩm giao là compiler TokenVector thuần |

## ① Đã gỡ: TokenVector gọi được tiến trình ngoài

`tests/tkvc_step0_process_test.tkv` — **4/4 PASS**. Chứng minh một chương trình
TokenVector thuần có thể:

1. tìm `ilasm.exe`
2. khởi chạy nó, nhận **exit code** (`rc=0` / `rc=1`)
3. nhận được **báo lỗi thật** từ `ilasm` (nên compiler phát hiện được `.tkv` hỏng)
4. chạy thử `.exe` vừa sinh

Cách làm: P/Invoke `__tkv_extern_pinvoke__` + `system()` của `msvcrt`.

**Hai ngõ cụt đã thử, đừng thử lại:**

- `CreateProcessA` cần con trỏ tới `PROCESS_INFORMATION`; TokenVector chỉ truyền
  struct bằng kiểu `Ten*` và **chưa có toán tử lấy địa chỉ** → không dùng được.
  `system()` trả thẳng exit code nên không cần struct nào.
- `--target library` ra DLL, nhưng hàm của TokenVector là static method của một
  class, **không export P/Invoke** → `ctypes` không gọi được. Cơ chế export
  chưa tồn tại.

**Hai đặc tính của `system()`:**

- phải bọc `cmd.exe /S /C "..."` với dấu nháy **lồng hai đầu**, nếu không sẽ
  *"The filename, directory name, or volume label syntax is incorrect."*
- không tự ghi file log; muốn chạy im lặng phải tự thêm `>nul 2>nul`.

## ② Đang làm: lexer TokenVector

`lexer_lib.tkv` — tokenizer đầu tiên, viết bằng TokenVector thuần.

```powershell
powershell -File tools\compiler_tkv\run.ps1
# hoặc chi tiết:
python tools\compiler_tkv\probe_bridge.py       # cầu nối: 4/4
python tools\compiler_tkv\probe_many_files.py   # độ chính xác: 10/10
python tools\compiler_tkv\probe_real_file.py <file>
```

**Cầu nối:** TokenVector không có `subprocess`, nên Python **gọi** chương trình
TokenVector đã biên dịch (`lexer.exe <input> <output>`), chứ không nhúng được
IL vào cùng file. Mỗi bước chuyển thêm một phần compiler sang TokenVector đều đi
qua cầu nối này.

### Trạng thái: khớp 100% trên nguồn TokenVector thật

| Nội dung | Trạng thái |
|---|---|
| Định danh | ✅ |
| Số nguyên / thực, `0x` `0o` `0b`, gạch dưới | ✅ |
| Chuỗi `"..."` và docstring 3 dấu nháy (nhiều dòng) | ✅ |
| Chú thích `#` | ✅ |
| Toán tử 1 và 2 ký tự, gồm `->` và gán tăng `+=` | ✅ |

10/10 file khớp tuyệt đối với CPython, gồm `projects/tkvcalc.tkv` (5.670 token)
và `tools/tkv_guide.tkv` (2.198 token).

**Còn thiếu** (chưa test, chưa dùng trong nguồn hiện có): số thực dạng khoa
học `1e5` / `1.5e-3`. Kiểm chứng trước khi viết parser.

### File Python phải khác — và đó là đúng

`tkv.tkv`, `tkv_compile.tkv`, `compiler/*.tkv` dùng nháy đơn `'` và escape đầy
đủ — TokenVector **không** có. Lexer TokenVector không khớp chúng **là đúng**,
và chính sự lệch đó chứng minh lexer phân biệt được hai ngôn ngữ. Vì vậy
`probe_many_files.py` tách hai nhóm: nhóm TokenVector phải khớp, nhóm Python chỉ
để quan sát.

## Ba sai lầm của tôi trong lúc làm probe — đều ở *harness*, không phải lexer

Ghi lại vì lần sau sẽ lặp lại nếu không nhớ:

1. **Probe dùng exe cache** → sửa lexer xong vẫn thấy kết quả y hệt. Đã sửa
   thành luôn build lại (đúng bẫy `build_tkvc.ps1` phải xoá cache PyInstaller).
2. **Ghi token 1 dòng 1 cái** → token chứa xuống dòng bị `split('\n')` cắt vụn.
3. **Thay xuống dòng bằng ký tự escape** (`\` + `n`) → **nhập nhằng**: một chuỗi
   nguồn thật chứa đúng ký tự đó bị biến đổi, thành lỗi giả ở `projects/tour.tkv`.
   Cách đúng là `<độ dài>:<token>`.

Cả ba đều là lỗi của **cách đo**, không phải của lexer. Không có test thì sẽ
tưởng lexer sai.

## Thứ tự làm tiếp (đề xuất)

1. Kiểm chứng số khoa học `1e5` / `1.5e-3`.
2. **Chuyển `tokenize()` vào compiler Python** cho một hạn chế: đọc số nguyên và
   số thực. Đo chi phí thêm mỗi lần biên dịch.
3. Mở rộng dần sang biểu thức, rồi phát biểu, rồi cấu trúc lớp — mỗi bước giữ
   testkit 118/118 xanh.
4. Khi đã phủ hết: `build_tkvc.ps1` biên dịch các module này vào `tkvc.exe`, và
   thôi dùng `ast.parse`.
