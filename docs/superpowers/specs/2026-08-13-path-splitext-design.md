# os.path.splitext() — Design

## Bối cảnh

`compiler/il_features/stdlib_path.py` hiện có `path_join`/`path_exists`/
`path_basename`/`path_dirname`/`path_isfile`/`path_isdir` — ánh xạ thẳng
`System.IO.Path`, tên hàm PHẲNG (`path_join`, không phải `os.path.join`),
theo đúng quy ước đã có. Đây là mục 4 batch 5.5b của
`docs/PYTHON_GAP_CHECKLIST.md`.

Python `os.path.splitext(p)` trả về 1 TUPLE `(root, ext)`. Cơ chế giải
nén tuple hiện tại (`x, y = f(...)`, `compiler/il_features/tuple_type.py`)
CHỈ nhận diện lời gọi hàm NGƯỜI DÙNG tự khai báo (tra `func_table` —
xem `fpw_tuple_assign`/`codegen_tuple_assign`), KHÔNG nhận builtin như
`path_join`. Đã hỏi người dùng: chọn mở rộng cơ chế giải nén hỗ trợ
builtin (thay vì rẽ nhánh 2 hàm riêng `path_splitext_root`/
`path_splitext_ext`) để khớp đúng 1-đối-1 API Python thật.

## Mục tiêu

Thêm `path_splitext(p) -> (str, str)`, dùng được qua
`root, ext = path_splitext(p)`.

## Kiến trúc

### 1. `path_splitext(p)` trong `stdlib_path.py`

```
ext = Path.GetExtension(p)
root = p.Substring(0, p.Length - ext.Length)
return (root, ext)   # ValueTuple<string,string>
```

Cần 2 local ẩn (`p`, `ext`) khai qua `temps_fn=` trên
`register_expr_builtin` — TÁI DÙNG cơ chế `declare_named`/first-pass đã
dùng cho `sample(lst,k)` (RandomSeed Task 3). Đăng ký:
```python
register_expr_builtin('path_splitext', compile_path_splitext, None,
                       temps_fn=_splitext_temps,
                       return_ta=TypeAnn('str', 'tuple', tuple_dtypes=['str', 'str']))
```
`EXPR_BUILTIN_RETURN_TA` (registry có sẵn trong `il_dispatch.py`) hiện
chưa từng dùng cho builtin trả `shape='tuple'`, nhưng cơ chế đã hỗ trợ
sẵn (`register_expr_builtin`'s `return_ta` param không giới hạn shape cụ
thể nào).

### 2. Mở rộng `tuple_assign` nhận diện builtin trả tuple (core)

Sửa `compiler/il_features/tuple_type.py`, 2 hàm:

- **`fpw_tuple_assign`** (nhánh `elif len(rhs_nodes) == 1`, dòng
  ~182-202): hiện `raise SyntaxError` nếu `call_node[1] not in
  func_table`. Thêm rẽ nhánh TRƯỚC khi raise: nếu
  `call_node[1] in EXPR_BUILTIN_RETURN_TA` VÀ
  `EXPR_BUILTIN_RETURN_TA[call_node[1]].shape == 'tuple'`, dùng
  `tuple_dtypes` từ đó thay cho `callee.return_type.tuple_dtypes`, phần
  còn lại (khai `declare_named` cho từng target + local tạm) giữ
  NGUYÊN logic.
- **`codegen_tuple_assign`** (nhánh `elif len(rhs_nodes) == 1`, dòng
  ~111-128): TƯƠNG TỰ — nếu không phải hàm người dùng, tra
  `EXPR_BUILTIN_RETURN_TA` lấy `tuple_dtypes`, phần `compile_expr` +
  `stloc`/`ldfld Item1..N` giữ NGUYÊN (đã tổng quát, không phụ thuộc
  nguồn hàm là user function hay builtin).

Đây là core touch NHỎ, tái dùng được cho bất kỳ builtin trả tuple nào
sau này (hiện chỉ `path_splitext` dùng, nhưng cơ chế không giới hạn 1
builtin).

## Giới hạn đã biết, có chủ đích

File bắt đầu bằng dấu chấm không có phần mở rộng khác (`.bashrc`) —
`.NET Path.GetExtension` coi TOÀN BỘ tên file là extension (trả
`".bashrc"`), khác Python (`os.path.splitext('.bashrc')` →
`('.bashrc', '')`, không coi dấu chấm dẫn đầu là extension). Chấp nhận
được — giống các giới hạn hành vi khác đã ghi nhận trước đó (`re_findall`
với group con, `TkvStr::RFind`'s `sub=""`) — không xử lý riêng trong
batch này.

## Kiểm chứng

- Test mới: `path_splitext("a/b/file.txt")` → `("a/b/file", ".txt")`;
  `path_splitext("noext")` → `("noext", "")`; xác nhận
  `root, ext = path_splitext(p)` giải nén đúng qua cơ chế
  `tuple_assign` mở rộng.
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — 6 hàm `path_*` cũ
  và mọi lời gọi `tuple_assign` với hàm người dùng khác (nếu có test
  hiện hữu) không đổi hành vi.
- Cả 2 cây (`compiler/il_features/{stdlib_path,tuple_type}.py`/`.tkv`)
  sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
