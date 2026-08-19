# divmod() — Design

## Bối cảnh

Python `divmod(a, b)` trả tuple `(a // b, a % b)`. `docs/PYTHON_GAP_CHECKLIST.md`
dòng 152 đã xác nhận từ trước: `_DIVMOD_POW_HELPER` trong
`compiler/il_features/int_type.py` CHỈ là helper nội bộ cho toán tử
`//`/`%`/`**` trên kiểu `int` (số nguyên tùy ý), KHÔNG phải hàm
`divmod()` built-in trả tuple — gap thật, đây là mục cuối batch 5.5b.

`//`/`%` trên kiểu số nguyên CỐ ĐỊNH (`i32`/`i64`) đã có logic floor-đúng-
kiểu-Python (khác `div`/`rem` của CIL vốn cắt về 0) — implement trong
`compiler/il_features/operators.py`'s `_emit_int_floor_div_or_mod`, dùng
4 local tạm (`a`,`b`,`q`,`r`) khai qua `_walk_intdiv_nodes`
(`il_codegen.py`) — cơ chế first-pass RIÊNG cho node `binop`, khóa theo
`id(node)`.

`divmod()` là 1 lời gọi hàm (node `call`), không phải `binop`, nên
KHÔNG tái dùng trực tiếp được `_walk_intdiv_nodes`/`__idiv{id(node)}` —
cần viết lại logic floor-adjust (đã CHỨNG MINH ĐÚNG qua
`_emit_int_floor_div_or_mod`) trong 1 hàm mới, dùng cơ chế `temps_fn=`
(giống `path_splitext`/`sample` — batch trước).

Cơ chế giải nén tuple builtin (`x, y = f(...)`, mở rộng ở batch
`os.path.splitext()`) hiện chỉ hỗ trợ `EXPR_BUILTIN_RETURN_TA` CỐ ĐỊNH
(dtype không đổi theo tham số — đủ cho `path_splitext` luôn trả
`(str,str)`). `divmod(a,b)` cần dtype PHỤ THUỘC `a`/`b` (`i32` hoặc
`i64`) — cần mở rộng thêm `return_ta_fn` động.

## Mục tiêu

Thêm `divmod(a, b) -> (i32,i32)` hoặc `(i64,i64)` (tùy dtype của `a`),
dùng được qua `q, r = divmod(a, b)`.

## Kiến trúc

### 1. Mở rộng `register_expr_builtin` — `return_ta_fn` động

Sửa `compiler/il_dispatch.py`:
- Thêm registry `EXPR_BUILTIN_RETURN_TA_FN = {}` (cạnh
  `EXPR_BUILTIN_RETURN_TA` có sẵn).
- `register_expr_builtin` thêm tham số `return_ta_fn=None` — hàm
  `(args, scope) -> TypeAnn|None`, dtype PHỤ THUỘC tham số thực tế lúc
  gọi (khác `return_ta` cố định của `path_splitext`). Lưu vào
  `EXPR_BUILTIN_RETURN_TA_FN[name]` nếu có.

### 2. Mở rộng `tuple_assign` nhận diện `return_ta_fn` (core, tiếp tục
mở rộng từ batch `os.path.splitext()`)

Sửa `compiler/il_features/tuple_type.py`, 2 hàm (nhánh builtin đã có từ
batch trước, thêm 1 bước thử nữa TRƯỚC khi raise lỗi cuối):
- **`fpw_tuple_assign`**: nếu `EXPR_BUILTIN_RETURN_TA` không khớp, thử
  `EXPR_BUILTIN_RETURN_TA_FN.get(builtin_name)` — gọi
  `fn(call_node[2], infer_scope)`, nếu trả về `TypeAnn` với
  `shape=='tuple'` và đúng số lượng target, dùng `tuple_dtypes` từ đó.
- **`codegen_tuple_assign`**: TƯƠNG TỰ, gọi `fn(call_node[2], scope)`
  (real scope tại thời điểm codegen — cùng cấu trúc `[name] ->
  (kind, idx, ta)` như `infer_scope`, dùng được chung logic tra dtype).

### 3. `divmod(a, b)` trong file mới `compiler/il_features/divmod_builtin.py`

- **Giới hạn suy dtype**: tham số ĐẦU (`a`) PHẢI là 1 BIẾN đơn đã khai
  báo kiểu `i32`/`i64` (giống giới hạn `sample`/`choice` "chỉ nhận 1
  biến đơn", KHÔNG hỗ trợ biểu thức phức tạp) — dtype của `divmod` suy
  THẲNG từ dtype khai báo của biến đó.
- **`_divmod_dtype(args, scope)`**: helper dùng chung cho cả
  `return_ta_fn` VÀ `temps_fn`/`codegen` — trả `None` nếu `args[0]`
  không phải `var` hoặc chưa khai báo (raise `SyntaxError` rõ ràng ở
  điểm dùng thật, không raise ngay trong hàm suy dtype — giữ đúng quy
  ước `return_dtype_fn` khác trong codebase, trả `None` để caller tự
  quyết định raise).
- **`_divmod_temps(node, ctx)`**: khai 4 local ẩn `a`/`b`/`q`/`r` cùng
  dtype (suy qua `_divmod_dtype`, mặc định `i32` nếu không suy được —
  lỗi thật sẽ lộ ra ở `compile_divmod` khi thực sự codegen).
- **`compile_divmod(args, scope, out, dtype, ctx)`**: viết lại logic
  floor-adjust của `_emit_int_floor_div_or_mod` (đã chứng minh đúng qua
  `//`/`%` binop) — khác ở chỗ tính CẢ `q` VÀ `r` CÙNG LÚC (1 điều kiện
  điều chỉnh DÙNG CHUNG cho cả 2, không toggle theo `op` như bản gốc
  vì bản gốc chỉ cần 1 trong 2 giá trị mỗi lần gọi):
  ```
  q = a / b ; r = a rem b        # CIL div/rem, cat ve 0
  neu r != 0 VA (a XOR b) < 0:
      q = q - 1                   # floor adjust
      r = r + b                   # modulo adjust
  return (q, r)
  ```
  Chỉ hỗ trợ `i32`/`i64` (raise `SyntaxError` rõ ràng nếu dtype khác) —
  Python `divmod()` trên số thực dùng ngữ nghĩa khác (`math.floor`),
  ngoài phạm vi batch này.
- Đăng ký: `register_expr_builtin('divmod', compile_divmod, None,
  temps_fn=_divmod_temps, return_ta_fn=_divmod_return_ta_fn)`.

## Giới hạn đã biết, có chủ đích

- Chỉ `i32`/`i64` — không `f32`/`f64` (raise lỗi biên dịch rõ ràng).
- Tham số đầu PHẢI là 1 biến đơn (không biểu thức phức tạp) — giống
  tiền lệ `sample`/`choice`/`shuffle`.
- `b == 0` (chia cho 0): để `div`/`rem` của CIL tự ném
  `DivideByZeroException` — không tự viết message riêng (giống tiền lệ
  `sample`/`GetRange` để lỗi .NET tự nhiên, chấp nhận sai khác nhỏ với
  `ZeroDivisionError` của Python thật).

## Kiểm chứng

- Test mới: `divmod(a, b)` với `a`/`b` cùng dấu, khác dấu (kiểm tra
  đúng floor-adjust), `i32` và `i64`; đối chiếu `//`/`%` binop hiện có
  (phải cho CÙNG kết quả `q`/`r` như `a // b`/`a % b`).
- Regression toàn bộ `Testkit/*.tkv` qua cây `.py` — `//`/`%` binop cũ
  và `path_splitext`'s `tuple_assign` không đổi hành vi.
- Cả 2 cây (`compiler/il_features/{divmod_builtin,tuple_type}.py`,
  `compiler/il_dispatch.py`/`.tkv`) sửa đồng bộ.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.
