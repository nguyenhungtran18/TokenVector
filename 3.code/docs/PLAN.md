# TokenVector — Kế hoạch hoàn chỉnh

Ghi lại 2026-09-28. Thay thế mọi bản plan trước. Mọi mục ở đây đều dựa trên
**kết quả đo được**, không phải suy đoán: 91 trường hợp biên dịch thật, 65 file
Testkit, 26 test Inference, 18 suite Data.

---

## 1. Trạng thái hiện tại

| Cổng | Kết quả |
|---|---|
| `3.code\tools\testkit_gate.ps1` | **65/65** |
| Inference | **26/26** |
| Data gate | **PASS** (library 2/2, fragments 0 lỗi thật, suites 18/18) |
| Benchmark | 7 kernel, checksum 7/7 OK |

Đo được trên máy này (min của 5 lần, đã trừ startup):

| kernel | TokenVector | CPython | nhanh hơn | NumPy |
|---|---|---|---|---|
| fib | 12 075 µs | 941 157 µs | **78×** | – |
| string | 18 629 µs | 50 687 µs | **2.7×** | – |
| sort | 17 344 µs | 1 032 756 µs | **60×** | – |
| add | 1 455 µs | 67 717 µs | **47×** | 1.8× chậm hơn |
| matmul32 | 4 462 µs | 8 805 µs | **2.0×** | **746× chậm hơn** |
| f32mm scalar | 147 µs | 1 533 µs | 10.4× | – |
| **f32mm_vec (SIMD)** | **34 µs** | 1 528 µs | **45×** | – |

SIMD 4-lane đạt **4.08×** so với scalar — ngay tại trần lý thuyết 4 lane.
Startup 24.6 ms so với CPython 35.8 ms (1.5× nhanh hơn).

---

## 2. Bug đã sửa trong chu kỳ này

Bốn lỗi này đều **có sẵn từ lâu**, lộ ra khi viết test cho tính năng mới.
Điểm chung: tất cả đều **âm thầm** hoặc chỉ lộ khi gặp cách viết ít dùng.

| # | Lỗi | Biểu hiện | Vì sao lọt |
|---|---|---|---|
| 1 | **Thiếu `ret`** | Hàm có kiểu trả mà không kết thúc bằng `return` → `InvalidProgramException` lúc chạy | Mọi hàm test đều có `return` explicit ở cuối |
| 2 | **`ldc.i4 <số > int32`** | Literal lớn trong ngữ cảnh `i32` → IL không hợp lệ, ilasm báo *"syntax error at token"* | Chưa test nào dùng giá trị > 2³¹ |
| 3 | **`str(<so sánh>)` in `"True"`** | Cùng một giá trị, hai dạng chuỗi: nội tuyến ra `"True"`, gán biến ra `"1"` | Không test nào so dạng chuỗi của boolean |
| 4 | **`__lt__`/`__gt__` record trả hằng số** | `C(1) < C(0)` → 1, thân hàm người dùng bị bỏ qua | Testkit có `dunder_eq/getitem/len/str/add` nhưng **không có** `dunder_lt_test` |

Bài học rút ra, và nó định hình phần còn lại của kế hoạch:

> **Cổng chỉ phủ những gì ai đó ngồi viết test cho.** 65 file test không bảo chứng
> cho 65 tính năng — chúng bảo chứng cho 65 *đường đi đã được đi qua*.
> Bốn bug trên đều nằm ngoài tập đường đi đó.

---

## 3. Kiểu `bool` — đã thêm

`"bool"` là **alias của `"i32"`**, không phải kiểu riêng. Lý do:

- So sánh và logic **đã luôn** sinh `i32` 0/1 trong cả compiler
  (`dunder_eq_test.tkv` viết `__eq__ -> "i32"`). Thêm chuỗi riêng đòi sửa mọi
  nhánh so sánh, mọi nơi lưu biến, mọi hàm có tham số boolean — và không thu
  hồi được gì vì mã cũ đã biên dịch.
- Python cũng vậy: `bool` là lớp con của `int`, không phải kiểu độc lập.
- Độ lớn bằng 0, mở rộng có giá trị không đổi.

Cài đặt: `DTYPES.add('bool')` + `canon_dtype()` trong `TypeAnn.__init__` — **một
điểm hội tụ duy nhất**, nên không phải sửa 100+ chỗ kiểm tra dtype.

Kèm theo: danh sách dtype trong thông báo lỗi giờ **sinh từ `DTYPES`** thay vì
viết cứng `f32/f64/i32/i64/str` — trước đó nó sai lệch với `DTYPES` thật và
chính sai lệch đó làm 6 probe của tôi báo nhầm "thiếu tính năng".

Cổng: `Testkit/bool_type_test.tkv`, 20 check.

---

## 4. Danh sách thiếu (54 mục, đã đo)

### 4a. Rẻ — làm được ngay, mỗi cái một chỗ sửa

| Mục | Ghi chú |
|---|---|
| `is` / `is not` | Không có token `is` trong expression parser |
| `f(*xs)`, `f(**kw)` | Giải nén khi gọi |
| `list.extend()` | `.append()`, `.insert()` đã có |
| `for k, v in d.items()` | Gán `k, v = ...` đã có |
| `enumerate(a, 1)` | Tham số bắt đầu |
| `print(..., sep=, end=)` | Từ khoá tham số |
| `@classmethod` | `@property`, `@staticmethod` đã có |
| Literal **octal** `0o`, **nhị phân** `0b` | Hex đã có |
| Số khoa học `1e3` | |
| Tuple literal `(1, 2)` | `-> "tuple"` chưa phải dtype |
| `in` trên record | Giờ chỉ dict/set/list/str |

### 4b. Cần thiết kế — không phải vá

| Mục | Vì sao khó |
|---|---|
| **`lambda`** | Cần sinh closure delegate; `closures.tkv` đã có nền nhưng chưa có đường cho lambda |
| **Dict comprehension** | List comprehension có; dict cần đường ghi khác |
| **Literal lồng** `[{"a":1}]`, `{"k":[1,2]}` | `d["k"] = [1,2]` chạy được, chỉ thiếu *dạng literal* |
| **`try/except/else`** | ~~Da xong 2026-09-28.~~ Phai tach **HAI nhan**, xem ghi chu ben duoi. |
| **`for/else`, `while/else`** | ~~Đã xong 2026-09-28, xem Bước 4.~~ |
| Set literal `{1,2,3}` | Phải `set()` + `.add()` |
| `del` biến / phần tử | |

### 4c. Khó — cần mở rộng state machine

| Mục | Vì sao khó |
|---|---|
| `yield from` | Phải cho state machine generator ăn iterator thứ hai (MoveNext/Current vào cùng đường yield). **Không kiểm chứng được bằng bộ suite nó chặn** — `native_test_suite.tkv` là bộ 16 case duy nhất dùng nó, và file đó hiện không build. |
| `return <giá trị>` trong generator | `StopIteration.value` |
| `for/else` + `while/else` | `else` **không được chạy sau `break`**, mà CIL không có cờ nào cho việc đó. Phải cấp biến cờ cho mỗi `break`. |
| Comprehension lồng `[.. for x .. for y ..]` | |
| Slice có bước `a[::2]` | |
| Biểu thức điều kiện `a if c else b` | Và `c ? a : b` **cũng không hợp lệ**, dù chính thông báo lỗi của compiler bảo dùng cú pháp đó — cần sửa thông báo hoặc hỗ trợ cả hai |
| Hàm lồng phải là câu lệnh **đầu tiên** | `def inner()` sau `k = 1` → lỗi |
| Chuỗi nhiều dòng `"""..."""` | |

---

## 5. Thứ tự thực hiện

### Bước 1 — Nhóm rẻ (4a) — *làm tiếp ngay*
Khoảng 11 mục, mỗi mục một commit riêng, mỗi commit kèm test. Cổng 65/65 phải
xanh sau **từng** commit, không phải một lần cuối.

**Vi sao làm trước:** giá trị cao nhất trên công sức thấp nhất, và mỗi mục đều
là *việc độc lập* — một mục hỏng không chặn 10 mục còn lại.

**Cần thêm trước khi bắt đầu:** một helper chạy một file `.tkv` và trả về
pass/fail, để mỗi test mới không phải viết lại vòng build+chạy. `testkit_gate.ps1`
làm được phần này ở quy mô 65 file nhưng chưa có API cho một lệnh.

### Bước 2 — Sửa `str()` trên kết quả so sánh
`str(a > 3)` nên ra `"1"` cho khớp `v = a > 3; str(v)`.

**Cần quyết định trước:** đổi `"True"` → `"1"` có thể làm hỏng code đang dựa vào
`"True"`. Trong repo này tôi **không tìm thấy** chỗ nào dựa vào nó, nhưng người
dùng bên ngoài thì chưa biết. Đây là thay đổi **phá vỡ**, cần ghi vào changelog.

### Bước 3 — ~~`raise <biến>` + `try/except/else`~~ *đã xong 2026-09-28*
`raise <biến>` (`Testkit/raise_var_test.tkv` 7/7) và `try/except/else`
(`Testkit/try_except_else_test.tkv` 10/10).

**Bài học về `try/else` — đừng lồng nhau.** Lần thử đầu sinh `.try` bao ngoài
cho `else`, rồi phát nhãn ở sai chỗ, tạo vòng lặp vô hạn; đã revert. Cách đúng
không cần cấu trúc lồng: sau khi `.try`, đường "không có lỗi" và đường "handler
đã bắt" đều là `leave` tới **cùng một nhãn**, nên bên ngoài vùng `.try` không
phân biệt được. Vì vậy phải tách nhãn **ngay trong thân try**:

```
.try { than_try; leave NO_EXC }      <- duong sach
catch { handler; leave END }         <- duong co loi, NHAY QUA else
NO_EXC:  than_else                   <- nam NGOAI vung .try
END:
```

Không thể dùng `br NO_EXC` ở cuối thân try: CIL cấm `br` thoát khỏi thân
`.try` (ECMA-335 III.3.64), bắt buộc `leave` — nên `NO_EXC` bắt buộc nằm ngoài
vùng `.try`, đó chính là chỗ duy nhất đặt được. Với `finally`, thân `else` sinh
bên trong `.try` của `finally` để `finally` vẫn chạy sau nó, và `break` trong
thân `else` khi đó bị từ chối vì `br` thuần không hợp lệ trong vùng bảo vệ.

### Bước 4 — ~~`for/else` / `while/else`~~ *đã xong 2026-09-28*
`Testkit/for_while_else_test.tkv` 15/15, đã đối chiếu CPython 3.11 cho các ca
lồng nhau.

**Không dùng cờ `did_break` như dự kiến.** Kỹ thuật đó cần 1 local mới, mà tên
local phải duy nhất giữa hai lần duyệt câu lệnh (first pass khai báo, codegen
đọc) — mà số lần đếm ở hai lần duyệt không đảm bảo khớp. Dùng **nhãn** thì không
cần gì: `break` trỏ tới nhãn nằm **sau** thân `else`, còn thoát bình thường rơi
vào `else`. `codegen_break` **không đổi một dòng nào** — nó vốn đọc
`loop_stack[-1][1]`, nên chỉ cần đẩy nhãn khác vào đó.

Điểm dễ sai: nhãn `break` phải đặt **sau** `emit_sb_flush`, không phải ngay tại
`end_lbl`. Nếu đặt trước, `break` sẽ bỏ qua bước tổng hợp chuỗi của vòng lặp.

`for x in <list>` không cần mã nguồn riêng: macro `for_in_list` viết lại thành
`for i in range(len(x))`, và dòng `else:` gốc vẫn nằm nguyên nên parser `for`
range nhặt được. Riêng `for x in <record>` dùng `__iter__`/`__next__` nên phải
sửa tay (`codegen_for_in_iter`).

### Bước 5 — `lambda` — ~~XONG, xem mục 8~~

**Không còn là việc cần làm.** `lambda` đã hoạt động từ Wave 3 (A2,
2026-07-29) qua đường khai báo kiểu `func` — kể cả khi bắt biến ngoài. Cách
dùng: `g: "func(i32) -> i32" = lambda x: x + 1`, hoặc truyền thẳng cho tham số
kiểu `func`: `apply_it(lambda x: x * 2, 5)`.

Dạng `g = lambda x: ...` không có khai báo kiểu thì báo lỗi, và điều đó
**đúng**: node lambda chỉ mang *tên* tham số, mà ngôn ngữ này không suy luận
kiểu — mỗi hàm có đúng một chữ ký.

Đã có gate: `Testkit/lambda_test.tkv` (11 check, gồm cả trường hợp bắt biến
ngoài). Mục này bị xếp nhầm vào "cần thiết kế" vì `CLAUDE.md` ghi sai là
thiếu — xem mục 8.

### Bước 6 — `yield from`
Chỉ làm sau khi `native_test_suite.tkv` build được, vì hiện **không có bộ test
nào** chạm tới nó.

---

## 6. Việc không làm, và lý do

| Việc | Vì sao |
|---|---|
| **f64 vector hóa** | CLR 4.x không có `Vector<T>`/`Vector256`. Cần retarget .NET 8 — thay đổi nền tảng, không phải việc compiler. |
| **Sửa 4 fragment Data** | `tokenvector_compute`/`datetime`/`io`/`stats` cần hằng số module. Đã ghi ở `Data\SESSION_HANDOFF.md`, để session riêng. |
| **Xoá repo con `3.code`** | Không hoàn tác được. Mọi commit đã có trong parent qua tag `nested-3code-snapshot`. Chờ quyết định. |
| **`f32x8`/`VBuf8` retire** | Đã ghi chú là không phải SIMD nhưng chưa gỡ. 8 số rời, không lợi. |

---

## 7. Rủi ro cần nhớ

**Thay đổi phá vễ là mặc định ở đây.** Không có cờ opt-in cho hầu hết tính năng.
Một thay đổi sai trong compiler không hỏng compiler — nó **hỏng chương trình
đã biên dịch**, và chỉ lộ ở chỗ người dùng đã viết test.

Ba hệ quả thực tế:

1. **Mỗi commit phải kèm test**, không phải "chạy thử thấy được".
2. **Cổng phải chạy lại sau từng commit**, không gom một lần cuối — nếu không
   sẽ không biết commit nào làm hỏng.
3. **Bốn bug ở mục 2 đều lọt cổng 65/65.** Cổng bảo chứng cho tập đường đi đã
   đi qua, không phải cho tập đường đi chưa ai thử.

Ngoài ra: `str()` của giá trị boolean **không nhất quán** giữa nội tuyến và
gán biến (mục 2, #3) — bất kỳ test nào dùng `check()` với giá trị boolean đều
phải gán biến trước, nếu không nó sẽ hỏng một cách rất khó hiểu.

---

## 8. Cổng nghiệm thu

Chạy trước khi coi bất cứ thay đổi nào là xong:

```powershell
# 1. Build lại compiler TỪ CÂY NGUỒN (binary cũ che hồi quy)
.\3.code\build_tkvc.ps1

# 2. Testkit — 65 file
.\3.code\tools\testkit_gate.ps1

# 3. Inference
.\3.code\dist\tkvc.exe build D:\TokenVector.Inference\tv\tests\inference_tests.tkv `
    --entry main --out $env:TEMP\inf.exe --no-lint
.\%TEMP%\inf.exe

# 4. Data — mất khoảng 5 PHUT, khong tre
powershell -File D:\TokenVector.Data\tools\datagate.ps1

# 5. Benchmark — tu build kernel tu dist\tkvc.exe
python .\3.code\bench\run.py
```

Bước 1 **không được bỏ**. Bốn bug ở mục 2 lộ ra chính vì đã rebuild; `dist\tkvc.exe`
cũ từng che một test suite không build được.

Bước 4 mất ~296 s vì nó build rồi **thực thi** 18 check, không chỉ biên dịch.
Không phải tre.

## 8. Sai lệch giua tai lieu va thuc te (2026-09-28)

Khi lam viec theo danh sach thieu, phat hien mot *tinh dang ton tai* chua
bao gio duoc ghi ra: `lambda` **da chay** tu Wave 3 (A2, 2026-07-29), ke ca
khi bat bien ngoai. Ca `CLAUDE.md` va `PLAN.md` deu ghi no la thieu.

Khong phai may khong may: dong comment trong `il_codegen.tkv` ngay canh
duong do ghi ro `_compile_expr` khong dispatch duoc node `lambda`, nen
duong gan bien thuong bao loi - nhung `_compile_funcref_arg` case (d) thi co,
va no la duong dung khi co khai bao kieu `func`. Ai doc comment do se ket
luận nguoc.

**Bai hoc ve phuong phap:** dung kiem tra "co that su thieu khong" truoc khi
cong bo thoi gian sua. Mot probe that bai mot mau nham hon mot khai niem sai -
va `lambda` nam trong ca hai. Bay gio no co gate
(`Testkit/lambda_test.tkv`) nen khong the bien mat im lang lan nua.

Cung trong lo nay, hai dieu nua sua xong theo huong nguoc lai:

- `==` tren container nem `InvalidCastException` (sua bang `ceq`).
- `__lt__`/`__gt__` tren record tra ve hang so (sua bang `__lt__`).
Ca hai deu im lang; ca hai deu bi bo qua vi khong co test nao chay qua duong do.