# Debug PDB thật — Design

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md` mục 10 (`#5 Debug`, nghiên cứu Qwen3/Groq
2026-08-11) đề xuất "Portable PDB + Source Link" để breakpoint thật trong
VS Code/Visual Studio, không cần `pdb` runtime. Kiểm tra thật (bắt buộc
theo nguyên tắc chép/convert) cho thấy: KHÔNG có gì để chép — cả 2 cây đều
KHÔNG có bất kỳ dòng `.line`/`SequencePoint`/`/debug` nào, và
`_strip_lines` (`compiler/il_codegen.py:2037`) hiện **bỏ hẳn số dòng gốc**
ngay khi parse — gap thật, thiết kế mới hoàn toàn.

**Phát hiện quan trọng (xác minh THẬT qua `ilasm.exe /debug`, không suy
đoán)**: chạy thử `ilasm.exe <file>.il /exe /debug /output:...` sinh ra 1
file `.pdb` có chữ ký byte đầu `"Microsoft C/C++ MSF 7.00"` — đây là
**Windows PDB cổ điển** (định dạng MSF), **KHÔNG PHẢI Portable PDB**
(Portable PDB bắt đầu bằng magic bytes `"BSJB"`). Điều này ĐÚNG và phù
hợp: `ilasm.exe` là công cụ của .NET Framework (mscorlib v4.0.30319,
không phải .NET Core/5+), .exe biên dịch ra chạy trên full .NET Framework
— Windows PDB cổ điển là định dạng chuẩn xác cho debugger native của
Visual Studio, KHÔNG cần Source Link (Source Link là cơ chế của hệ sinh
thái .NET Core/Portable PDB, không áp dụng ở đây). **Sửa lại phần "Portable
PDB + Source Link" trong checklist gốc — không chính xác cho toolchain
`ilasm.exe`/Framework của project này.**

## Mục tiêu

Build có cờ `--debug` (mặc định TẮT) sinh `.exe` + `.pdb` cho phép đặt
breakpoint TRÊN TỪNG DÒNG source `.tkv`/`.py` gốc, step qua trong Visual
Studio (debugger native đọc PDB cổ điển trực tiếp) — không cần `pdb`
runtime, không đổi hành vi build mặc định (không `--debug` → giống hệt
hiện tại, không `.line`/không PDB, không overhead).

## Kiến trúc

### 1. Giữ số dòng gốc qua parser

`_strip_lines(body_lines)` (`compiler/il_codegen.py:2037`) hiện trả về
`list[(indent, text)]` — đổi thành `list[(indent, text, line_no)]`
(`line_no` là số dòng 1-based TRONG FILE SOURCE GỐC, tính từ vị trí
`body_lines` bắt đầu — cần đối chiếu lại nơi gọi `_strip_lines` để biết
`body_lines` đã offset bao nhiêu so với đầu file, xem mục "Điểm cần xác
minh khi code" bên dưới).

`_parse_block` (dòng 2149) — MỖI lần tạo 1 `Stmt` dict mới (mọi kind:
`assign`/`if`/`for`/`return`/`nested_def`/...), gắn thêm 1 key
`'src_line'` lấy từ dòng gốc của statement đó. Đây là điểm sửa DUY NHẤT
trong parser — không cần sửa riêng từng nhánh parse theo kind.

### 2. Emit `.line` tại 1 điểm dispatch trung tâm (KHÔNG sửa 50 file `il_features/*.py`)

`_codegen_stmts` (vòng lặp trung tâm gọi `STMT_CODEGEN[stmt['kind']]` cho
mọi statement) — chèn `.line {stmt['src_line']} '{ctx["source_path"]}'`
vào `body` NGAY TRƯỚC khi gọi hàm codegen đã đăng ký của statement đó.
Đây là kiến trúc mấu chốt giúp tính năng khả thi mà KHÔNG cần sửa ~50 file
`il_features/*.py` — mọi hàm STMT_CODEGEN đã đăng ký (kể cả của record
method, nested def, async closure) đều đi QUA vòng lặp này, nên đều tự
động có `.line` đứng trước, không cần đụng vào logic bên trong từng hàm.

Giới hạn có ý thức: granularity ở mức STATEMENT (1 dòng = 1 `.line`),
KHÔNG phải sub-expression — khớp với cách Python/hầu hết ngôn ngữ block
1-statement-1-dòng vốn hoạt động (không đặt breakpoint giữa 1 biểu thức
được).

### 3. Truyền `source_path` xuống ctx

Đường dẫn file `.tkv`/`.py` gốc (đã có sẵn ở `tkv.py`'s
`Path(args.source)`) truyền xuyên suốt: `tkv.py` → `compile_tkv_cli`
(`tkv_compile.py`) → `gen_il_program` → `gen_il_function` → thêm vào dict
`ctx['source_path']` (dùng đường dẫn TUYỆT ĐỐI, escape dấu `\` đúng cú
pháp chuỗi IL — xem ví dụ `'C:\\\\tmp\\\\src.tkv'` đã xác nhận chạy đúng
qua probe thật).

### 4. Cờ `--debug`, mặc định TẮT

`tkv.py`'s `build` subcommand thêm `--debug` (action `store_true`,
default `False`). Threading xuống `compile_tkv_cli(..., debug=False)` →
khi `debug=True`: (a) `gen_il_function`/`_codegen_stmts` mới emit
`.line` (khi `debug=False`, hoàn toàn KHÔNG emit gì thêm — giống hệt
hành vi hiện tại, không overhead); (b) `assemble_il_to_exe`
(`tokenvector_compile.py`) nhận thêm tham số `debug: bool = False`, khi
`True` thêm `/debug` vào lệnh gọi `ilasm.exe` (bên cạnh `/exe`/`/output`
đã có) — sinh thêm `<out>.pdb` cạnh `.exe`.

## Phạm vi

- Hàm top-level, method record (kể cả method không async), async closure
  (`Invoke()` sinh bởi plan Concurrency vừa xong) — TẤT CẢ đi qua
  `_codegen_stmts`, đều có `.line` tự động.
- **Generator (`gen_il_generator_function`, `MoveNext()`)** — dùng đường
  codegen RIÊNG (không qua `_codegen_stmts` theo cùng cách — có gọi
  `_codegen_stmts` ở dòng 3796 nhưng kết quả `body_code` được nhúng LẠI
  vào 1 cấu trúc `switch`/state khác, cần kiểm tra riêng có tương thích
  hay không) — NGOÀI PHẠM VI lượt đầu này, ghi lại như gap đã biết, không
  chặn phần còn lại.
- Không làm Source Link (không cần thiết cho classic Windows PDB/Full
  Framework debugging, xem phần "Phát hiện quan trọng" ở trên).
- VS Code: cần cấu hình debug native (`cppvsdbg` hoặc tương đương attach
  process) để đọc PDB cổ điển — KHÔNG dùng được debug adapter C#/.NET Core
  mặc định của VS Code (đó là cho Portable PDB/.NET Core). Ghi rõ trong
  docs, không code thêm (cấu hình launch.json là việc của người dùng khi
  cần debug, ngoài phạm vi compiler).

## Điểm cần xác minh khi code (KHÔNG giả định, xác minh qua build+debug thật)

- `body_lines` truyền vào `_strip_lines`/`_parse_block` có phải LUÔN bắt
  đầu từ dòng 1 của TOÀN BỘ file nguồn, hay đã bị cắt/offset (vd thân hàm
  được tách riêng khỏi phần chữ ký trước khi truyền vào)? Cần đọc lại nơi
  gọi (`gen_il_function`'s `body_lines` tham số, `tkv_compile.py`'s nơi
  tách từng hàm ra khỏi file nguồn) để cộng đúng offset — nếu sai, `.line`
  sẽ trỏ sai dòng (breakpoint đặt nhầm chỗ, lỗi ÂM THẦM khó phát hiện nếu
  không tự tay đặt breakpoint thử và xác nhận đúng dòng dừng).
- Escape ký tự đặc biệt trong đường dẫn file cho cú pháp chuỗi IL (dấu
  `\`, khoảng trắng, ký tự Unicode nếu đường dẫn có tiếng Việt có dấu) —
  xác minh qua ilasm thật với 1 đường dẫn chứa khoảng trắng/dấu tiếng Việt
  thật (project nằm trong `D:\Claude AI Project\...`, CÓ khoảng trắng
  thật trong đường dẫn — trường hợp KHÔNG hiếm, phải test).
- Có cần `.line` cho MỌI statement, hay bỏ qua vài kind không có "vị trí"
  ý nghĩa (vd statement rỗng/tự sinh nội bộ như `epilogue`)? — statement
  DO PARSER TẠO RA (không có trong source, vd `nested_def`'s hidden_local
  gán) không có `src_line` thật — cần giá trị fallback hợp lý (dùng dòng
  của statement cha) thay vì lỗi `KeyError`.
- Xác nhận thật: đặt 1 breakpoint qua Visual Studio (hoặc ít nhất
  `WinDbg`/`cdb` nếu không có sẵn Visual Studio đầy đủ trên máy build) lên
  1 dòng cụ thể trong file `.tkv` test, chạy `.exe --debug`, xác nhận
  chương trình DỪNG ĐÚNG dòng đó, biến cục bộ đọc được — đây là bằng chứng
  regression-guard chính (không chỉ "build ra `.pdb` không lỗi" — phải
  THẬT SỰ dừng đúng chỗ).

## Kiểm chứng

- Test mới: build `pdb_lines_py_tree_test.tkv --debug`, xác nhận
  `.pdb` sinh ra, chữ ký byte đầu đúng `"Microsoft C/C++ MSF"` (không
  phải `"BSJB"`).
- Xác nhận build KHÔNG `--debug` (mặc định) hoàn toàn KHÔNG đổi output
  `.il`/`.exe` so với trước thay đổi này (byte-for-byte hoặc ít nhất
  không có dòng `.line` nào xuất hiện) — đảm bảo tính năng THẬT SỰ opt-in,
  không có overhead/rủi ro cho build mặc định.
- Xác nhận thật qua debugger (mục "Điểm cần xác minh" cuối) — breakpoint
  dừng đúng dòng, không chỉ PDB tồn tại.
- Regression toàn bộ `Testkit/*.tkv` qua `.py` tree KHÔNG `--debug` —
  không đổi (đúng ý "mặc định không ảnh hưởng").
- **KHÔNG rebuild `tkvc.exe`** (theo chỉ thị người dùng, giống plan
  Concurrency trước) — chỉ regression qua cây `.py`, `release/3.code`
  KHÔNG rebuild/động tới `dist/`.

## Ngoài phạm vi (ghi lại để khỏi hỏi lại)
- Portable PDB / Source Link — không áp dụng cho toolchain `ilasm.exe`
  Framework của project này (xem "Phát hiện quan trọng").
- `.line` cho thân generator (`MoveNext()`) — gap đã biết, để dành.
- Cấu hình VS Code launch.json cho debug native — việc của người dùng,
  không phải compiler.
- `pdb` runtime tương tác — đã xác nhận KHÔNG cần (non-goal từ trước, xem
  `docs/PYTHON_GAP_CHECKLIST.md` mục Loại 2).
