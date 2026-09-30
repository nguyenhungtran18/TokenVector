# BẢNG SO SÁNH ĐO ĐẠC: TOKENVECTOR VS CPYTHON 3.12

> **Ngày đo**: 2026-09-30 · **Cổng lúc đo**: 95/95 + negative 15/15
> **Cách đo**: `tools/parity_probe/` — 102 phép thử chạy song song trên cả hai
> bên, in ra cùng một danh sách nhãn, máy so từng dòng.
> Chạy lại: `powershell -File tools\parity_probe\run.ps1`

Bản trước của tài liệu này tự ghi "95%+ Parity" và khẳng định hỗ trợ `iter()`,
`next()`. Cả hai điều đó **không có cơ sở**: `iter`/`next` không hề tồn tại trong
compiler, và con số parity được đo lại ở đây.

---

## 1. KẾT QUẢ ĐO

```
py: 102 dong, tv: 102 dong
KHOP  : 95
KHAC  : 7
```

**95/102 phép thử cho kết quả giống hệt CPython.** 7 phép khác được phân loại
thành 3 nhóm ở mục 3 — và **không cái nào trong số đó là "giới hạn được báo trước"**:
tất cả đều cho kết quả sai mà không báo lỗi.

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

---

## 3. 7 PHÉP KHÁC — 3 BUG IM LẶNG, 4 GIỚI HẠN ĐÃ BIẾT

### 3.1 BUG: `split` bỏ qua phần còn lại của dấu phân cách nhiều ký tự

```python
"Hello, World".split(", ")   # Python: ['Hello', 'World']
```
TokenVector cho `['Hello', ' World']` — nó chỉ tách theo **ký tự đầu tiên** của
dấu phân cách, phần còn lại bị bỏ. Không báo lỗi.

### 3.2 BUG: truyền generator vào tham số kiểu `list[...]` cho list rỗng

```python
join_i(gen_upto(4))   # Python: 4 phần tử
```
TokenVector: **0 phần tử**. Generator tự nó vẫn đúng — `for v in gen_upto(4)`
ra đủ `0 1 2 3`, và `yield from` cũng đúng. Chỉ hỏng ở chỗ truyền nó làm
**đối số** cho tham số `list[i32]`. Không báo lỗi.

### 3.3 BUG: lát kiểu `int` truyền vào tham số `list[i32]` — lẫn kiểu, đọc rác

```python
lit = [1, 2, 3]          # list[int] (TkvInt, 16 byte)
full = lit[0:3]          # lát -> vẫn list[int]
take_i32(full)           # tham số khai list[i32]
```
TokenVertor đọc `List<TkvInt>` như `List<int32>`: hoặc ra **số 0 im lặng**, hoặc
văng `OverflowException`. Ở chỗ dùng cục bộ thì đúng (`lit[0:3]` in ra `1 2 3`);
chỉ hỏng khi đi qua ranh giới tham số. Đây là loại bug nguy hiểm nhất: **sai
giá trị mà không có dấu hiệu nào**.

Nguyên nhân: kiểu phần tử của biểu thức lát được suy ra khác với kiểu phần tử
của list nguồn, nên tại lời gọi không có phép chuyển đổi nào được phát ra, và
.NET nhận `List<int>` ở chỗ cần `List<int32>`.

> Ba bug trên đều **không** xuất hiện trong Testkit hiện tại, vì gate chỉ kiểm
> đúng→sai, chưa có chiều "sai→đúng". Xem `docs/PLAN.md`.

### 3.4 `str()` của biểu thức bool in `True`/`False`, của biến in `1`/`0`

```python
t = 1 > 0
str(t)        # Python: 'True'   TokenVector: '1'
str(1 > 0)    # TokenVector: 'True'  (biểu thức nội tuyến)
```
Đã biết từ trước, ghi ở `CLAUDE.md`. Không phải bug logic — nhưng là **bẫy im
lặng** khi in log: cùng một giá trị mà hai cách in ra hai kiểu.

### 3.5 Container rỗng được coi là đúng trong `or`/`and`

```python
a = []
a = a or [1]
len(a)     # Python: 1   TokenVector: 0
```
`or`/`and` trả về **đúng toán hạng** (đã kiểm: `x or 9` → 9, `y and 5` → 5,
`d["k"] or 42` → 42). Chỉ sai ở chỗ kiểm tra tính đúng của list rỗng — nó coi là
đúng. `d["k"] or 42` vẫn đúng vì giá trị là `0`.

### 3.6 `and`/`or` trả toán hạng, nhưng `str()` lại ra bool

`str(1 and 2)` → TokenVector in `True`, Python in `2`. Cùng gốc với 3.4.

---

## 4. GIỚI HẠN BIÊN DỊCH (báo lỗi rõ, không im lặng)

Những cái này **từ chối build kèm thông điệp chỉ đường**, nên an toàn hơn 3.1–3.3.
Đây là chi phí trả cho việc mọi thứ phải suy kiểu lúc biên dịch:

| Viết kiển trong Python | TokenVector |
|---|---|
| `7 / 2` (→ `3.5`) | Từ chối trên `i32`. Dùng `7.0 / 2` hoặc `//` |
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

- **Ngôn ngữ lõi** (mục 2): đo được **95/102 ≈ 93%** trên bộ thử này. Gọi là
  "95%+" mà không đo là nói bừa; con số thật là 93%, và 4/7 phép khác là bùa
  mắt thường.
- **OOP**: kế thừa và `__init__` chạy thật, nhưng ctor lớp con và toán tử `<`/`>`
  trên record còn lệch Python.
- **Bất đồng bộ / luồng**: có `async def`/`await`, `thread_spawn`/`thread_join`, và
  không GIL — đây là ưu thế thật, không phải điểm cần dè.
- **Thư viện**: 167 hàm đăng ký phẳng, **không có `import re` rồi `re.replace()`**,
  không có `socket`, không có `ctypes`, không có metaclass. Đây là khoảng cách lớn
  nhất với Python và **không thể đo bằng bộ thử cú pháp**.
- **PyPI**: không dùng được. Cần wrapper FFI/P-Invoke thủ công.

**Ưu tiên nếu sửa tiếp** — theo mức độ nguy hiểm, không theo độ khó:

1. 3.3 (lẫn kiểu khi truyền lát `list[int]` vào tham số `list[i32]`) — sai giá trị
   **và** có thể đọc ngoài vùng nhớ.
2. 3.1 (`split` nhiều ký tự) — sai âm thầm, rất dễ gặp khi parse dữ liệu.
3. 3.2 (generator làm đối số) — sai âm thầm, mất dữ liệu.
4. Bổ sung cổng so sánh: hiện gate chỉ kiểm đúng→sai, nên cả 3 bug trên lọt.
