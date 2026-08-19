# re.findall/re.split — Design

## Bối cảnh

`compiler/il_features/stdlib_re.py` hiện có `re_match`/`re_search`/
`re_fullmatch`/`re_sub` — ánh xạ thẳng `System.Text.RegularExpressions.Regex`,
tên hàm PHẲNG (`re_match`, không phải `re.match`), theo đúng quy ước đã có
của `path_join`/`file_exists`/`read_file` (cú pháp DSL hiện tại hiểu
`x.y(...)` là METHOD_CALL trên 1 biến đã khai báo kiểu, không phải gọi hàm
module-level). Đây là mục đầu tiên trong batch 5.5b của
`docs/PYTHON_GAP_CHECKLIST.md`.

## Mục tiêu

Thêm `re_findall(pattern, s) -> list[str]` và `re_split(pattern, s) ->
list[str]`.

## Phạm vi

- **`re.compile()` KHÔNG làm** (quyết định rõ ràng, đã hỏi người dùng): DSL
  không có kiểu "compiled regex object", và method-call cú pháp `x.y()` chỉ
  áp dụng cho biến đã khai báo kiểu cụ thể (list/str/record...) — không có
  chỗ để gắn `.findall()`/`.match()` lên 1 đối tượng regex tùy ý. Truyền
  pattern dạng string literal trực tiếp mỗi lần gọi là đủ cho use-case thực
  tế, khớp tiền lệ dự án (đã bỏ qua các tính năng OOP-nặng tương tự trước
  đây).
- **Giới hạn đã biết, có chủ đích** (giống `re_sub`'s "repl là string
  thường, không dịch backreference"): `re_findall` với pattern có group con
  (`(...)`) trả về `.Value` của TOÀN BỘ match, KHÔNG phải tuple các group
  con như Python `re.findall()` khi pattern có group. Chấp nhận được, ngoài
  phạm vi batch này.

## Kiến trúc

Cả 2 hàm thêm vào `compiler/il_features/stdlib_re.py`, đăng ký qua
`register_expr_builtin(..., 'str', return_shape='list')` — đúng cách
`os_list_files`/`sys_argv` đã đăng ký cho `list[str]`.

### 1. `re_split(pattern, s) -> list[str]`

Không cần local ẩn — `Regex.Split(input, pattern)` trả thẳng `string[]`,
và `string[]` là `IEnumerable<string>` hợp lệ để đưa thẳng vào
`List<string>` constructor:

```
call string[] [System]System.Text.RegularExpressions.Regex::Split(string, string)
newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
```

Y HỆT pattern `_push_os_list_files` (`stdlib_os.py`) đã dùng cho
`Directory.GetFiles()` — copy đúng cấu trúc đó, đổi API gọi.

### 2. `re_findall(pattern, s) -> list[str]`

`MatchCollection` (kiểu trả về của `Regex.Matches()`) KHÔNG tự động
convert sang `List<string>` được — mỗi phần tử là 1 `Match`, cần trích
`.Value` từng phần tử qua vòng lặp chỉ số (`MatchCollection` có
`get_Item(int32)`/`get_Count()`, không phải generic `IEnumerable<Match>`
sạch để LINQ — codebase này không dùng LINQ). Thuật toán:

```
mc = Regex.Matches(input, pattern)      # MatchCollection
result = new List<string>()
for i in [0, mc.Count):
    result.Add(mc[i].Value)
push result                             # gia tri tra ve
```

3 local ẩn (`mc: MatchCollection`, `result: List<string>`, `i: i32`) khai
qua `ctx['declare_named']` bên trong 1 `temps_fn=` callback đăng ký cùng
`register_expr_builtin('re_findall', ..., temps_fn=_findall_temps, ...)`
— TÁI DÙNG NGUYÊN XI cơ chế first-pass hidden-local đã dùng cho
`sample(lst, k)` ở RandomSeed Task 3 (`_sample_temps`/`declare_named`
trong `stdlib_random.py`), không phát minh cơ chế mới. Hàm codegen builtin
KHÔNG tự chèn `.locals init` trực tiếp — mọi local ẩn PHẢI khai ở
first-pass trước khi bất kỳ codegen thật nào chạy (xem cảnh báo tương tự
đã áp dụng cho Task 3).

**Bắt buộc trước khi code**: xác nhận THẬT (không đoán) qua PowerShell
reflection chữ ký IL chính xác của:
- `MatchCollection::get_Item(int32) -> Match`
- `MatchCollection::get_Count() -> int32`
- `Match::get_Value() -> string`

```bash
powershell -Command "[System.Text.RegularExpressions.MatchCollection].GetMethod('get_Item')"
powershell -Command "[System.Text.RegularExpressions.MatchCollection].GetMethod('get_Count')"
powershell -Command "[System.Text.RegularExpressions.Match].GetMethod('get_Value')"
```

Nếu chữ ký khác dự đoán, sửa lại IL cho khớp — không giữ nguyên đoán mò.

## Kiểm chứng

- Test mới (mở rộng file test `re` hiện có hoặc tạo file mới trong
  `Testkit/`): `re_findall` trên chuỗi có NHIỀU match (vd tìm mọi số trong
  1 chuỗi hỗn hợp chữ+số) — xác nhận đúng số lượng + đúng nội dung từng
  phần tử theo thứ tự xuất hiện. `re_split` trên delimiter dạng regex (vd
  `\s+` tách nhiều khoảng trắng liên tiếp) — xác nhận đúng số phần tử +
  nội dung.
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — 4 hàm `re_*` cũ
  không đổi hành vi.
- Cả 2 cây (`compiler/il_features/stdlib_re.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
