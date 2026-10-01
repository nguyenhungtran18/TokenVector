# BẢNG SO SÁNH ĐO ĐẠC: TOKENVECTOR VS CPYTHON 3.12

> **Ngày đo**: 2026-09-30 (đo lần 3) · **Cổng lúc đo**: 103/103 + negative 20/20
> **Cách đo**: `tools/parity_probe/` — 119 phép thử chạy song song trên cả hai
> bên, in ra cùng một danh sách nhãn, máy so từng dòng.
> Chạy lại: `powershell -File tools\parity_probe\run.ps1`

Bản trước của tài liệu này tự ghi "95%+ Parity" và khẳng định hỗ trợ `iter()`,
`next()`. Cả hai điều đó **không có cơ sở**: `iter`/`next` không hề tồn tại trong
compiler, và con số parity được đo lại ở đây.

Mốc đo lần 1: 102 phép, **95 khớp / 7 khác** — và cả 7 đều cho kết quả sai mà
không báo lỗi. Mốc đo lần 2 (bản này): 119 phép, **119 khớp / 0 khác**.

---

## 1. KẾT QUẢ ĐO

```
py: 119 dong, tv: 119 dong
entry tra ve: 0 (doc o runtime, khong so sanh voi py)
KHOP  : 119
KHAC  : 0
```

**119/119 phép thử cho kết quả giống hệt CPython.**

### 1.1 Sai lệch trong chính tài liệu lần 1 (đã sửa ở đây)

Bản lần 1 mục 4 ghi:

> `7 / 2` (→ `3.5`) — **Từ chối trên `i32`. Dùng `7.0 / 2` hoặc `//`**

**Điều đó sai.** Không có từ chối nào: `7 / 2` biên dịch xanh, chạy xanh, và
trả `3` — vì compiler dùng thẳng `div` của CIL (chia nguyên). Người đọc tài liệu
này sẽ tin là nó báo lỗi, và viết code dựa trên niềm tin đó. Đây là loại sai lệch
nguy hiểm nhất: **tài liệu sai theo hướng an toàn giả**, trong khi thực tế im lặng
ra số sai. Đã sửa ở commit hiện tại (`/` giữa hai số nguyên trả float), xem mục 3.

---

## 2. NHỮNG GÌ ĐÃ ĐO KHỚP (95)

| Miền | Nhãn đo được | Ghi chú |
|---|---|---|
| Số học | `div_floor`, `div_neg_floor`, `mod_neg`, `pow`, `fdiv`, `int_big`, `hex`, `oct`, `bin`, `sci`, `abs`, `minmax`, `round`, `int_from_str` | Kể cả số nguyên vượt int32 (`10^12`), hex/oct/bin, ký hiệu khoa học |
| Chuỗi | `upper`, `lower`, `len`, `find`, `find_miss`, `replace`, `strip`, `startswith`, `slicing`, `find_only`, `isdigit`, `format_pct`, `str_concat`, `in`, `cmp` | Cả so sánh `<` trên chuỗi |
| List | `append_len`, `sort`, `reverse`, `index`, `count`, `in`, `slice`, `del_item`, `extend`, `remove`, `max_min`, `sum`, `mutate_list` | `del` phần tử, `sort`, `reverse` |
| Dict/Set | `d_len`, `d_get`, `d_add`, `d_in`, `d_del`, `d_keys`, `set_len`, `set_discard`, `set_in` | `pop` trả về giá trị, giống Python |
| Comprehension | `comp`, `comp_if`, `comp_2for`, `dictcomp`, `setcomp` | Cả 3 loại, nhiều `for`, có `if` |
| HOF | `lambda`, `map`, `filter` | Xem mục 4 về cách truyền lambda |
| Điều khiển | `loop_break_cont`, `while`, `for_else`, `cond_ternary`, `cond_question` | Cả hai dạng biểu thức điều kiện, kể cả `c ? a : b` |
| Ngoại lệ | `exc_basic`, `exc_type`, `exc_else`, `exc_from`, `exc_finally`, `exc_custom_msg`, `exc_unmatched` | `try/except/else/finally`, `raise ... from`, ngoại lệ tự định nghĩa |
| OOP | `ctor_run`, `dunder_add`, `dunder_eq`, `dunder_str`, `dunder_len`, `method`, `inherit` | `__init__` **thật sự chạy** (xem `SESSION_HANDOFF.md` mục 0) |
| Hàm | `closure`, `default_arg`, `recursion`, `global_ok` | `nonlocal` cho biến bắt, đối số mặc định, `global` |
| Generator | `gen_ret`, `star_args`, `star_args_expand`, `kwargs`, `kwargs_expand`, `lambda_param` | `yield`, `yield from`, `f(*xs)`, `f(**kw)` |
| Kiểu | `list_identity`, `isinstance_like` | Container so sánh **theo tham chiếu** — giống Python |
| Chia / `int()` / float (nhóm 14) | `slash_int`, `slash_int_neg`, `slash_int_neglen`, `slash_lit`, `floordiv_after`, `int_lit_f`, `int_lit_f_neg`, `int_lit_whole`, `sci_small`, `sci_big`, `sci_edge`, `sci_rt`, `whole_dot`, `half`, `third` | Thêm ở vòng đo lần 2 — xem mục 3.2 |

---

## 3. NHỮNG GÌ ĐÃ TÌM RA VÀ XỬ LÝ

### 3.1 Đã sửa (mốc đo lần 1, 7 phép lệch)

Cả 7 phép lệch của mốc đo lần 1 đã được sửa và ghim bằng Testkit. Ghi lại đây vì
nguyên nhân gốc đáng nhớ:

| Lệch | Nguyên nhân gốc |
|---|---|
| `"a, b".split(", ")` bỏ phần còn lại của dấu phân cách | tách theo **ký tự đầu tiên** thay vì cả chuỗi |
| Generator truyền vào tham số `list[i32]` ra list rỗng | không materialize generator khi làm đối số |
| Lát `list[int]` truyền vào tham số `list[i32]` đọc rác | thiếu phép ép container, .NET nhận `List<TkvInt>` ở chỗ cần `List<int32>` |
| `str(bool biến)` ra `1`/`0` | biến bool mang giá trị i32 0/1 |
| `and`/`or` coi container rỗng là đúng | kiểm tra tính đúng chỉ dựa vào giá trị `0` |
| `str(1 and 2)` ra `True` | cùng gốc với dòng trên |

Bài học đã được ghim vào gate: cổng trước đó chỉ kiểm **đúng→sai**, nên cả 6 lỗi
này lọt qua. Nay có `Testkit/parity_pin_test.tkv` làm chiều **sai→đúng**.

### 3.2 Mới tì ra ở vòng ra soát lần 2 — cả 3 đều SAI ÂM THẦM

**(a) `/` giữa hai số nguyên trả số nguyên.** `7 / 2` → `3` (Python: `3.5`),
`-7 / 2` → `-3` (Python: `-3.5`). Compiler rơi thẳng xuống `div` của CIL. Sửa:
promote `i32`/`i64` → `f64` ở **cả** `_infer_dtype` và `compile_binop` — thiếu một
trong hai thì bên gọi vẫn yêu cầu `i64` và nhánh báo lỗi cũ chặn ngang.

**(b) `int(<hằng số thực>)` sinh IL không hợp lệ.** `int(3.9)` biên dịch thành
`ldc.i4 3.9`; `ldc.i4` chỉ nhận số nguyên nên `ilasm` báo
`syntax error at token '3.9'`. Qua biến thì đúng (`f = 3.9; int(f)` → `3`), vì
`_infer_dtype` trả `None` cho node `'num'`. Sửa ở `push_int_builtin`; thêm lưới an
toàn trong `_expr_num` để không chỗ nào phát ra `ldc.i4 3.9` nữa.

**(c) `str()` của float ở khoảng khoa học sinh chuỗi không parse được.**
`str(1e-7)` → `"1E-07"`, không có dấu chấm, nên đoạn vá `.0` nối thêm → `"1E-07.0"`.
`Double.Parse("1E-07.0")` ném `FormatException` — mất khả năng đọc lại. Gốc rễ là
một **giả định sai** trong chính compiler: comment cũ ghi "`ToString` không tự
chuyển sang dạng E trong khoảng giá trị thường gặp" — sai, ngoài `[1e-5, 1e16]` nó
luôn dùng dạng khoa học. Sửa: chỉ nối `.0` khi **không** có `.` và **không** có `e`,
và hạ chữ `E` cho khớp Python.

Ba lỗi này ghim bằng `Testkit/parity_div_float_test.tkv` (12 phép) và
`parity_probe` nhóm 14 (15 phép).

### 3.3 Vòng ra soát thứ 3 — đo lại toàn bộ, tìm 4 lỗi nữa

Vòng trước tôi kết luận từ một số phép đo rời rạc và đã **sai ba lần**. Vòng này
viết probe chạy song song với CPython trên ~40 phép, tách từng mảng.

**4 lỗi thật, đã sửa (đều là "biên dịch xong, chạy xong, ra sai"):**

| Lỗi | CPython | TokenVector (trước) | Nguyên nhân gốc |
|---|---|---|---|
| `str()` trên biến tuple | `"(5, 7)"` | `"5"` | `_infer_dtype` chỉ trả **dtype**, không trả shape. Biến tuple mang dtype của **phần tử đầu** (`int`) → nhánh `if dtype == 'int'` của `str()` gọi `TkvInt.Str`, đọc 4 byte đầu của `ValueTuple` |
| `str()` trên `list[int]` | `"[1, 2, 3]"` | **sập** `InvalidCastException` lúc chạy | **Cùng một nguyên nhân** — `list[int]` cũng mang dtype `int` |
| Escape: `\xNN`, `\uNNNN`, `\UNNNNNNNN`, `\0` | `"A"`, `é`, emoji, byte NUL | `"x41"`, `"U0001F600"`, **chuỗi rỗng** | Chuỗi đẩy thẳng ra `ldstr`, **escape do ilasm quyết định chứ không phải Python** |
| `x = 1` rồi `x = "abc"` | `"abc"` | **chuỗi rỗng**, exit code 0 | `ldstr` đẩy vào slot 4 byte của local i32 |

Escape **không** chỉ lệch nguyên tắc mà còn hỏng dữ liệu thật: `TokenVector.Data`
dùng `"\x01"` làm **dấu phân cách trường** khi gép group key. Vì ilasm không giải
mã, chuỗi đó là 4 ký tự `\x01` chứ không phải byte 0x01. Cả hai bên đều vậy nên
test vẫn xanh — nhưng dữ liệu chứa đúng chuỗi `\x01` sẽ bị cắt nhầm.

Vì vậy cách sửa là **giai mã escape trong compiler theo đúng quy tắc Python** và
phát ra literal đã an toàn hóa cho `ldstr` — không phải cấm. Sau khi sửa, toàn bộ
escape khớp CPython; riêng `\U0001F600` cho độ dài **2** vì chuỗi là UTF-16
(surrogate pair), xem mục 3.4.

Cả 4 lỗi giờ **báo lỗi biên dịch rõ ràng** (nguyên tắc "sai âm thầm nguy hiểm hơn
lỗi ồn ào"). Ghim bằng `Testkit/negative/str_tuple.tkv`,
`Testkit/negative/reassign_int_str.tkv`, `Testkit/rec_tuple_mb_test.tkv`,
`Testkit/str_escape_test.tkv`.

**Sai lần thứ tư — `len()`:**

Bản trước ghi "`len()` đếm byte UTF-8, in `7` cho `Tiếng`". Đo lại bằng **ký tự
thật** thay vì escape cho thấy: `len("café")` = 4, `len("Tiếng")` = 5, `len("日本語")`
= 3 — **khớp CPython ở mọi ký tự BMP**. Con số `9` từng gặp là do escape `\U`
**không được hỗ trợ**: ilasm bỏ dấu `\`, nên chuỗi thành literal `"U0001F600"` — đúng
9 ký tự.

Chế độ thật là **UTF-16** (`string` của .NET), nên lệch **chỉ ở ký tự ngoài BMP**:

| | CPython | TokenVector |
|---|---|---|
| `len("😀")` | 1 | **2** (surrogate pair) |
| `em[0:1]` với `em = "😀"` | cả ký tự | **nửa surrogate** |

Bài học lặp lại lần nữa: **một phép đo không đủ để kết luận cơ chế.** Phải đo
nhiều lớp (ASCII / 2 byte / 3 byte / 4 byte), và phải phân biệt "ký tự hỏng khi
hiển thị trên console" với "chương trình trả sai" — tôi từng đọc ký tự console
hỏng thành bug rồi báo bạn rằng cắt chuỗi đa byte hỏng, hoàn toàn sai.

### 3.4 Vòng đo 12 miền chưa có phép thử — tìm 3 lỗi, đã sửa

Mọi phép thử trước đều tập trung vào thư viện `num`. Vòng này dựng probe cho 12
miền **chưa từng** có phép thử nào, mỗi miền một cặp file `.tkv`/`.py` chạy
độc lập.

**Ba lỗi thật:**

| Lỗi | CPython | TokenVector (trước) | Nguyên nhân gốc |
|---|---|---|---|
| f-string với spec dạng số nguyên | `"00042"` | in ra chuỗi `"{n:05d}"` | Regex `\{(\w+)(:\.(\d+)f)?\}` chỉ khớp `{var}` và `{var:.Nf}`; spec khác **không khớp** nên cả f-string thành chuỗi thường và được phát nguyên văn |
| `int("123456789012345678901234567890")` | đúng số | **ném `OverflowException` lúc chạy** | Suy ra `i64` rồi emit `Int64::Parse`; giá trị là literal nên biết chắn vượt Int64 ngay lúc biên dịch — nay đi đường `TkvInt` (BigInteger) |
| `break` trong thân `try` khi có `finally` | `3` | **ném `InvalidProgramException` lúc chạy** | `br` thuần thoát khỏi vùng `.try` bảo vệ của `finally`; các guard sẵn chỉ chặn `break` trong `finally` và trong `else` |

Sau khi sửa: f-string hỗ trợ `d`/`x`/`X`, zero-pad `05d`, dấu `+`, `.Nf` — **khớp
CPython 7/7**; `int` vô hạn khớp 5/5; `break` trong `try`+`finally` báo lỗi biên
dịch rõ.

Đáng chú ý: khi dịch spec sang .NET tôi **đo trực tiếp trên máy** trước khi viết
code — `Int64(42).ToString(f)` cho `b`/`o` là **lỗi** (không tồn tại ở .NET), `n`
cho số nguyên ra `"42.00"`. Chỉ dựa vào trí nhớ về .NET thì đã viết sai (`00000d`
ra `000042d`, vì chuỗi custom của .NET coi chữ cái là ký tự thường).

**Tìm thêm 8 tính năng thiếu** (báo lỗi rõ, không im lặng):

| Tính năng | Tình trạng |
|---|---|
| `with` statement | Không có |
| `sorted()` | Không có (chỉ `list.sort()` tại chỗ) |
| `max`/`min`/`sum` với `key=` | Không có (không có tham số từ khoá) |
| `del` trên lát `del xs[1:3]` | Không có |
| `def` lồng trong hàm | Không có |
| `class` lồng trong hàm | Không có |
| Generator trả giá trị qua `return` | Không có |
| `datetime`, `Decimal` | Không có |

**Khớp rồi (trước đây chưa biết):** `try` lồng nhau, `round(x, n)`, so sánh
chained `1 < x < 3`, `xs[0] += 10`, `if` có `finally` không `break`.

### 3.5 Vòng đo "bảng chưa đo" — 22 tính năng, tìm 1 lỗi, hủy 8 nghi ngờ

Bảng "chưa đo" ở mục 7 liệt kê những thứ tôi **không biết** đúng hay sai. Vòng này
dựng probe cho 22 mục, mỗi mục một cặp file `.tkv`/`.py` chạy độc lập.

**Hủy 8 nghi ngờ của tôi** — những thứ tôi tưởng thiếu hoặc hỏng thì **có và đúng**:

`str.count` · `str.zfill` · `str.title` · `str.ljust` · `str.center` ·
`lstrip` với ký tự · `startswith` với tuple · lát chuỗi có bước (`s[::2]`) ·
thứ tự khóa `dict` · duyệt `items()` trong `for` · `dict.values()` ·
tràn `i32` khi `+=` (tự nâng, khớp Python) · tích luỹ float · `True + True` ·
`+=` trên thuộc tính record · `-=` `*=` · lớp ngoại lệ tự định nghĩa ·
`raise` trong generator · `yield from` lồng nhau · generator làm tham số hàm khác ·
đệ quy 900 · vòng lặp 200 000 · walrus `:=`

**Một lỗi thật, chưa chẩn đoán xong:**

Khi gộp **tất cả** các nhóm trên vào **một hàm `run`**, chương trình sập lúc
chạy: `NullReferenceException` trong `TkvInt.Str`. Tách ra thành hai file thì
**các phần đều chạy đúng**. Tức là lỗi phụ thuộc kích thước file, không phải lỗi
logic của bất kỳ mục nào. Tôi chưa khoanh vùng được nên **ghi lại là chưa chẩn
đoán**, không đoán. Ghim bằng `Testkit/gap_lang_test.tkv` +
`Testkit/gap_exc_gen_test.tkv` (tách sẵn để tránh lỗi trên).

**Thiếu, đã đo (báo lỗi rõ):** `str.isalpha` và mọi method chuỗi ngoài danh sách
cho phép · phép `|` `&` trên set · `int("ff", 16)` có cơ số · `del` trên biến ·
comprehension lồng nhau · comprehension có `else` · `def`/`class` lồng trong hàm

**Không được khẳng định:** gán nhiều đích `a = b = 7` **chạy đúng** khi build với
`--no-lint`, nhưng linter cảnh báo "multiple-target assignment chưa hỗ trợ". Vì
chỉ chạy được ở chế độ bỏ kiểm tra, tôi **không** đưa vào test và **không** coi là
đã hỗ trợ.

**Giới hạn tài nguyên:** đệ quy sâu ~50 000 làm sập `StackOverflowException`
(giới hạn stack của .NET). CPython với `setrecursionlimit` cao thì chạy được —
đây là khác biệt về nguồn lực, không phải lỗi logic.

### 3.6 Số phức / container / async — tìm 2 lỗi ở nơi có sẵn code nhưng không có phép thử so với CPython

Các tính năng dưới đây **đã có** test (`complex_test.tkv` 12 phép,
`bytearray_test.tkv` 6, `frozenset_test.tkv` 4, `async_await_py_tree_test.tkv` 3).
Nhưng chúng chỉ so với **giá trị viết tay**, chưa bao giờ đối chiếu CPython. Đó
là chỗ trống thật — và nó chứa 2 lỗi.

| Lỗi | CPython | TokenVector (trước) | Nguyên nhân |
|---|---|---|---|
| `abs(complex(3,4))` | `5.0` | **sập** `MissingMethodException` lúc chạy | Gọi `System.Math::Abs(Complex)` — hàm **không tồn tại** trong .NET |
| `str(complex(4,6))` | `(4+6j)` | `(4, 6)` | Dùng `Complex.ToString()` của .NET |

`complex_test.tkv` có 12 phép nhưng **không phép nào** gọi `abs()` trên số phức
và **không phép nào** kiểm `str()` — nên cả hai lỗi lọt qua.

**Sửa `abs`:** thử `Complex::Abs(Complex)` (hàm có thật, trả `double`) thì kết quả
**vẫn sai** — ra `3.0` thay vì `5.0`, tức đọc 8 byte đầu của struct `Complex`
(phần thực) thay vì kết quả hàm. Đây là **sai âm thầm**, nên tôi **dừng sửa** và
chuyển sang **lỗi biên dịch rõ ràng** kèm hướng dẫn
`sqrt(c.real*c.real + c.imag*c.imag)`. Sửa nửa vời thành giá trị sai tệ hơn nhiều
so với báo lỗi.

Cũng lưu ý: `abs()` khai báo kiểu trả về theo **toán hạng**, nên với complex nó
trả `'complex'` trong khi Python trả `float` — đã sửa thành `'f64'`. Và lần đầu
guard của tôi **không bắt được** lỗi vì so sánh `dtype`, trong khi biến đó là kiểu
**ngữ cảnh** (`print(str(abs(c)))` cho `dtype='str'`), không phải kiểu toán hạng.

**Đã ghim và khớp CPython:** cộng/nhân/bình phương số phức (`.real`/`.imag`) ·
`==` trên số phức · `bytearray` append/len/index · `frozenset` len/in ·
`async`/`await` giá trị trả về.

**Còn thiếu, đã đo:** toán tử `%` (`"%d" % x`) · gán lát `xs[1:3] = [...]` ·
`nonlocal` · `int("ff", 16)` có cơ số · phép `|` `&` trên set ·
`str.isalpha` và method chuỗi ngoài danh sách · `del` trên biến ·
`def`/`class` lồng trong hàm · comprehension lồng nhau / có `else` ·
`with` · `sorted()` · `key=` · `iter()`/`next()` · stdlib · `datetime`/`Decimal` ·
metaclass · `str()` tuple/list · method trên literal/biểu thức ·
tham số chỉ-khoá/chỉ-vị-trí · record có field container

**Giới hạn:** `divmod` với **hằng số nguyên** không suy được kiểu trả về tuple
(`divmod(-7, 2)` lỗi), trong khi `divmod(int(...), int(...))` chạy được —
`divmod_test.tkv` chỉ dùng dạng thứ hai nên không thấy.

### 3.7 Còn lệch, đã đo, **quyết định không sửa**

| Mục | CPython | TokenVector | Vì sao không sửa |
|---|---|---|---|
| Ký tự **ngoài BMP** (emoji, 4 byte) | đếm/slice theo codepoint | UTF-16: `len("😀")` = 2, cắt chuỗi tách đôi surrogate | Đổi sang codepoint là **thay đổi kiến trúc** (`string` .NET là UTF-16), không phải sửa bug. Mọi ký tự BMP đều đúng |
| Gán số nguyên vào biến đã khai `f64` | `2` | `2.0` | Hệ quả của "1 local giữ 1 kiểu": giá trị được widen một chiều |
| `a <= b` trên record khi chỉ có `__lt__` | `TypeError` | dùng `__lt__` | TokenVector permissive hơn Python — ngược hướng với các lỗi trên |
| `1.0 / 0.0` | `ZeroDivisionError` | `inf` | Theo IEEE như C/NumPy/JS. Ném lỗi sẽ tốn một nhánh trên phép chia nóng |
| `1.0 % 0.0` | `ZeroDivisionError` | `nan` | Như trên |
| `str(-0.0)` viết thẳm | `'-0.0'` | `'0.0'` | **Lỗi thật, còn sót**: chỉ hỏng ở dạng nội tuyến; gán biến hay tính toán đều đúng |

### 3.4 Lỗi của CHÍNH công cụ đo (làm số đẹp hơn thực tế)

`diff.py` nạp output vào dict theo nhãn: `d[k] = v`. Nhãn trùng bị **ghi đè im
lặng** — phép bị ghi đè **không hề được so**, và báo cáo vẫn in
`KHOP: N` với `KHAC: 0` như thể đã kiểm hết.

Cụ thể: hai nhãn `in` (chuỗi, list) và `isinstance_like` (OOP, số) bị trùng →
119 dòng chỉ còn **117 nhãn**, 2 phép không bao giờ được so. Bản đo lần 2 tôi
đã báo "117/117" là **sai**: con số đúng là 119.

Đã sửa: `diff.py` giờ **báo lỗi và thoát mã 1** khi có
- nhãn trùng (buộc phải đặt tên khác trong nguồn probe),
- dòng không có dạng `nhan = gia tri` mà không phải dòng giá trị trả về của entry,
- nhãn chỉ có ở một bên.

Dòng giá trị trả về của entry là hợp lệ: runtime in nó ra (đã kiểm — exe in `7`
khi entry `return 7`, còn process exit code vẫn là `0). `diff.py` chỉ chấp nhận
**đúng một** dòng số nguyen ở cuối file, và in nó ra để không phải bỏ qua mù quáng.

Tên nhãn đã tách: `in_str`/`in_list`, `isinstance_like_oop`/`isinstance_like_num`.

> Bài học chung: **công cụ đo cũng có bug âm thầm, và hướng lệch của nó là làm
> kết quả trông tốt hơn.** Cùng nguyên tắc với `/` — chỉ khác là nó nằm trong
> dụng cụ kiểm chứng chứ không trong ngôn ngữ.

---

## 4. GIỚI HẠN BIÊN DỊCH (báo lỗi rõ, không im lặng)

Những cái này **từ chối build kèm thông điệp chỉ đường**, nên an toàn hơn 3.1–3.3.
Đây là chi phí trả cho việc mọi thứ phải suy kiểu lúc biên dịch:

| Viết kiển trong Python | TokenVector |
|---|---|
| `int / int` với kiu `int` vô hạn (`a: "int" = 2; a / 2`) | Từ chối — chuyển `TkvInt` sang `double` chưa làm. **Không** phải mọi `i32` |
| `x: list[int] = [...]` (annotation cho biến local) | Từ chối — suy tự động |
| `d.get(k)` | Bắt buộc 2 tham số: `d.get(k, default)` |
| `"a".split(",")` (gọi method trên literal) | Phải gán vào biến trước |
| `a.extend([1, 2])` | Phải gán list vào biến trồng |
| `[x*2 for x in xs]` lồng trong `f(...)` | Chỉ được làm vế phải trực tiếp của phép gán cho tên trần |
| `map(lambda x: x+1, xs)` | Phải truyền TÊN hàm top-level, hoặc biến đã khai `func(...)` |
| `yield from [7, 8]` | Chỉ `yield from <biến list>` hoặc `<ham generator>(...)` |
| `[1,2,3][0:3]` (lát trên literal) | Phải gán list vào biến trước |
| `len(xs[0])` | Chỉ `len(<biến trần>)` |
| `s.index(x)`, `s.count(x)` | `str.index`/`str.count` không có; `list.count` chỉ ở vế phải trực tiếp |
| `",".join(["a","b"])` | Phải truyền biến kiểu `list[str]` |
| `raise TypeError(...)` | Chỉ 6 loại sẵn có: `Exception`, `IndexError`, `KeyError`, `OverflowError`, `ValueError`, `ZeroDivisionError` |
| `Dog("rex")` khi base có `__init__(self, name)` | Ctor của lớp con nhận **mọi field gộp** (`Dog("rex", 4)`); `__init__` của lớp con bị bỏ qua |
| `class C: pass` (không field) | Từ chối: `record khong co field nao` |
| `x < y` trên record (`__lt__`) | `__lt__`/`__gt__` **đã hoạt động đúng** (đo lại ở mục 3.3) |
| list literal `[1, 2]` | Phần tử là `int` (số nguyên vô hạn), **không trộn được** với `i32` |

---

## 5. NHỮNG GÌ BẢN CŨ KHAI SAI

| Bản cũ ghi | Thực tế |
|---|---|
| "Generator & Iterators — 100%, hỗ trợ `iter()`, `next()`" | `iter`/`next` **không tồn tại** trong compiler. Chỉ có `yield`, `yield from`, và `for x in <generator>` |
| "Metaclass, `obj.__class__`" | Không có gì cả — 0 dòng trong compiler |
| "OOP 100% parity" | Ctor lớp con ≠ `__init__` mà Python kế thừa. `__lt__`/`__gt__`/`__eq__` trên record **đã hoạt động đúng** — ghi "hỏng" là cũ |
| "Gán biến đổi kiểu động 100%" | Không có. Mọi thứ suy kiểu lúc biên dịch — mục 4 chính là hệ quả |
| "FFI: P/Invoke + `ctypes`" | P/Invoke có (47 dòng IL sinh ra), nhưng **`ctypes` không tồn tại** |
| "56 hàm builtin" | 167 hàm được đăng ký qua `register_expr_builtin` (đếm bằng regex trên `compiler/il_features/*.tkv`) |
| "Chuỗi tam báy nhiều dòng" | Đúng, đã có |
| "`del` chưa hỗ trợ" | Đã có |

---

## 6. SO SÁNH KIẾN TRÚC (giữ nguyên, phần này vẫn đúng)

| Đặc tính | CPython 3.12 | TokenVector (AOT CIL) |
|---|---|---|
| Thực thi | Thông dịch bytecode `ceval.c`, kiểu động lúc chạy | Biên dịch AOT ra CIL, `.exe` độc lập |
| Runtime | Cần CPython (~50–100 MB) | Không cần runtime |
| Bộ nhớ | `PyObject*` con trỏ heap, refcount + GC chu kỳ | Kiểu vô hướng không boxing + GC .NET |
| Đa luồng | **Có GIL** | `System.Threading.Thread`, không GIL |
| Suy luận kiểu | Lúc chạy | **Lúc biên dịch** — nguồn của toàn bộ giới hạn mục 4 |
| Kiểu container | Đồng nhất & hỗn hợp | Đồng nhất; `list[int]` ≠ `list[i32]` |

---

## 7. ĐÁNH GIÁ

- **Ngôn ngữ lõi** (mục 2): **119/119** trên bộ thử này. Con số 119 **không** có
  nghĩa là TokenVector ngang Python. Ba mốc đo liên tiếp đã chứng minh điều đó:
  95/102 → 102/102 → 119/119, mà **vẫn còn lỗi âm thầm ở ngoài bộ thử** — và ở
  mỗi vòng ra soát tôi lại *báo nhầm* một thứ đang đúng thành bug. **Bộ thử hẹp
  không phải bằng chứng**, chỉ là mẫu tốt để bắt lỗi khi biết mình đang tìm gì.
- **OOP**: kế thừa và `__init__` chạy thật; `__eq__`/`__lt__`/`__gt__`/`__str__`
  trên record **hoạt động đúng** (đã đo lại). Còn lệch ở ctor lớp con.
- **Bất đồng bộ / luồng**: có `async def`/`await`, `thread_spawn`/`thread_join`, và
  không GIL — đây là ưu thế thật, không phải điểm cần dè.
- **Thư viện**: 167 hàm đăng ký phẳng, **không có `import re` rồi `re.replace()`**,
  không có `socket`, `ctypes`, `sys`, `os`, `json`, `math`, không có metaclass
  (đã đo: mọi `import` đó đều bị từ chối). Đây là khoảng cách lớn nhất với Python
  và **không thể đo bằng bộ thử cú pháp**.
- **PyPI**: không dùng được. Cần wrapper FFI/P-Invoke thủ công.
- **Đoạn đã biết, chưa đo**: kiểu `datetime`, `Decimal`, `try` lồng nhau, `with`,
  thứ tự khóa `dict`, `sorted` ổn định, `round` nhiều tham số, số nguyên vượt
  `i64`. Không nằm trong 119 phép nên **không được coi là đã đạt**.

**Ưu tiên nếu sửa tiếp** — theo mức độ nguy hiểm, không theo độ khó:

1. **Cắt chuỗi ở ký tự ngoài BMP** (`em = "😀"; em[0:1]`) — trả nửa surrogate
   pair. Hẹp hơn nhiều so với cảnh báo sai đã ghi trước đây: **ký tự BMP thì
   hoàn toàn đúng**, kể cả tiếng Việt có dấu.
2. `str(-0.0)` nội tuyến mất dấu (mục 3.4) — lỗi thật còn sót.
3. **Mở rộng `parity_probe`**, vì nó mới là thứ đáng tin: 6 lỗi âm thầm đầu tiên
   lọt qua Testkit, và bản thân probe cũng từng nuốt 2 phép do nhãn trùng (mục
   3.4). Miền chưa có phép thử nào: `with`, `try` lồng nhau, `datetime`, `Decimal`,
   thứ tự khóa `dict`, `sorted` ổn định, `round` nhiều tham số, số nguyên vượt
   `i64`, và **ký tự ngoài BMP**.
4. **Đừng báo lỗi từ một phép đo.** Ba lần trong tài liệu này tôi kết luận cơ chế
   từ vài dữ kiện rồi nói thành quy luật, và cả ba lần đều sai — kể cả lần báo
   "cắt chuỗi đa byte hỏng", vốn chỉ là ký tự console hiển thị hỏng. Phải đo
   nhiều lớp và so bằng **so sánh boolean** chứ không đoán từ hình thức in ra.
