# Task 1 Report — Điều tra pipeline compile + điểm parse pragma

## Step 1: `tkv.py build`
`tkv.py:35` — `result = compile_tkv_cli(src, out_exe, entry_name=args.entry, debug=args.debug)`.
Import trực tiếp `from tkv_compile import compile_tkv_cli, CliError, TranspileError` (dòng 10).
XÁC NHẬN: `tkv.py build` gọi `compile_tkv_cli` TRỰC TIẾP, không qua trung gian nào khác.

## Step 2: pipeline nào compile_tkv_cli thực sự dùng

`compile_tkv_cli` (tkv_compile.py:1633) gọi `extract_program_file(tkv_path)` ở dòng 1646
(KHÔNG gọi `_parse_program_ast` trực tiếp). `extract_program_file` (dòng 1137) tự nó gọi
`_parse_program_ast(source_text)` ở dòng 1160 (và đệ quy gọi lại chính nó cho mỗi
`__tkv_import__`). Vậy chuỗi thật là:

```
tkv.py build -> compile_tkv_cli -> extract_program_file -> _parse_program_ast
```

`compile_tkv_cli` sau đó tự gọi `gen_il_program` (dòng 1679) trực tiếp — KHÔNG đi qua
`transpile_program`/`_transpile_extracted`.

`transpile_program`/`_transpile_extracted` (định nghĩa dòng 1305/1319) grep toàn repo
CHỈ được gọi ở:
- `test/verify/while_test.py`, `try_except_test.py`, `tkv_compile_test.py`,
  `string_test.py`, `self_host_test.py`, `list_test.py`, `for_in_list_test.py`,
  `for_in_dict_test.py`, `dict_test.py`, `break_continue_test.py`
- các bản mirror tương ứng dưới `release/3.code/test/verify/*.tkv`
- nội bộ `tkv_compile.py`/`tkv_compile.tkv` (transpile_file gọi `_transpile_extracted` ở
  dòng ~1342, xem thêm bên dưới)

KHÔNG có nơi nào trong pipeline `tkv.py build` dùng 2 hàm này — chúng chỉ phục vụ
unit test cấp thấp (test 1 file `.tkv` đơn lẻ không import, không sinh `.exe` đầy đủ,
không entry point tự động). `transpile_file` (dòng ~1335) dùng `_transpile_extracted`
cho luồng "compile file có import nhưng không đóng gói .exe" — cũng KHÔNG phải luồng
`tkv.py build`.

KẾT LUẬN: CHỈ CẦN patch pipeline `_parse_program_ast` → `extract_program_file` →
`compile_tkv_cli`. KHÔNG cần sửa `transpile_program`/`_transpile_extracted`/`transpile_file`
(bỏ qua ở Task 2/3 theo đúng chỉ dẫn trong plan) — nhưng LƯU Ý Task 2 Step 4: cả
`extract_program`, `extract_program_file` VÀ `transpile_program` đều unpack tuple trả về
của `_parse_program_ast` (xem danh sách call site ở dưới), nên khi thêm phần tử mới vào
tuple trả về của `_parse_program_ast`, PHẢI sửa cả 3 call site unpack đó (không phải chỉ
2 như ước tính sơ bộ trong plan) để tránh lỗi unpack, dù `transpile_program` không dùng
tới `extern_methods`.

## Step 3: Số dòng chính xác (đọc file thật, tkv_compile.py)

- `extern_assemblies = []` khởi tạo: **dòng 796** (khớp ước tính plan).
- Nhánh `elif ... __tkv_extern_assembly__`: điều kiện `elif` bắt đầu **dòng 874**,
  thân xử lý kết thúc **dòng 911** (đúng như ước tính "874-911" trong plan — khớp
  chính xác). Nhánh kế tiếp (`elif isinstance(node, ast.Import)`) bắt đầu dòng 912 —
  đây là điểm chèn nhánh `__tkv_extern_method__` mới (Task 2 Step 3) NGAY SAU dòng 911,
  TRƯỚC dòng 912.
- Lời gọi `gen_il_program` trong `compile_tkv_cli`: **dòng 1679** (khớp ước tính plan
  "khoảng 1679" — chính xác).

### Tuple trả về `_parse_program_ast` — TẤT CẢ call site unpack (để Task 2 Step 4 dùng)

`_parse_program_ast` return statement ở dòng 1038-1039:
```python
return (record_defs, record_methods_raw, record_bases, record_interfaces, interface_defs, pairs,
        import_names, extern_assemblies, module_consts, module_globals)
```
10 phần tử hiện tại. 3 call site unpack (không phải 2):
1. `extract_program` — dòng 1082-1084 (unpack đủ 10, dùng `extern_assemblies`, bỏ
   `import_names` sau khi validate rỗng).
2. `extract_program_file` — dòng 1158-1160 (unpack đủ 10, dùng cả `import_names` lẫn
   `extern_assemblies`).
3. `_parse_program_ast` không tự gọi lại chính nó — nhưng 2 hàm trên (`extract_program`,
   `extract_program_file`) lại được downstream bởi `compile_tkv_cli`
   (qua `extract_program_file`, dòng 1644-1646) và `transpile_program`
   (qua `extract_program`, dòng 1328-1329) — cả 2 đều re-unpack tuple TRẢ VỀ của
   `extract_program`/`extract_program_file` (9 phần tử, không có `import_names`),
   KHÔNG unpack trực tiếp tuple của `_parse_program_ast`. Vậy thực tế:
   - Sửa tuple `_parse_program_ast` (10→11 phần tử) → phải sửa unpack ở
     `extract_program` (dòng 1082-1084) và `extract_program_file` (dòng 1158-1160).
   - Tuple trả về của `extract_program`/`extract_program_file` (9→10 phần tử, thêm
     `extern_methods`) → phải sửa tiếp unpack ở `compile_tkv_cli` (dòng 1644-1646,
     dùng `extern_methods`) và `transpile_program` (dòng 1328-1329, bỏ qua
     `extern_methods` bằng `_`).

Tổng cộng 4 điểm unpack cần sửa khi thêm `extern_methods` xuyên suốt 2 tầng tuple
(không phải 2 như plan ước tính sơ bộ — Task 2 Step 4 cần cập nhật lại danh sách này).

### Cấu trúc dữ liệu thật của `extern_assemblies` sau parse

LUÔN LUÔN là `list[tuple[str, str_or_None, str_or_None]]` — KHÔNG BAO GIỜ trộn lẫn
string trần và tuple. Cả 2 dạng cú pháp nguồn đều được normalize về tuple 3 phần tử
ngay trong `_parse_program_ast`:
- Cú pháp chuỗi đơn/list chuỗi (`__tkv_extern_assembly__ = "System.Xml"` hoặc
  `["System.Xml", "System.Data"]`) → dòng 895-896: mỗi phần tử chuỗi được append thành
  `(e.value, 'DEFAULT', 'DEFAULT')`.
- Cú pháp tuple 3 phần tử (`(ten, publickeytoken_hex_or_None, version_or_None)`) →
  dòng 897-906: append `tuple(parts)` (3 phần tử, `parts[1]`/`parts[2]` có thể là
  `None` thật nếu nguồn viết `None`).

Xác nhận thêm tại nơi tiêu thụ `extern_assemblies`, `compile_tkv_cli` dòng 1735:
`for asm_name, pubkeytoken, version in extern_assemblies:` — unpack 3 biến trực tiếp,
không có nhánh xử lý "string đơn" nào khác → chứng minh list LUÔN đồng nhất tuple 3
phần tử, không trộn lẫn.

## Khuyến nghị cho Task 2/3

1. Task 2 Step 3 (chèn nhánh `elif __tkv_extern_method__`): chèn NGAY SAU dòng 911
   (trước dòng 912 `elif isinstance(node, ast.Import)`).
2. Task 2 Step 4 (cập nhật tuple + unpack): phải sửa **4 điểm**, không phải 2:
   - `_parse_program_ast` return (dòng 1038-1039): thêm `extern_methods`.
   - `extract_program` unpack (dòng 1082-1084) + return (dòng 1091-1092): thêm
     `extern_methods` xuyên qua.
   - `extract_program_file` unpack (dòng 1158-1160) + return (dòng 1210-1211): thêm
     `extern_methods` xuyên qua, VÀ xử lý gộp đệ quy (giống `extern_assemblies.extend(
     imp_extern_assemblies)` ở dòng 1200) — file import cũng có thể khai
     `__tkv_extern_method__` riêng, cần `extend` tương tự.
   - `compile_tkv_cli` unpack (dòng 1644-1646): nhận `extern_methods`, dùng ở Task 3
     Step 6 (đăng ký động trước `gen_il_program`, dòng 1679).
   - `transpile_program` unpack (dòng 1328-1329): chỉ cần `_` bỏ qua `extern_methods`
     (không dùng — pipeline test riêng, không liên quan `tkv.py build`).
3. Task 3 Step 6: `declared_assembly_names` trích tên từ `extern_assemblies` — vì cấu
   trúc LUÔN là tuple 3 phần tử đồng nhất, code trích tên đơn giản là
   `{t[0] for t in extern_assemblies}` — KHÔNG cần xử lý 2 dạng khác nhau (list string
   vs tuple) như plan lo ngại, vì `_parse_program_ast` đã normalize sẵn.
4. KHÔNG cần đụng đến `transpile_program`/`_transpile_extracted`/`transpile_file` cho
   mục tiêu `tkv.py build` — chỉ cần đảm bảo chúng không bị crash do đổi tuple shape
   (xử lý bằng `_` ở bước unpack là đủ).
