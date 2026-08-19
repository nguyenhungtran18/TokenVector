# Syntax Baseline Linter (#4 Tương thích cú pháp) — Design

## Bối cảnh

`docs/PYTHON_GAP_CHECKLIST.md`'s mục "#4 Tương thích cú pháp — LÀM SAU" (Loại 2,
giới hạn kiến trúc): TokenVector không cố tương thích 100% mọi phiên bản cú
pháp Python — chấp nhận là 1 subset. Vấn đề hiện tại: khi code `.tkv` dùng
construct KHÔNG được compiler hỗ trợ, lỗi phát hiện **rải rác** ở nhiều điểm
sâu trong pipeline (`tkv_compile.py`/`il_codegen.py`/`compiler/il_features/*`)
— chất lượng thông báo không đồng đều, và với construct hoàn toàn chưa được
handle, code rơi vào lỗi Python gốc (`AttributeError`/`KeyError`) khó hiểu
thay vì 1 thông báo "cú pháp này chưa hỗ trợ" rõ ràng.

## Mục tiêu

1 lượt kiểm tra **tiền xử lý (pre-flight)** chạy TRƯỚC khi vào pipeline biên
dịch chính: quét TOÀN BỘ cây AST của file `.tkv` nguồn, đối chiếu MỖI node
với 1 **whitelist** các construct compiler THẬT SỰ hỗ trợ, báo cáo HẾT mọi
construct không nằm trong whitelist (không dừng ở lỗi đầu tiên) — kèm số
dòng, tên construct, và gợi ý thay thế nếu có.

## Kiến trúc

### Module mới: `compiler/syntax_baseline.py`

Hàm chính `check_syntax_baseline(source_text) -> list[SyntaxFinding]` (hoặc
tương đương) — dùng `ast.parse(source_text)` chuẩn Python (KHÔNG đụng vào
`tkv_compile.py`/`il_codegen.py`/bất kỳ file compiler nào khác), đệ quy
(`ast.walk` hoặc `NodeVisitor` tùy chọn lúc implement) toàn bộ cây AST.

`SyntaxFinding` gồm tối thiểu: `line` (số dòng nguồn), `construct_name` (tên
construct không hỗ trợ, vd `"list comprehension"`), `suggestion`
(chuỗi gợi ý thay thế, có thể rỗng/`None` nếu chưa có gợi ý sẵn).

### Whitelist — suy ra từ code compiler thật

**KHÔNG tự đoán/liệt kê thủ công trước.** Whitelist phải suy ra từ việc đọc
THẬT toàn bộ `tkv_compile.py` + `il_codegen.py` + mọi file trong
`compiler/il_features/*.py` để xác định chính xác node type/pattern nào
được handle ở đâu — kể cả các điểm đăng ký ĐỘNG (`register_expr_builtin`,
`LINE_PARSERS`, `ASSIGN_RHS_PARSERS`, `FIRST_PASS_WALK`, `STMT_CODEGEN`...).
Đây là công việc điều tra tốn công nhất của toàn bộ tính năng, tương tự Task 1
"điều tra pipeline" đã làm cho `__tkv_extern_method__` — phải là 1 task
riêng, kết quả là 1 danh sách whitelist THẬT (node type Python AST → có hỗ
trợ hay không, và điều kiện/giới hạn nếu có, vd "chỉ hỗ trợ decorator dạng
`@deco` đơn, không xếp chồng nhiều decorator" — xem comment thật trong
`tkv_compile.py` dòng ~191-192).

Whitelist nên tổ chức theo NHÓM node AST Python chuẩn (`ast.ListComp`,
`ast.DictComp`, `ast.SetComp`, `ast.GeneratorExp`, `ast.Lambda`,
`ast.NamedExpr` walrus, `ast.Match`, `ast.JoinedStr` f-string, `ast.Starred`
sai ngữ cảnh, `ast.AsyncFor`, gán đa mục tiêu `a = b = c`, v.v.) — mỗi nhóm
map tới 1 quyết định: hỗ trợ đầy đủ / hỗ trợ có điều kiện (kèm mô tả điều
kiện) / không hỗ trợ.

### Tích hợp vào `tkv.py build`

Trong `tkv.py::main()`, TRƯỚC lời gọi `compile_tkv_cli`: đọc `source_text`
từ `src`, gọi `check_syntax_baseline(source_text)`. Nếu trả về ≥1 finding:
in HẾT toàn bộ finding ra `stderr` (mỗi dòng: số dòng + tên construct + gợi
ý nếu có), rồi `sys.exit(1)` — KHÔNG gọi `compile_tkv_cli`.

Cờ mới `--no-lint` (`action='store_true'`, mặc định `False`) trên subcommand
`build` — khi bật, bỏ qua bước gọi `check_syntax_baseline` hoàn toàn, đi
thẳng vào `compile_tkv_cli` như hành vi hiện tại (dùng khi linter báo sai/
cần debug chính linter).

### Bảng gợi ý thay thế

1 dict hằng số trong `syntax_baseline.py`, map tên construct → chuỗi gợi ý,
CHỈ cho các trường hợp phổ biến nhất đã biết trước (không cần đầy đủ 100%
— construct hiếm không có trong bảng thì `suggestion=None`, thông báo vẫn
báo đúng vị trí + tên construct, chỉ thiếu phần gợi ý). Ví dụ dự kiến (xác
nhận lại lúc implement, đối chiếu đúng thuật ngữ đã dùng trong
`PYTHON_GAP_CHECKLIST.md`):
- List/dict/set comprehension → "dùng vòng `for` tường minh thay vì
  `[x for x in y]`"
- Lambda phức tạp (đa dòng/nhiều biểu thức) → "dùng hàm top-level đặt tên,
  truyền qua tham số kiểu `func` (xem `map`/`filter`/`reduce`)"
- f-string → "dùng `.format()` hoặc nối chuỗi `+`"
- Walrus `:=` → "tách thành 2 câu lệnh riêng (gán rồi dùng)"
- `match`/`case` → "dùng chuỗi `if`/`elif`/`else`"
- Gán đa mục tiêu `a = b = c` → "tách thành nhiều dòng gán riêng"

## Phạm vi KHÔNG làm

- Linter chỉ kiểm tra **CÚ PHÁP** (hình dạng AST) — KHÔNG kiểm tra kiểu dữ
  liệu/dtype, KHÔNG kiểm tra logic nghiệp vụ (đó vẫn là việc của
  `compile_tkv_cli`/`TranspileError` hiện có, không thay đổi).
- KHÔNG thay thế các `TranspileError`/`SyntaxError` rải rác hiện có trong
  pipeline compile — chúng vẫn tồn tại nguyên vẹn cho lỗi phát hiện SÂU hơn
  mức linter với tới (vd 1 construct ĐƯỢC liệt kê hỗ trợ trong whitelist
  nhưng dùng SAI NGỮ CẢNH cụ thể, ví dụ decorator hợp lệ nhưng đặt trên
  method trong class — comment `tkv_compile.py:192` xác nhận đây là giới
  hạn RIÊNG, không phải whitelist AST-shape chung).
- KHÔNG tự động sửa code người dùng — chỉ báo cáo.
- KHÔNG chặn `test/verify/*.py`/`transpile_program`/`transpile_file`
  (dùng nội bộ bởi test suite, không đi qua `tkv.py build`) — linter CHỈ
  gắn vào đường CLI `tkv.py build`.
- Mirror `.tkv` tự-host: xác nhận lúc implement liệu `syntax_baseline.py`
  cần port sang `release/3.code/compiler/` hay không (tùy vào việc `tkv.py`
  bản tự-host có tồn tại/được dùng hay không — cần điều tra, không giả
  định trước).

## Kiểm chứng

- Test tích cực: 1 file `.tkv` hợp lệ (dùng mọi construct ĐƯỢC hỗ trợ,
  tham khảo `Testkit/*.tkv` có sẵn) → linter trả về 0 finding, build tiếp
  tục bình thường.
- Test từng construct KHÔNG hỗ trợ (list comprehension, f-string, walrus,
  match-case, lambda đa dòng, gán đa mục tiêu — tối thiểu các construct có
  trong bảng gợi ý) → mỗi case: linter báo ĐÚNG số dòng + tên construct +
  gợi ý tương ứng, build DỪNG (không gọi `compile_tkv_cli`).
- Test file có NHIỀU lỗi cùng lúc → linter báo HẾT tất cả (không dừng ở lỗi
  đầu tiên), đếm đúng số lượng finding.
- Test `--no-lint` → file có construct không hỗ trợ NHƯNG dùng cờ này →
  linter bị bỏ qua, build đi thẳng vào `compile_tkv_cli` (có thể fail ở đó
  với lỗi khác, hoặc pass nếu compiler thực ra xử lý được dù không có trong
  whitelist — trường hợp này log lại như 1 "gap trong whitelist" cần bổ
  sung sau, không phải lỗi của linter).
- Regression: chạy `tkv.py build` cho TOÀN BỘ `Testkit/*.tkv`/`test/*.tkv`
  hiện có (không dùng `--no-lint`) — xác nhận linter KHÔNG báo false-positive
  cho bất kỳ file nào đang build+chạy PASS trước đây (đây là bài test quan
  trọng nhất, chứng minh whitelist đủ đầy đủ cho toàn bộ test suite thật).
