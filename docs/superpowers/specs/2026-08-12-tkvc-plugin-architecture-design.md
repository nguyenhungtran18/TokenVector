# Thiết kế: tách `tkvc.exe` thành core nhẹ + thư viện plugin nạp động

**Ngày:** 2026-08-12
**Trạng thái:** Đã duyệt thiết kế, chuẩn bị viết plan triển khai

## 1. Mục tiêu

`tkvc.exe` (bộ biên dịch TokenVector tự-host, đóng gói qua PyInstaller
`--onefile` + `--collect-submodules il_features`) hiện nhúng CỨNG toàn bộ
~50 file trong `compiler/il_features/` vào 1 file exe, dù chương trình
đang biên dịch có dùng tới tính năng đó hay không.

Mục tiêu (người dùng xác nhận cả 2, không đánh đổi):
1. **Gọn/nhẹ**: `tkvc.exe` chỉ còn phần thật sự cần để engine dịch chạy
   được — không nhúng các "thư viện" (math/re/random/os.path/file I/O/
   sqlite/http/json/datetime/itertools...).
2. **Mở rộng không cần build lại**: thêm 1 thư viện mới = viết 1 file
   `.py`/`.tkv` mới, thả vào thư mục cạnh `tkvc.exe` — không cần build
   lại chính `tkvc.exe` từ source.

Analogy đã thống nhất với người dùng: giống CPython — interpreter core
không hardcode gọi vào ruột `os`/`json`/`re`, mà qua cơ chế import +
"giao thức module" chung; core Python cũng KHÔNG thể tắt kiểu `list`/
`dict`/`str` đi được (đó là ngữ nghĩa ngôn ngữ, không phải thư viện).

## 2. Hiện trạng (đã xác minh bằng cách đọc code, không đoán)

### 2.1 Hai cơ chế dispatch song song trong `il_codegen.py`

**Cơ chế MỚI (data-driven, ~15+ module đã dùng)**: `il_dispatch.py`'s
`register_expr_builtin`/`register_line_parser`/`register_stmt_codegen`/
`register_macro_expander`/`register_first_pass_walk`. Module tự gọi các
hàm `register_*` này lúc `import` (side-effect) — `il_codegen.py` KHÔNG
biết tên hàm cụ thể, chỉ tra bảng `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE`
theo tên chuỗi lúc runtime. Đây CHÍNH LÀ cơ chế "tự đăng ký, load rồi
quên" phù hợp cho plugin — ví dụ `stdlib_json.py`, `stdlib_sqlite.py`,
`comprehension.py`, `fstring.py`, `stdlib_aggregates.py`...

**Cơ chế CŨ (hardcode if/elif trong `_expr_call`, dòng ~1685-1795 của
`il_codegen.py`)**: viết từ trước khi có bảng đăng ký, dạng
`if name == 'read_file': return _file_io_compile_read_file(...)`. Danh
sách tên đang đi đường này (xác minh bằng grep trực tiếp):
`read_file`/`file_exists` (`file_io.py`), `pow`/`math_pi`/`math_e`/
`math_gcd`/toàn bộ `_MATH_FUNCS` (`stdlib_math.py`/`stdlib_math_trig.py`),
`random`/`randint`/`choice`/`uniform`/`randrange` (`stdlib_random.py`),
`path_join`/`path_exists`/`path_basename`/`path_dirname`/`path_isfile`/
`path_isdir` (`stdlib_path.py`), `xml_encode_name` (`stdlib_xml.py`),
`re_match`/`re_sub`/`re_search`/`re_fullmatch` (`stdlib_re.py`), `str`/
`fmt_float` (`string_feature.py`). Các tên này bắt buộc `il_codegen.py`
phải `from il_features.X import compile_Y` TRỰC TIẾP để gọi được trong
nhánh if/elif — đây là thứ đang chặn việc tách file.

### 2.2 Nhóm KHÔNG tách được — ngữ nghĩa kiểu dữ liệu lõi

Các module implement kiểu dữ liệu cơ bản của ngôn ngữ (indexing/binop/
compare/container), gắn thẳng vào bộ dịch biểu thức lõi
(`register_expr_codegen` cho tag `'index'`/`'binop'`/`'compare'`...),
KHÔNG phải "hàm gọi được" (`name(...)`) nên không đi qua
`EXPR_BUILTIN_CODEGEN` được — giống Python không "tắt" kiểu `list` được:

- `list_type.py`, `set_type.py`, `dict_type.py`, `tuple_type.py`
- `string_feature.py`'s `compile_index_str`/`compile_len_str`/
  `compile_binop_concat`/`compile_compare_str` (RIÊNG `str()`/`fmt_float`
  builtin trong CÙNG file này thì tách được — xem 2.1)
- `operators.py`, `int_type.py`
- `closures.py`, `generator_lazy.py`/`generator_feature.py` (đặc thù
  ngôn ngữ: hàm lồng, generator lazy)
- `slicing.py`, `comprehension.py` — TÁCH ĐƯỢC (macro-expander thuần,
  KHÔNG có ai import trực tiếp tên hàm) — xếp vào nhóm 3 bên dưới dù
  liên quan cú pháp cơ bản, vì cơ chế đăng ký của chúng ĐÃ đúng chuẩn
  registry (macro-expander, không gọi thẳng tên hàm)

### 2.3 Build script hiện tại (`release/3.code/build_tkvc.ps1`)

Copy toàn bộ `.tkv` → staging `.py`, rồi PyInstaller `--onefile
--collect-submodules il_features` — flag `--collect-submodules` ép nhúng
MỌI submodule trong package `il_features`, kể cả module không được
`import` tĩnh ở đâu cả. Đây là 1 điểm phải sửa (xem mục 4).

## 3. Ranh giới Core / Library (quyết định cuối)

**CORE (giữ trong `tkvc.exe`, luôn nhúng)**:
- `tkv.py`/`tkv_compile.py`/`tokenvector_compile.py` (entry point + CLI)
- `il_core.py`, `il_dispatch.py`, `typed_dsl_parser.py`
- `il_codegen.py` (engine dịch biểu thức/statement chính)
- `list_type.py`, `set_type.py`, `dict_type.py`, `tuple_type.py`
- `string_feature.py` (CHỈ phần index/len/concat/compare — xem 3.2 về
  việc tách riêng `str()`/`fmt_float`)
- `operators.py`, `int_type.py`
- `closures.py`, `generator_lazy.py`, `generator_feature.py`
- **Cơ chế nạp plugin mới** (module mới, xem mục 4)

**LIBRARY (tách thành file rời, nạp động)** — TẤT CẢ module còn lại,
sau khi migrate xong nhóm 2.1 sang `register_expr_builtin`:
`file_io.py` (`read_file`/`file_exists`/`write_file`/`append_file`),
`stdlib_math.py`, `stdlib_math_trig.py`, `stdlib_random.py`,
`stdlib_path.py`, `stdlib_xml.py`, `stdlib_re.py`, `string_feature.py`'s
`str()`/`fmt_float` (tách riêng phần builtin ra khỏi phần core index/
compare — xem 3.2), cộng toàn bộ nhóm ĐÃ SẴN dùng registry mới:
`stdlib_json.py`, `stdlib_json_get.py`, `stdlib_sqlite.py`,
`stdlib_http.py`, `stdlib_http_full.py`, `stdlib_os.py`,
`stdlib_hashlib.py`, `stdlib_base64.py`, `stdlib_zipfile.py`,
`stdlib_shutil.py`, `stdlib_functional.py`, `async_await.py`,
`typecheck.py`, `datetime_type.py`, `stdlib_input.py`,
`stdlib_itertools.py`, `stdlib_itertools_expr.py`, `stdlib_aggregates.py`,
`stdlib_repeat.py`, `stdlib_eval.py`, `stdlib_cjson.py`, `stdlib_string_count.py`,
`stdlib_string_zfill.py`, `string_title.py`, `string_join.py`,
`string_split.py`, `string_format.py`, `string_percent_format.py`,
`fstring.py`, `comprehension.py`, `slicing.py`, `set_methods_batch2.py`,
`set_to_list.py`, `list_methods_batch2.py`, `list_methods_batch3.py`,
`list_copy.py`, `list_count_index.py`, `dict_keys_values.py`,
`dict_items_list.py`, `for_in_kvlist.py`, `int_builtin.py`,
`float_builtin.py`, `expr_hoist.py`, `logging_feature.py`,
`pickle_feature.py`, `stdlib_sys.py`, string_methods_batch3.py's
`RETURN_DTYPE` (xem 3.2 - export dạng dict cần xử lý riêng).

### 3.1 Điểm cần xử lý đặc biệt: export không phải hàm side-effect

Một số module KHÔNG chỉ đăng ký side-effect, còn export HẰNG SỐ/DICT bị
đọc trực tiếp bởi `il_codegen.py`:
- `stdlib_math_trig.py`'s `EXTRA_FUNCS` (được `.update()` thẳng vào
  `_MATH_FUNCS` của `il_codegen.py`)
- `string_methods_batch3.py`'s `RETURN_DTYPE` (gán thẳng vào
  `_STR_METHOD_RETURN_DTYPE`)
- `closures.py`'s `_collect_var_names` (hàm helper dùng trong lambda)

Các case này migrate bằng cách: đổi từ "đọc dict lúc import" sang "gọi 1
hàm đăng ký" (vd `register_math_extra_funcs(dict)` giống hệt pattern
`register_expr_builtin` đã có) — để `il_codegen.py` không cần `from X
import EXTRA_FUNCS` nữa mà nhận qua side-effect callback.
`_collect_var_names` (dùng trong `closures.py` chính nó, KHÔNG phải bị
`il_codegen.py` gọi trực tiếp theo grep) - xác minh lại lúc code, có thể
đã tự đủ điều kiện ở nhóm core (closures.py) nên không cần xử lý gì thêm.

### 3.2 `string_feature.py` cần TÁCH LÀM 2 FILE

Hiện `compile_str_builtin`/`compile_fmt_float` (builtin `str()`/
`fmt_float()`, TÁCH ĐƯỢC) nằm CHUNG file với `compile_index_str`/
`compile_len_str`/`compile_binop_concat`/`compile_compare_str` (ngữ
nghĩa lõi kiểu `str`, KHÔNG tách được). Cần tách thành
`string_feature.py` (core, giữ 4 hàm compile_index/len/concat/compare)
+ `string_builtin.py` (library, `str()`/`fmt_float()` qua
`register_expr_builtin`, file MỚI).

## 4. Cơ chế nạp plugin

### 4.1 Vị trí thư mục plugin

- Chế độ dev (`python tkv.py build ...`, cây `.py` gốc): thư mục plugin
  = `compiler/il_features/` như hiện tại — KHÔNG đổi hành vi cây `.py`
  gốc trong chế độ này (đường phát triển nhanh giữ nguyên, đơn giản).
- Chế độ `tkvc.exe` đóng gói (PyInstaller frozen): thư mục plugin =
  `il_features/` đặt CẠNH file `.exe` đang chạy (xác định qua
  `os.path.dirname(sys.executable)` khi `getattr(sys, 'frozen', False)`
  là `True` — cờ chuẩn PyInstaller dùng để phát hiện chế độ frozen).

### 4.2 Cách nạp

Module mới `compiler/plugin_loader.py` (core, luôn nhúng):
- Hàm `discover_plugin_dir()`: trả đường dẫn thư mục plugin theo 4.1.
- Hàm `load_plugins()`: liệt kê `*.py` (hoặc `*.tkv` — dùng lại
  `tkv_import_hook.py` đã có từ phiên trước cho việc này ở cây tự-host)
  trong thư mục đó, `importlib.util.spec_from_file_location` +
  `exec_module` từng file — mỗi file tự chạy các lệnh `register_*` của
  nó (KHÔNG đổi code bên trong từng module plugin).
- Gọi `load_plugins()` 1 LẦN lúc `tkv_compile.py` khởi động, TRƯỚC khi
  gọi `gen_il_program`/`compile_tkv_cli`.

### 4.3 Rủi ro thật đã biết: thứ tự import

Phiên trước phát hiện bug thật: `stdlib_cjson.py` import SAU khi
`il_codegen` đăng ký `json_get_str` khiến nó ÂM THẦM ĐÈ lên bản đúng
(khác tên hàm, cùng registry) — sửa bằng đổi tên `cjson_*`. Quét thư
mục theo alphabet sẽ cho thứ tự KHÁC thứ tự import cứng hiện tại — có
thể lộ ra collision tương tự ở chỗ khác. Biện pháp: `load_plugins()`
raise lỗi RÕ RÀNG nếu phát hiện 1 tên bị đăng ký 2 lần bởi 2 file khác
nhau (thêm 1 lớp kiểm tra vào `register_expr_builtin`/`register_line_parser`/
v.v. trong `il_dispatch.py` — hiện các hàm này gán thẳng dict không cảnh
báo trùng, xem ghi chú bug `json_get_str` cũ) — biến "đè âm thầm" thành
"lỗi to lúc build/test", bắt được NGAY thay vì để lộ ra như bug cũ.

## 5. Thay đổi build script (`build_tkvc.ps1`)

- Bỏ `--collect-submodules il_features`.
- Staging tổ chức lại: các file thuộc nhóm LIBRARY (mục 3) copy `.tkv`→`.py`
  vào `staging/il_features_library/` (thư mục RIÊNG, NGOÀI package
  `compiler/`) thay vì `staging/compiler/il_features/`; nhóm CORE vẫn
  copy vào `staging/compiler/il_features/` như cũ. PyInstaller chỉ thấy
  package `il_features` gồm đúng nhóm core (Python import tĩnh trong
  `il_codegen.py` chỉ trỏ tới core nên tự nhiên không kéo theo nhóm
  library) — không cần liệt kê `--exclude-module` cho từng file trong
  ~40 file nhóm library (dễ sai sót, khó bảo trì khi thêm module mới).
- Sau khi PyInstaller build xong, COPY nguyên `staging/il_features_library/*.py`
  sang `dist/il_features/` (cạnh `tkvc.exe`) — giữ đuôi `.py` vì đây là
  nơi `plugin_loader.py` sẽ `exec_module` trực tiếp, không cần chạy qua
  Python import system chuẩn đòi hỏi đuôi cụ thể, nhưng `.py` cho dễ
  đọc/debug đúng như file thật luôn được dùng (nguồn `.tkv` giữ nguyên
  trong git, staging là tạm).

## 6. Migration nhóm 2.1 (if/elif cũ → `register_expr_builtin`)

Với mỗi tên trong danh sách 2.1 (`read_file`, `file_exists`, `pow`,
`math_pi`, `math_e`, `math_gcd`, các tên trong `_MATH_FUNCS`, `random`,
`randint`, `choice`, `uniform`, `randrange`, `path_join`, `path_exists`,
`path_basename`, `path_dirname`, `path_isfile`, `path_isdir`,
`xml_encode_name`, `re_match`, `re_sub`, `re_search`, `re_fullmatch`,
`str`, `fmt_float`): thêm 1 lời gọi `register_expr_builtin(tên, hàm_compile,
return_dtype, ...)` NGAY TRONG file module tương ứng (giống pattern
`stdlib_aggregates.py`/`stdlib_functional.py` đã làm), xoá nhánh
if/elif tương ứng trong `il_codegen.py`, xoá import trực tiếp. `round`/
`_MATH_FUNCS` dùng chung 1 vòng lặp (`_MATH_FUNCS` là 1 dict tên→tên .NET
method) — cần 1 vòng `for` đăng ký hàng loạt thay vì viết tay từng dòng.

**Việc riêng, làm TRƯỚC khi tách file `stdlib_math.py`/`stdlib_re.py`/...
ra khỏi exe** — đây là bước bắt buộc để gỡ import cứng, không phụ thuộc
cơ chế nạp plugin (mục 4), có thể làm/test độc lập trước.

## 7. Kiểm chứng (test cả 2 cây, đúng quy trình đã thiết lập)

- Sau MỖI bước migrate (từng tên trong mục 6, hoặc từng nhóm nhỏ): build
  qua `.py` tree (`python tkv.py build`) + chạy lại các test liên quan
  trực tiếp tính năng đó (vd `math_extra_test.tkv`, `re_extend_test.tkv`,
  `random_extend_test.tkv`, `path_isfile_isdir_test.tkv`).
- Sau khi xong TOÀN BỘ migration + cơ chế nạp plugin + build script mới:
  chạy lại **TOÀN BỘ** `release/3.code/Testkit/*.tkv` (đã có ~30 file)
  qua cả `.py` tree VÀ `tkvc.exe` build lại từ chính nó (self-hosted,
  qua `build_tkvc.ps1` mới) — đối chiếu PASS/FAIL không đổi so với
  trước khi migrate.
- Đo lại kích thước `dist/tkvc.exe` trước/sau để xác nhận mục tiêu
  "gọn nhẹ" đạt được thật (không chỉ lý thuyết).
- Test riêng cơ chế plugin: xoá thử 1 file trong `dist/il_features/`
  (vd `stdlib_math.tkv`→`.py`), build 1 chương trình DÙNG `pow()`, xác
  nhận báo lỗi RÕ RÀNG (không phải crash khó hiểu) khi thiếu plugin —
  rồi thêm lại, xác nhận build được bình thường (không cần build lại
  `tkvc.exe`).

## 8. Ngoài phạm vi (không làm ở đây)

- KHÔNG đổi cơ chế biên dịch `.tkv`→`.py` staging hiện tại (`build_tkvc.ps1`
  đầu file) — chỉ đổi PHẦN đóng gói PyInstaller.
- KHÔNG đổi hành vi cây `.py` gốc (`python tkv.py build`) — chế độ dev
  vẫn quét `compiler/il_features/` tại chỗ như cũ, KHÔNG bắt buộc mô
  phỏng cơ chế "file cạnh exe" (không có "exe" ở chế độ này).
- KHÔNG tách `list_type`/`dict_type`/`set_type`/`tuple_type`/`operators`/
  `int_type`/`closures`/`generator_*` (mục 2.2) — ngữ nghĩa ngôn ngữ
  lõi, ở lại core vĩnh viễn trừ khi có thiết kế lại kiểu dữ liệu hoàn
  toàn khác (ngoài phạm vi dự án hiện tại).
- KHÔNG làm plugin "hot-reload" (nạp lại khi file thay đổi giữa các lần
  build) — mỗi lần chạy `tkvc.exe build ...` là 1 process mới, nạp
  plugin 1 lần lúc khởi động là đủ.
