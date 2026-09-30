# BẢNG SO SÁNH ĐO ĐẠC: TOKENVECTOR VS CPYTHON 3.12

> **Ngày đo**: 2026-09-30 (đo lần 2) · **Cổng lúc đo**: 97/97 + negative 15/15
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

### 3.3 Còn lệch, đã đo, **quyết định không sửa**

Các mục này sai lệch thật với CPython. Ghi lại công khai thay vì giấu:

| Mục | CPython | TokenVector | Vì sao không sửa |
|---|---|---|---|
| `len()` chuỗi Unicode | đếm **codepoint** | đếm **byte UTF-8** | Chuỗi là mảng byte để AOT/No-GIL/nhịp nhanh. Đổi sang đếm codepoint là thay đổi kiến trúc, không phải sửa bug |
| `1.0 / 0.0` | `ZeroDivisionError` | `inf` | Theo IEEE như C/NumPy/JS. Ném lỗi sẽ tốn một nhánh trên phép chia nóng — không đáng |
| `1.0 % 0.0` | `ZeroDivisionError` | `nan` | Như trên |
| `str(-0.0)` viết thẳm | `'-0.0'` | `'0.0'` | **Lỗi thật, còn sót**: chỉ hỏng ở dạng nội tuyến; gán biến hay tính toán đều đúng. Tệp `.0` chỉ mất dấu |

> Cảnh báo thực dụng cho `len()`: `"Tiếng"` dài **5** codepoint ở Python và
> **7 byte** ở TokenVector — hai bên đều in `5`? Không: TokenVector in `7`.
> Trường hợp *trùng số* xảy ra với chuỗi 5 ký tự ASCII có 1 ký tự 2 byte
> (`"café"`): cả hai đều ra `4`, nên dễ tưởng khớp. Cắt chuỗi theo chỉ số byte là
> sai với mọi chuỗi có ký tự đa byte, và hỏng âm thầm.

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
| `x < y` trên record (`__lt__`) | `__lt__`/`__gt__` **đang hỏng** — trả hằng, bỏ thân hàm |
| list literal `[1, 2]` | Phần tử là `int` (số nguyên vô hạn), **không trộn được** với `i32` |

---

## 5. NHỮNG GÌ BẢN CŨ KHAI SAI

| Bản cũ ghi | Thực tế |
|---|---|
| "Generator & Iterators — 100%, hỗ trợ `iter()`, `next()`" | `iter`/`next` **không tồn tại** trong compiler. Chỉ có `yield`, `yield from`, và `for x in <generator>` |
| "Metaclass, `obj.__class__`" | Không có gì cả — 0 dòng trong compiler |
| "OOP 100% parity" | Ctor lớp con ≠ `__init__` mà Python kế thừa; `__lt__`/`__gt__` hỏng |
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
  nghĩa là TokenVector ngang Python — nó chỉ có nghĩa là 119 phép thử đã chọn đều
  khớp. Mốc lần 1 từng là 95/102 và vẫn lọt 6 lỗi âm thầm, trong đó có `/` — loại
  rất cơ bản. **Bộ thử hẹp không phải bằng chứng**, chỉ là mẫu tốt để bắt lỗi khi
  biết mình đang tìm gì.
- **OOP**: kế thừa và `__init__` chạy thật, nhưng ctor lớp con và toán tử `<`/`>`
  trên record còn lệch Python.
- **Bất đồng bộ / luồng**: có `async def`/`await`, `thread_spawn`/`thread_join`, và
  không GIL — đây là ưu thế thật, không phải điểm cần dè.
- **Thư viện**: 167 hàm đăng ký phẳng, **không có `import re` rồi `re.replace()`**,
  không có `socket`, không có `ctypes`, không có metaclass. Đây là khoảng cách lớn
  nhất với Python và **không thể đo bằng bộ thử cú pháp**.
- **PyPI**: không dùng được. Cần wrapper FFI/P-Invoke thủ công.
- **Đoạn đã biết, chưa đo**: `sys`/`os`/`re`/`json` mức module, kiểu `datetime`,
  `Decimal`, số phứn, `int` vô hạn (`TkvInt`) ở các phép toán. Không nằm trong
  119 phép nên **không được coi là đã đạt**.

**Ưu tiên nếu sửa tiếp** — theo mức độ nguy hiểm, không theo độ khó:

1. `str(-0.0)` nội tuyến mất dấu (mục 3.3) — lỗi thật còn sót.
2. **Mở rộng `parity_probe`**, vì nó mới là thứ đáng tin: 6 lỗi âm thầm đầu tiên
   đều lọt qua Testkit. Miền chưa có phép thử nào: ngữ pháp `del`/`with`/`global`
   kết hợp, `try` lồng nhau, số phứn, `datetime`, thứ tự khóa `dict`, sắp xếp
   (`sorted` ổn định?), `round` với nhiều tham số, số nguyên vượt `i64`.
3. `len()`/cắt chuỗi trên văn bản Unicode — đã biết, nhưng là **thay đổi kiến
   trúc**, cần quyết định riêng chứ không gộp vào đợt sửa nhỏ.
