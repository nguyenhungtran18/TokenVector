# .format() keyword args — Design

## Bối cảnh

`compiler/il_features/string_format.py` hiện thực `"literal".format(a, b)`
như 1 MACRO TEXT-LEVEL — viết lại thành biểu thức nối chuỗi TRƯỚC khi
dòng được parse (giống `fstring.py`), chạy trong `MACRO_EXPANDERS`
(`_expand_macros`, lặp tới điểm cố định). Chỉ nhận placeholder `{}` (tự
tăng chỉ số), `{N}` (chỉ số tường minh, cho phép reorder), `{N:.Mf}`/
`{:.Mf}` (spec số thập phân cố định qua `fmt_float()`). KHÔNG nhận
`{name}` (keyword) vì cú pháp gọi hàm DSL nói chung KHÔNG hỗ trợ tham số
dạng `name=value`. Đây là mục 3 trong batch 5.5b của
`docs/PYTHON_GAP_CHECKLIST.md`.

## Mục tiêu

Thêm hỗ trợ `.format(name=value, ...)` và placeholder `{name}` —
`"Xin chào {name}, bạn {age} tuổi".format(name=n, age=a)`.

## Kiến trúc

Vì macro chạy ở MỨC VĂN BẢN (không qua AST parser chung), có thể tự xử
lý cú pháp `name=value` CHỈ RIÊNG trong `.format(...)` mà KHÔNG cần đổi
cú pháp gọi hàm DSL nói chung ở nơi khác (giới hạn "không hỗ trợ
`name=value`" của DSL vẫn giữ nguyên cho mọi lời gọi hàm khác — chỉ
`.format()` có xử lý đặc biệt vì nó là macro text, không phải lời gọi
hàm thật).

### 1. `_split_top_level_args` — phân loại positional vs keyword

Sửa `compiler/il_features/string_format.py`: sau khi tách theo dấu phẩy
top-level như hiện tại (giữ nguyên logic quét `depth`/`quote`), phân
loại MỖI phần bằng regex `^(\w+)\s*=(?!=)(.*)$` (dấu `=` không theo sau
bởi `=` khác, tránh khớp nhầm `==`/`>=`/`<=`/`!=` bên trong biểu thức):
- Khớp → `(name, value_expr)` thêm vào dict `kwargs`.
- Không khớp → thêm nguyên văn vào list `positional` (giữ đúng thứ tự
  xuất hiện, giống hiện tại).

Hàm đổi chữ ký trả về `(positional: list[str], kwargs: dict[str, str])`
thay vì chỉ `list[str]` — cập nhật ĐÚNG 1 nơi gọi (`try_expand_format`).

### 2. `_PLACEHOLDER_RE` — nhận placeholder dạng tên

Mở rộng regex hiện tại (chỉ số `\d*`) thêm nhánh tên định danh:
```python
_PLACEHOLDER_RE = re.compile(r'\{(\w*)(:\.(\d+)f)?\}')
```
(`\w*` thay `\d*` — khớp CẢ chuỗi rỗng (`{}`), số (`{0}`), VÀ tên
(`{name}`) trong 1 nhóm bắt — phân biệt 3 trường hợp ở bước xử lý sau
bằng cách thử `int(idx_str)`, bắt `ValueError` để coi là tên).

### 3. `_format_content_to_concat_expr` — tra cứu theo tên khi cần

Nhận thêm tham số `kwargs: dict[str, str]`. Logic xử lý mỗi placeholder:
- Chuỗi rỗng (`{}`) → hành vi cũ, tự tăng chỉ số trong `positional`.
- Là số (`int(idx_str)` thành công) → hành vi cũ, tra `positional[idx]`.
- Không phải số (là tên định danh) → tra `kwargs[idx_str]`; KHÔNG có key
  → `SyntaxError` rõ ràng (giống lỗi thiếu index hiện có):
  ```
  il_codegen: .format() thieu tham so keyword '{idx_str}'
  ```

## Phạm vi

- Vẫn CHỈ nhận dạng `"literal".format(...)` — chuỗi literal PHẢI đứng
  TRỰC TIẾP trước `.format(` (giới hạn cũ giữ nguyên, không mở rộng).
- Vẫn KHÔNG nhận format spec nào khác ngoài `.Nf` (giới hạn cũ giữ
  nguyên).
- Positional và keyword CÓ THỂ trộn lẫn trong cùng 1 lời gọi
  (`.format(a, name=b)`) — khớp ngữ nghĩa Python thật, không cấm.
- KHÔNG đổi cú pháp gọi hàm DSL nói chung — `name=value` CHỈ được hiểu
  đặc biệt bên trong `.format(...)`, không áp dụng cho bất kỳ lời gọi
  hàm nào khác.

## Kiểm chứng

- Test mới: `.format(name=..., age=...)` thuần keyword; trộn
  `.format(a, name=b)` positional+keyword; `{}`/`{N}` vẫn hoạt động
  đúng như cũ (không regression); thiếu keyword → build lỗi rõ ràng
  (không cần test runtime, chỉ cần xác nhận `SyntaxError` đúng thông
  điệp qua build-time).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `string_format_test`
  (test hiện có cho `{}`/`{N}`/`{N:.Mf}`) không đổi hành vi.
- Cả 2 cây (`compiler/il_features/string_format.py`/`.tkv`) sửa đồng
  bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
