# TÀI LIỆU THAM CHIẾU ĐẦY ĐỦ — TOKENVECTOR

> **Đây là file tham chiếu DUY NHẤT.** Trước đây có 3 file cùng nói một
> thứ (`REFERENCE.md` + `BUILTIN_REFERENCE.md` sinh tự động + `HAM_BUILTIN.md`)
> và chúng **mâu thuẫn nhau** — đã gộp lại 2026-10-02.
>
> **Cú pháp** = gõ thế nào. **Tính năng** = làm gì. Chỉ ghi những gì đã **probe
> thật** hoặc đọc thẳng từ mã nguồn compiler — không suy đoán. Khi một mục ghi
> *khác Python*, §5 nói rõ khác ở đâu.
>
> **Không đầy đủ thì gate sẽ báo.** Chạy `gen_builtin_ref.tkv --check`
> — FAIL nếu có tên đã đăng ký mà tài liệu này chưa đề cập.
>
> **Harness (agent) đừng đoán — hỏi tool.** `tools\tkv_guide.tkv` viết bằng
> chính TokenVector (không còn bản Python — hai bản trôi lệch nhau):
> `powershell -File tools\build_tkv_guide.ps1` rồi
> `dist\tkv_guide.exe rules | find <tên> | names | lint | verify <file>`.
> `verify` **in ra 2 lệnh** (build + chạy) vì TokenVector chưa có `subprocess`;
> phải chạy cả hai. Thêm `--file out.txt` để nhận UTF-8.
>
> **Quy ước kiểu** (chi tiết ở `CLAUDE.md`): `i32`/`i64`/`f32`/`f64`/`str` là kiểu
> vô hướng; `bool` là **bí danh của `i32`**; `int` là số nguyên vô hạn (struct
> `TkvInt`) — khác `i32` thật, trộn hai kểu gây type-confusion thật trong IL.
> **"Biến"** = tham số phải là *tên biến đã khai báo*, không phải biểu thức phức
> tạp — đây là giới hạn có thật của phần lớn hàm dưừng dưới.

## Mục lục

| # | Phần | Nội dung |
|---|---|---|
| [1](#1-ngôn-ngữ--cú-pháp-và-câu-lệnh) | Ngôn ngữ | Cú pháp câu lệnh, container, record |
| [2](#2-hàm-builtin--cú-pháp-và-tính-năng) | Hàm builtin | 185 hàm, cú pháp + tính năng + khác biệt Python |
| [3](#3-method-của-container-và-record) | Method | 28 method có kiểu + các method lệnh |
| [4](#4-dạng-dựng-giá-trị-vế-phải-của-phép-gán) | Dạng gán | 31 dạng vế phải được đăng ký riêng |
| [5](#5-còn-thiếu--đã-probe-không-phải-suy-đoán) | Còn thiếu | Giới hạn đã đo, không giới hạn do đoán |
| [6](#6-hướng-dẫn-dùng--cho-chỗ-khác-python) | Hướng dẫn dùng | 14 mục "ở đây khác Python, và vì sao" |
| [7](#7-danh-mục-đầy-đủ-sinh-tự-động) | Danh mục đầy đủ | 376 tên + danh sách file (sinh tự động) |

| [8](#8-ba-sự-cố-đã-ghi--đừng-tin-mù) | Ba sự cố | Những chỗ đã sai vì tin tài liệu |

---

## 1. NGÔN NGỮ — CÚ PHÁP VÀ CÂU LỆNH

### 1.1 Hàm gốc xử lý trực tiếp (không qua bảng đăng ký)

| Cú pháp | Chức năng |
|---|---|
| `print(x, …)` | In ra stdout, tự xuống dòng. Nhiều tham số được nối bằng dấu cách. |
| `len(c)` | Độ dài chuỗi / list / dict / set / bytes. |
| `range(a, b, c)` | Dải số, dùng với `for i in range(...)`. |
| `abs(x)` | Trị tuyệt đối. **Trên số phức sẽ báo lỗi biên dịch** (chưa hỗ trợ). |
| `round(x, n)` | Làm tròn. |

### 1.2 Câu lệnh điều khiển

| Dạng | Ghi chú |
|---|---|
| `if …:` / `elif …:` / `else:` | `elif` là từ khoá thật. |
| `while …:` / `else:` | `else` chạy khi vòng lặp **kết thúc không `break`**. `continue` không bỏ qua nó. |
| `for x in xs:` / `else:` | Chạy với `range(...)`, list/dict/set, generator, record (`__iter__`/`__next__`), và record khác để duyệt cặp. `for … else` chạy khi không `break`. |
| `break` / `continue` / `pass` | `break`/`continue` trong `else` của `try` **không** hợp lệ khi có `finally`. |
| `try` / `except E as e:` / `else:` / `finally:` | `else` chỉ chạy khi **không** handler nào khớp, và chạy **trước** `finally`. |
| `raise E(msg)` / `raise e` / `raise E(msg) from e` / `raise` | `raise <record tự định nghĩa>` luôn truyền tham số dạng `str`, nên ctor phải nhận `str`. |
| `with open(p, "r") as h:` | `with` tự `Dispose` trong `finally`. |
| `with ctx(...) as …:` | Quản lý tài nguyên chung. |
| `return` / `yield` / `yield from` | `yield from` chỉ nhận **biến list** hoặc **lời gọi hàm generator**. |
| `match` / `case` | Hạn chế (pattern matching chưa đầy đủ). |
| `del xs[i]` | **Không** hỗ trợ `del xs[i:j]`. |
| `import` | Dùng `__tkv_import__ = ["ten_file"]` (không dấu `.tkv`); `import`/`from … import` của Python bị bỏ qua. |

### 1.3 Container

| Loại | Khai báo | Ghi chú |
|---|---|---|
| list | `xs = [1, 2, 3]` | Chỉ dạng literal, toàn bộ vế phải phải là 1 dòng. Comprehension `[x*y for x in a for y in b if …]` chỉ khi là **toàn bộ** vế phải của phép gán ra **tên trần**. |
| dict | `d = {"a": 1}` | `{}` là dict rỗng (như Python). Khóa trùng giữ **giá trị cuối**. |
| set | `s = {1, 2, 3}` | Phần tử trùng bị loại, kiểu nâng lên float nếu có float. **Thứ tự không định.** `set()` là set rỗng. |
| tuple | `t = (1, 2)` | `ValueTuple` — **chỉ 2..7 phần tử**, không có indexer, không iterable bằng `iter()`. |
| bytes / bytearray | `b"abc"`, `bytes(3)`, `bytearray(n)` | `bytes` bất biến, `bytearray` sửa được. |
| str | `"abc"` | Chỉ dấu nháy kép. Không có chuỗi 3 dấu nháy. |

### 1.4 Record

| Quy tắc | Nội dung |
|---|---|
| Khai báo | `class P:` rồi khai **field có kiểu ở thân class**, trước `__init__`. |
| `pass` | `pass` trong thân record **bị bỏ qua hoàn toàn**, cùng đường với docstring — nên `class B(A): pass` (lớp con không khai báo gì thêm) là hợp lệ, đúng như Python. Đóng 2026-10-12; trước đó cả hai compiler đều từ chối. Phạm vi: chỉ trong thân **record**; `pass` ở cấp module vẫn bị từ chối (module chỉ nhận def/class/HẰNG SỐ/biến có kiểu/`__tkv_import__`). Record chỉ có `pass` mà **không field nào** vẫn là lỗi biên dịch. |
| `__init__` | Phải nhận **đúng** các field đã khai. `Stub()` với field `value` sẽ lỗi. |
| Toán tử | `__eq__`/`__lt__`/`__gt__`… phải khai `-> "i32"` (hoặc `"bool"`) **và nằm trong thân class**. Dunder đặt ở cấp module **không được đăng ký** → `a == b` rơi về so sánh tham chiếu, `a < b` báo lỗi sai nghĩa. |
| Field container | Xem §6.12 (Cửa A) — được gán **bên ngoài** constructor, nhưng phải được gán **ở đâu đó**. |

### 1.5 Đa luồng

`thread_spawn` / `thread_join` — native thread pooling, **không** có GIL.

---

## 2. HÀM BUILTIN — CÚ PHÁP VÀ TÍNH NĂNG

### 2.1 Chuyển đổi kiểu, phản chiếu, si, tra cứu

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `str` | `str(x)` | Chuyển số → chuỗi. **Nhận MỌI biểu thức** (đã probe 10/10: `str(a + b)`, `str(len(xs) + 1)`, `str(xs[0])`, `str(x > 0)` đều biên dịch và chạy đúng). `bool` → `"True"`/`"False"`. ~~Chỉ nhận 1 biến~~ — claim cũ **sai**, đã gỡ 2026-10-02. |
| `repr` | `repr(x)` | Như Python: chuỗi → thêm dấu nháy kép (`repr("a")` = `'"a"'`); số → giống `str()`; bool → `"True"`/`"False"`. |
| `format` | `format(v)`<br>`format(v, spec)` | `format(v)` == `str(v)`. `format(v, spec)` dịch spec Python sang định dạng .NET rồi gọi `ToString`. **Phải là chuỗi literal** (dịch lúc biên dịch). Ví dụ: `format(3.14159, ".2f")` → `"3.14"`. |
| `fmt_num` | `fmt_num(x, spec)` | Định dạng số bằng format string của .NET, dùng cho f-string `{n:05d}` / `{n:x}` / `{n:+}`. Spec phải literal. |
| `fmt_float` | `fmt_float(x, n)` | Làm tròn số thực, `n` chữ số thập phân (`.NET` dùng `"F<n>"`, không có dấu `.`). **`x` bắt buộc là 1 biến đơn** — `fmt_float(7.0, 2)` và `fmt_float(a + b, 2)` đều bị từ chối lúc biên dịch. Gán ra biến trước: `v = a + b; fmt_float(v, 2)`. |
| `int` | `int(x)` | Chuỗi → `i32`. Chuỗi ngoài `int32` **ném `OverflowException`** — dùng `int64()` cho số lớn. |
| `int64` | `int64(x)` | Bản 64-bit riêng: `str` → `i64` (nhận `"2147483648"` mà `int()` ném lỗi). Thay cho cách cũ "ép `int()` thành 64-bit". |
| `float` | `float(x)` | Chuỗi/số nguyên → `f64`. |
| `bool` | `bool(x)` | Trả `0`/`1` như Python. **Chỉ hỗ trợ biến số hoặc chuỗi literal** (giá trị xác định lúc biên dịch) — vì vậy hãy dùng `x != 0`. |
| `chr` | `chr(n)` | Mã → ký tự 1 chữ. |
| `ord` | `ord(s)` | Ký tự → mã. |
| `bin` | `bin(n)` | Số nguyên → chuỗi `"0b1010"` (tiền tố `0b` như Python). |
| `oct` | `oct(n)` | Số nguyên → chuỗi `"0o17"`. |
| `hex` | `hex(n)` | Số nguyên → chuỗi `"0xff"`. |
| `ascii` | `ascii(s)` | Ký tự > 127 viết dạng `\xNN`. **Chỉ nhận chuỗi literal** (tính lúc biên dịch); biến chuỗi sẽ phải quét từng ký tự lúc chạy nên chưa hỗ trợ. |
| `complex` | `complex(re, im)` | Số phức, **đúng 2 tham số** (không có dạng 1 tham số, không có literal `3+4j`). |
| `f32x4` | `f32x4(a, b, c, d)` | Vector 4 lane `f32`, **đúng 4 tham số**, cả 4 ép về `f32`. Không có literal dạng `f32x4(1,2)`. |
| `type` | `type(obj)` | Kiểu của biến. Trả `System.Type`, **luôn** là `"type"` (không phụ thuộc đối tượng). |
| `isinstance` | `isinstance(obj, T)` | `obj` phải là biến (thứ 2 là tên kiểu/lớp). |
| `issubclass` | `issubclass(A, B)` | Cả 2 phải là tên class. |
| `callable` | `callable(x)` | `1` nếu là hàm, `0` nếu không. TokenVector là AOT nên **trả lời lúc biên dịch**. |
| `dir` | `dir(obj)` | Danh sách tên trường + method của record. Sinh sẵn lúc biên dịch (`List<string>`), vì compiler buộc phải biết record trước. |
| `id` | `id(x)` | Số nguyên danh tính qua `RuntimeHelpers.GetHashCode`. **Không cam khi ổn định giữa 2 lần chạy** (Python cũng vậy). Tham số phải là biến — `id(3)` vô nghĩa nên từ chối. |
| `hash` | `hash(x)` | Số nguyên → chính nó; chuỗi **literal** → FNV-1a 64-bit. **Khác Python** (Python dùng SipHash có khoá muỗi tiến trình) nên dùng được làm khoá/kiểm tra nhưng **không** dùng để khớp số với Python. Biến chuỗi/container chưa nhận. |
| `getattr` | `getattr(o, "field")`<br>`getattr(o, "field", default)` | Đọc field của record với **kiểu thật** (suy qua `return_dtype_fn`). Tên field phải chuỗi literal. Thiếu field → lỗi biên dịch. Bản 3 tham số trả `default` nếu thiếu. |
| `hasattr` | `hasattr(o, "field")` | `1`/`0`. |
| `setattr` | `setattr(o, "field", v)` | Gán field. Tên literal. `o` phải là biến. |
| `delattr` | `delattr(o, "x")` | **Cố ý báo lỗi biên dịch.** Field của record là field của *struct* trong IL, số lượng/vị trí đã chốt lúc biên dịch — xoá 1 field mà giữ nguyên phần tử sẽ hỏng IL. Dùng `del xs[i]` cho container. |
| `eval_arith` | `eval_arith(expr)` | Tính biểu thức số học từ chuỗi (thêm ngoặc/số, `+ - * /`). 1 tham số. |
| `eval_expr` | `eval_expr(expr)`<br>`eval_expr(expr, name=v, ...)` | Đánh giá biểu thức, **có thể kèm biến** dạng keyword. Tham số đầu phải là biểu thức chuỗi, không được keyword. |
| `eval_code` | `eval_code(code_str)` | `eval` chuỗi mã, trả giá trị biểu thức. |
| `exec_code` | `exec_code(code_str)` | `exec` chuỗi mã. |

---

### 2.2 Toán học & số

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `math_pi` | `math_pi()` | Hằng số π (`f64`). Ngôn ngữ không có cú pháp `module.attr` nên hằng số được đặt thành hàm 0 tham số. |
| `math_e` | `math_e()` | Hằng số e. |
| `math_gcd` | `math_gcd(a, b)` | ƯCLN, thuật toán Euclid, **trả tuyệt đối** (khớp `math.gcd`). |
| `atan2` | `atan2(y, x)` | `atan2` góc. **Thứ tự tham số giống Python**: y trước, x sau. |
| `hypot` | `hypot(x, y)` | `sqrt(x² + y²)`. **Không** dùng `System.Math::Hypot` — không tồn tại trong .NET Framework 4.8 (đã probe bằng file `.il` riêng: `ilasm` **không** báo lỗi lúc assemble, chỉ ném `MissingMethodException` khi chạy). |
| `factorial` | `factorial(n)` | Giai thừa, dtype giữ nguyên của `n`. Chỉ `i32`/`i64`. |
| `pow` | `pow(x, y)` | `x ** y`. **Đường số nguyên là số nguyên chính xác** (không qua `System.Math::Pow` vốn là float và làm sai ở số lớn — đã từng đối chiếu: `3**38` lệch với CPython). |
| `divmod` | `divmod(a, b)` | Trả cặp `(thương, phần dư)`. `a` phải là **biến** đã khai báo `i32`/`i64`. |
| `functools_clamp_i32` | `clamp_i32(val, lo, hi)` | Chặn `i32` trong khoảng. |
| `functools_clamp_f64` | `clamp_f64(val, lo, hi)` | Chặn `f64` trong khoảng. |

---

### 2.3 Tổng hợp, sắp xếp, lặp

> Nguồn của các hàm này phải là **1 biến** `list`/`set`/`frozenset` (đọc `TypeAnn`
> từ `scope` cần một *tên*). `xs[0:2]` hay `f(xs)` phải gán ra biến trước.

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `sum` | `sum(xs)`<br>`sum(xs, start)`<br>`sum(xs, key=f)` | Tổng. Tham số 2 là **giá trị khởi tạo** (biểu thức bất kỳ), không phải tham số thứ hai của list — khớp Python. `key=` là **mở rộng của TokenVector** (CPython `sum()` không có `key`); nó cộng tổng **khóa**. |
| `min` | `min(xs)`<br>`min(xs, key=f)`<br>`min(a, b, c, …)` | Nhỏ nhất. `key=` trả về **phần tử** (không phải khóa) và giữ phần tử **đầu** khi trùng khóa. Dạng 2+ tham số là macro ở tầng văn bản → biên dịch thành ternary lồng nhau. |
| `max` | `max(xs)`<br>`max(xs, key=f)`<br>`max(a, b, c, …)` | Như `min`. Danh sách rỗng → `ArgumentOutOfRangeException` **lúc chạy** (không giả lập `ValueError` như Python). |
| `any` | `any(xs)` | Có phần tử *truthy* không. Phần tử falsy = bằng 0. |
| `all` | `all(xs)` | Tất cả phần tử *truthy*. |
| `sorted` | `sorted(xs)`<br>`sorted(xs, key=f)`<br>`sorted(xs, reverse=b)`<br>`sorted(xs, key=f, reverse=b)` | Trả **list mới**, không sửa `xs`. `reverse=` **chưa được đánh giá lúc biên dịch** (rẽ nhánh lúc chạy) nên `reverse=flag` chạy đúng như Python. `key` phải là tên hàm; kiểu trả về phải so sánh được (cho phép thêm `str`). **Không ổn định khi trùng khóa** (khác Python). |
| `reversed` | `reversed(xs)` | **Khác Python**: Python trả iterator, TokenVector trả **list bản sao đã đảo chiều** (ngôn ngữ chưa có iterator). Dùng được cho cả `for v in reversed(xs):` và `ys = reversed(xs)`. Không sửa `xs`. |
| `most_common` | `most_common(c, n)` | `n` cặp `(khóa, số lần)` phổ biến nhất. `c` phải là 1 biến `Counter`. Chỉ dùng được ở vị trí `pairs: "list[(K,V)]" = most_common(c, n)` — không suy được dtype phần tử từ vế phải. |
| `iter` | `it = iter(xs)` | Tạo con trỏ. **Chỉ ở vị trí gán** (cần tên biến đích để đặt tên biến ẩn) — `next(iter(xs))` là lỗi biên dịch. Nguồn: `list`, `set`, `frozenset`, `dict` (**khóa**), `str` (**chuỗi 1 ký tự**). Không hỗ trợ `tuple` (`ValueTuple` không có indexer). Xem `REFERENCE.md` §6.12. |
| `next` | `next(it)`<br>`next(it, default)` | Trả phần tử kế và tăng con trỏ. Hết dữ liệu: `next(it)` **ném `StopIteration`**, `next(it, default)` trả `default` (chỉ tính ở nhánh hết). `default` phải **cùng dtype** phần tử. Cũng dùng được như lệnh độc lập (`next(it)` một dòng) để chỉ tăng con trỏ. |
| `enumerate` | `pairs: "list[(i32,T)]" = enumerate(xs)` | Cặp `(chỉ số, giá trị)`. Bắt buộc khai báo kiểu tường minh; nguồn phải là `list` phần tử vô hướng có kiểu cố định (không dùng list literal không kiểu vì dtype là `int`/`TkvInt`, lệch layout IL của tuple). |
| `zip` | `pairs: "list[(A,B)]" = zip(a, b)` | Ghép theo vị trí, **chỉ 2-ary**, lấy `min(len(a), len(b))`. |
| `chain` | `chain(a, b)` | Nối 2 list (dạng biểu thức). |
| `product` | `product(a, b)` | Tích lũy nhân các phần tử (dạng biểu thức). |
| `combinations` | `combinations(a, r)` | Tổ hợp. Dạng biểu thức; `a` phải là 1 biến list. |

---

### 2.4 Hàm bậc cao

Tham số hàm **chỉ nhận TÊN** — một biến kiểu `func` đã khai báo, hoặc tên hàm
top-level. Không nhận lambda tại chỗ vì lambda thân không mang kiểu, mà kiểu tham
số/trả về của nó chỉ suy được từ một `TypeAnn` "mục tiêu" biết trước.

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `map` | `out = map(f, xs)` | Áp `f` lên từng phần tử → list mới. Chữ ký `f` phải khớp dtype phần tử. |
| `filter` | `out = filter(f, xs)` | Giữ phần tử mà `f` trả **0/1** (giá trị truthy). |
| `reduce` | `out = reduce(f, xs[, init])` | Gộp lần lượt. |

---

### 2.5 Chuỗi, bytes, CSV, XML

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `bytes_from_string` | `bytes_from_string(s)` | Chuỗi → `bytes` (mảng byte). |
| `string_from_bytes` | `string_from_bytes(b)` | Ngược lại. |
| `csv_parse_line` | `csv_parse_line(line, sep)` | Tách 1 dòng CSV → `List<string>`. |
| `csv_read_lines` | `csv_read_lines(path)` | Đọc cả file → `List<string>`. |
| `csv_join_row` | `csv_join_row(fields, sep)` | Ngược lại của `csv_parse_line`. |
| `csv_write_lines` | `csv_write_lines(path, lines)` | Ghi list dòng ra file, trả `i32`. |
| `xml_encode_name` | `xml_encode_name(s)` | Escape tên để đưa vào XML. |
| `struct_i32_to_hex` | `struct_i32_to_hex(val)` | `i32` → chuỗi hex byte-order nhị phân (để đọc/ghi file nhị phân). |
| `struct_f64_to_hex` | `struct_f64_to_hex(val)` | `f64` → hex theo **bit pattern** IEEE-754. |
| `read_ansi` | `read_ansi(p, off, n)` | Đọc n byte từ con trỏ native, giải mã ANSI/ASCII. Khác `bstr_read` là không ném lỗi khi con trỏ 0. |

---

### 2.6 File, đường dẫn, OS

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `read_file` | `read_file(path)` | Đọc **toàn bộ** file thành chuỗi. Chuẩn hoá kết thúc dòng như Python: `\r\n` và `\r` đều thành `\n` (đã đo: CPython đếm 600 token, `File.ReadAllText` đếm 698 — nguyên nhân là không chuẩn hoá). |
| `file_exists` | `file_exists(p)` | `1`/`0`. |
| `path_exists` | `path_exists(p)` | Kiểm tra **cả file lẫn thư mục** (khớp `os.path.exists`). Gọi `File.Exists` lẫn `Directory.Exists` — .NET Framework không có hàm duy nhất như `Path.Exists` của .NET 6+. |
| `path_isfile` | `path_isfile(p)` | Chỉ file. |
| `path_isdir` | `path_isdir(p)` | Chỉ thư mục. |
| `path_join` | `path_join(a, b)` | Nối 2 đường dẫn. **Chỉ 2 tham số** (Python `os.path.join` nhận số lượng bất kỳ). |
| `path_basename` | `path_basename(p)` | Tên file. |
| `path_dirname` | `path_dirname(p)` | Thư mục cha. |
| `path_name` | `path_name(p)` | Thành phần cuối của đường dẫn. |
| `path_stem` | `path_stem(p)` | Tên file bỏ phần mở rộng. |
| `path_suffix` | `path_suffix(p)` | Phần mở rộng, có dấu chấm. |
| `path_splitext` | `path_splitext(p)` | Trả cặp `(gốc, phần mở rộng)`. **Khác Python:** file bắt đầu bằng dấu chấm không có đuôi khác (`.bashrc`) bị coi là **có** extension — vì `Path.GetExtension` của .NET vậy; chấp nhận sự khác biệt này. |
| `path_parent` | `path_parent(p)` | Thư mục cha (bản pathlib). |
| `path_abspath` | `path_abspath(p)` | Chuẩn hoá + nối với thư mục làm việc nếu là đường dẫn tương đối. Khớp 1:1 với `os.path.abspath` (đã đối chiếu). |
| `path_normpath` | `path_normpath(p)` | Chuẩn hoá `.`/`..` (không nối với thư mục làm việc). |
| `path_read_text` | `path_read_text(p)` | Đọc cả file thành chuỗi. **Không giữ handle → không khoá file.** |
| `path_write_text` | `path_write_text(p, s)` | Ghi đè file. |
| `os_getenv` | `os_getenv(name)` | Đọc biến môi trường. |
| `os_mkdir` | `os_mkdir(p)` | Tạo thư mục. |
| `os_list_files` | `os_list_files(p)` | Liệt kê file trong thư mục → `List<string>`. |
| `os_remove` | `os_remove(p)` | Xoá 1 file. **Trả 1 nếu xoá, 0 nếu không tồn tại** — không ném lỗi (dùng được để test tự dọn dữ liệu). |
| `sys_argv` | `sys_argv()` | `List<string>` tham số dòng lệnh. **Chỉ hỗ trợ tham số vô hướng** (`i32 i64 f32 f64 str`) — chưa có quy ước serialize container. |
| `zip_create` | `zip_create(folder, zip_path)` | Nén thư mục ra file zip. |
| `zip_extract` | `zip_extract(zip_path, folder)` | Giải nén. |
| `db_open` | `db_open(path)` | Mở SQLite, trả handle `i64`. |
| `db_exec` | `db_exec(handle, sql)` | Chạy SQL không trả dòng. |
| `db_query_text` | `db_query_text(handle, sql)` | Truy vấn, trả cột đầu tiên dạng chuỗi (cột `NULL` → chuỗi rỗng). |
| `db_query_int` | `db_query_int(handle, sql)` | Như trên, dạng số nguyên. |
| `db_close` | `db_close(handle)` | Đóng. |

> **Chỉ dùng ở vị trí gán (không phải hàm gọi được):** `shutil_rmtree(p)` và
> `win_gui(...)` được đăng ký ở nhóm *dạng phải phải của phép gán*, tức
> `shutil_rmtree = shutil_rmtree(p)` mới chạy được. Xem mục 7.

---

### 2.7 Nén, mã hoá, hash

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `base64_encode` | `base64_encode(s)` | Chuỗi → base64 (UTF-8 trước). |
| `base64_decode` | `base64_decode(s)` | Ngược lại. |
| `sha256_hex` | `sha256_hex(s)` | SHA-256 → chuỗi hex **thường**. |
| `md5_hex` | `md5_hex(s)` | MD5 → hex thường. Không dùng cho bảo mật — giữ ở đây để tương thích dữ liệu cũ. |

---

### 2.8 JSON, SQLite, ZIP

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `json_dumps` | `json_dumps(obj)` | Đối tượng → chuỗi JSON. |
| `json_loads` | `obj = json_loads(s)`<br>`obj = json_loads(s, Record)` | Chuỗi JSON → record. Bản 2 tham số chỉ định record đích; kiểu khai báo bên trái **phải khớp** record đó. |
| `json_get_str` | `json_get_str(json_text, key)` | Đọc 1 trường kiểu chuỗi **không cần parse toàn bộ** (dùng cho config lớn). |
| `cjson_parse` | `h = cjson_parse(s)` | Parse CJSON → handle `i64` (nhanh hơn `json_loads`, trả về handle thay vì đối tượng). |
| `cjson_get_str` | `cjson_get_str(h, key)` | Đọc trường chuỗi từ handle. |
| `cjson_get_obj` | `cjson_get_obj(h, key)` | Đọc trường object (trả handle con). |
| `cjson_delete` | `cjson_delete(h)` | Giải phóng handle. |

---

### 2.9 Mạng & HTTP

> Cú pháp của `http_get`/`http_post` là **ngoại lệ** so với `urllib` của Python:
> **URL đứng trước** và không có object `response` trả về — kết quả là chuỗi thô.

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `http_get` | `http_get(url)` | GET, trả chuỗi thân phản hồi. |
| `http_post` | `http_post(url, payload)` | POST. Muốn tự chọn Content-Type dùng `http_post_type`. |
| `http_post_type` | `http_post_type(url, payload, content_type)` | POST kèm Content-Type. |
| `http_put` | `http_put(url, payload, content_type)` | PUT. |
| `http_delete` | `http_delete(url)` | DELETE (không có thân yêu cầu). |
| `http_request` | `http_request(method, url, payload, headers)` | Tổng quát, 4 tham số. Tham số đầu **phải là chuỗi literal** (`"GET"`/`"POST"`/…) vì trình biên dịch cần biết trước có ghi thân yêu cầu hay không. |
| `http_server_generate` | `http_server_generate(port, length)` | Sinh nội dung server mẫu. |
| `socket_resolve_host` | `socket_resolve_host(host)` | Phân giải tên host → IP. |

---

### 2.10 Regex

> Dùng **.NET Regex**, không phải `re` của Python. Thứ tự tham số: **pattern trước,
> chuỗi sau** (giống `re`). Các hàm chỉ tìm ở **bất kỳ đầu nào** nên phải tự thêm
> `^`/`$` khi cần neo.

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `re_match` | `re_match(pattern, s)` | `IsMatch` ở **bất kỳ đầu nào** — khác Python (Python `re.match` neo đầu). Muốn neo đầu phải tự viết `^`. |
| `re_search` | `re_search(pattern, s)` | Tìm ở bất kỳ đầu nào — **đây mới là nghĩa gốc của Python `re.search()`**. |
| `re_fullmatch` | `re_fullmatch(pattern, s)` | Neo **cả hai đầu** (tự thêm `^…$`). Khớp `re.fullmatch`. |
| `re_sub` | `re_sub(pattern, repl, s)` | Thay thế toàn bộ. |
| `re_split` | `re_split(pattern, s)` | Tách theo regex → `List<string>`. |
| `re_findall` | `re_findall(pattern, s)` | Các khớp → `List<string>` (lấy `.Value` của từng match). |
| `re_replace` | `re_replace(text, pattern, repl)` | **Thứ tự KHÁC**: chuỗi trước, pattern sau. Đây là bản BCL gọi thẳng `Regex.Replace`. |

---

### 2.11 Ngẫu nhiên

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `random` | `random()` | Số thực trong `[0.0, 1.0)`. |
| `randint` | `randint(a, b)` | Số nguyên trong `[a, b]` (**đóng hai đầu** như Python). |
| `randrange` | `randrange(a, b)` | Số nguyên trong `[a, b)` (**nửa mở**) như Python. Khác `randint`. |
| `uniform` | `uniform(a, b)` | Số thực trong `[a, b]`. |
| `choice` | `choice(lst)` | 1 phần tử ngẫu nhiên. `lst` phải là **biến** (dùng 2 tham chiếu riêng: 1 lấy `Count`, 1 lấy `Item`). |
| `sample` | `sample(lst, k)` | `k` phần tử ngẫu nhiên, **không mutate** `lst`. |
| `random_randint` | `random_randint(lo, hi)` | Bản BCL `Random.Next` — `[lo, hi)` (**khác** `randint`). |

---

### 2.12 Đa luồng, hệ thống, thời gian

| Hàm | Cú pháp | Tính năng / khác biệt Python |
|---|---|---|
| `thread_spawn` | `h = thread_spawn(fn_name)` | Chạy hàm top-level trên thread, trả handle. **Không** dùng `Thread`/`ThreadStart` (delegate `void` không có kênh trả giá trị) — dùng `Task<T>`. |
| `thread_join` | `v = thread_join(h)` | Chờ và trả **giá trị thật** của worker. Nếu không suy ra được kiểu thì mặc định `i64`. |
| `thread_sleep` | `thread_sleep(ms)` | Ngủ `ms` mili giây. |
| `multiprocessing_cpu_count` | `multiprocessing_cpu_count()` | Số lõi CPU. |
| `process_get_pid` | `process_get_pid()` | PID tiến trình. |
| `input` | `input()`<br>`input(prompt)` | Đọc 1 dòng từ console. |
| `datetime` | `datetime()` | **Trả thời điểm hiện tại** (`UtcNow`) và **không nhận tham số**. *Không cùng nghĩa với Python*: `datetime(2026, 9, 30)` ở Python tạo ngày đó, ở đây là lỗi biên dịch. |
| `datetime_ticks` | `datetime_ticks(d)` | Số tick của 1 mốc thời gian. |
| `datetime_add` | `datetime_add(d, td)` | Cộng khoảng thời gian. |
| `datetime_sub` | `datetime_sub(d, td)` | Trừ khoảng thời gian. |
| `datetime_diff` | `datetime_diff(d1, d2)` | Hiệu giữa 2 mốc. |
| `datetime_strptime` | `datetime_strptime(s, fmt)` | Chuỗi → mốc thời gian theo định dạng. |
| `asyncio_sleep_ms` | `asyncio_sleep_ms(ms)` | Ngủ không chặn (async). |
| `asyncio_get_ticks` | `asyncio_get_ticks()` | Số tick của vòng lặp async. |

---

### 2.13 Bộ nhớ native, FFI, SIMD

> **Cực kỳ nguy hiểm nếu dùng sai** — đều thao tác con trỏ thô (`i64` là *địa
> chỉ*, không phải số). Dùng khi nói chuyện với thư viện C hoặc dữ liệu nhị phân.

| Hàm | Cú pháp | Tính năng |
|---|---|---|
| `alloc_bytes` | `alloc_bytes(n)` | Cấp `n` byte trong heap native, trả con trỏ. |
| `free_bytes` | `free_bytes(p)` | Giải phóng. |
| `read_u8` | `read_u8(p, off)` | Đọc 1 byte. |
| `write_u8` | `write_u8(p, off, v)` | Ghi 1 byte. |
| `read_i32` | `read_i32(p, off)` | Đọc 4 byte. |
| `write_i32` | `write_i32(p, off, v)` | Ghi 4 byte. |
| `read_i64` | `read_i64(p, off)` | Đọc 8 byte. |
| `write_i64` | `write_i64(p, off, v)` | Ghi 8 byte. |
| `read_f32` | `read_f32(p, off)` | Đọc 4 byte float32. Không dùng `Marshal::ReadSingle` — **không tồn tại** trong .NET Framework 4.8 (đã kiểm bằng reflection). |
| `write_f32` | `write_f32(p, off, v)` | Ghi float32 nguyên bản (không ép qua `i32` — sẽ cắt exponent và sai số bit). |
| `bstr_alloc` | `bstr_alloc(s)` | Cấp BSTR (dùng allocator chuẩn của BSTR — `StringToBSTR`). |
| `bstr_free` | `bstr_free(p)` | Giải phóng BSTR. |
| `bstr_read` | `bstr_read(p)` | Đọc BSTR. **Khác `read_ansi`**: `PtrToStringBSTR` ném lỗi khi con trỏ 0 nên phải kiểm tra trước. |
| `vtable_cell` | `vtable_cell(fn)` | Gói con trỏ hàm thô (`i64`) vào 1 ô 1 mục. |
| `c_puts` | `c_puts(msg)` | P/Invoke `ucrtbase.dll!puts`. |
| `ctypes_cdll` | `ctypes_cdll(name)` | `LoadLibraryA`. |
| `ctypes_call` | `ctypes_call(...)` | Bọc lời gọi C. |
| `py_tuple_new` | `py_tuple_new(size)` | Tạo `List<object>` kiểu `PyTuple`. |
| `py_dict_new` | `py_dict_new()` | Tạo `Dictionary<object, object>` kiểu `PyDict`. |
| `deque_reverse` | `deque_reverse(lst)` | Đảo list tại chỗ (tương đương `lst.reverse()`). |
| `deque_clear` | `deque_clear(lst)` | Xoá hết phần tử. |
| `reserve` | `reserve(lst, n)` | Đặt trước `Capacity` của `List<T>` (tránh nhân đôi ~7 MB cho buffer pixel lớn). Trả capacity mới nên dùng được cả như lệnh độc lập. |
| `v_load4` | `v_load4(p, off)` | Nạp 16 byte (4 lane) → `f32x4`. `off` tính theo **byte**. |
| `v_store4` | `v_store4(p, off, v)` | Ghi 4 lane. |
| `v_hsum4` | `v_hsum4(v)` | Gom 4 lane về 1 `f32`. **Thứ tự cộng là `((X+Y)+Z)+W`** — phải khớp đúng thứ tự của vòng scalar, nếu ghep cặp `(X+Y)+(Z+W)` thì sai số float. |
| `v_hsum` | `v_hsum()` | Tổng 8 lane, dùng ở dưới khối. Lưu ý IL: `ldfld` **pop** 1 phần tử (đối tượng) nên phải đẩy lại `ldloc` trước *mỗi* `ldfld` — đẩy 1 lần rồi `ldfld` 8 lần sẽ làm phần tử thứ 2 trở thành đối tượng và sinh `InvalidProgramException` lúc chạy. |
| `v_lane` | `v_lane(i)` | Rút lane `i`. **Chỉ hằng số 0..7** (đọc lane theo biến có nhánh động, mà đơn vị ở đây giống hệt "chỉ số hằng số" của `lst[-1]`, nên để hằng số). |
| `v_load8` | `v_load8(p, off)` | Nạp 8 lane (32 byte), trả lane 0. |
| `v_store8` | `v_store8(p, off)` | Ghi 8 lane, trả 0 (dùng như lệnh độc lập). |
| `v_fill8` | `v_fill8(x)` | Nạp cả 8 lane = `x` (broadcast). |
| `v_add8` | `v_add8(x)` | Mỗi lane `+= x`. |
| `v_sub8` | `v_sub8(x)` | Mỗi lane `-= x`. |
| `v_mul8` | `v_mul8(x)` | Mỗi lane `*= x`. |
| `v_mul8_add8` | `v_mul8_add8(x, y)` | Mỗi lane `= lane*x + y` — gộp 2 phép trong 1 lần ghi field. |

---

### 2.14 Đánh giá động

| Hàm | Cú pháp | Tính năng |
|---|---|---|
| `eval_arith` | `eval_arith(s)` | Biểu thức số học trong chuỗi. |
| `eval_expr` | `eval_expr(s)`<br>`eval_expr(s, name=v, …)` | Biểu thức có biến. |
| `eval_code` | `eval_code(s)` | `eval` mã. |
| `exec_code` | `exec_code(s)` | `exec` mã. |

---

### 2.15 GUI / ứng dụng ngoài

> Phần lớn là mã **riêng của dự án**, không phải API chuẩn Python.

| Hàm | Cú pháp | Tính năng |
|---|---|---|
| `launch_tms_gui` | `launch_tms_gui(db_path)` | Mở cửa sổ quản lý TMS. |
| `launch_tms_db_manager` | `launch_tms_db_manager(...)` | Mở trình quản lý CSDL. |
| `launch_tms_web` | `launch_tms_web(html_path)` | Mở giao diện web từ file HTML. |
| `launch_media_player_gui` / `media_player_gui_window` | `launch_media_player_gui(...)` | Mở cửa sổ trình phát media. |
| `win_gui` | *(chỉ ở vị trí gán)* | Cửa sổ Win32. |

---

## 3. Method của container và record

> **Method chỉ gọi được trên một BIẾN**, không gọi trên literal hay biểu thức phức
> tạp: `",".join(xs)` không được — phải `t = ","; t.join(xs)`.

### 3.1 `str` — 21 method

Tên ở đây ghi **đủ đường dẫn** (`str.strip`) để khớp với danh mục ở mục 7.

| Method | Tính năng |
|---|---|
| `str.upper` / `str.lower` | Viết hoa / viết thường toàn bộ. |
| `str.capitalize` | Viết hoa chữ cái đầu, hạ phần còn lại. |
| `str.strip` / `str.lstrip` / `str.rstrip` | Cắt khoảng trắng hai đầu / bên trái / bên phải. |
| `str.startswith` / `str.endswith` | Kiểm tra tiền tố / hậu tố. |
| `str.find` / `str.rfind` | Vị trí đầu tiên / cuối cùng; `-1` nếu không có (không ném lỗi như Python). |
| `str.split` | Tách theo dấu phân cách → `List<string>`. |
| `str.join` | Nối các phần tử của list bằng chuỗi này làm dấu phân cách. |
| `str.replace` | Thay chuỗi con. |
| `str.isdigit` | Toàn bộ là chữ số hay không. |
| `str.count` | Đếm số lần xuất hiện. |
| `str.title` | Viết hoa đầu mỗi từ. |
| `str.zfill` | Thêm số `0` ở trước cho đủ độ rộng. |
| `str.center` / `str.ljust` / `str.rjust` | Căn giữa / căn trái / căn phải trong bề rộng cho trước. |

### 3.2 `list` / `set` / `frozenset` / `dict` / `datetime`

| Method | Chủ thể | Tính năng |
|---|---|---|
| `list.copy` | `list` | Bản sao (không cùng tham chiếu). |
| `set.to_list` | `set` | Chuyển thành `List<T>`. |
| `frozenset.to_list` | `frozenset` | Chuyển thành `List<T>`. |
| `dict.keys` | `dict` | Trả **list mới** các khóa (không phải view như Python). |
| `dict.values` | `dict` | Trả list mới các giá trị. |
| `dict.items` | `dict` | Trả list cặp; dùng được trong `for k, v in d.items():`. |
| `datetime.strftime` | `datetime` | Định dạng thời gian. |

Ngoài ra `list` còn các method chuẩn `append` / `extend` / `insert` / `remove` /
`pop` / `clear` / `reverse` / `index` / `count` / `sort` (xem mục 7
và `REFERENCE.md` §3.3 — một số dạng là **lệnh độc lập**, không phải biểu thức):

```tokenvector
xs.append(v)          # lệnh độc lập
xs.sort(key=neg)      # decorate - sort - undecorate: KHONG on dinh khi trung khoa
ys = xs.copy()        # ban sao qua moi bien
```

### 3.3 Dunder của record

`__eq__`, `__lt__`, `__gt__`, `__add__`… **phải khai báo ở thân class** (thụt lề
đúng). Dunder đặt ở cấp module (không thụt lề) **không được đăng ký** → `a == b`
rơi về so sánh tham chiếu và `a < b` báo lỗi sai nghĩa. Toán tử trả về phải khai
`-> "i32"` (hoặc `"bool"`).

---

---

## 4. DẠNG DỰNG GIÁ TRỊ (VẾ PHẢI CỦA PHÉP GÁN)

Các dạng này được **đăng ký riêng cho vế phải phép gán** (31 dạng, xem §7) vì compiler cần biết kiểu container ngay từ câu lệnh gán.

| Cú pháp | Chức năng |
|---|---|
| `b"abc"` | Literal bytes (bất biến) |
| `bytes(n)` | `n` byte 0 |
| `bytes([1,2,3])` | Từ danh sách số |
| `bytes("s", "utf-8")` | Từ chuỗi literal (chỉ literal) |
| `bytearray(n)` | Mảng byte **sửa được** |
| `xs = [1, 2, 3]` | Danh sách |
| `d = {"a": 1}` | Từ điển |
| `s = {1, 2, 3}` | Tập hợp (`{}` là dict rỗng, như Python) |
| `frozenset()` | Tập hợp bất biến |
| `t = tuple_literal` | Bộ |
| `"ab" * 3` | Lặp chuỗi |
| `md5_hex(s)` / `sha256_hex(s)` | Băm chuỗi |
| `base64_decode(s)` | Giải mã Base64 |
| `os_getenv` / `os_list_files` / `os_mkdir` | (xem 2.6) |
| `shutil_rmtree(p)` | Xoá cây thư mục |
| `datetime()` | UtcNow |
| `f32buf_new(...)` | Bộ đệm f32 |
| `f32buf(n)` | Cấp `n` phần tử f32 trong heap native. **Chỉ local** — xem 2.7 |
| `f32buf_wrap` | `a = f32buf_wrap(p, n)` — mượn bộ đệm từ con trỏ `p` + độ dài `n`. **Không cấp phát**; `f32buf_free` **không** giải phóng nó. Cho phép vòng elementwise trong hàm có tham số được P6 vector hoá. Xem 2.7 |
| `f32buf_ptr` | `f32buf_ptr(a)` — con trỏ native của bộ đệm → `i64` |
| `f32buf_len` | `f32buf_len(a)` — số phần tử của bộ đệm → `i32` |
| `win_gui` | (cửa sổ Windows) |

---

Được **ghi đè để có dtype chính xác**, thay vì để compiler tự đoán:

| Dạng | Ví dụ |
|---|---|
| `list_new` / `list_call` | `xs = list()`, `ys = list(xs)` (bản **sao**) |
| `tuple_call` / `tuple_literal` | `t = tuple([1,2])`, `t = (1, 2)` — xem `REFERENCE.md` §5.3.1 (chỉ 2..7 phần tử) |
| `list_literal` / `dict_literal` / `set_literal` / `tuple_literal` | `xs = [1,2,3]` |
| `list_repeat` / `repeat_str` | `xs = [0] * 1000`, `pad = " " * n` |
| `list_slice` | `ys = xs[a:b]`, `ys = xs[a:b:step]` (step **dương**) |
| `list_count` | `n = xs.count(v)` |
| `iter_call` | `it = iter(xs)` — xem §3 |
| `open_call` | `f = open(p, "w")` |
| `bytes_new` / `bytes_literal` / `bytearray_new` | `b = bytes(3)`, `b = bytes("a", "utf-8")` |
| `dict_new` / `frozenset_new` / `frozenset_call` / `set_new` | `d = {}`, `fs = frozenset([1,2])` |
| `os_getenv` / `os_mkdir` / `os_remove` / `os_list_files` | `v = os_getenv("X")` |
| `base64_encode` / `base64_decode` / `md5_hex` / `sha256_hex` | `s = sha256_hex(t)` |
| `csv`-family, `f32buf_new`, `shutil_rmtree`, `win_gui` | xem mục 7 |

---

## 5. CÒN THIẾU — đã probe, không phải suy đoán

### 5.1 Exception: có **21**, Python có ~75

Probe bằng `raise X("x")` / `except X`.

| Có sẵn từ trước (6) | Thêm 2026-09-30 (15) |
|---|---|
| `Exception` `IndexError` `KeyError` `OverflowError` `ValueError` `ZeroDivisionError` | `TypeError` `AttributeError` `RuntimeError` `NotImplementedError` `MemoryError` `ArithmeticError` `EOFError` `OSError` `FileNotFoundError` `PermissionError` `IsADirectoryError` `NotADirectoryError` `ImportError` `StopIteration` |

**Cố ý KHÔNG thêm** (có lý do ghi trong `_EXC_TYPE_MAP`):

| Không thêm | Vì sao |
|---|---|
| `LookupError` | Là **cha** của `KeyError`/`IndexError`, mà bản đồ phẳng không biểu diễn được. Ánh xạ về `System.Exception` sẽ khiến `except LookupError:` bắt **mọi** lỗi — sai âm thàm. Dùng `except Exception:` hoặc tự định nghĩa |
| `AssertionError`, 9 lớp `Warning`, `SystemExit`, `KeyboardInterrupt`, `RecursionError`, `UnicodeError` + con, `ExceptionGroup` | Không có đối chiếu CLR, hoặc không bắt được (`RecursionError` là `StackOverflowException` — CLR không cho bắt). Gộp về `System.Exception` là bắt quá đà |
| `NameError` | TokenVector báo lỗi biến chưa khai báo ở **biên dịch**, không tồn tại lúc chạy |

Muốn có thêm thì tự định nghĩa: `class TypeError(Exception):` với field đầu
tiên kiểu `str` làm thông điệp.

> Đã sửa luôn lỗi thông điệp `IndexError`: `ArgumentOutOfRangeException(string)`
> gán vào `ParamName` chứ không phải `Message`, nên `str(e)` ra
> *"Parameter name: het rooc"* và `Message` rỗng. Nay dùng
> `.ctor(paramName, message)` với `("", msg)`.

### 5.2 Hàm Python có, TokenVector không có (đã probe với cú pháp đúng)

| Nhóm | Thiếu |
|---|---|
| Lặp | `aiter()`, `anext()` (đồng bộ `iter()`/`next()` **đã có** 2026-10-02, xem 6.12) |
| File | `open()` như hàm (chỉ dùng được trong `with open(...)`) |
| Khác | `slice()`, `breakpoint()`, `exit()`, `quit()`, `help()`, `eval()`, `exec()`, `compile()`, `super()`, `property()`, `globals()`, `locals()`, `vars()` |

Đã thêm 2026-09-30: `callable()`, `dir()`, `id()`, `hash()`, `ascii()`.
Đã thêm 2026-10-02: `iter()`, `next()` (nguồn: list/set/dict/str — xem 6.12).
`delattr()` **cố ý báo lỗi biên dịch** (xem 6.10).

### 5.3 Constructor container: thiếu một nửa

| Cú pháp | Trạng thái |
|---|---|
| `dict()` | **CÓ** |
| `set()` | **CÓ** |
| `bytes(n)` / `bytes([..])` | **CÓ** (thêm 2026-09-30) |
| `bytearray()` / `bytearray(n)` | **CÓ** — `bytearray(n)` thêm 2026-09-30 |
| `list()` / `list(ys)` | **CÓ** (2026-09-30). `list(ys)` là **bản sao** |
| `tuple([a,b,c])` / `tuple(t)` | **CÓ, nhưng khác Python** (2026-09-30) — xem 5.3.1 |
| `list([])` | Không nhận — tham số phải là **biến**. `list()` cho list rỗng |
| `frozenset()` / `frozenset([..])` / `frozenset(ys)` | **CÓ** (2026-09-30) |
| `object()` | **KHÔNG** |

### 5.3.1 `tuple()` — khác Python, vì khác kiến trúc

`tuple` của TokenVector **không** phải container biến độ dài. Nó là
`System.ValueTuple<T1..TN>` — **value type** với số phần tử **cố định 2..7**,
biết lúc biên dịch (`il_tupleN_type` từ chối N < 2).

| Dạng | Kết quả |
|---|---|
| `tuple([5, 6, 7])` | **CÓ** — độ dài biết lúc biên dịch nên đổi được |
| `tuple((4, 5))` | **CÓ** — tương đương `(4, 5)` |
| `tuple(t)` khi `t` là tuple | **CÓ** — trả chính `t` (Python cũng vậy) |
| `tuple()` rỗng | **Lỗi biên dịch** — arity 0 không biểu diễn được |
| `tuple(xs)` khi `xs` là biến list | **Lỗi biên dịch** — độ dài `xs` chưa biết |
| `tuple([1])` | **Lỗi biên dịch** — cần ít nhất 2 phần tử |

Đây là **xung đột thiết kế**, không phải thiếu công code — nên phải báo lỗi rõ
kèm gợi ý cách viết thay thế, không trả về thứ gì đó sai.

### 5.4 Lỗi chẩn đoán cần sửa

Gọi sai **dạng** báo *"ham 'X' khong ton tai"* dù tên có tồn tại:

```tokenvector
b = bytes("a")      # Loi: ham 'bytes' khong ton tai  <- SAI, bytes CO ton tai
b = bytes(3)        # OK
```

Thông điệp phải phân biệt "tên không có" với "dạng gọi sai". Đây chính là
lý do probe bằng một cú pháp cố định cho kết luận sai.

Ngoài ra: `except IndexError` có thể bắt phải `ArgumentOutOfRangeException`
của .NET (in *"Specified argument was out of the range of valid values."* thay
vì thông điệp đã `raise`) — cần kiểm lại ánh xạ lỗi.

### 5.5 Các hạng mục khác

| Hạng mục | Thực trạng |
|---|---|
| ~~`max/min/sum` với `key=`~~ | **Đã có** (2026-10-02) — xem 6.14 |
| Bước âm của lát `a[::-1]` | Bị từ chối (chỉ nhận bước dương) |
| `del xs[i:j]` | Không có (`del xs[i]` thì có) |
| `yield from` | Không có |
| Tham số keyword-only / positional-only | Không có |
| `Decimal` | Không tồn tại |
| `.year` / `.month` / `.day` trên datetime | Không có |
| `getattr` với tên field là **biến** | Không hỗ trợ — phải là chuỗi literal |
| `set`/`dict` có **field kiểu container** | **Đã cho phép** (2026-09-30, Cửa A): field container được gán **bên ngoài** constructor. Vẫn bị từ chối nếu **không được gán ở đâu cả**. Xem 6.12 |
| `*` / `**` unpacking tại call site | **Đã có** (`('star'|'star2', ...)`) |
| `divmod(a, b)` | Tham số phải là **biến**, không nhận literal |

### 5.6 Những thứ **không dùng được** trên `tkvc-tv.exe`

Đo bằng probe trực tiếp lên `dist\tkvc-tv.exe`.

| Mức độ | Mục | Triệu chứng |
|---|---|---|
| **Sai âm thầm** | `"%02x" % v` (có spec độ rộng/zero-pad) | in ra nguyên chuỗi `"%02x"` |
| Không đăng ký | `format(v, spec)` | `ham 'format' khong ton tai` |
| Không đăng ký | `isinstance(x, T)` | `ham 'isinstance' khong ton tai` |
| Không đăng ký | `callable`, `dir`, `ascii`, `delattr` | `ham ... khong ton tai` |
| Khác | `hash(v)` | **có**, nhưng là FNV-1a — dùng làm khoá thì được, **không tương thích giá trị** với Python |

**Dòng đầu tiên nguy hiểm nhất.** `%` với `%d`/`%s` thì **đúng**; chỉ hỏng
khi có spec độ rộng. Hỏng kiểu này **biên dịch vẫn xanh và exit 0** — chỉ sai
khi chạy:

```tokenvector
a = 65
s = "%02x" % a     # CPython: "41"   -> tkvc-tv in ra: "%02x"
```

Bởi vậy **không dùng `%` khi port code Python sang đường TokenVector.**
Thay bằng f-string — đã probe đúng:

```tokenvector
f"{a:02x}"         # -> "41"      DUNG
f"{a:05d}"         # -> "00065"   DUNG tren ca hai compiler
```

**Còn chạy đúng trên `tkvc-tv`** (đã probe từng cái, kể cả lúc chạy):
f-string kèm format spec, generator expression bên trong `join()`, `.format()`
trên chuỗi literal.

> `CLAUDE.md` từng ghi `format(v, spec)` "hoạt động" và `.format()` "được
> probe". Cả hai chỉ đúng với **bootstrap**. Với sản phẩm: `format()`
> không tồn tại. Đây là lần thứ hai một tuyên bố trong tài liệu hỏng vì
> được kiểm bằng compiler sai — hãy luôn probe `tkvc-tv`.

---

---

## 6. HƯỚNG DẪN DÙNG — CHO CHỖ KHÁC PYTHON

Đọc mục này trước khi viết code chuyển từ Python.

### 6.1 `datetime` — hoàn toàn khác

Python dùng `datetime(2026, 9, 30)` để **tạo ngày**. TokenVector **không có**
hàm đó.

| Việc | Python | TokenVector | Cách viết |
|---|---|---|---|
| Tạo ngày từ số | `datetime(2026, 9, 30)` | **không có** | `d = datetime_strptime("2026-09-30", "%Y-%m-%d")` |
| Giờ hiện tại | `datetime.now()` | `datetime()` | `d = datetime()` — **0 tham số** |
| Đọc thành phần | `d.year`, `d.month`, `d.day` | **không có** | `y = d.year` ✗ → dùng `strftime` |
| Định dạng | `d.strftime("%Y")` | **có** | `y = d.strftime("%Y")` |
| Ra số để tính | `d.timestamp()` | `datetime_ticks(d)` | `n = datetime_ticks(d)` |

**Vì sao:** `datetime` ở đây vật lý là **số ticks int64** (như
`System.DateTime.Ticks`). Số nguyên không có "thành phần năm/tháng" nên phải
quy đổi qua `strftime`. Đây là quyết định thiết kế, không phải thiếu hàm.

```python
# Python
d = datetime(2026, 9, 30)
print(d.year, d.month)      # 2026 9

```

```tokenvector
# TokenVector
d = datetime_strptime("2026-09-30", "%Y-%m-%d")
print(d.strftime("%Y"), d.strftime("%m"))    # 2026 09
```

### 6.2 `tuple` — số phần tử cố định

`tuple` là `System.ValueTuple<T1..TN>`, số phần tử **biết lúc biên dịch**
(2..7), không phải container biến độ dài.

| Việc | Python | TokenVector |
|---|---|---|
| Tạo | `t = (1, 2, 3)` | `t = (1, 2, 3)` — giống hệt |
| Chuyển từ list | `tuple(xs)` | `tuple([1, 2, 3])` — chỉ **list literal** |
| Rỗng | `tuple()` | ✗ — dùng `()`? không có; dùng list `[]` |
| Độ dài động | `len(t)` | ✗ — dùng `len()` trên list |

Nếu cần độ dài không cố định, dùng `list`. Xem `list(xs)`.

### 6.3 `set` / `frozenset` — không lấy được theo chỉ số

Giống Python: set không subscript. Muốn duyệt, chuyển sang list trước.

```tokenvector
s = {3, 1, 2}
for v in s:            # thứ tự KHÔNG xác định, như Python
    print(v)

xs = s.to_list()       # chuyển sang list để lấy theo chỉ số / sắp xếp
xs.sort()
```

### 6.4 `bytes` — bất biến, `bytearray` — sửa được

```tokenvector
b = b"abc"                  # bất biến
b2 = bytes("héllo", "utf-8")   # chỉ chuỗi LITERAL
b3 = bytes([1, 2, 3])
n = bytes(5)                # 5 byte 0
a = bytearray(3)            # sửa được
a.append(65)                # OK
b.append(66)                # ✗ LỖI BIÊN DỊCH - bytes bất biến
```

`bytes(<biến chuỗi>, "utf-8")` **không hỗ trợ** (đường chạy chưa có).
Chuỗi phải là literal.

### 6.5 `format` — spec phải là literal, giá trị phải là biến hoặc số

```tokenvector
n = 42
a = format(n, "05d")        # OK
b = format(3.14159, ".2f")  # OK (số literal)
c = format(3.14159, ".2f")  # OK
d = format(a + b, ".2f")    # ✗ - phai gan bien truoc:
t = a + b                   #    t = a + b; format(t, ".2f")
```

Spec không dịch được sang .NET (`","`, `">"`, `"<"`, `"^"`) sẽ **báo lỗi biên
dịch** chứ không đoán.

### 6.6 Exception — chỉ 21 loại, và bản đồ phẳng

Dùng `try/except/else/finally` như Python. Nhưng:

- Chỉ có 21 loai (mục 5.1). Loại khác phải tự định nghĩa.
- **Không có phân cấp.** `except KeyError` không bắt được lỗi cha. Dùng
  `except Exception` để bắt rộng.
- `FileNotFoundError` và `ImportError` cùng ánh xạ về một kiểu .NET, nên
  `except` cái này cũng bắt cái kia. Đừng dựa vào phân biệt.

### 6.7 Method container là **câu lệnh**, không phải biểu thức

```tokenvector
xs.append(1)          # OK - dạng câu lệnh
y = xs.pop()          # ✗ - pop() chỉ là CÂU LỆNH, không phải biểu thức
n = len(xs)           # OK
```

Nếu cần giá trị trả về, tách ra biến:
```tokenvector
last = xs[len(xs) - 1]   # thay cho xs.pop()
```

### 6.8 SIMD — dùng thay vì lặp tay

```tokenvector
v = f32x4(1.0, 2.0, 3.0, 4.0)
w = v_add8(v, v)        # cộng từng phần tử
s = v_hsum(v)           # tổng ngang
```
Đây là phần mở rộng so với Python, không thay thế gì.

### 6.9 `getattr` / `setattr` — tên field phải là literal

```tokenvector
o = Pt(1, "a")
v = getattr(o, "x")        # OK
n = "x"
w = getattr(o, n)          # ✗ - phai la chuoi LITERAL
```

Đường đọc động theo tên biến chưa có: tên field là quyết định lúc biên dịch.

### 6.10 Hàm phản chiếu — khác Python ở đâu

| Hàm | Python | TokenVector |
|---|---|---|
| `callable(f)` | `True`/`False` | Trả `i32` nên in `"1"`/`"0"` — **cùng nghĩa** |
| `dir(o)` | 32 tên (kể cả `__init__`, `__class__`…) | Chỉ tên TokenVector có: **tru��ng + method của record** |
| `id(x)` | Số định danh | `RuntimeHelpers.GetHashCode` — **không cam k�ết ổn định** giữa 2 lần chạy (Python cũng vậy) |
| `hash(42)` | `42` | `42` — **giống hệt** |
| `hash("abc")` | `-2654188841952103486` (SipHash) | `-1792535898324117685` (**FNV-1a**) |
| `ascii("abc")` | `"'abc'"` | `"'abc'"` — giống |
| `delattr(o, "x")` | Xoá field | **Lỗi biên dịch** |

### 6.11 `open()` — có dạng hàm (2026-09-30), nhưng có một giới hạn thật

TokenVector **có** `open(path, mode)` dùng như hàm, trả về handle cùng kiểu với
`with open(...)` nên `.read()` / `.write()` / `.close()` hoạt động y hệt:

```tokenvector
p = "C:/Windows/Temp/t.txt"
f = open(p, "w")
f.write("abc")
f.close()

g = open(p, "r")
s = g.read()
g.close()
```

`mode` phải là **chuỗi literal** `"r"` / `"w"` / `"a"` — compiler phải biết mode
lúc biên dịch để chọn `StreamReader` hay `StreamWriter`. Không nhận `"rb"`,
`"wb"`, `"r+"`.

### `close()` — **ĐÃ SỬA 2026-10-02**, mở lại cùng đường dẫn là được

Trước đây tài liệu này ghi *"file vẫn bị khoá sau `.close()`"* và bảo tránh
mở lại. **Sai — và đó là bug thật, không phải giới hạn runtime.**

`f.close()` **luôn** phát `TextWriter::Dispose()`, nhưng handle mode `"r"` là
`StreamReader`, không phải `TextWriter` — nên lệnh đó **không giải phóng file**:

```tokenvector
g = open(p, "r")
s = g.read()
g.close()
f = open(p, "w")        # IOException: file đang bị dùng bởi tiến trình khác
```

**Build vẫn xanh, chỉ lỗi lúc chạy.** Nay `close()` chọn `TextReader::Close()`
hay `TextWriter::Close()` theo mode, giống hệt cách `.write()`/`.read()` đã làm.

Mọi cặp thao tác sau đều chạy đúng:

| Trình tự | Kết quả |
|---|---|
| `w` → đóng → `w` (ghi đè) | ✅ |
| `r` → đóng → `w` (ghi đè) | ✅ (trước: `IOException`) |
| `w` → đóng → `a` (ghi nối) | ✅ |
| `r` → đóng → `r` (đọc lại) | ✅ |
| `w` → đóng → `r` (đọc lại) | ✅ |

Ghim bằng `tests/open_function_test.tkv` — bài test đó trước đây **cố tình
chỉ mỗi đường dẫn một lần** để tránh bug; nay mở lại liên tục cùng đường dẫn.

Vẫn nên cân nhắc `path_write_text`/`path_read_text` cho code ngắn gọn, và
`with open(...)` khi file rất lớn (đọc dòng bằng `StreamReader`, không nạp hết
vào RAM).
không có kiểu riêng nên `h.read()` không dispatch được. Thay vào đó **hai chức
năng đó đã có sẵn ở dạng hàm**, dùng được ngay:

| Python | TokenVector | Ghi chú |
|---|---|---|
| `f = open(p, "r")` rồi `f.read()` | `s = path_read_text(p)` | đọc **toàn bộ** file thành chuỗi |
| `f = open(p, "w")` rồi `f.write(s)` | `path_write_text(p, s)` | ghi đè |
| `f = open(p, "a")` rồi `f.write(s)` | `s = path_read_text(p)`<br>`path_write_text(p, s + noi_moi)` | đọc rồi ghi lại |
| `os_remove(p)` | `os.remove(p)` | Xoá 1 file. **Trả 1** nếu xoá, **0** nếu file không tồn tại — **không** ném lỗi |
| `os.path.exists(p)` | `file_exists(p)` hoặc `path_exists(p)` | |

```python
# Python
f = open("t.txt", "w")
f.write("hello")
f.close()
```

```tokenvector
# TokenVector
path_write_text("t.txt", "hello")
```

**Khi nào vẫn nên dùng `with open(...)`:** khi file **rất lớn** — `path_read_text`
nạp hết vào RAM, còn `with open(...)` đọc dòng bằng `StreamReader`. Với file
nhỏ, `path_read_text` gọn hơn nhiều.

### 6.12 `iter()` / `next()` — **ĐÃ CÓ** (2026-10-02)

```tokenvector
xs = [10, 20, 30]
it = iter(xs)
a = next(it)              # 10
b = next(it)              # 20
d = next(it, -1)          # 30
e = next(it, -1)          # -1  (het du lieu -> default)
```

`next(it)` khi hết dữ liệu **ném `StopIteration`** (bắt được bằng
`except StopIteration as err:`).

**Vì sao dùng được — đo, không đoán.** `next()` cần *con trỏ tiến*: một giá trị
thay đổi mỗi lần gọi. Ngôn ngữ tĩnh kiểu không có biến "thay đổi kiểu", nên
**TRIZ: tách con trỏ khỏi container** — `iter(xs)` cấp phát **2 biến ẩn**
(hidden local) đặt tên theo **tên biến đích**:

| Tên ẩn | Kiểu | Vai trò |
|---|---|---|
| `__itsrc_it` | `List<T>` (đúng `TypeAnn` của nguồn) | tham chiếu list |
| `__itpos_it` | `i32` | con trỏ |

Biến `it` tự nó là **một local `i32`** làm "token" — đọc nó không có nghĩa gì
(khác Python, nơi nó là một object).

Đặt tên theo **tên biến** chứ không phải `id(node)` như mọi `temps_fn` khác là
điểm mấu chốt: `next(it)` chỉ nhìn thấy *tên* `it`, không nhìn thấy node của
`iter()` đã biên dịch xong. Nếu đặt theo `id(node)` thì `next()` không tìm ra
con trỏ nào.

Với nguồn là `list`, `__itsrc_it` giữ **cùng một tham chiếu `List<T>`** với
nguồn, nên `xs.append(...)` giữa chừng vẫn được thấy (giống Python). `a = iter(xs)`
và `b = iter(xs)` cho hai con trỏ độc lập.

#### Nguồn nào được nhận (2026-10-02)

Mọi nguồn đều được **chuẩn hoá thành `List<T>`** lúc `iter()` chạy, nên `next()`
chỉ phải biết một hình dạng duy nhất:

| Nguồn | `next(it)` trả về | Cách chuẩn hoá |
|---|---|---|
| `list` | phần tử | giữ nguyên tham chiếu (thấy cả thay đổi giữa chừng) |
| `set` / `frozenset` | phần tử, **thứ tự không định** | `new List<T>(HashSet<T>)` — 1 lệnh |
| `dict` | **KHÓA** (đúng nghĩa Python) | duyệt `GetEnumerator()` dồn `get_Key()` vào list |
| `str` | **chuỗi 1 ký tự** | vòng lặp `Substring(i, 1)` dồn vào list |
| `tuple` | — | **không hỗ trợ** |

`iter("abc")` cho `'a'`, `'b'`, `'c'`; `iter({"a":1})` cho `'a'` — không phải giá
trị.

**Vì sao `tuple` không hỗ trợ:** tuple của TokenVector là `ValueTuple` — một
**value type không có indexer**, đọc `t[i]` bằng CIL không được. Duyệt tuple đã có
đường riêng: `for x in t:` (đã hỗ trợ).

#### Vì sao `iter()` không chạy được ở cấp module

Không phải thiếu mã — **cấp module của TokenVector không có biến nào**:
`tkv_compile` chỉ nhận hàm/class, hằng số, và biến `global` có kiểu vô hướng
(`counter: "i32" = 0`); một phép gán `xs = [1, 2, 3]` ở cấp module bị từ chối
(*"gap Assign o dong N"*). Mà `iter()` lại **bắt buộc** nhận một *tên biến* (để
đặt tên biến ẩn theo) — nên ở cấp module không tồn tại cách nào gọi được nó.
Dùng trong hàm là cách duy nhất.

#### Giới hạn còn lại — đã probe, không suy đoán

| Trường hợp | Kết quả |
|---|---|
| `iter()` chỉ ở **vị trí gán** `it = iter(<tên biến>)` | `next(iter(xs))` → lỗi biên dịch rõ (xem `tests/negative/iter_in_expression.tkv`) |
| Nguồn là `tuple` | lỗi biên dịch rõ (xem `iter_on_tuple.tkv`) |
| `default` **phải cùng dtype** với phần tử | `next(list[i32], "")` → lỗi biên dịch. Python tự nâng rộng kiểu; TokenVector không (một biến chỉ giữ một kiểu, và 2 nhánh của một biểu thức phải cùng kiểu) |
| Không chia sẻ qua `copy`/truyền hàm | `next` chỉ nhận **tên biến** |
| `StopIteration` **cùng loại với `RuntimeError`** | cả hai ánh xạ `[mscorlib]System.InvalidOperationException`, nên `except RuntimeError:` sẽ **bắt** phải `StopIteration`. Muốn phân biệt "hết dữ liệu" thì dùng `next(it, default)` |

#### Lịch sử: từ "không làm được" tới làm được

Bản cũ của mục này ghi *"chưa có, đây là lý do **thật**"*, dựa trên hai kết luận
sai đã được đo lại:

1. *"Record không thể chứa field kiểu container"* — **sai.** `.ctor` chỉ *lọc*
   container khỏi danh sách tham số; gán trong `__init__` vẫn chạy.
2. *"Cần sinh lớp runtime mới trong IL"* — **không cần.** Xem bảng 2 biến ẩn ở
   trên.

**Nguyên nhân gốc thật** (tìm bằng `--emit-il`): `records[name]` lọc container
khỏi tham số `.ctor`, còn `__init__` khai tham số cho field `src` → chữ ký lệch
nhau → đối số container bị đưa vào ô `pos`:

```il
ldloc.s 0                                                  ; xs (List<TkvInt>)
call valuetype TkvInt TkvInt::ToI64(valuetype TkvInt)     ; bien LIST thanh so
newobj instance void It::.ctor(int64)                      ; truyen vao tham so `pos`
```

Đây là **biên dịch sai mà không báo lỗi**. Nay đã chặn ở **hai** tầng:

- `tests/negative/next_default_wrong_dtype.tkv` và các test còn lại chặn phía
  người dùng;
- `_expr_call` (il_codegen) chặn phía compiler: đối số container bị zip nhầm vào
  field vô hướng giờ **báo lỗi** thay vì phát sinh `TkvInt::ToI64(container)`.

**Cửa A (2026-09-30)** là tiền đề: field container **được gán bên ngoài
constructor**.

```tokenvector
class It:
    src: "list[int]"      # CHU Y: list[int], khong phai list[i32] - xem duoi
    pos: "i32"

    def __init__(self, start: "i32"):
        self.pos = start

it = It(0)                # .ctor chi nhan field VOHUONG
it.src = xs                # container gan muon, ben ngoai constructor
it.pos = 0
```

- Quy tắc cũ *"field container phải được gán trong `__init__`"* đã đổi thành
  **"phải được gán ở đâu đó"** (`_check_container_fields_assigned` trong
  `tkv_compile.tkv`, quét **toàn bộ** AST). Field nào không được gán ở đâu cả vẫn
  bị từ chối — `tests/negative/record_container_uninit.tkv`.
- **Cảnh báo kiểu:** khi nguồn là *list literal* thì phải khai `list[int]`
  (dtype `int` → struct `TkvInt`), **không** phải `list[i32]` (int32 thô). Trộn hai
  kieu này gây type-confusion *thật* trong IL sinh ra — đã xác nhận bằng thực
  nghiệm, không chỉ lý thuyết. `list[i32]` chỉ đúng khi nguồn là **tham số hàm**
  khai `xs: "list[i32]"`.

### 6.13 Dọn rác sau khi build / chạy

**Trước 2026-09-30 TokenVector không xoá được file nào.** `shutil_rmtree` chỉ xoá
*cây thư mục*. Hậu quả cụ thể: test `open_equivalent_test.tkv` ghi file tạm ra
thư mục repo rồi **không xoá được** — phải đổi cả đường đi vào TEMP để lách,
và file rác đã lỡ được commit vào git.

Nay có `os_remove(p)`:

```tokenvector
p = "C:/Windows/Temp/cong.txt"
path_write_text(p, "abc")
ok = os_remove(p)          # 1 - da xoa
again = os_remove(p)       # 0 - khong con, KHONG nem loi
```

**Khác Python một chỗ:** `os.remove` của Python **ném `FileNotFoundError`** khi
file không tồn tại. `os_remove` trả `0`. Chọn vậy để vùng dọn dẹp không cần
bọc `try/except` và chạy lại nhiều lần vẫn an toàn — chấp nhận khác Python để
đổi lấy sự tiện lợi cho việc dọn rác.

**Quy tắc cho người viết test:** file tạm phải nằm trong **TEMP** và được
`os_remove()` **ngay trong test**. Đừng để lại file trong repo — `testkit_gate.ps1`
cố tình ghi kết quả ra TEMP để một lần chay không làm bẩn repo; test tự tạo file
trong repo thì phá vỡ nguyên tắc đó.

`for v in xs:` đã hoạt động và là cách dùng thay thế cho phần lớn mã Python.
Để có `iter()`/`next()` thật sự cần một **kiểu iterator** mà compiler phải biết
dispatch `__next__` trên đó — đụng vào cơ chế method/type dispatch lõi. Chưa
làm. Nếu cần lấy phần tử kế tiếp theo chỉ số:

```tokenvector
v = xs[i]           # tương đương next() khi đã biết chỉ số
for v in xs:        # tương đương iter()
    ...
```

**`hash()` chuỗi KHÔNG khớp Python** và đây là chủ ý:
- .NET `String.GetHashCode()` **bị ngẫu nhiên theo tiến trình** — cùng một chuỗi sẽ ra số khác giữa 2 lần chạy. TokenVector dùng FNV-1a 64-bit nên **ổn định**.
- Dùng được để làm khóa/kiểm tra giữa các lần chạy. **Không** dùng để so số với Python.
- `hash()` chỉ nhận **chuỗi literal** (tính lúc biên dịch) hoặc số nguyên. Biến chuỗi → lỗi biên dịch.

**`delattr()` cố ý không chạy.** Field của record là field **của struct** trong IL, số lượng và vị trí đã chốt lúc biên dịch. Xoá một field mà giữ nguyên phần tử sẽ hỏng IL; bỏ qua thì sai nghĩa so với Python. Nên báo lỗi biên dịch kèm gợi ý `del xs[i]` cho container.

**Ghi chú thẳng thắn:** đường `ascii()` với ký tự > 127 **chưa được xác nhận** bằng file `.tkv`, vì byte UTF-8 của ký tự không ASCII phụ thuộc cách compiler đọc file. Test chỉ ghim phần ASCII. Đừng tin phần này khi chưa tự chạy.

**Giới hạn `hash()` với ký tự > 127 (2026-10-05, đã đo trên `tkvc-tv`).**

Bản TokenVector của `hash()` lấy `ord(ch)` trực tiếp, **không** đi qua
`s.encode('utf-8')` — vì trên đường TokenVector `.encode(...)` chỉ nhận biến
kiểu **record**, gọi trên chuỗi thì báo lỗi biên dịch. Hệ quả:

| Chuỗi | Kết quả |
|---|---|
| Thuần ASCII | **giống hệt** (1 byte = 1 ord) |
| Có ký tự > 127 | **khác** — TokenVector hash theo *code point*, không phải *byte UTF-8* |

`hash("abc")` kiểm chứng đúng: `0x0E71FA2190541574B` (vector chuẩn FNV-1a-64).
Nếu cần hash ổn định **và** phải khớp cả hai compiler, chỉ dùng chuỗi ASCII.

Lưu ý kỹ thuật: literal số nguyên TokenVector là số **không giới hạn**
(`struct TkvInt`), và phép `&` trên giá trị vượt `Int32` cắt cụt **đúng bằng
mod 2⁶⁴** (đã đối chiếu BigInteger). Nên `& 18446744073709551615` là mask
đúng cho FNV-1a-64. Không cần `int64()` cho việc này.

### 6.14 `key=` và `reverse=` (2026-10-02) — cho `min`/`max`/`sum`/`sorted`

```tokenvector
def neg(v: "int") -> "int":
    return 0 - v

xs = [3, 1, 2]
a = max(xs, key=neg)              # 1  (gia tri -1 la lon nhat)
b = min(xs, key=neg)              # 3  (gia tri -3 la nho nhat)
ys = sorted(xs, key=neg)         # [3, 2, 1] - LIST MOI, khong sua xs
zs = sorted(xs, reverse=True)     # [3, 2, 1]
```

**Đây là thứ CHƯA BAO GIỜ chạy được — và lý do sai hai lần.** `CLAUDE.md` và
bản cũ của mục này ghi *"`key=` hỏng ở **tầng parser**"*. Sai:

1. Parser **không** hỏng. `il_core._parse_one_call_arg` đã trả
   `('kwarg', ten, expr)` đúng cách từ 2026-08-28 (chính tài liệu cũ cũng
   ghi nhận điều đó rồi vẫn kết luận sai).
2. Thứ làm hỏng là **macro text-level `min`/`max`** trong `stdlib_aggregates.tkv`:
   nó chỉ **đếm dấu phẩy**, nên `max(xs, key=f)` bị viết lại thành
   `(xs > (key=f) ? xs : (key=f))` và parser báo lỗi trên `=`. Nay macro **nhận
   ra kwarg và từ chối việc phẳng** (`_has_kwarg`), để builtin xử lý.

#### Ngữ nghĩa — đã đối chiếu CPython

| Cú pháp | Kết quả |
|---|---|
| `max(xs, key=f)` / `min(xs, key=f)` | trả về **PHẦN TỬ**, không phải khóa (giống Python) |
| Trùng khóa | giữ **phần tử ĐẦU** (so sánh tuyệt đối) — giống Python |
| `sorted(xs, key=f)` | trả **list mới**, không sửa `xs` |
| `sorted(xs, reverse=<số/bool>)` | `reverse` **chưa được đánh giá lúc biên dịch**, rẽ nhánh lúc chạy → `reverse=flag` chạy đúng như Python |
| `sorted(xs, key=f, reverse=True)` | khoá tăng rồi đảo — giống Python |
| `sum(xs, key=f)` | **MỞ RỘNG, không có trong Python.** CPython `sum()` **không** nhận `key` (tra `TypeError`). TokenVector nhận và cộng tổng **KHÓA**; dtype kết quả là dtype của `f`, không phải dtype phần tử |

#### Ràng buộc — đã probe

| Ràng buộc | Vì sao |
|---|---|
| Nguồn phải là **1 BIẾN** `list`/`set` | giới hạn có sẵn của `sum/min/max/sorted` (đọc `TypeAnn` từ `scope` cần một *tên*) |
| `key` phải nhận **đúng 1 tham số** đúng dtype phần tử | nếu không, IL sai kiểu |
| Kiểu **trả về** của `key` phải so sánh được: `i32 i64 f32 f64 int bool` | `min/max/sum` phát `cgt`/`clt` trực tiếp; so sánh 2 chuỗi bằng cách đó là IL sai |
| `sorted` **được phép** khóa kiểu `str` | nó so sánh qua `List<ValueTuple<K,T>>.Sort()` của .NET, `ValueTuple` có sẵn `IComparable` theo K |
| `key` phải là **TÊN** (biến kiểu `func`, hoặc hàm top-level) | cùng giới hạn với `map(f, xs)`; không nhận lambda tại chỗ |
| Tên keyword sai / lặp lại → **lỗi biên dịch** | im lặng bỏ qua là loại sai âm thành nguy hiểm nhất: `max(xs, keyy=f)` sẽ biên dịch thành `max(xs)` và cho kết quả **đúng theo ý mình** |
| `min/max` **2+ tham số** vẫn là macro ternary | `max(a, b)` / `max(a, max(b, c))` không đổi |

**Không ổn định khi trùng khóa** (`sorted`, giống `.sort(key=)`): khác Python
dùng stable sort. Đã ghi ở phần `emit_sort_by_key`.

---

---

## 7. DANH MỤC ĐẦY ĐỦ (sinh tự động)

> Khối dưới do `gen_builtin_ref.tkv` ghi vào — **đừng sửa tay**.
> Dùng nó để kiểm tra "tên này đã có thật chưa" và để **không ghi đè file**
> khi tạo module mới trong `compiler/il_features/`.

<!-- BEGIN GENERATED: danh muc ten + danh sach file -->
### Danh muc ten da dang ky

**Dung de:** truoc khi **them mot ham**, **doi mot kieu** hay tao file
moi trong `compiler_bootstrap/compiler/il_features/`, kiem danh muc nay va
kiem tra file da ton tai chua. Da co mot lan: tao `bytes_type.tkv` de bo
sung ham `bytes()` nhung file do **da ton tai** va la module that cua
compiler - ghi de lam hong ca buoc bien dich.

**CANH BAO - co ten khong nghia la co dung duoc.** Muc nay lay tu
`register_*`, no chi chung minh *co entry dang ky*, KHONG chung minh
*tinh nang chay duoc den cuoi*. Hay **probe that** roi tin ket qua.

**DANG CAU LENH (MACRO CAP DONG) (37)**

`attr_assign` `break` `bytearray_append` `bytes_append_blocked` `container_clear` `continue` `del_index` `f32buf_free_stmt`
`for` `for_in_dict_items` `for_in_generator` `for_in_iter` `if` `index_call_stmt` `list_append` `list_extend`
`list_extend_expr` `list_insert` `list_remove` `list_reverse` `list_sort` `match` `multi_assign` `nested_def`
`pass` `raise` `return` `set_add` `set_discard` `set_remove` `try` `tuple_assign`
`while` `with_ctx` `with_open` `yield_from_stmt` `yield_stmt`

**DANG PHAI PHAI CUA PHE GAN (26)**

`base64_decode` `base64_encode` `bytearray_new` `bytes_literal` `bytes_new` `datetime` `dict_new` `f32buf_new`
`frozenset_new` `iter_call` `list_call` `list_count` `list_literal` `list_repeat` `list_slice` `md5_hex`
`open_call` `os_getenv` `os_list_files` `os_mkdir` `repeat_str` `set_new` `sha256_hex` `shutil_rmtree`
`tuple_call` `win_gui`

**DUNDER CUA RECORD (0)**


**HAM BUILTIN (GOI DUOC TRUC TIEP) (163)**

`__tkv_lap` `alloc_bytes` `ascii` `atan2` `atomic_add` `atomic_inc` `base64_decode` `base64_encode`
`bin` `bool` `bstr_alloc` `bstr_free` `bstr_read` `c_puts` `callable` `choice`
`chr` `cjson_delete` `cjson_get_obj` `cjson_get_str` `cjson_parse` `complex` `cpu_count` `ctypes_call`
`ctypes_cdll` `date_make` `date_today` `datetime` `datetime_add` `datetime_diff` `datetime_fromisoformat` `datetime_make`
`datetime_strptime` `datetime_sub` `datetime_ticks` `db_close` `delattr` `dict` `dir` `eval_arith`
`eval_code` `exec_code` `f32x4` `factorial` `file_exists` `float` `fmt_float` `fmt_spec`
`format` `free_bytes` `getattr` `hasattr` `hash` `hex` `http_delete` `http_get`
`http_post` `http_post_type` `http_put` `hypot` `id` `int` `int64` `isinstance`
`issubclass` `iter` `list` `lock_acquire` `lock_release` `math_degrees` `math_e` `math_gcd`
`math_isinf` `math_isnan` `math_log2` `math_pi` `math_radians` `md5_hex` `next` `oct`
`ord` `os_getenv` `os_list_files` `os_mkdir` `os_remove` `parallel_for` `path_abspath` `path_basename`
`path_dirname` `path_exists` `path_isdir` `path_isfile` `path_join` `path_name` `path_normpath` `path_parent`
`path_read_text` `path_stem` `path_suffix` `path_write_text` `pow` `proc_ra` `proc_run` `py_dict_new`
`py_tuple_new` `randint` `random` `random_randint` `randrange` `re_fullmatch` `re_match` `re_replace`
`re_search` `re_split` `re_sub` `read_ansi` `read_f32` `read_file` `read_i32` `read_i64`
`read_u8` `repr` `reversed` `set` `setattr` `sha256_hex` `simd_add` `simd_axpy`
`simd_dot` `simd_hw` `simd_isa` `simd_lanes_f32` `simd_lanes_f64` `simd_max` `simd_min` `simd_mul`
`simd_scale` `simd_sub` `simd_sum` `slice_step` `str` `str_maketrans` `sys_argv` `thread_id`
`thread_join` `thread_sleep` `thread_spawn` `time_perf` `time_sleep` `time_time` `timedelta_make` `type`
`uniform` `v_hsum4` `v_load4` `v_store4` `vtable_cell` `write_f32` `write_i32` `write_i64`
`write_u8` `xml_encode_name` `zip_extract`

**KIEU CAU LENH (SINH IL) (68)**

`assign_base64_decode` `assign_base64_encode` `assign_bytearray_new` `assign_bytes_literal` `assign_bytes_new` `assign_datetime_now` `assign_dict_new` `assign_f32buf_new`
`assign_frozenset_empty` `assign_frozenset_literal` `assign_frozenset_new` `assign_iter` `assign_list_count` `assign_list_from` `assign_list_literal` `assign_list_new`
`assign_list_repeat` `assign_list_slice` `assign_md5_hex` `assign_multi_target` `assign_open` `assign_os_getenv` `assign_os_list_files` `assign_os_mkdir`
`assign_repeat_str` `assign_set_new` `assign_sha256_hex` `assign_shutil_rmtree` `assign_tuple_identity` `assign_win_gui` `attr_assign` `break`
`bytearray_append` `call_stmt` `container_clear` `continue` `del_index` `f32buf_free_stmt` `for` `for_in_call_list`
`for_in_dict_items` `for_in_generator` `for_in_iter` `if` `index_call_stmt` `list_append` `list_extend` `list_extend_expr`
`list_insert` `list_remove` `list_reverse` `list_sort` `nested_def` `pass` `raise` `return`
`return_tuple` `sb_append` `set_add` `set_discard` `set_remove` `try` `tuple_assign` `while`
`with_ctx` `with_open` `yield_from_stmt` `yield_stmt`

**MACRO VIET TAY (59)**

`apply` `argmax` `assert` `attr_sau_goi` `binop_macro` `boolop_gia_tri` `comp_in_expr` `compound_attr`
`compound_index` `compound_var` `datetime_py` `dense` `deque` `dict_literal` `dict_or_set_comp` `dict_update`
`double_index` `enumerate_start` `expr_hoist` `for_chain` `for_enum_tuple` `for_enumerate` `for_in_kvlist` `for_in_list`
`for_in_ntuple` `for_tuple_literal` `for_zip` `fromkeys` `fstring` `genexp_call` `get_is_none` `hoist_agg`
`hoist_count` `is_none` `key_agg` `list_comp` `list_goi_ham` `map_filter` `math_dot` `math_ext`
`matvec` `minmax_2arg` `most_common` `multi_target` `next_genexp` `ngoac_dt` `normalize` `open_mode`
`ordereddict` `partition` `scale` `set_literal` `set_op` `slice_gan` `sort_lambda` `star_unpack`
`string_format` `string_percent_format` `unpack_split`

**METHOD CHUOI (qua dict STR_METHODS) (28)**

`str.capitalize` `str.casefold` `str.endswith` `str.find` `str.index` `str.isalnum` `str.isalpha` `str.isascii`
`str.isdecimal` `str.isdigit` `str.islower` `str.isnumeric` `str.isspace` `str.istitle` `str.isupper` `str.join`
`str.lower` `str.lstrip` `str.removeprefix` `str.removesuffix` `str.replace` `str.rfind` `str.rindex` `str.rstrip`
`str.startswith` `str.strip` `str.swapcase` `str.upper`

**METHOD CONTAINER (ten, dung chung nhieu kieu) (0)**


**METHOD THEO KHU VUC (39)**

`date.isoformat` `date.isoweekday` `date.strftime` `date.weekday` `datetime.date` `datetime.isoformat` `datetime.isoweekday` `datetime.strftime`
`datetime.weekday` `dict.items` `dict.keys` `dict.values` `file.readline` `file.readlines` `frozenset.to_list` `list.copy`
`match.end` `match.group` `match.groups` `match.start` `set.to_list` `str.center` `str.count` `str.finditer`
`str.join` `str.ljust` `str.match` `str.rjust` `str.rsplit` `str.search` `str.split` `str.splitlines`
`str.sub` `str.title` `str.translate` `str.zfill` `timedelta.total_seconds` `tuple.count` `tuple.index`

**Tong so ten da dang ky: 420**

### File trong `compiler_bootstrap/compiler/il_features/`

| File | Kich thuoc (ky tu) |
|---|---|
| `__init__.tkv` | 0 |
| `async_await.tkv` | 1919 |
| `bytearray_type.tkv` | 6280 |
| `bytes_type.tkv` | 13014 |
| `call_star_args.tkv` | 17460 |
| `chan_ly.tkv` | 4902 |
| `closures.tkv` | 19011 |
| `complex_type.tkv` | 8603 |
| `comprehension.tkv` | 76839 |
| `control_flow.tkv` | 145072 |
| `counter_type.tkv` | 19951 |
| `datetime_py.tkv` | 16213 |
| `datetime_type.tkv` | 11863 |
| `defaultdict_type.tkv` | 5799 |
| `dict_get.tkv` | 3226 |
| `dict_items_list.tkv` | 3958 |
| `dict_keys_values.tkv` | 4369 |
| `dict_pop.tkv` | 3322 |
| `dict_remove_keep.tkv` | 6840 |
| `dict_setdefault.tkv` | 2422 |
| `dict_type.tkv` | 45994 |
| `divmod_builtin.tkv` | 4746 |
| `duck_typing.tkv` | 25628 |
| `dynamic_exec.tkv` | 3839 |
| `expr_hoist.tkv` | 15585 |
| `f32buf_type.tkv` | 8886 |
| `ffi_feature.tkv` | 4089 |
| `file_io.tkv` | 18978 |
| `float_builtin.tkv` | 2767 |
| `for_in_kvlist.tkv` | 11848 |
| `fstring.tkv` | 11586 |
| `generator_feature.tkv` | 1428 |
| `generator_lazy.tkv` | 23903 |
| `int_builtin.tkv` | 11538 |
| `int_narrow.tkv` | 12146 |
| `int_type.tkv` | 38748 |
| `iter_next.tkv` | 19100 |
| `kwarg_resolve.tkv` | 4052 |
| `lap_chung.tkv` | 13469 |
| `list_copy.tkv` | 1880 |
| `list_count_index.tkv` | 7845 |
| `list_methods_batch2.tkv` | 20635 |
| `list_methods_batch3.tkv` | 2844 |
| `list_pop.tkv` | 2645 |
| `list_type.tkv` | 94201 |
| `logging_feature.tkv` | 4498 |
| `metaprogramming.tkv` | 23542 |
| `multi_assign.tkv` | 4710 |
| `nativebuf.tkv` | 12877 |
| `nested_array_extern.tkv` | 6442 |
| `operators.tkv` | 51740 |
| `pickle_feature.tkv` | 4680 |
| `print_feature.tkv` | 5703 |
| `process_feature.tkv` | 8202 |
| `pycapi_shim.tkv` | 3068 |
| `question_ternary.tkv` | 11088 |
| `record_feature.tkv` | 39894 |
| `regex_match.tkv` | 17477 |
| `set_methods_batch2.tkv` | 10306 |
| `set_to_list.tkv` | 3291 |
| `set_type.tkv` | 18201 |
| `simd_feature.tkv` | 33786 |
| `slicing.tkv` | 17277 |
| `stdlib_aggregates.tkv` | 43929 |
| `stdlib_base64.tkv` | 3892 |
| `stdlib_bcl.tkv` | 3333 |
| `stdlib_cjson.tkv` | 5622 |
| `stdlib_eval.tkv` | 10910 |
| `stdlib_functional.tkv` | 23462 |
| `stdlib_hashlib.tkv` | 4812 |
| `stdlib_http.tkv` | 12177 |
| `stdlib_http_full.tkv` | 15046 |
| `stdlib_input.tkv` | 1639 |
| `stdlib_itertools.tkv` | 7732 |
| `stdlib_itertools_expr.tkv` | 9856 |
| `stdlib_itertools_real.tkv` | 16775 |
| `stdlib_json.tkv` | 36316 |
| `stdlib_json_get.tkv` | 4565 |
| `stdlib_math.tkv` | 25031 |
| `stdlib_math_trig.tkv` | 1532 |
| `stdlib_os.tkv` | 7072 |
| `stdlib_path.tkv` | 19046 |
| `stdlib_pathlib.tkv` | 4128 |
| `stdlib_random.tkv` | 20376 |
| `stdlib_re.tkv` | 8994 |
| `stdlib_repeat.tkv` | 6326 |
| `stdlib_shutil.tkv` | 1883 |
| `stdlib_sqlite.tkv` | 12357 |
| `stdlib_str_translate.tkv` | 6348 |
| `stdlib_string_count.tkv` | 4573 |
| `stdlib_string_zfill.tkv` | 5286 |
| `stdlib_sys.tkv` | 3027 |
| `stdlib_xml.tkv` | 1438 |
| `stdlib_zipfile.tkv` | 3987 |
| `str_accum.tkv` | 12143 |
| `string_builtin.tkv` | 61655 |
| `string_feature.tkv` | 11032 |
| `string_format.tkv` | 10607 |
| `string_join.tkv` | 11394 |
| `string_methods_batch2.tkv` | 5535 |
| `string_methods_batch3.tkv` | 25926 |
| `string_methods_batch4.tkv` | 2900 |
| `string_methods_batch5.tkv` | 9135 |
| `string_percent_format.tkv` | 8738 |
| `string_split.tkv` | 11988 |
| `string_title.tkv` | 6181 |
| `threading_feature.tkv` | 14143 |
| `tkvstr.tkv` | 25486 |
| `tuple_methods.tkv` | 3844 |
| `tuple_type.tkv` | 44283 |
| `typecheck.tkv` | 7081 |
| `vector4_type.tkv` | 10308 |
| `win32_gui_window.tkv` | 2596 |

<!-- END GENERATED -->

---

## 8. BA SỰ CỐ ĐÃ GHI — đừng tin mù

1. **Có tên không có nghĩa là dùng được.** `datetime` có đủ đăng ký nhưng
   `datetime(2026, 9, 30)` từng biên dịch xanh rồi trả về **hôm nay**.
2. **Ngoài danh mục vẫn chạy đúng.** `with open(...)`, `sorted()`, `print`,
   `len`, `range`, `abs`, `round` không có trong 354 tên.
3. **Tài liệu cũ đã sai nhiều lần.** Biểu thức điều kiện `a if c else b`
   bị ghi là "không có" nhưng chạy đúng.

→ **Hãy probe thật.** Chạy `dist\bin\tkv_guide.exe verify <file.tkv>` — nó in ra
hai lệnh cần chạy (build rồi chạy). Đọc cả **output** lẫn **exit code**: build
xanh **không** bảo chứng giá trị đúng.
