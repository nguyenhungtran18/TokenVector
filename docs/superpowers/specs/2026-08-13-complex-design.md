# `complex` — Design

## Bối cảnh

DSL chưa có kiểu số phức. `System.Numerics.Complex` (struct, assembly
`System.Numerics`, KHÔNG phải `[mscorlib]` — xác nhận qua PowerShell
reflection `[System.Numerics.Complex].Assembly.FullName`) có sẵn:
ctor `(double, double)`, static `Add`/`Subtract`/`Multiply`/`Divide`
(4 tham số dạng `(Complex, Complex) -> Complex`), thuộc tính
`Real`/`Imaginary`/`Magnitude`/`Phase` (đọc qua getter instance
`get_Real()`/...), static `Abs(Complex) -> double`. Đây là mục 2/4
trong 6.8 (sau `frozenset`, commit `d47359d`).

## Mục tiêu

Thêm `complex` làm 1 DTYPE VÔ HƯỚNG MỚI (giống cách `int` BigInteger
được thêm trước đây — `IL_SCALAR['complex']`, xuất hiện trong
`DTYPES`/mọi bảng dtype hiện có) — `c = complex(re, im)` tạo giá trị,
`+`/`-`/`*`/`/` giữa 2 giá trị `complex` hoạt động đúng, `.real`/
`.imag`/`.magnitude` đọc được, `str(c)` in ra (định dạng mặc định của
.NET, không phải cú pháp Python `"3+4j"`).

## Kiến trúc

- **`IL_SCALAR['complex']`**: `'valuetype [System.Numerics]System.Numerics.Complex'`
  — cần thêm `.assembly extern System.Numerics` vào đầu file `.il`
  sinh ra (`tkv_compile.py`, giống `.assembly extern System.Core` đã
  có cho `HashSet<T>`) — CHỈ khi chương trình thật sự dùng `complex`
  (tránh assembly reference thừa nếu không dùng — kiểm tra cách
  `System.Core` hiện được thêm CÓ ĐIỀU KIỆN hay LUÔN LUÔN, làm theo
  đúng cách đó).
- **Constructor `complex(re, im)`**: 1 builtin nhận đúng 2 tham số
  `f64` (ép kiểu nếu truyền `i32`/literal nguyên, giống các builtin số
  khác), sinh `newobj instance void valuetype [System.Numerics]System.Numerics.Complex::.ctor(float64, float64)`.
  Gán vào biến MỚI (`c = complex(1.0, 2.0)`) suy dtype `complex` tự
  động (giống cách `int`/kết quả các builtin khác được suy qua
  `_infer_dtype`/`declare_scalar`).
- **Toán tử `+`/`-`/`*`/`/`**: thêm nhánh MỚI trong `compile_binop`
  (`operators.py`) khi `operand_dtype == 'complex'` — gọi
  `call valuetype [System.Numerics]System.Numerics.Complex System.Numerics.Complex::Add(valuetype ...Complex, valuetype ...Complex)`
  (tương tự cho `Subtract`/`Multiply`/`Divide`) — dùng STATIC method
  (không phải `op_Addition`), đơn giản hơn, không cần `ldloca` (nhận
  2 tham số BẰNG GIÁ TRỊ, không phải instance call).
- **`.real`/`.imag`/`.magnitude`**: 3 thuộc tính đọc-only trên biến
  `complex` — thêm vào `compile_attr` (`record_feature.py`, nhánh mới
  TRƯỚC nhánh record hiện có, khi `obj_ta.dtype == 'complex'`):
  `ldloca.s {var}` (struct cần ĐỊA CHỈ cho instance call, giống pattern
  đã xác minh trong `int_type.py`/`TkvInt`/`BigInteger`), rồi
  `call instance float64 valuetype [System.Numerics]System.Numerics.Complex::get_Real()`
  (tương tự `get_Imaginary()`/`get_Magnitude()`).
- **`str(c)`**: thêm nhánh `dtype == 'complex'` vào `emit_to_str`
  (`tkvstr.py`) — `ldloca.s {var}; call instance string valuetype
  ...Complex::ToString()` (KHÔNG cần `newobj`/format thủ công — dùng
  `ToString()` MẶC ĐỊNH của struct, cho ra `"(re, im)"`, GHI RÕ đây
  KHÔNG PHẢI cú pháp Python `"3+4j"` — giới hạn có ý thức, rẻ).

## Phạm vi

- KHÔNG hỗ trợ literal `3+4j` (cú pháp riêng của Python, cần thêm
  lexer/token mới — ngoài phạm vi, chỉ `complex(re, im)`).
- KHÔNG hỗ trợ `==`/`!=` giữa 2 `complex` (dù `Complex` có
  `op_Equality`, để dành cho sub-project riêng nếu cần — không phải
  yêu cầu tối thiểu của 6.8).
- KHÔNG hỗ trợ `complex` trong `list`/`dict`/`set` (container lồng
  kiểu `complex` — ngoài phạm vi, chỉ biến vô hướng đơn).
- KHÔNG hỗ trợ hàm lượng giác/mũ phức (`cmath.sin`, v.v.) — dù BCL có
  sẵn (`Complex.Sin`/`Exp`/...), ngoài phạm vi batch này.
- `str(c)` dùng định dạng `.ToString()` mặc định của .NET, không phải
  cú pháp Python.

## Kiểm chứng

- Test mới: `c = complex(3.0, 4.0)` — `.real`==3.0, `.imag`==4.0,
  `.magnitude`==5.0 (3-4-5 triangle, dễ verify). `a + b`/`a - b`/
  `a * b`/`a / b` giữa 2 `complex` — verify qua `.real`/`.imag` của
  kết quả (tính tay đối chiếu). `str(c)` không crash (không cần khớp
  định dạng chính xác).
- Regression: `int`/`f64`/`i32`/`str` binop không đổi hành vi.
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
