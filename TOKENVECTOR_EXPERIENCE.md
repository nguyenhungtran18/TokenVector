# Tổng Hợp Lỗi & Kinh Nghiệm Lập Trình Với TokenVector (tkvc)

Tài liệu này đúc kết toàn bộ các lỗi biên dịch thực tế và kinh nghiệm kỹ thuật rút ra trong quá trình phát triển dự án với ngôn ngữ **TokenVector Native (`.tkv`)** và trình biên dịch **`tkvc.exe`** ([`nguyenhungtran18/TokenVector`](https://github.com/nguyenhungtran18/TokenVector)).

---

## 1. Hạn Chế Logic Ở Module Level (Top-Level Scope)

### Lỗi thường gặp:
```text
[tkv] Loi: Chi ho tro dinh nghia ham/class-record top-level, HANG SO cap module (vd MAX = 10), (va '__tkv_import__') trong 1 file TokenVector; gap If o dong ...
```

### Nguyên nhân:
TokenVector biên dịch mã nguồn thẳng sang cấu trúc tĩnh của .NET Common Intermediate Language (CIL). Parser của TokenVector không hỗ trợ các lệnh thực thi tự do ở phạm vi ngoài hàm/class như trình thông dịch Python.

### Quy tắc khắc phục:
- **Tuyệt đối không sử dụng:** Khối `if __name__ == "__main__":` hoặc các câu lệnh chạy tự do ngoài hàm.
- **Phạm vi module chỉ được chứa:**
  - Import module: `__tkv_import__ = "module_name"`
  - Khai báo Assembly ngoại vi: `__tkv_extern_assembly__ = ["System.Drawing", "System.Windows.Forms"]`
  - Hằng số cấp module (tên biến viết hoa toàn bộ): `BUFFER_SIZE = 65536`

  - Định nghĩa hàm: `def function_name(...) -> "...":`
  - Định nghĩa lớp/record: `class RecordName:`
- **Điểm vào (Entry Point):** Được chỉ định thông qua tham số CLI của compiler:
  ```cmd
  tkvc build src/cli_runner.tkv --entry main --out bin/app.exe
  ```

---

## 2. Quy Chuẩn Định Nghĩa Class (Record Struct Model)

### Lỗi thường gặp:
```text
[tkv] Loi: class 'PosixRuntimeBridge': record khong co field nao
SyntaxError: il_codegen: record 'TransferMetricsCalculator' can 2 tham so (alpha, smoothed_speed), gap 0
```

### Nguyên nhân:
Trong TokenVector, từ khóa `class` thực chất biểu diễn một **CIL Typed Record / Struct**. Trình sinh mã (`il_codegen`) yêu cầu:
1. Mỗi record bắt buộc phải khai báo ít nhất một trường dữ liệu (field) có định kiểu rõ ràng ở đầu class.
2. Trình biên dịch tự động sinh ra một **Positional Constructor** nhận đúng và đủ tất cả các trường theo thứ tự khai báo.

### Quy tắc khắc phục:
```TokenVector
# 1. Khai báo đúng chuẩn:
class TransferMetricsCalculator:
    alpha: "f64"
    smoothed_speed: "f64"

    def record_transfer(self, delta: "i64") -> "f64":
        return self.smoothed_speed

# 2. Khởi tạo instance (bắt buộc truyền đủ tham số):
calc = TransferMetricsCalculator(0.2, 0.0)
```

---

## 3. Hệ Thống Kiểu Vô Hướng (Unboxed Scalar Types)

### Lỗi thường gặp:
```text
[tkv] Loi: class '...' field '...': dtype 'bool' khong hop le (vo huong: ['f32', 'f64', 'i32', 'i64', 'int', 'str']...)
```

### Nguyên nhân:
Hệ thống kiểu của TokenVector tập trung vào hiệu năng cao không cấp phát heap (Zero heap boxing). Kiểu `bool` không nằm trong danh mục kiểu vô hướng hỗ trợ mà được ánh xạ qua số nguyên 32-bit.

### Bảng kiểu vô hướng hợp lệ:
| Kiểu DSL | Kiểu .NET CIL Tương Ứng | Miền Giá Trị / Ý Nghĩa |
| :--- | :--- | :--- |
| `"i32"` | `int32` | Số nguyên 32-bit (dùng thay thế cho cả logic `bool`: `1` = True, `0` = False). |
| `"i64"` | `int64` | Số nguyên 64-bit cho kích thước file, offset byte lớn. |
| `"int"` | `TkvInt` | Số nguyên lớn (BigInteger). |
| `"f32"` | `float32` | Số thực đơn 32-bit. |
| `"f64"` | `float64` | Số thực kép 64-bit cho tính toán tốc độ mạng, thời gian. |
| `"str"` | `string` | Chuỗi ký tự UTF-8 bất biến. |

---

## 4. Yêu Cầu Về Hàm Top-Level Và Giá Trị Trả Về

### Lỗi thường gặp:
```text
[tkv] Loi: File khong co ham top-level nao co annotation kieu DSL
SyntaxError: il_codegen: khong dich duoc dong: 'return'
```

### Nguyên nhân:
- `tkvc.exe` yêu cầu mỗi tệp `.tkv` phải chứa ít nhất một hàm ở phạm vi ngoài cùng (top-level) có chú thích kiểu trả về để neo giữ bảng phương thức CIL.
- Trong các hàm có định kiểu, lệnh `return` trần (không có giá trị) bị coi là cú pháp không hợp lệ.

### Quy tắc khắc phục:
- Luôn đảm bảo mỗi file có hàm top-level:
  ```TokenVector
  def init_module() -> "i32":
      return 1
  ```
- Luôn trả về giá trị khớp với kiểu dữ liệu đã khai báo:
  - Kiểu `"i32"` / `"i64"`: `return 0`
  - Kiểu `"str"`: `return ""`
  - Kiểu `"f64"`: `return 0.0`

---

## 5. Cơ Chế Tìm Kiếm & Phân Giải Import (`__tkv_import__`)

### Lỗi thường gặp:
```text
[tkv] Loi: file '...': import module 'core_engine' khong tim thay trong thu muc hien tai hoac site-packages
```

### Nguyên nhân:
`tkvc.exe` tìm kiếm các tệp `.tkv` được import tương đối dựa trên **Current Working Directory (CWD)** tại thời điểm gọi lệnh shell, thay vì dựa theo thư mục chứa file nguồn.

### Quy tắc khắc phục:
Khi biên dịch các module phụ thuộc lẫn nhau nằm trong thư mục con (ví dụ `src/`):
```cmd
:: Di chuyển vào thư mục chứa module trước khi gọi build
cd src
..\tkvc.exe build cli_runner.tkv --entry main --out ..\bin\tv-downloader-cli.exe
cd ..
```

---

## 6. Tạo Thư Mục Đầu Ra Trước Khi Build

### Lỗi thường gặp:
```text
FileNotFoundError: [Errno 2] No such file or directory: 'bin\\output.il'
```

### Nguyên nhân:
Trong pipeline nội bộ của `tkvc.exe`, compiler sẽ phát sinh tệp mã trung gian CIL (`.il`) tại cùng thư mục với file `.exe` chỉ định trong `--out`, sau đó mới gọi assembler `ilasm` để lắp ráp. Nếu thư mục đích (như `bin/`) chưa tồn tại sẵn trên hệ thống tệp, compiler sẽ dừng với lỗi `FileNotFoundError`.

### Quy tắc khắc phục:
Luôn tạo thư mục đầu ra trong kịch bản tự động hóa trước khi gọi `tkvc`:
```cmd
if not exist "bin" mkdir "bin"
```

---

## 7. Tính Toán Số Học Tránh Tràn Số & Lỗi Dấu Phẩy Động (`nan%`)

### Hiện tượng:
Biểu thức chia số thực lồng nhau: `percent = (float(bytes) / float(total)) * 100.0` đôi khi phát sinh mã opcode CIL tính toán ra kết quả `nan%` nếu các biến số nguyên `i64` quá lớn hoặc con trỏ bộ đệm chưa được đồng bộ tức thì.

### Quy tắc khắc phục:
Ưu tiên thực hiện phép nhân trước rồi chia nguyên số học trong các logic tính phần trăm tiến trình:
```TokenVector
# Cách tối ưu và ổn định tuyệt đối trên CIL:
pct = (bytes_received * 100) // stream_size
progress_str = "[download] " + str(pct) + "% complete"
```

---

## 8. Lỗi Restricted Headers Trong `http_request` (`System.ArgumentException`)

### Lỗi thường gặp:
```text
Unhandled Exception: System.ArgumentException: The 'Range' header must be modified using the appropriate property or method.
   at System.Net.WebHeaderCollection.ThrowOnRestrictedHeader(String headerName)
   at System.Net.WebHeaderCollection.Set(String name, String value)
```

### Nguyên nhân:
TokenVector ánh xạ `http_request` sang lớp `[System]System.Net.HttpWebRequest` của .NET BCL. Theo quy định bảo mật của .NET, một số HTTP Header bị coi là "Restricted" và không được phép gán trực tiếp qua tập hợp `Headers.Set(name, value)`:
- `Range`, `Host`, `Connection`, `Content-Length`, `Expect`, `Date`, `If-Modified-Since`, `Transfer-Encoding`, `Proxy-Connection`.

### Quy tắc khắc phục:
- Không truyền các header bị hạn chế trên vào dictionary `headers` khi gọi `http_request`.
- Chỉ truyền các header hợp lệ như `User-Agent`, `Accept`, `Authorization`, `X-Custom-Header`, v.v.

---

## 9. Khởi Tạo Dictionary (`dict`) Trong Mã Nguồn `.tkv`

### Lỗi thường gặp:
```text
SyntaxError: il_codegen: khong tokenize duoc bieu thuc tai '{"key": "val"}'
SyntaxError: il_codegen: ham 'dict' khong ton tai
```

### Nguyên nhân:
Parser và Tokenizer của TokenVector không hỗ trợ khai báo dictionary trực tiếp dạng `{k: v}` hoặc qua hàm gọi `dict()`.

### Quy tắc khắc phục:
- Khởi tạo một dictionary rỗng bằng dấu ngoặc nhọn `{}` trên một dòng độc lập:
```TokenVector
headers = {}
headers["User-Agent"] = "TokenVector-Agent"
headers["Accept"] = "*/*"
```

---

## 10. Cơ Chế Ánh Xạ Tham Số CLI Vào Hàm Entry Point (`main`)

### Lỗi thường gặp:
```text
Unhandled Exception: System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at TKVApp.Main(String[] args)
```

### Nguyên nhân:
Khi một hàm entry point khai báo tham số: `def main(url: "str") -> "i32":`, trình biên dịch `tkvc` tự động sinh mã CIL đọc trực tiếp `args[0]`. Nếu người dùng chạy file `.exe` trần (không truyền tham số trong dòng lệnh hoặc click đúp chuột), chỉ số mảng sẽ bị vượt quá biên.

### Quy tắc khắc phục:
- Đối với các binary CLI cho người dùng cuối có thể click đúp chuột hoặc chạy không cần tham số, định nghĩa entry point không tham số:
```TokenVector
def main() -> "i32":
    # Thiết lập giá trị mặc định hoặc đọc từ cấu hình
    target_url = "https://example.com/default.mp4"
    return 0
```

---

## 11. Bắt Buộc Sử Dụng UTF-8 Without BOM Cho File Nguồn `.tkv`

### Lỗi thường gặp:
```text
SyntaxError: invalid non-printable character U+FEFF
    \ufeff# -*- coding: utf-8 -*-
    ^
```

### Nguyên nhân:
Trình phân tích AST nội bộ của `tkvc` đọc file văn bản thuần. Nếu file được lưu với UTF-8 có Byte Order Mark (BOM: `0xEF, 0xBB, 0xBF`), ký tự vô hình `U+FEFF` sẽ nằm ở đầu file và làm hỏng token đầu tiên.

### Quy tắc khắc phục:
- Luôn cấu hình editor hoặc script sinh file với encoding `UTF-8 (without BOM)`.
- Trong PowerShell: sử dụng `[System.IO.File]::WriteAllText(path, content, [System.Text.UTF8Encoding]::new($false))` thay vì `Out-File -Encoding utf8`.

---

## 12. Phát Triển Windows GUI Với WinForms & Kiến Trúc Plugin (`il_features/`)

### Lỗi thường gặp:
```text
[tkv] Syntax baseline linter: tim thay 2 loi cu phap khong ho tro:
  dong 7: goi ham/bieu thuc doc lap o cap top-level
```

### Nguyên nhân:
- `__tkv_extern_assembly__` không phải là lời gọi hàm mà là một gán danh sách các chuỗi tên Assembly:
  `__tkv_extern_assembly__ = ["System.Windows.Forms", "System.Drawing"]`.
- Để xây dựng ứng dụng Windows GUI (Form, TextBox, Button, FolderBrowserDialog, Event Handler) với TokenVector, mã nguồn `.tkv` kết hợp với hệ thống plugin mở rộng trong thư mục `il_features/`.

### Quy tắc phát triển GUI:
1. **Plugin Mở Rộng (`il_features/win32_gui_window.tkv`):**
   - Đăng ký hàm builtin thông qua `register_expr_builtin('launch_downloader_gui', _push_launch_downloader_gui, 'i32')`.
   - Bơm lớp CIL Form (`DownloaderForm`) vào `ctx['extra_classes']`, bao gồm các control WinForms:
     - `txtUrl`: Nhập đường dẫn link video/audio stream.
     - `txtFolder`: Thư mục lưu đích.
     - `btnBrowse`: Nút duyệt thư mục qua `FolderBrowserDialog`.
     - `btnDownload`: Nút tải xuống, kích hoạt luồng tải qua CLI engine.
     - `lblStatus`: Hiển thị trạng thái tiến trình tải.
2. **Mã Nguồn Ứng Dụng (`src/gui_runner.tkv`):**
   > [!NOTE]
   > `System.Drawing` sử dụng `PublicKeyToken = b03f5f7f11d50a3a` (khác với token mặc định `b77a5c561934e089` của `mscorlib` / `System.Windows.Forms`), do đó cần khai báo dưới dạng tuple 3 phần tử `(name, pubkeytoken, version)`:
   ```TokenVector
   # -*- coding: utf-8 -*-
   __tkv_extern_assembly__ = [
       "System.Windows.Forms",
       ("System.Drawing", "B0 3F 5F 7F 11 D5 0A 3A", "4:0:0:0")
   ]

   def run() -> "i32":
       return launch_downloader_gui()
   ```
3. **Biên Dịch & Đóng Gói Thành Executable Native:**
   ```cmd
   tkvc build src/gui_runner.tkv --entry run --out bin/tv-downloader-gui.exe
   ```

---

## 13. Loại Bỏ Cửa Sổ Console Bằng `.subsystem 0x0002` (Zero-Console GUI) & Ẩn CMD Con

### Vấn đề:
Khi chạy ứng dụng WinForms được biên dịch từ `tkvc`, Windows mặc định mở kèm một cửa sổ console màu đen (CMD) phía sau, hoặc khi bấm nút Download, cửa sổ CMD con lại bung lên làm gián đoạn trải nghiệm người dùng.

### Nguyên nhân:
1. Trình biên dịch `ilasm.exe` mặc định gắn cờ subsystem `3` (`IMAGE_SUBSYSTEM_WINDOWS_CUI` - Console User Interface).
2. Khi gọi `Process::Start("cmd.exe", ...)`, nếu không cấu hình ẩn cửa sổ và tắt ShellExecute, hệ điều hành sẽ tự cấp phát một console mới.

### Quy tắc khắc phục:
1. **Chuyển subsystem của file `.exe` sang GUI (Subsystem 2):**
   Thêm chỉ thị `.subsystem 0x0002` vào phần đầu của các lớp ngoài (`ctx['extra_classes']`). ILASM sẽ tự động ghi cờ Subsystem = 2 (`IMAGE_SUBSYSTEM_WINDOWS_GUI`) vào PE header:
   ```cil
   .subsystem 0x0002
   .class public auto ansi beforefieldinit DownloaderForm extends [System.Windows.Forms]System.Windows.Forms.Form
   ```
2. **Chạy Process ngầm không tạo cửa sổ (`CreateNoWindow = true`):**
   Trong phương thức khởi chạy tiến trình CIL:
   ```cil
   ldloc.s psi
   ldc.i4.1 // WindowStyle.Hidden
   callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_WindowStyle(valuetype [System]System.Diagnostics.ProcessWindowStyle)

   ldloc.s psi
   ldc.i4.0 // UseShellExecute = false
   callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_UseShellExecute(bool)

   ldloc.s psi
   ldc.i4.1 // CreateNoWindow = true
   callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_CreateNoWindow(bool)
   ```

---

## 14. Tránh Lỗi Ký Tự (Mojibake) Trong Trình Hợp Dịch ILASM

### Vấn đề:
Ký tự đặc biệt (ví dụ icon mũi tên `⬇`, ký tự Unicode) trên nút bấm hoặc nhãn hiển thị bị biến thành ký tự lạ dạng `â¬‡` hoặc ô vuông rác.

### Nguyên nhân:
Mặc dù file mã nguồn lưu theo chuẩn `UTF-8 without BOM`, `ilasm.exe` của .NET Framework theo mặc định đọc file nguồn dưới dạng Windows ANSI code page (`Source file is ANSI`). Các ký tự Unicode đa byte bị ngắt thành nhiều ký tự ANSI riêng lẻ gây hiện tượng vỡ font (Mojibake).

### Quy tắc khắc phục:
- Đối với nhãn control giao diện (`Button`, `Label`), ưu tiên sử dụng text chuẩn ASCII (ví dụ `"DOWNLOAD"`, `"[ BROWSE ]"` thay vì kèm icon Unicode trực tiếp vào chuỗi `ldstr`).
- Nếu bắt buộc dùng ký tự Unicode đặc biệt trong IL, phải mã hóa qua mảng byte UTF-8 / UTF-16 hoặc nạp qua tài nguyên Resource.

---

## 15. Lỗi Độ Lệch Nhảy CIL Quá Lớn Cho Nhãn Chuyển Tiếp (`Offset ... is too large for 1 byte pcrel`)

### Lỗi thường gặp:
```text
tv-downloader-gui.il(1709) : error : Offset of forward reference label 'RET_VID_EMPTY' called from PC=8 is too large for 1 byte pcrel
tv-downloader-gui.il(1709) : error : Method 'ExtractVideoId' compilation failed.
```

### Nguyên nhân:
Trong tập lệnh Common Intermediate Language (CIL), các opcode nhảy có hai dạng:
1. **Dạng ngắn (Short Branch - có hậu tố `.s`):** Ví dụ `brtrue.s`, `brfalse.s`, `blt.s`, `bge.s`, `bne.un.s`, `br.s`. Dạng này chỉ dành 1 signed byte cho offset nhảy (khoảng cách từ `-128` đến `+127` bytes).
2. Khi nhảy tới một nhãn ở xa phía trước (Forward Reference Label) mà khối mã lệnh trung gian dài hơn 127 bytes, trình hợp dịch `ilasm.exe` không thể thu gọn địa chỉ trong 1 byte và sẽ báo lỗi biên dịch thất bại.

### Quy tắc khắc phục:
- Trong bất kỳ phương thức CIL nào có khối logic xử lý trung bình hoặc dài, **không sử dụng hậu tố `.s`** cho các bước nhảy tới nhãn xa. Luôn dùng lệnh nhảy 4-byte đầy đủ:
  ```cil
  // SAI (Dễ lỗi khi khối code phình to):
  brtrue.s RET_VID_EMPTY
  bne.un.s RET_VID_EMPTY
  bge.s RET_VID_EMPTY

  // ĐÚNG (An toàn tuyệt đối cho mọi khoảng cách offset):
  brtrue RET_VID_EMPTY
  bne.un RET_VID_EMPTY
  bge RET_VID_EMPTY
  ```

---

## 16. Định Danh Chính Xác Assembly Trong Lời Gọi BCL Ngoại Vi (`Cross-assembly global references are not supported`)

### Lỗi thường gặp:
```text
tv-downloader-gui.il(1731) : warning : Reference to undeclared extern assembly 'System.Net.WebHeaderCollection'. Attempting autodetect
tv-downloader-gui.il(1731) : error : Cross-assembly global references are not supported ('Add')
```

### Nguyên nhân:
Trong cú pháp khai báo kiểu của CIL, phần nằm trong cặp ngoặc vuông `[...]` đại diện cho **Tên Assembly (DLL)**, không phải là Namespace:
- Viết `[System.Net.WebHeaderCollection]::Add(...)` là sai, vì ILASM sẽ lầm tưởng có một thư viện mang tên `System.Net.WebHeaderCollection.dll`.
- Lớp `WebHeaderCollection` thực chất nằm bên trong assembly `System.dll`.

### Quy tắc khắc phục:
- Luôn tuân thủ quy tắc định danh đầy đủ: `[Tên_Assembly]Namespace.ClassName::MethodName`:
  ```cil
  // SAI:
  callvirt instance void [System.Net.WebHeaderCollection]::Add(string, string)

  // ĐÚNG:
  callvirt instance void [System]System.Net.WebHeaderCollection::Add(string, string)
  ```
- **Bảng tra cứu Assembly cho các kiểu .NET BCL phổ biến:**
  | Kiểu .NET | Assembly đại diện | Cú pháp CIL chuẩn |
  | :--- | :--- | :--- |
  | `System.String`, `System.Int32`, `System.IO.File` | `[mscorlib]` | `[mscorlib]System.IO.File::WriteAllText(...)` |
  | `System.Text.StringBuilder` | `[mscorlib]` | `[mscorlib]System.Text.StringBuilder::AppendLine(...)` |
  | `System.Net.WebClient` | `[System]` | `[System]System.Net.WebClient::UploadString(...)` |
  | `System.Net.WebHeaderCollection` | `[System]` | `[System]System.Net.WebHeaderCollection::Add(...)` |
  | `System.Net.WebUtility` | `[System]` | `[System]System.Net.WebUtility::HtmlDecode(...)` |
  | `System.Text.RegularExpressions.Regex` | `[System]` | `[System]System.Text.RegularExpressions.Regex::Replace(...)` |
  | `System.Diagnostics.Process` | `[System]` | `[System]System.Diagnostics.Process::Start(...)` |
  | `System.Windows.Forms.*` | `[System.Windows.Forms]` | `[System.Windows.Forms]System.Windows.Forms.Control::...` |
  | `System.Drawing.*` | `[System.Drawing]` | `[System.Drawing]System.Drawing.Point::.ctor(...)` |

---

## 17. Kỹ Thuật Trích Xuất YouTube Transcript & Subtitles Thuần CIL (Bypass PO Token Không Cần Python)

### Vấn đề:
YouTube Desktop Web hiện đã áp dụng cơ chế xác thực **Proof-of-Origin (PO Token)** nghiêm ngặt. Khi gửi request lấy `timedtext` từ web client mà không có session PO token, YouTube trả về phản hồi rỗng (0 bytes). Các công cụ truyền thống như `youtube-transcript-api` hoặc `haron/yt-dlp-transcript` đòi hỏi Python runtime cồng kềnh hoặc dễ bị block.

### Giải pháp kỹ thuật trong TokenVector:
1. **Giao tiếp qua YouTube InnerTube Endpoint với Client Context `ANDROID`:**
   - URL: `POST https://www.youtube.com/youtubei/v1/player`
   - User-Agent: `com.google.android.youtube/21.26.364 (Linux; U; Android 11)`
   - Payload JSON:
     ```json
     {
       "videoId": "VIDEO_ID",
       "contentCheckOk": true,
       "context": {
         "client": {
           "clientName": "ANDROID",
           "clientVersion": "21.26.364",
           "androidSdkVersion": 30,
           "osName": "Android",
           "osVersion": "11"
         }
       }
     }
     ```
   - Client context này hoàn toàn không yêu cầu PO token và trả về đầy đủ mảng `captionTracks` cùng URL trực tiếp `baseUrl`.
2. **Gửi nhận dữ liệu bằng `WebClient` gọn nhẹ:**
   - Dùng `WebClient::UploadString(url, postJson)` để gửi POST mà không cần qua tầng `HttpWebRequest` phức tạp.
   - Dùng `WebClient::DownloadString(baseUrl)` tải trực tiếp caption XML `timedtext format 3`.
3. **Phân tích cú pháp XML trực tiếp (In-Memory Stream Parsing):**
   - Lặp qua các thẻ `<p t="..." d="...">` bằng `IndexOf` và `Substring` siêu nhanh, trích xuất start time `tStart` và duration `tDur`.
   - Làm sạch các thẻ con (như `<s>word</s>`) bằng `Regex::Replace(text, "<[^>]+>", "")`.
   - Giải mã ký tự thực thể HTML qua `WebUtility::HtmlDecode`.
4. **Sinh đồng thời 2 tệp đầu ra:**
   - `[Title].srt`: Phụ đề SubRip có timestamp chuẩn `hh:mm:ss,fff`.
   - `[Title]_transcript.txt`: Toàn văn transcript liên tục, tối ưu hóa cho AI LLM tóm tắt nội dung.
5. **Hiệu quả:**
   - Toàn bộ thuật toán được biên dịch trực tiếp ra CIL nhị phân, chỉ tăng thêm ~5 KB cho file `.exe` (tổng ~21 KB) và thực thi hoàn tất chỉ trong khoảng **1 giây**!

---

## 18. Tối Ưu Hóa Nối Chuỗi & Định Dạng Thời Gian Trong CIL (Zero-Allocation Formatting)

### Vấn đề:
Khi format timestamp phụ đề (`00:01:23,450`), việc gọi hàm `String.Format("{0:00}:{1:00}:{2:00},{3:000}", h, m, s, milli)` yêu cầu 4 tham số. Trong CIL / .NET, overload nhận từ 4 tham số trở lên bắt buộc phải khởi tạo một mảng `object[]` (`newarr [mscorlib]System.Object`) và thực hiện thao tác đóng gói kiểu giá trị (`box [mscorlib]System.Int64`) 4 lần, gây tiêu hao RAM và tạo áp lực lên bộ gom rác (Garbage Collector - GC).

### Giải pháp tối ưu:
Gọi phương thức `ToString("00")` và `ToString("000")` trực tiếp từ biến địa phương (bằng lệnh nạp địa chỉ `ldloca.s`), sau đó tận dụng các overload `String.Concat` có sẵn:
```cil
ldloca.s 0 // h
ldstr "00"
call instance string [mscorlib]System.Int64::ToString(string)
ldstr ":"
ldloca.s 1 // m
ldstr "00"
call instance string [mscorlib]System.Int64::ToString(string)
call string [mscorlib]System.String::Concat(string, string, string) // "hh:mm"

ldstr ":"
ldloca.s 2 // s
ldstr "00"
call instance string [mscorlib]System.Int64::ToString(string)
ldstr ","
call string [mscorlib]System.String::Concat(string, string, string, string) // "hh:mm:ss,"

ldloca.s 3 // milli
ldstr "000"
call instance string [mscorlib]System.Int64::ToString(string)
call string [mscorlib]System.String::Concat(string, string) // "hh:mm:ss,fff"
```
**Lợi ích:**
- Hoàn toàn **không cấp phát mảng heap (`newarr`)**.
- Hoàn toàn **không boxing (`box`)**.
- Tốc độ xử lý hàng nghìn dòng phụ đề diễn ra tức thì trong vài mili-giây.

---

## 19. Định Nghĩa Ngữ Pháp (TextMate Grammar), Tự Động Thụt Lề & Khai Báo Ngôn Ngữ TokenVector Với GitHub Linguist

### Mục tiêu:
Để ngôn ngữ **TokenVector (`.tkv`)** được công nhận chính thức trên GitHub toàn cầu (hiển thị `● TokenVector 100%` trên Languages bar) và hỗ trợ trải nghiệm lập trình hoàn hảo (tự động thụt lề 4 khoảng trắng, tự đóng mở ngoặc, tô màu cú pháp đầy đủ từ khóa `def`, `class`, `__tkv_import__`, `"i32"`, `"f64"`), hệ thống ngôn ngữ cần có bộ quy chuẩn ngữ pháp chuẩn TextMate.

### Kiến trúc bộ nhận diện gồm 3 tệp cốt lõi:

#### 1. Quy tắc Thụt Lề & Cặp Ngoặc (`language-configuration.json`):
Quy định cho VS Code và GitHub Editor:
- Khi gõ dấu `:` kết thúc một khối lệnh (`def`, `class`, `if`, `for`, `while`,...), dòng tiếp theo tự động tăng thụt lề (indent) thêm 4 khoảng trắng.
- Khi gõ `elif`, `else`, `except`, dòng tự động giảm lề (dedent).
- Tự động đóng cặp ngoặc `()`, `[]`, `{}`, `""`, `''`.
```json
{
  "comments": {
    "lineComment": "#"
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"", "notIn": ["string"] },
    { "open": "'", "close": "'", "notIn": ["string", "comment"] }
  ],
  "surroundingPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["\"", "\""],
    ["'", "'"]
  ],
  "indentationRules": {
    "increaseIndentPattern": "^\\s*(def|class|if|elif|else|for|while|try|except|finally).*:\\s*$",
    "decreaseIndentPattern": "^\\s*(elif|else|except|finally)\\b.*:"
  }
}
```

#### 2. Ngữ Pháp Tô Màu Cú Pháp (`syntaxes/tokenvector.tmLanguage.json`):
Định nghĩa định danh scope `source.tokenvector` và regex bóc tách từ khóa:
- **Kiểu dữ liệu nguyên thủy TokenVector:** `"i32"`, `"i64"`, `"f32"`, `"f64"`, `"str"`, `"int"`, `bool`.
- **Từ khóa điều khiển:** `def`, `class`, `return`, `if`, `elif`, `else`, `for`, `while`, `import`, `raise`, `try`, `except`.
- **Biến hệ thống đặc biệt:** `__tkv_import__`, `__tkv_extern_assembly__`, `__tkv_entry__`, `self`.
- **Hàm & Lớp:** Khai báo hàm (`def name`), gọi hàm (`name()`), khai báo class (`class Name`).
- **Toán tử & Số:** Hỗ trợ toán tử số nguyên, chuỗi, gán kiểu `->`, số nguyên, số thực, hex `0x...`.

#### 3. Tệp Manifest Gói Tiện Ích (`package.json`):
```json
{
  "name": "tokenvector-syntax",
  "displayName": "TokenVector Language Support",
  "description": "Official syntax highlighting and language configuration for TokenVector (.tkv)",
  "version": "1.0.0",
  "publisher": "nguyenhungtran18",
  "engines": {
    "vscode": "^1.75.0"
  },
  "categories": [
    "Programming Languages"
  ],
  "contributes": {
    "languages": [
      {
        "id": "tokenvector",
        "aliases": ["TokenVector", "tokenvector", "tkv"],
        "extensions": [".tkv"],
        "configuration": "./language-configuration.json"
      }
    ],
    "grammars": [
      {
        "language": "tokenvector",
        "scopeName": "source.tokenvector",
        "path": "./syntaxes/tokenvector.tmLanguage.json"
      }
    ]
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/nguyenhungtran18/TokenVector"
  }
}
```

---

### Quy Trình Khai Báo Chính Thức Lên GitHub Linguist:

1. **Đưa bộ Grammar lên GitHub công khai:**
   Tạo repository `https://github.com/nguyenhungtran18/tokenvector-grammar` (hoặc đặt trong repo chính `TokenVector`).
2. **Fork repo `github/linguist`:**
   Mở tệp `lib/linguist/languages.yml` trên nhánh fork và thêm mục:
   ```yaml
   TokenVector:
     type: programming
     color: "#007ACC"
     extensions:
       - ".tkv"
     tm_scope: source.tokenvector
     ace_mode: text
     language_id: 849382019
   ```
   *(Lưu ý: `language_id` là một số nguyên dương ngẫu nhiên chưa bị trùng trong `languages.yml`)*.
3. **Thêm vào danh sách Submodule Grammar (`vendor/README.md`):**
   ```markdown
   - [tokenvector](https://github.com/nguyenhungtran18/tokenvector-grammar) (source.tokenvector)
   ```
4. **Tạo mẫu mã nguồn kiểm thử (`samples/TokenVector/example.tkv`):**
   Đưa một đoạn code mẫu viết bằng TokenVector để CI của Linguist chạy automated tests.
5. **Gửi Pull Request:**
   Bấm **Create Pull Request** lên nhánh `master` của `github/linguist`. Sau khi các maintainers của GitHub merge, TokenVector sẽ trở thành ngôn ngữ được nhận diện chính thức trên toàn hệ thống GitHub!

---

### Cách Cài Đặt Ngay Vào VS Code Cục Bộ Để Lập Trình:
Không cần đợi GitHub, bạn có thể kích hoạt tính năng tô màu và thụt lề tự động cho `.tkv` ngay trên máy tính của bạn:
1. Sao chép thư mục `tokenvector-grammar` vào thư mục extension của VS Code:
   - **Windows:** `%USERPROFILE%\.vscode\extensions\tokenvector-syntax`
   *(Đã được cài đặt và kích hoạt tự động trên hệ thống).*
2. Khởi động lại VS Code.
3. Mọi file có đuôi `.tkv` sẽ lập tức:
   - Hiển thị ngôn ngữ góc dưới bên phải là **TokenVector**.
   - Tự động thụt lề 4 khoảng trắng sau dấu `:`.
   - Tự động đóng ngoặc và tô màu cú pháp chuyên nghiệp!

---

## 20. Kiến Trúc Hoàn Thiện Trình Biên Dịch & Runtime TokenVector (`tkvc`)

Để đưa TokenVector từ một ngôn ngữ thử nghiệm trở thành ngôn ngữ lập trình độc lập, ổn định và được công nhận rộng rãi, dưới đây là các cải tiến kiến trúc cốt lõi cho tác giả hoàn thiện trình biên dịch `tkvc`:

### 1. Thuật Toán Xử Lý Thụt Lề (Indent/Dedent Lexer Engine)
Cú pháp TokenVector dựa trên khối lệnh thụt lề (Off-side rule tương tự Python). Để loại bỏ hoàn toàn các lỗi cú pháp thụt lề giả định, Lexer cần sử dụng mô hình ngăn xếp độ sâu (**Indentation Stack**):

```text
Khởi tạo: Stack = [0] (mức thụt lề gốc tại cột 0)

Với mỗi dòng mã nguồn mới (sau khi loại bỏ dòng trống và chú thích #):
1. Đếm số lượng khoảng trắng đầu dòng = col_depth.
2. So sánh col_depth với đỉnh ngăn xếp (current_depth = Stack.peek()):
   - Nếu col_depth > current_depth:
       Stack.push(col_depth)
       Phát sinh Token: INDENT (bắt đầu khối con)
   - Nếu col_depth < current_depth:
       Lặp lại cho đến khi Stack.peek() == col_depth:
           Stack.pop()
           Phát sinh Token: DEDENT (kết thúc khối con)
       Nếu Stack rỗng hoặc Stack.peek() != col_depth:
           Ném lỗi IndentationError: "unindent does not match any outer indentation level"
   - Nếu col_depth == current_depth:
       Không phát sinh token thụt lề, tiếp tục phân tích dòng.
3. Khi gặp EOF (End of File):
   Phát sinh DEDENT tương ứng với từng phần tử còn lại trong Stack (ngoại trừ 0).
```

### 2. Tự Động Giải Quyết Kích Thước Nhánh CIL (Automatic Branch Size Resolver)
Tránh lỗi sụp đổ trình dịch `Offset ... is too large for 1 byte pcrel` của `ilasm`:
- **Vấn đề:** Các lệnh nhảy ngắn như `brtrue.s`, `brfalse.s`, `blt.s`, `bge.s` chỉ chứa offset 1-byte có dấu (khoảng cách từ `-128` đến `+127` bytes). Khi hàm chứa logic xử lý HTTP hoặc giải mã chuỗi dài, khoảng cách giữa lệnh nhảy và nhãn vượt quá 127 bytes, gây lỗi biên dịch.
- **Giải pháp cho `il_codegen`:**
  1. **Phương pháp an toàn nhất:** Luôn phát sinh phiên bản lệnh 4-byte đầy đủ (`brtrue`, `brfalse`, `blt`, `bge`, `br`, `bne.un`). Chênh lệch kích thước binary chỉ là 3 bytes cho mỗi lệnh nhảy nhưng đảm bảo 100% không bao giờ gặp lỗi offset limit.
  2. **Phương pháp tối ưu hóa 2-Pass:**
     - Pass 1: Tính toán khoảng cách dự kiến giữa instruction và nhãn đích (Label).
     - Pass 2: Nếu `offset >= -128` và `offset <= 127`, phát sinh lệnh `.s`; ngược lại phát sinh lệnh 4-byte thông thường.

### 3. Hỗ Trợ Top-Level Statements (Scripting Mode)
Thay vì báo lỗi khi gặp câu lệnh ngoài hàm, trình biên dịch có thể tự động bao gói các biểu thức tự do vào một hàm khởi tạo module ẩn:
```TokenVector
# Mã nguồn người dùng viết tự do:
x = 10
y = 20
print(x + y)
```
Trình sinh mã CIL sẽ tự động chuyển đổi thành:
```il
.class public auto ansi abstract sealed beforefieldinit '$<Module>'
{
    .method private static void '$<Init>'() cil managed
    {
        .entrypoint
        .maxstack 2
        // Code của các câu lệnh top-level ở đây
        ret
    }
}
```
Điều này cho phép TokenVector vừa hoạt động như một ngôn ngữ kịch bản tiện lợi, vừa hoạt động như một ngôn ngữ biên dịch hướng cấu trúc chặt chẽ.

### 4. Mở Rộng Hệ Thống Kiểu Vô Hướng (Scalar Type Extension)
- **Hỗ trợ `bool` như First-Class Primitive:** Thay vì ép người dùng dùng `i32` (`1` / `0`), trình biên dịch nên thêm `bool` vào danh sách unboxed types hợp lệ, ánh xạ CIL sang `bool` (`int8`), tải bằng `ldc.i4.0` / `ldc.i4.1`.
- **Hỗ trợ kiểu hàm rỗng `void`:** Cho phép `def my_func() -> "void":` và hỗ trợ lệnh `return` trần không giá trị (CIL `ret`).
- **Default Field Values cho Class:** Cho phép `class MyClass: timeout: "i32" = 30` để trình biên dịch tự sinh parameterless constructor `.ctor()` với giá trị mặc định.

---

## 21. Checklist Đăng Ký TokenVector Lên GitHub Linguist Chính Thức

Để GitHub toàn cầu (github.com) tự động hiển thị thanh màu **TokenVector** và highlight cú pháp chuẩn:

1. **Chuẩn bị Repository Grammar:**
   - Bộ grammar đã được đóng gói hoàn chỉnh tại `tokenvector-grammar/` gồm:
     - `syntaxes/tokenvector.tmLanguage.json` (Grammar TextMate chuẩn)
     - `language-configuration.json` (Quy tắc thụt lề 4 khoảng trắng, auto-closing pairs)
     - `package.json` (Extension manifest)
     - `LICENSE` (Giấy phép MIT)
     - `README.md` (Giới thiệu ngôn ngữ và cú pháp)
   - Đẩy thư mục này lên GitHub công khai tại: `https://github.com/nguyenhungtran18/tokenvector-grammar`.

2. **Quy Định Tiếp Nhận Của GitHub Linguist (`github/linguist`):**
   - Repository mã nguồn: Phải có ít nhất 100 - 200 dòng mã nguồn `.tkv` thực tế trên các repo công khai thuộc GitHub (Hiện tại `nguyenhungtran18/TokenVector` và `nguyenhungtran18/TokenVector-Media-Downloader` đã vượt xa tiêu chí này).
   - Ngữ pháp phải có license mã nguồn mở hợp lệ (MIT).

3. **Thao Tác Gửi PR:**
   - Fork repo `github/linguist`.
   - Chạy lệnh thêm submodule:
     ```bash
     git submodule add https://github.com/nguyenhungtran18/tokenvector-grammar vendor/grammars/tokenvector
     ```
   - Thêm vào `lib/linguist/languages.yml`:
     ```yaml
     TokenVector:
       type: programming
       color: "#007ACC"
       extensions:
         - ".tkv"
       tm_scope: source.tokenvector
       ace_mode: text
       language_id: 849382019
     ```
   - Thêm tệp mã nguồn mẫu vào `samples/TokenVector/downloader.tkv`.
   - Chạy kiểm thử tự động của Linguist:
     ```bash
     bundle exec rake test
     ```
   - Tạo Pull Request lên `github/linguist`. Sau khi hoàn tất, bất kỳ ai đẩy file `.tkv` lên GitHub đều sẽ được nhận diện là **TokenVector** 100%.

---

## 22. Nhật Ký Triển Khai Thực Tế & Hồ Sơ Đệ Trình GitHub Linguist

Dưới đây là nhật ký toàn bộ các công việc và tạo phẩm kỹ thuật đã thực hiện thành công trên hệ thống để phục vụ việc hoàn thiện ngôn ngữ và công nhận chính thức TokenVector:

### 22.1. Đóng Gói Và Cài Đặt VS Code Extension Cho TokenVector
- **Đã tạo trọn bộ tiện ích mở rộng:** Thư mục `tokenvector-grammar/` gồm đầy đủ 5 tệp tiêu chuẩn VS Code:
  - `syntaxes/tokenvector.tmLanguage.json`: Phân rã token cho unboxed scalar types (`"i32"`, `"i64"`, `"f32"`, `"f64"`, `"str"`, `"int"`), từ khóa điều khiển (`def`, `class`, `if`, `while`, v.v.), biến đặc biệt (`__tkv_import__`, `__tkv_extern_assembly__`), số hex, toán tử và chuỗi.
  - `language-configuration.json`: Quy tắc thụt lề tự động (Indent/Dedent) 4 khoảng trắng sau dấu `:` và cơ chế tự đóng/mở ngoặc `{}`, `[]`, `()`, `""`, `''`.
  - `package.json`: Manifest khai báo ID ngôn ngữ `tokenvector`, scope `source.tokenvector`, file extension `.tkv`.
  - `LICENSE`: Giấy phép mã nguồn mở MIT chuẩn.
  - `README.md`: Hướng dẫn cú pháp và thông tin repository.
- **Cài đặt trực tiếp vào hệ thống:**
  Đã triển khai vào `%USERPROFILE%\.vscode\extensions\tokenvector-syntax`. Ngay bây giờ, bất kỳ cửa sổ VS Code nào mở file `.tkv` đều tự động nhận diện ngôn ngữ là **TokenVector**, kích hoạt tô màu cú pháp và tự động thụt lề 4 space.
- **Khởi tạo Git Repository độc lập:**
  Thư mục `tokenvector-grammar/` đã được `git init`, commit gốc `452da6c`, cấu hình sẵn remote `origin https://github.com/nguyenhungtran18/tokenvector-grammar.git`, sẵn sàng `git push` ngay khi tạo repo trên GitHub.

### 22.2. Thu Thập & Chứng Minh Dữ Liệu "Evidence of Usage"
- Maintainer của GitHub Linguist yêu cầu ngôn ngữ phải có ít nhất 100–200 dòng mã nguồn thực tế trên các repo công khai.
- **Kết quả kiểm chứng thực tế:**
  Repository `TokenVector-Media-Downloader` đã đạt **13.621 dòng mã nguồn `.tkv`** thực tế phân bổ trong 85 tệp mã nguồn (từ network BCL, parsing HTTP JSON, giải mã XML timedtext, tới giao diện Win32 GUI). Con số này đáp ứng và vượt xa tiêu chuẩn khắt khe nhất của GitHub Linguist.

### 22.3. Đóng Gói Bộ Hồ Sơ Đệ Trình Linguist (`linguist-submission/`)
Đã chuẩn bị đầy đủ bộ hồ sơ đóng gói sẵn tại `d:\yt-dlp\linguist-submission/`:
1. `TokenVector.yml`: Khối khai báo YAML chuẩn format `lib/linguist/languages.yml`:
   - Định danh `TokenVector`, màu `#007ACC`, scope `source.tokenvector`, `language_id: 849382019`.
2. `samples/TokenVector/downloader.tkv`: File mã nguồn mẫu 45 dòng code idiomatic TokenVector phục vụ cho test suite tự động của Linguist.
3. `PR_BODY.md`: Văn bản mô tả Pull Request bằng tiếng Anh chuẩn mực, viện dẫn đầy đủ bằng chứng 13.600+ dòng code, link compiler, link grammar và checklist yêu cầu.
4. `HD_DANG_KY_LINGUIST.md`: Tài liệu hướng dẫn 3 bước thao tác gửi PR lên GitHub.

### 22.4. Cấu Hình Nhận Diện Kho Lưu Trữ Hiện Tại (`.gitattributes`)
- Đã cấu hình `*.bat linguist-vendored=true` và `*.sh linguist-vendored=true` để loại bỏ 100% các script build rác khỏi thanh Languages bar của GitHub.
- Đã định danh `*.tkv linguist-detectable=true` và `*.tkv linguist-language=TokenVector` để GitHub nhận diện định dạng tệp tin.

---

## 23. Cam Kết Bảo Mật Mã Nguồn Cục Bộ
- File `TOKENVECTOR_EXPERIENCE.md` và mã nguồn trong `D:\TokenVector` được giữ nguyên vẹn trên máy cục bộ, nằm trong danh sách `.gitignore`, tuyệt đối không commit hay push ra ngoài môi trường public.

---

## 24. Tinh Chỉnh Giao Diện GUI: Chuẩn Hóa 100% Tiếng Anh & Nút Bấm "GET TRANSCRIPT"
- **Loại bỏ hoàn toàn tiếng Việt có dấu trong WinForms CIL:** Trình lắp ráp `ilasm` khi đọc lệnh `ldstr` chứa ký tự Unicode đa byte tiếng Việt nếu không thiết lập cờ mã hóa UTF-8 nhị phân sẽ tự động chuyển đổi sang mã ANSI cục bộ, dẫn đến lỗi biến dạng font trên giao diện (ví dụ `TẢI TRANSCRIPT` bị hiển thị thành `Táº¢I TRANSCRIPT`). Do đó, chuẩn hóa 100% tiếng Anh cho toàn bộ UI (nút bấm, dropdown format, thông báo trạng thái) là giải pháp tối ưu, chuyên nghiệp và loại bỏ hoàn toàn lỗi hiển thị trên mọi phiên bản Windows.
- **Loại bỏ URL mẫu:** Ô `txtUrl` không còn chứa sẵn đường link video thử nghiệm, mở lên là rỗng hoàn toàn để người dùng dán link mới thuận tiện.
- **Bố trí lại 3 nút bấm chuẩn hóa tiếng Anh:**
  - `btnDownload` (X=20, Width=175): Nút **`DOWNLOAD`** video/audio theo định dạng chọn.
  - `btnTranscript` (X=205, Width=190): Nút **`GET TRANSCRIPT`** độc lập, bấm 1 phát tải ngay cả `.srt` và `_transcript.txt`.
  - `btnStop` (X=405, Width=175): Nút **`STOP`** dừng tiến trình và dọn dẹp file tạm.
- **Tích hợp CIL Event Handler:** Phương thức `OnTranscriptClick` gọi trực tiếp `DownloadTranscriptAndSrt`, quản lý trạng thái enable/disable đồng bộ cho cả 3 nút bấm và thanh tiến trình `progressBar`.

---

## 25. Bẫy BCL CIL: Giới Hạn Tối Đa 4 Tham Số Của `System.String::Concat`
- **Hiện tượng lỗi:** Khi hoàn tất tải transcript và chuẩn bị hiện thông báo `MessageBox`, ứng dụng bị crash ném ngoại lệ:
  ```text
  System.MissingMethodException: Method not found:
  'System.String System.String.Concat(System.String, System.String, System.String, System.String, System.String)'
  ```
- **Nguyên nhân cốt lõi:**
  Trong .NET BCL (`mscorlib`), lớp `System.String` **chỉ hỗ trợ nạp chồng tối đa 4 tham số rời**:
  - `Concat(string, string)` (2 chuỗi)
  - `Concat(string, string, string)` (3 chuỗi)
  - `Concat(string, string, string, string)` (4 chuỗi)
  Hoàn toàn **không tồn tại** overload nhận 5 chuỗi rời rạc. Nếu muốn nối 5 chuỗi trở lên, BCL yêu cầu truyền mảng `Concat(string[])` hoặc phải xâu chuỗi (chaining) các lần gọi.
- **Giải pháp tối ưu không cấp phát mảng (Zero-allocation):**
  Xâu chuỗi hai lệnh `Concat` 3 tham số:
  ```il
  // Bước 1: Ghép 3 chuỗi đầu tiên
  ldstr "Header text\n\n- "
  ldloc.title
  ldstr ".srt\n- "
  call string [mscorlib]System.String::Concat(string, string, string)

  // Bước 2: Ghép kết quả trên với 2 chuỗi còn lại
  ldloc.title
  ldstr "_transcript.txt"
  call string [mscorlib]System.String::Concat(string, string, string)
  ```

---

## 26. Chuẩn Hóa Timeline Transcript Của YouTube: Định Dạng `[mm:ss]` & Khử Ngắt Dòng Thô
- **Vấn đề thực tế:** Khi trích xuất caption tracks XML (`fmt=srv3`), YouTube trả về các thẻ `<p t="..." d="...">` chứa nội dung lời thoại. Có 2 vấn đề lớn:
  1. Nếu xuất văn bản thuần không có timestamp, người dùng không thể đối chiếu dòng lời thoại với vị trí video trên timeline.
  2. Bên trong nội dung thẻ `<p>`, YouTube thường chèn ký tự ngắt dòng `\r\n` giữa các câu để canh lề subtitle. Khi nối chuỗi trực tiếp, các ký tự `\r\n` này làm câu thoại bị bẻ gãy thành nhiều dòng con rời rạc không mang timestamp ở đầu dòng.
- **Giải pháp Native CIL:**
  1. Viết hàm `FormatTimelineTime(int64 ms)` tính toán:
     - Nếu `h == 0`: Định dạng `[mm:ss]` (ví dụ `[00:21]`, `[01:05]`).
     - Nếu `h > 0`: Định dạng `[hh:mm:ss]` (ví dụ `[01:25:40]`).
  2. Làm sạch nội dung bằng cách thay thế `\r` thành rỗng và `\n` thành khoảng trắng trước khi đưa vào `txtSb.AppendLine`:
     ```il
     ldloc.txtSb
     ldloc.tStart
     call string DownloaderForm::FormatTimelineTime(int64)
     ldstr "  "
     ldloc.cleanedText
     ldstr "\r"
     ldstr ""
     callvirt instance string [mscorlib]System.String::Replace(string, string)
     ldstr "\n"
     ldstr " "
     callvirt instance string [mscorlib]System.String::Replace(string, string)
     call string [mscorlib]System.String::Concat(string, string, string)
     callvirt instance class [mscorlib]System.Text.StringBuilder::AppendLine(string)
     pop
     ```
  3. Kết quả mang lại: Mỗi dòng trong file `_transcript.txt` là một mốc timeline hoàn chỉnh, liên tục, khớp 100% với video timeline của YouTube.

---

## 27. Kiến Trúc Bộ Giải Mã & Tải Luồng HLS (.m3u8) Thuần Native CIL (~25 KB)
- **Bối cảnh & Thách thức:** Các trang web xem phim, anime, truyền hình trực tuyến thường không cung cấp file MP4 tĩnh trực tiếp mà phân phối qua giao thức HLS (HTTP Live Streaming) dưới dạng tệp tin danh sách phát `.m3u8` và hàng nghìn phân đoạn `.ts`.
- **Giải pháp Native TokenVector:**
  1. **Nhận diện thông minh (Smart Detection):** Tự động bắt mọi URL chứa `.m3u8` khi người dùng dán vào ô `txtUrl` và chuyển hướng thẳng sang phân hệ `DownloadHlsStream`.
  2. **Hỗ trợ cả Master Playlist & Media Playlist:** Tự động phát hiện chỉ thị `#EXT-X-STREAM-INF`, bóc tách luồng con tốt nhất và tải lại playlist phân đoạn.
  3. **Bộ chuyển đổi URL tương đối (Relative URL Resolver):** Sử dụng `System.Uri` để chuẩn hóa các đường dẫn tương đối (`/hls/seg1.ts` hoặc `seg1.ts`) thành URL tuyệt đối chuẩn xác.
  4. **Ghép nối nhị phân thời gian thực (Zero-dependency Binary Merging):** Lợi dụng bản chất liên tục của luồng MPEG-2 Transport Stream (`.ts`), ứng dụng ghi trực tiếp từng mảng byte phân đoạn vào `FileStream`, tự động sinh ra file video hoàn chỉnh mà không cần FFmpeg hay bất kỳ thư viện ngoài nào.
  5. **Quản lý tiến trình & Cancel an toàn:** Tự động tính toán phần trăm theo số lượng segment (`(i + 1) * 100 / totalSegments`), cho phép nhấn **STOP** để dừng tải và xóa file tạm `.part` tức thì.

---

## 28. Khắc Phục Lỗi InvalidProgramException Trong CLR JIT: Cân Bằng Ngăn Xếp (Stack Balance) & Định Danh Assembly Chuẩn Xác
- **Triệu chứng thực tế:** Khi gọi phương thức CIL vừa viết (ví dụ `DownloadHlsStream`), .NET CLR lập tức ném ngoại lệ:
  `System.InvalidProgramException: Common Language Runtime detected an invalid program.`
  tại dòng gọi method, ngay cả khi code chưa chạm tới dòng lệnh đầu tiên của method.
- **Nguyên nhân cốt lõi trong cơ chế JIT Verification của CLR:**
  Trước khi thực thi, CLR JIT Compiler tiến hành một lượt duyệt tĩnh (Verification Pass) trên mã CIL của phương thức:
  1. **Stack Imbalance / Underflow:** Mỗi lệnh trong CIL (như `call String::Concat(string, string)`) tiêu thụ một số lượng toán hạng cố định trên evaluation stack. Nếu số lượng lệnh `Concat` gọi nhiều hơn số toán hạng được `ld*` đưa vào stack, evaluation stack bị âm (Stack Underflow) -> CLR từ chối mã nguồn và ném `InvalidProgramException`.
  2. **Sai định danh Assembly (Assembly Qualification):** Khai báo sai tên assembly trong ngoặc vuông (ví dụ `[System.ComponentModel.Component]System.ComponentModel.Component::Dispose()` thay vì `[System]System.ComponentModel.Component::Dispose()`) khiến CLR không tìm thấy assembly tương ứng tại thời điểm JIT, dẫn đến lỗi biên dịch JIT.
  3. **Kiểu dữ liệu gán vào Local Slot không tương thích:** Gán một `valuetype` (như `DateTime`) vào slot kiểu số nguyên nguyên bản `int32` (`stloc.s 11`).
- **Bài học & Giải pháp khắc phục triệt để:**
  1. **Quy tắc ngăn xếp phân rã rõ ràng:** Khi nối nhiều chuỗi, luôn nhóm thành các cụm 3 tham số `call string [mscorlib]System.String::Concat(string, string, string)` có số lượng `ldstr` / `ldloc` đẩy vào tương ứng đúng 1:1, kiểm tra từng bước tính sâu của stack.
  2. **Định danh Assembly chuẩn:** Luôn kiểm tra kỹ namespace và tên assembly thực tế trong GAC của .NET Framework (`[mscorlib]`, `[System]`, `[System.Windows.Forms]`, `[System.Drawing]`).
  3. **Kỹ thuật kiểm thử JIT tĩnh tự động (Static JIT Verification Testing):**
     Sử dụng `RuntimeHelpers.PrepareMethod` qua PowerShell Reflection để bắt CLR JIT biên dịch trước toàn bộ các phương thức mà không cần mở GUI hay kích hoạt sự kiện:
     ```powershell
     $asm = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes('tv-downloader-gui.exe'))
     $formType = $asm.GetType('DownloaderForm')
     foreach ($m in $formType.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Instance,Static')) {
         [System.Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($m.MethodHandle)
     }
     ```
     Nếu có bất kỳ phương thức nào vi phạm stack depth, sai type hay thiếu assembly, lệnh trên sẽ lập tức chỉ điểm chính xác tên phương thức bị lỗi, giúp phát hiện lỗi JIT 100% trước khi phát hành binary.

---

## 29. Tự Động Bóc Tách Luồng HLS (Auto-Sniffer), Bộ Lọc Quảng Cáo 3 Lớp & Bẫy Giới Hạn CIL Short Branch (.s)
- **Vấn đề thực tế từ người dùng:**
  - Người dùng không muốn phải tự mở F12 Network để tìm link `.m3u8` thủ công khi xem phim trên các website.
  - Khi cào mã nguồn trang, thường gặp phải các clip video quảng cáo pre-roll / mid-roll của nhà mạng quảng cáo (thời lượng 5s, 15s) dẫn đến tải nhầm quảng cáo thay vì bộ phim chính.
- **Kiến trúc giải pháp Native CIL:**
  1. **Bộ cào & bóc tách đa tầng (Multi-tier Sniffer):**
     - Chuẩn hóa các chuỗi json-escaped `\/` thành `/` trước khi Regex.
     - Dùng Regex `https?://[^'\"<>\s]+\.m3u8[^\s'\"<>]*` để quét toàn bộ playlist trực tiếp.
     - Nếu không có, quét tiếp thẻ `<iframe src="...">` (tối đa 3 iframe player) để quét luồng nhúng.
  2. **Bộ lọc quảng cáo 3 lớp thông minh (3-Layer Anti-Ad Filter):**
     - *Lớp 1 (Blacklist):* Loại bỏ ngay các URL chứa từ khóa quảng cáo (`doubleclick`, `adnxs`, `popads`, `adservice`, `/ads/`, `preroll`, `midroll`, `vast`, `vpaid`).
     - *Lớp 2 (Deep Inspection):* Đọc nhanh số lượng phân đoạn của playlist. Bỏ qua tất cả các luồng có $\le 15$ phân đoạn (tương đương clip quảng cáo $< 60$ giây).
     - *Lớp 3 (Max Duration Heuristic):* Chọn luồng có số lượng phân đoạn lớn nhất trong tất cả các luồng tìm được.
- **Bẫy kỹ thuật CIL Assembler: Lỗi "Offset of forward reference label is too large for 1 byte pcrel":**
  - **Triệu chứng:** `ilasm.exe` báo lỗi:
    `error : Offset of forward reference label '...' called from PC=... is too large for 1 byte pcrel`
    khiến hàm biên dịch thất bại.
  - **Nguyên nhân:** Các lệnh rẽ nhánh dạng short `.s` (như `br.s`, `brtrue.s`, `bge.s`, `bgt.s`, `ble.s`) chỉ mã hóa độ dời (offset) trong phạm vi 1 byte có dấu (từ -128 đến +127 bytes). Khi hàm có logic phức tạp gồm nhiều câu lệnh rẽ nhánh và khối xử lý dài, khoảng cách tới nhãn vượt quá 127 bytes khiến `ilasm` không thể gói vào 1 byte.
  - **Quy tắc an toàn tuyệt đối:**
    Đối với các nhãn nhảy xa (như thoát vòng lặp, nhảy tới khối xử lý lỗi, nhảy tới hàm con), **luôn sử dụng lệnh rẽ nhánh chuẩn 4-byte** (`br`, `brtrue`, `brfalse`, `bge`, `bgt`, `ble`, `bne.un`), chỉ dùng `.s` khi nhảy qua 1-2 câu lệnh kế cận.

---

## 30. Thực Nghiệm Trình Bắt Gói Mạng Tự Động (Browser CDP Sniffer - tv-sniff.exe) & Đánh Giá Hiệu Quả Thực Tế
- **Bối cảnh & Thực nghiệm:**
  - Thiết kế và thử nghiệm công cụ `tv-sniff.exe` dựa trên Chrome DevTools Protocol (CDP) điều khiển Edge/Chrome qua WebSocket nhằm tự động phát hiện luồng `.m3u8` có kèm token động.
- **Kết luận thực nghiệm & Quyết định thu hồi:**
  - Đối với các website có cơ chế chống bot nâng cao (Anti-bot, Cloudflare Turnstile, yêu cầu nhấp chuột thật vào player đa tầng iframe chống gian lận), phương pháp tự động hóa headless/sniff CDP gặp hạn chế về độ ổn định, gây kéo dài thời gian chờ (timeout) và trải nghiệm người dùng không tối ưu.
  - **Quyết định kỹ thuật:** Loại bỏ hoàn toàn module `tv-sniff.exe` và các lệnh gọi liên quan khỏi `tv-downloader-gui.exe`, đưa ứng dụng trở về kiến trúc cốt lõi tinh gọn, ổn định và hướng dẫn người dùng dán link `.m3u8` trực tiếp khi gặp luồng bảo vệ phức tạp.

---

## 31. Khắc Phục Lỗi "(Not Responding)" Khi Nhấn Nút Browse... (Single-Threaded Apartment - STA Model Trong Windows Forms)
- **Triệu chứng:**
  - Trong `tv-downloader-gui.exe`, khi người dùng nhấn nút `Browse...` để chọn thư mục tải về, thanh tiêu đề ứng dụng chuyển sang trạng thái `(Not Responding)` và cửa sổ bị đơ hoàn toàn.
- **Nguyên nhân gốc rễ (Root Cause Analysis):**
  1. **ApartmentState MTA (Multi-Threaded Apartment):**
     - Khi `tkvc.exe` tạo entrypoint `Main` mặc định cho ứng dụng, luồng khởi chạy không có thuộc tính `[System.STAThreadAttribute]`.
     - Theo đặc tả kiến trúc .NET Framework & Windows OS, `FolderBrowserDialog` là một Shell COM Dialog (dựa trên `SHBrowseForFolder` / `IFileDialog`). Khi được gọi trên luồng MTA, Windows Shell COM bị xung đột cơ chế đồng bộ (Synchronization Deadlock) khiến luồng GUI kẹt cứng vô hạn trong vòng lặp Shell message pump.
  2. **Thiếu liên kết Owner Window Handle:**
     - Gọi `FolderBrowserDialog::ShowDialog()` không tham số khiến hộp thoại không được gán vào `HWND` của form cha, gây lạc focus và làm hệ điều hành nhận diện nhầm form cha bị treo.
  3. **Rò rỉ tài nguyên COM (Resource Leak):**
     - `FolderBrowserDialog` không được gọi `Dispose()` sau khi hoàn tất phiên chọn thư mục.
- **Giải pháp kỹ thuật triệt để:**
  1. **Khởi chạy ứng dụng bằng Luồng STA Chuẩn (`DownloaderForm::StartGui`):**
     - Tạo phương thức khởi chạy tĩnh `StartGui()` trong CIL:
       ```cil
       .method public static hidebysig void StartGui() cil managed
       {
         .maxstack 2
         .locals init ([0] class [mscorlib]System.Threading.Thread V_th)
         ldnull
         ldftn void DownloaderForm::RunGuiInternal()
         newobj instance void [mscorlib]System.Threading.ThreadStart::.ctor(object, native int)
         newobj instance void [mscorlib]System.Threading.Thread::.ctor(class [mscorlib]System.Threading.ThreadStart)
         stloc.0
         ldloc.0
         ldc.i4.0 // ApartmentState.STA
         callvirt instance void [mscorlib]System.Threading.Thread::SetApartmentState(valuetype [mscorlib]System.Threading.ApartmentState)
         ldloc.0
         callvirt instance void [mscorlib]System.Threading.Thread::Start()
         ldloc.0
         callvirt instance void [mscorlib]System.Threading.Thread::Join()
         ret
       }
       ```
     - Đảm bảo 100% vòng lặp giao diện, Clipboard và mọi Shell Dialog đều chạy an toàn trên luồng STA.
  2. **Gán Chủ Sở Hữu Form Cho Dialog (`IWin32Window`):**
     - Đẩy `ldarg.0` (`this`) làm tham số khi gọi `ShowDialog`:
       `callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.CommonDialog::ShowDialog(class [System.Windows.Forms]System.Windows.Forms.IWin32Window)`
  3. **Giải Phóng Bộ Nhớ Đúng Chuẩn:**
     - Bổ sung lệnh gọi `callvirt instance void [System]System.ComponentModel.Component::Dispose()` tại nhãn dọn dẹp trước khi thoát phương thức.


