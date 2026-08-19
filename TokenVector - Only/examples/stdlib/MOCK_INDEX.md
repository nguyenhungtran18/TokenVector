# Module nào là THẬT, module nào là MOCK (cập nhật 2026-08-03)

Thư mục này có nhiều file tên nghe rất kêu ("AI Engine", "Zero-Copy",
"Autonomous Super Coder"). Bảng dưới nói thẳng cái nào chạy thật, cái nào
chỉ là khung rỗng — để không ai (kể cả Claude ở phiên sau) tưởng nhầm là
đã có sẵn năng lực đó.

## MOCK / PROTOTYPE — KHÔNG dùng cho việc thật

Mỗi file đều có khối nhãn `NHAN: MOCK / PROTOTYPE` ngay đầu file.

| File | Thực tế nó làm gì |
|---|---|
| `nuget_interop.tkv` | Nối chuỗi. Không tải gói NuGet nào. |
| `buffer.tkv` | Mã hoá kích thước vào 1 chuỗi. Không cấp phát, không zero-copy. |
| `code_optimizer.tkv` | 1 phép trừ + 1 phép cộng. Không đọc AST nào. |
| `dataset_ai.tkv` | 1 phép so sánh + 1 phép nhân chia. Không sinh dữ liệu. |
| `ai_neural.tkv` | MLP đồ chơi trên `i32`, "sigmoid" là hàm tuyến tính chặn 2 đầu. |
| `super_coder_agent.tkv` | Nối chuỗi + vòng lặp gọi `exec_str` (bản thân `exec.tkv` cũng là mock). |
| `tkv_repl.tkv` | 2 hàm nối chuỗi quanh `eval_str`. Không có vòng lặp REPL, không đọc stdin. (Bản thân `eval_str` **nay chạy thật** — xem dưới.) |
| `mock_access_pdf.tkv` | Nối chuỗi. Không mở Access, không đọc PDF. Tách ra từ `office_db_suite.tkv` ngày 2026-08-03. |
| `exec.tkv` | Chỉ gọi `eval_str` rồi trả 1. Không chạy được câu lệnh (`if`/`for`/`def`) từ chuỗi — bức tường kiến trúc, loại vĩnh viễn. Xem ROADMAP.md. |

## THẬT, đã kiểm chứng bằng đối chiếu ngoài

`hashlib.tkv`, `base64.tkv` (so từng ký tự với `hashlib`/`base64` của
CPython), `zipfile.tkv` (file .zip mở được bằng Python `zipfile`),
`os.tkv`, `shutil.tkv`, `datetime.tkv`, `collections.tkv`,
`csv.tkv` (RFC-4180, đối chiếu module `csv` của Python: dấu phẩy trong
ngoặc kép, `""` thoát, trường rỗng), `eval.tkv` (port
`System.Data.DataTable.Compute` — **hết mock từ 2026-08-03**),
`functools.tkv` (`reduce_i32` đối chiếu `functools.reduce`),
`http.tkv` (GET/POST/PUT/DELETE + Content-Type + header tuỳ ý, và
`*_full` đọc được **status code + header trả về** — xác nhận bằng HTTP
server thật chạy cục bộ, đọc lại đúng thứ server nhận được),
`http_server.tkv`, `office_db_suite.tkv` (file `.docx` tạo ra mở được thật).

Chạy kiểm chứng: `python test/verify/stdlib_regression_test.py`

## Giới hạn đã biết, chưa sửa

- `zip_extract` ném lỗi nếu file đã tồn tại trong thư mục giải nén
  (Python `extractall` ghi đè). Cố ý không sửa: sửa "đúng" ở đây nghĩa là
  tự xoá file của người dùng — việc phá huỷ dữ liệu, không làm âm thầm.
  Muốn ghi đè thì tự xoá trước.
- ~~`zip_create` ném lỗi nếu file `.zip` đích đã tồn tại~~ — **đã sửa
  2026-08-03**, nay ghi đè giống Python. Chính bộ test mới phát hiện ra.
- `buffer_size()` chỉ đọc lại con số từ chuỗi do `create_buffer()` tạo;
  truyền chuỗi khác định dạng sẽ ném lỗi ở `int()`.
- `json_dumps` thoát 7 ký tự phổ biến nhưng **chưa** đổi các ký tự điều
  khiển hiếm còn lại sang dạng `u`-4-chữ-số như `json.dumps`; chưa nhận
  container lồng nhau (list của list, dict có giá trị là dict).
- Thứ tự khoá trong JSON sinh từ dict theo thứ tự duyệt của
  `Dictionary<K,V>` — .NET **không cam kết** thứ tự này (Python dict thì
  có). Cần thứ tự ổn định thì tự sắp xếp trước.
- `round(x)` trả **f64**, Python trả **int** — `str(round(3.6))` ra
  `"4.0"` thay vì `"4"`. Cố ý chưa đổi: đổi sang `i32` sẽ làm
  `round(x*100)/100` biến thành **chia nguyên** — tức là thay một khác
  biệt hiển thị bằng một sai âm thầm. Cần số nguyên thì viết
  `int(round(x))`.
- `http_request` (`*_full`): 4 header hạn chế phổ biến (Content-Type,
  Accept, User-Agent, Referer) đã đi qua property riêng; các header hạn
  chế còn lại (Host, Connection, Content-Length, Range, Expect, Date…)
  vẫn ném `ArgumentException` nếu đặt.
