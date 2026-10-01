# TAI LIEU THAM CHIEU HAM - TOKENVECTOR

> Sinh/doi dong cung voi `docs/BUILTIN_REFERENCE.md` (danh muc TEN tu dong).
> File nay them **CUNG PHAP** va **Y NGHA**. Danh muc sinh tu dong chi co ten.

Tong so ten da dang ky: **354** (`BUILTIN_REFERENCE.md`).
Cong them **5 ham xu ly TRUC TIEP** khong qua bang dang ky: `print`, `len`,
`range`, `abs`, `round`.

**Hay DOC KY "BA SU CO" o cuoi truoc khi tin mot ham co chay duoc.**

---

## 1. HAM GOC XU LY TRUC TIEP (khong co trong 354)

| Cu phap | Chuc nang |
|---|---|
| `print(x)` | In ra stdout, tu dong xuống dòng |
| `len(c)` | Độ dài chuỗi/list/dict/set/bytes |
| `range(a, b, c)` | Dải số, dùng với `for i in range(...)` |
| `abs(x)` | Trị tuyệt đối. **Trên số phức sẽ báo lỗi biên dịch** (không hỗ trợ) |
| `round(x, n)` | Làm tròn |

---

## 2. HAM BUILTIN GỌI TRỰC TIẾP (176)

### 2.1 Chuyển đổi kiểu / dựng chuỗi

| Cú pháp | Chức năng |
|---|---|
| `str(x)` | Chuyển sang chuỗi. `str(bool)` ra `"True"`/`"False"` — khớp CPython |
| `int(x)` | Chuyển sang số nguyên |
| `int64(x)` | Số nguyên 64-bit (thoát giới hạn int32) |
| `float(x)` | Chuyển sang số thực |
| `bool(x)` | Chuyển sang bool (alias của `i32`) |
| `repr(x)` | `repr("a")` = `'a'` (dấu nháy đơn), giống Python |
| `bin(n)` | Chuỗi nhị phân, `"0b1010"` |
| `oct(n)` | Chuỗi bát phân, `"0o12"` |
| `hex(n)` | Chuỗi thập lục phân, `"0xa"` |
| `chr(n)` | Ký tự từ mã |
| `ord(c)` | Mã của ký tự |
| `complex(re, im)` | Số phức |
| `type(x)` | Tên kiểu |
| `isinstance(x, T)` | Kiểm tra kiểu → `i32` |
| `issubclass(A, B)` | Kiểm tra quan hệ kế thừa → `i32` |

### 2.2 Số học

| Cú pháp | Chức năng |
|---|---|
| `abs(x)` | (xem mục 1) |
| `pow(a, b)` | `a ** b` |
| `divmod(a, b)` | Cặp `(a // b, a % b)` |
| `factorial(n)` | Giai thừa |
| `hypot(a, b)` | Độ dài vector 2 chiều |
| `atan2(y, x)` | `atan2` |
| `math_pi` | Hằng số π |
| `math_e` | Hằng số e |
| `math_gcd(a, b)` | ƯCLN |
| `functools_clamp_i32(x, lo, hi)` | Chặn x vào [lo, hi] |
| `functools_clamp_f64(x, lo, hi)` | Chặn số thực vào [lo, hi] |

### 2.3 Tổng hợp / sắp xếp

| Cú pháp | Chức năng |
|---|---|
| `sum(xs)` | Tổng |
| `max(xs)` / `min(xs)` | Lớn nhất / nhỏ nhất |
| `sorted(xs)` | Trả **danh sách mới** đã sắp xếp |
| `reversed(xs)` | iterable đảo thứ tự, dùng `for v in reversed(xs):` |
| `any(xs)` / `all(xs)` | Có phần tử đúng / tất cả đúng |
| `enumerate(xs)` | Cặp `(chỉ số, giá trị)` |
| `zip(a, b)` | Ghép theo vị trí |
| `product(xs)` | Tích lũy nhân các phần tử |
| `most_common(d)` | Cặp `(khóa, số lần)` phổ biến nhất |
| `argmax(xs)` | Chỉ số phần tử lớn nhất |

> **`key=` chưa dùng được** — `max(xs, key=f)` hỏng ở **tầng parser**
> (*"expected ')', got '='"*), không phải thiếu hàm. Xem mục 5.

### 2.4 Hàm bậc cao

| Cú pháp | Chức năng |
|---|---|
| `map(f, xs)` | Áp `f` lên từng phần tử |
| `filter(f, xs)` | Giữ phần tử mà `f` đúng |
| `reduce(f, xs)` | Gộp lần lượt |

### 2.5 Chuỗi định dạng

| Cú pháp | Chức năng |
|---|---|
| `format(v)` | `== str(v)` |
| `format(v, spec)` | Định dạng theo spec Python. **Chỉ nhận biến hoặc số literal**; spec phải là chuỗi literal |
| `fmt_num(v, spec)` | Như `format(v, spec)` |
| `fmt_float(v, n)` | Làm tròn `v` còn `n` chữ số thập phân |

### 2.6 Ngẫu nhiên

| Cú pháp | Chức năng |
|---|---|
| `random()` | Số thực trong `[0, 1)` |
| `randint(a, b)` | Số nguyên trong `[a, b]` |
| `randrange(a, b)` | Số nguyên trong `[a, b)` |
| `choice(xs)` | Phần tử ngẫu nhiên |
| `sample(xs, k)` | `k` phần tử ngẫu nhiên |
| `uniform(a, b)` | Số thực trong `[a, b]` |

### 2.7 Đa luồng / tiến trình

| Cú pháp | Chức năng |
|---|---|
| `thread_spawn(f, ...)` | Tạo luồng mới (không GIL) |
| `thread_join(t)` | Chờ luồng kết thúc |
| `thread_sleep(ms)` | Ngủ `ms` mili giây |
| `process_get_pid()` | PID tiến trình |
| `multiprocessing_cpu_count()` | Số lõi CPU |
| `sys_argv()` | Tham số dòng lệnh |
| `asyncio_sleep_ms(ms)` | Ngủ bất đồng bộ |
| `asyncio_get_ticks()` | Đồng hồ monotonic |

### 2.8 Hệ điều hành / đường dẫn

| Cú pháp | Chức năng |
|---|---|
| `os_getenv(name)` | Biến môi trường |
| `os_mkdir(p)` | Tạo thư mục |
| `os_list_files(p)` | Liệt kê tên file trong thư mục |
| `shutil_rmtree(p)` | Xoá cây thư mục |
| `file_exists(p)` | File tồn tại |
| `path_exists(p)` | Tồn tại (bất kỳ) |
| `path_isfile(p)` | Là file |
| `path_isdir(p)` | Là thư mục |
| `path_join(a, b)` | Nối đường dẫn |
| `path_abspath(p)` | Đường dẫn tuyệt đối |
| `path_normpath(p)` | Chuẩn hóa |
| `path_basename(p)` | Tên file |
| `path_dirname(p)` | Tên thư mục cha |
| `path_name(p)` | Thành phần tên cuối |
| `path_stem(p)` | Tên bỏ phần mở rộng |
| `path_suffix(p)` | Phần mở rộng |
| `path_splitext(p)` | Tách `(tên, mở rộng)` |
| `path_parent(p)` | Thư mục cha |
| `path_read_text(p)` | Đọc toàn bộ file thành chuỗi |
| `path_write_text(p, s)` | Ghi chuỗi ra file |

### 2.9 Ghi / đọc file nhị phân

| Cú pháp | Chức năng |
|---|---|
| `alloc_bytes(n)` | Cấp `n` byte trả về con trỏ (i64) |
| `free_bytes(p)` | Giải phóng |
| `read_u8(p, off)` / `write_u8(p, off, v)` | Đọc/ghi 1 byte |
| `read_i32(p, off)` / `write_i32(p, off, v)` | Đọc/ghi int32 |
| `read_i64(p, off)` / `write_i64(p, off, v)` | Đọc/ghi int64 |
| `read_f32(p, off)` / `write_f32(p, off, v)` | Đọc/ghi f32 |
| `read_ansi(p, off)` | Đọc chuỗi C kết thúc bằng NUL |
| `read_file(p)` | Đọc file thành chuỗi |
| `reserve(xs, n)` | Bảo đảm sức chứa |

### 2.10 SIMD / vector (tối ưu tay)

| Cú pháp | Chức năng |
|---|---|
| `f32x4(...)` | Tạo vector 4 số f32 |
| `v_load4(p, i)` / `v_store4(p, i, v)` | Nạp/lưu vector4 |
| `v_load8(p, i)` / `v_store8(p, i, v)` | Nạp/lưu 8 số (SIMD rộng) |
| `v_add8(a, b)` / `v_sub8(a, b)` | Cộng/trừ theo lối |
| `v_mul8(a, b)` | Nhân theo lối |
| `v_mul8_add8(a, b, c)` | Nhân rồi cộng |
| `v_fill8(v, x)` | Lấp đầy giá trị |
| `v_hsum(v)` / `v_hsum4(v)` | Tổng theo chiều ngang |
| `v_lane(v, i)` | Lấy phần tử thứ `i` |
| `vtable_cell(t, i)` | Ô thứ `i` của bảng tra |

### 2.11 Chuẩn bị dữ liệu

| Cú pháp | Chức năng |
|---|---|
| `json_loads(s)` | Chuỗi JSON → cấu trúc |
| `json_dumps(x)` | Cấu trúc → chuỗi JSON |
| `json_get_str(obj, key)` | Lấy trường chuỗi |
| `cjson_parse(s)` | Phân tích JSON (bản C) |
| `cjson_get_str(o, k)` | Lấy trường chuỗi (bản C) |
| `cjson_get_obj(o, k)` | Lấy trường đối tượng (bản C) |
| `cjson_delete(o)` | Giải phóng |
| `csv_read_lines(p)` | Đọc CSV thành danh sách dòng |
| `csv_write_lines(p, rows)` | Ghi CSV |
| `csv_parse_line(s)` | Tách 1 dòng CSV |
| `csv_join_row(row)` | Ghép 1 dòng CSV |
| `xml_encode_name(s)` | Chuẩn hóa tên thẻ XML |
| `base64_encode(b)` / `base64_decode(s)` | Mã hóa/giải mã Base64 |
| `md5_hex(s)` | MD5 dạng hex |
| `sha256_hex(s)` | SHA-256 dạng hex |
| `struct_i32_to_hex(v)` | int32 → 4 byte hex |
| `struct_f64_to_hex(v)` | f64 → 8 byte hex |

### 2.12 Nén

| Cú pháp | Chức năng |
|---|---|
| `zip_create(p)` | Tạo file zip |
| `zip_extract(p, d)` | Giải nén vào thư mục |
| `zip` | (dạng câu lệnh) |

### 2.13 Regex

| Cú pháp | Chức năng |
|---|---|
| `re_match(p, s)` | Khớp từ đầu |
| `re_search(p, s)` | Tìm chỗ khớp bất kỳ |
| `re_fullmatch(p, s)` | Khớp trọn vẹn |
| `re_findall(p, s)` | Tất cả khớp |
| `re_split(p, s)` | Tách theo regex |
| `re_sub(p, r, s)` | Thay thế theo regex |
| `re_replace(p, r, s)` | Thay thế |

### 2.14 HTTP / socket

| Cú pháp | Chức năng |
|---|---|
| `http_get(url)` | GET |
| `http_post(url, body)` | POST |
| `http_post_type(url, body, typ)` | POST kèm Content-Type |
| `http_put(url, body)` | PUT |
| `http_delete(url)` | DELETE |
| `http_request(...)` | Gọi tổng quát |
| `http_server_generate(...)` | Sinh mã server |
| `socket_resolve_host(h)` | Phân giải tên miền |

### 2.15 Cơ sở dữ liệu nhúng

| Cú pháp | Chức năng |
|---|---|
| `db_open(p)` | Mở database |
| `db_close(h)` | Đóng |
| `db_exec(h, sql)` | Chạy câu lệnh |
| `db_query_int(h, sql)` | Truy vấn ra số nguyên |
| `db_query_text(h, sql)` | Truy vấn ra chuỗi |

### 2.16 FFI / C

| Cú pháp | Chức năng |
|---|---|
| `ctypes_cdll(name)` | Nạp thư viện DLL |
| `ctypes_call(...)` | Gọi hàm trong DLL |
| `c_puts(s)` | In ra stdout kiểu C |

### 2.17 Động / thời gian

| Cú pháp | Chức năng |
|---|---|
| `eval_expr(s)` | Đánh giá biểu thức |
| `eval_arith(s)` | Đánh giá biểu thức số học |
| `eval_code(s)` | Chạy mã |
| `exec_code(s)` | Thực thi mã |
| `input(p)` | Đọc dòng từ stdin |

### 2.18 datetime (khác Python)

| Cú pháp | Chức năng |
|---|---|
| `datetime()` | **0 tham số** — thời điểm hiện tại (UtcNow) |
| `datetime_strptime(s, fmt)` | Chuỗi → datetime |
| `datetime_ticks(d)` | datetime → số ticks int64 |
| `datetime_add(d, k)` | Cộng ticks |
| `datetime_sub(d, k)` | Trừ ticks |
| `datetime_diff(d1, d2)` | Hiệu → timedelta |

> `d.strftime(fmt)` là **method**. Truy cập `.year`/`.month`/`.day` **không có**.

### 2.19 Metaprogramming

| Cú pháp | Chức năng |
|---|---|
| `hasattr(o, "x")` | Có field/method không → `i32` |
| `getattr(o, "x")` | Đọc field. Tên phải là chuỗi literal; **suy đúng kiểu field** |
| `getattr(o, "x", g)` | Như trên, có giá trị mặc định |
| `setattr(o, "x", v)` | Gán field |

---

## 3. METHOD (28)

### 3.1 Chuỗi — qua dict `STR_METHODS` (13)

`capitalize` `endswith` `find` `isdigit` `join` `lower` `lstrip` `replace`
`rfind` `rstrip` `startswith` `strip` `upper`

### 3.2 Method có ghi rõ kiểu (15)

| Cú pháp | Chức năng |
|---|---|
| `str.center(w)` | Căn giữa trong bề rộng `w` |
| `str.count(x)` | Số lần xuất hiện |
| `str.join(xs)` | Nối danh sách bằng chuỗi này |
| `str.ljust(w)` / `str.rjust(w)` | Căn trái/phải |
| `str.split(sep)` | Tách thành danh sách |
| `str.title()` | Viết hoa chữ cái đầu mỗi từ |
| `str.zfill(w)` | Thêm số 0 bên trái |
| `dict.keys()` | Danh sách khóa |
| `dict.values()` | Danh sách giá trị |
| `dict.items()` | Danh sách cặp |
| `list.copy()` | Sao chép |
| `set.to_list()` / `frozenset.to_list()` | Chuyển sang danh sách |
| `datetime.strftime(fmt)` | Định dạng ngày |

### 3.3 Method container xử lý như **câu lệnh**

`xs.append(v)` · `xs.extend(ys)` · `xs.insert(i, v)` · `xs.remove(v)` ·
`xs.sort()` · `xs.reverse()` · `s.add(v)` · `s.discard(v)` · `s.remove(v)`

Đây là các **macro ở tầng câu lệnh** (LINE_PARSER), không phải method biểu thức —
nên **không** dùng được trong biểu thức, ví dụ `y = xs.pop()` không hợp lệ.

---

## 4. DẠNG DỰNG GIÁ TRỊ (vế phải của phép gán) — 25

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
| `os_getenv` / `os_list_files` / `os_mkdir` | (xem 2.8) |
| `shutil_rmtree(p)` | Xoá cây thư mục |
| `datetime()` | UtcNow |
| `f32buf_new(...)` | Bộ đệm f32 |
| `win_gui` | (cửa sổ Windows) |

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
| Lặp | `iter()`, `next()`, `aiter()`, `anext()` |
| File | `open()` như hàm (chỉ dùng được trong `with open(...)`) |
| Khác | `slice()`, `breakpoint()`, `exit()`, `quit()`, `help()`, `eval()`, `exec()`, `compile()`, `super()`, `property()`, `globals()`, `locals()`, `vars()` |

Đã thêm 2026-09-30: `callable()`, `dir()`, `id()`, `hash()`, `ascii()`.
`delattr()` **cố ý báo lỗi biên dịch** (xem 7.10).

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

```python
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
| `max/min/sum` với `key=` | Hỏng ở **tầng parser**: *"expected ')', got '='"*. Không phải thiếu hàm |
| Bước âm của lát `a[::-1]` | Bị từ chối (chỉ nhận bước dương) |
| `del xs[i:j]` | Không có (`del xs[i]` thì có) |
| `yield from` | Không có |
| Tham số keyword-only / positional-only | Không có |
| `Decimal` | Không tồn tại |
| `.year` / `.month` / `.day` trên datetime | Không có |
| `getattr` với tên field là **biến** | Không hỗ trợ — phải là chuỗi literal |
| `set`/`dict` có **field kiểu container** | Lỗi biên dịch (giữ container ở hàm thường) |
| `*` / `**` unpacking tại call site | **Đã có** (`('star'|'star2', ...)`) |
| `divmod(a, b)` | Tham số phải là **biến**, không nhận literal |

---

## 7. HƯỚNG DẪN DÙNG — cho chỗ KHÁC PYTHON

Đọc mục này trước khi viết code chuyển từ Python.

### 7.1 `datetime` — hoàn toàn khác

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

# TokenVector
d = datetime_strptime("2026-09-30", "%Y-%m-%d")
print(d.strftime("%Y"), d.strftime("%m"))    # 2026 09
```

### 7.2 `tuple` — số phần tử cố định

`tuple` là `System.ValueTuple<T1..TN>`, số phần tử **biết lúc biên dịch**
(2..7), không phải container biến độ dài.

| Việc | Python | TokenVector |
|---|---|---|
| Tạo | `t = (1, 2, 3)` | `t = (1, 2, 3)` — giống hệt |
| Chuyển từ list | `tuple(xs)` | `tuple([1, 2, 3])` — chỉ **list literal** |
| Rỗng | `tuple()` | ✗ — dùng `()`? không có; dùng list `[]` |
| Độ dài động | `len(t)` | ✗ — dùng `len()` trên list |

Nếu cần độ dài không cố định, dùng `list`. Xem `list(xs)`.

### 7.3 `set` / `frozenset` — không lấy được theo chỉ số

Giống Python: set không subscript. Muốn duyệt, chuyển sang list trước.

```python
s = {3, 1, 2}
for v in s:            # thứ tự KHÔNG xác định, như Python
    print(v)

xs = s.to_list()       # chuyển sang list để lấy theo chỉ số / sắp xếp
xs.sort()
```

### 7.4 `bytes` — bất biến, `bytearray` — sửa được

```python
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

### 7.5 `format` — spec phải là literal, giá trị phải là biến hoặc số

```python
n = 42
a = format(n, "05d")        # OK
b = format(3.14159, ".2f")  # OK (số literal)
c = format(3.14159, ".2f")  # OK
d = format(a + b, ".2f")    # ✗ - phai gan bien truoc:
t = a + b                   #    t = a + b; format(t, ".2f")
```

Spec không dịch được sang .NET (`","`, `">"`, `"<"`, `"^"`) sẽ **báo lỗi biên
dịch** chứ không đoán.

### 7.6 Exception — chỉ 21 loại, và bản đồ phẳng

Dùng `try/except/else/finally` như Python. Nhưng:

- Chỉ có 21 loai (mục 5.1). Loại khác phải tự định nghĩa.
- **Không có phân cấp.** `except KeyError` không bắt được lỗi cha. Dùng
  `except Exception` để bắt rộng.
- `FileNotFoundError` và `ImportError` cùng ánh xạ về một kiểu .NET, nên
  `except` cái này cũng bắt cái kia. Đừng dựa vào phân biệt.

### 7.7 Method container là **câu lệnh**, không phải biểu thức

```python
xs.append(1)          # OK - dạng câu lệnh
y = xs.pop()          # ✗ - pop() chỉ là CÂU LỆNH, không phải biểu thức
n = len(xs)           # OK
```

Nếu cần giá trị trả về, tách ra biến:
```python
last = xs[len(xs) - 1]   # thay cho xs.pop()
```

### 7.8 SIMD — dùng thay vì lặp tay

```python
v = f32x4(1.0, 2.0, 3.0, 4.0)
w = v_add8(v, v)        # cộng từng phần tử
s = v_hsum(v)           # tổng ngang
```
Đây là phần mở rộng so với Python, không thay thế gì.

### 7.9 `getattr` / `setattr` — tên field phải là literal

```python
o = Pt(1, "a")
v = getattr(o, "x")        # OK
n = "x"
w = getattr(o, n)          # ✗ - phai la chuoi LITERAL
```

Đường đọc động theo tên biến chưa có: tên field là quyết định lúc biên dịch.

### 7.10 Hàm phản chiếu — khác Python ở đâu

| Hàm | Python | TokenVector |
|---|---|---|
| `callable(f)` | `True`/`False` | Trả `i32` nên in `"1"`/`"0"` — **cùng nghĩa** |
| `dir(o)` | 32 tên (kể cả `__init__`, `__class__`…) | Chỉ tên TokenVector có: **tru��ng + method của record** |
| `id(x)` | Số định danh | `RuntimeHelpers.GetHashCode` — **không cam k�ết ổn định** giữa 2 lần chạy (Python cũng vậy) |
| `hash(42)` | `42` | `42` — **giống hệt** |
| `hash("abc")` | `-2654188841952103486` (SipHash) | `-1792535898324117685` (**FNV-1a**) |
| `ascii("abc")` | `"'abc'"` | `"'abc'"` — giống |
| `delattr(o, "x")` | Xoá field | **Lỗi biên dịch** |

### 7.11 `open()` — dùng hàm tương đương, không cần `open()`

TokenVector **không có** `open()` dạng hàm (chỉ có `with open(...)`). Không
phải vì thiếu hàm — mà vì handle là `StreamReader`/`StreamWriter` thuần .NET,
không có kiểu riêng nên `h.read()` không dispatch được. Thay vào đó **hai chức
năng đó đã có sẵn ở dạng hàm**, dùng được ngay:

| Python | TokenVector | Ghi chú |
|---|---|---|
| `f = open(p, "r")` rồi `f.read()` | `s = path_read_text(p)` | đọc **toàn bộ** file thành chuỗi |
| `f = open(p, "w")` rồi `f.write(s)` | `path_write_text(p, s)` | ghi đè |
| `f = open(p, "a")` rồi `f.write(s)` | `s = path_read_text(p)`<br>`path_write_text(p, s + noi_moi)` | đọc rồi ghi lại |
| `os.path.exists(p)` | `file_exists(p)` hoặc `path_exists(p)` | |

```python
# Python
f = open("t.txt", "w")
f.write("hello")
f.close()

# TokenVector
path_write_text("t.txt", "hello")
```

**Khi nào vẫn nên dùng `with open(...)`:** khi file **rất lớn** — `path_read_text`
nạp hết vào RAM, còn `with open(...)` đọc dòng bằng `StreamReader`. Với file
nhỏ, `path_read_text` gọn hơn nhiều.

### 7.12 `iter()` / `next()` — chưa có, và đây là lý do

`for v in xs:` đã hoạt động và là cách dùng thay thế cho phần lớn mã Python.
Để có `iter()`/`next()` thật sự cần một **kiểu iterator** mà compiler phải biết
dispatch `__next__` trên đó — đụng vào cơ chế method/type dispatch lõi. Chưa
làm. Nếu cần lấy phần tử kế tiếp theo chỉ số:

```python
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

---

## 8. BA SỰ CỐ ĐÃ GHI — đừng tin mù

1. **Có tên không có nghĩa là dùng được.** `datetime` có đủ đăng ký nhưng
   `datetime(2026, 9, 30)` từng biên dịch xanh rồi trả về **hôm nay**.
2. **Ngoài danh mục vẫn chạy đúng.** `with open(...)`, `sorted()`, `print`,
   `len`, `range`, `abs`, `round` không có trong 354 tên.
3. **Tài liệu cũ đã sai nhiều lần.** Biểu thức điều kiện `a if c else b`
   bị ghi là "không có" nhưng chạy đúng.

→ **Hãy probe thật.** Quy trình và bằng chứng: `3.code/docs/PLAN.md` mục 6.
