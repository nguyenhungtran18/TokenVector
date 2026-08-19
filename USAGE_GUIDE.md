# TokenVector - Hướng dẫn sử dụng

TokenVector biên dịch mã nguồn `.tkv` (cú pháp kiểu tĩnh) thẳng thành file
`.exe` độc lập của Windows — chỉ .NET Framework (có sẵn trên Windows) làm
runtime duy nhất.

**Yêu cầu máy đích thật (không giấu)**: cần **.NET Framework 4.x đã cài
sẵn** (rất phổ biến trên Windows, thường có sẵn) — `tkvc.exe` tự dò tìm
`ilasm.exe` trong thư mục cài đặt Framework của máy đó lúc chạy. KHÔNG
thể đóng gói riêng `ilasm.exe` mang theo (đã tự kiểm chứng: copy file đó
ra khỏi thư mục cài đặt gây lỗi `DLL_NOT_FOUND`, nó phụ thuộc các DLL
khác nằm cùng chỗ cài đặt).

## 1. Lấy công cụ

Công cụ biên dịch là **`dist/tkvc.exe`** — một file `.exe` độc lập.

Nếu chưa có `dist/tkvc.exe` hoặc cần build lại sau khi sửa `compiler/`:
```powershell
powershell -File build_tkvc.ps1
```

## 2. Biên dịch và chạy

```powershell
dist\tkvc.exe build examples\word_stats.tkv
examples\word_stats.exe "the quick brown fox the fox runs"
```

- `build <file.tkv>` → sinh `<file>.exe` cùng thư mục (đổi `--out` để chỉ
  định nơi khác).
- Nếu file có nhiều hàm, dùng `--entry <ten_ham>` để chọn entry point (mặc
  định: hàm duy nhất, hoặc hàm tên `main`).
- `.exe` sinh ra nhận tham số qua command-line, theo đúng thứ tự tham số
  của hàm entry (số → parse trực tiếp, chuỗi → nguyên văn).

## 3. Cú pháp `.tkv`

Annotation kiểu **bắt buộc** cho mọi tham số và giá trị trả về của hàm
top-level, ở dạng **chuỗi**: `x: "i32"`.

### Kiểu dữ liệu vô hướng
`"f32"` `"f64"` `"i32"` `"i64"` `"str"`.

```
def add(a: "i32", b: "i32") -> "i32":
    return a + b
```

### Điều khiển luồng
`if`/`elif`/`else`, `for i in range(n)` (có start/stop/step), `for x in
lst:`, `for k, v in d.items():`, `while`, `break`/`continue`,
`try`/`except <Loai>`/`except`/`finally`, `raise <Loai>("msg")`, `assert
cond, "msg"`.

### Container động
- `list`: `lst = []`, `.append(x)`, `lst[i]`, `len(lst)`, `.pop()`,
  `.index(x)`, `.count(x)`, `.reverse()`, `.copy()`, `lst * n`, slicing
  `lst[i:j]`.
- `dict`: `d = {}`, `d[k] = v`, `d[k]`, `key in d`, `.get(k, default)`,
  `.pop(k, default)`, `.setdefault(k, default)`, `.keys()`, `.values()`,
  `items_list = d.items()` + `for k, v in items_list:`.
- `set`: `set()`, `.add(x)`, `.remove(x)`, `.discard(x)`, `.union()`,
  `.intersection()`, `.difference()`.
- `tuple`: trả về nhiều giá trị (`return a, b`), giải nén (`x, y = f()`).
- Khai báo kiểu cho tham số/return container: `"list[i32]"`,
  `"dict[str,i32]"`.

### String
Literal, nối chuỗi (`+`), so sánh (`==`/`!=`), `len(s)`, `s[i]`,
`s[i:j]`, f-string (`f"{x}"`), và method: `.split()`, `.upper()`,
`.lower()`, `.strip()`, `.lstrip()`, `.rstrip()`, `.startswith()`,
`.endswith()`, `.find()`, `.count()`, `.zfill()`, `.capitalize()`,
`.title()`, `.join()`.

### Record (class kiểu field + method, KHÔNG động)
```
class Point:
    x: "f32"
    y: "f32"

    def __init__(self, x, y):
        self.x = x
        self.y = y

    def length(self) -> "f32":
        return (self.x * self.x + self.y * self.y) ** 0.5
```

### Kế thừa đơn + đa hình
```
class Animal:
    sound: "i32"
    def __init__(self, sound):
        self.sound = sound
    def speak(self) -> "i32":
        return self.sound

class Dog(Animal):
    def speak(self) -> "i32":
        return self.sound + 1
```
`super().__init__(...)` gọi constructor lớp cha. Method override qua tên
trùng, dispatch ảo thật (`callvirt`).

### Interface (mixin hành vi thuần, không field)
```
interface = lambda cls: cls  # shim ca phap bat buoc, khong anh huong bien dich

@interface
class Flyable:
    def fly(self) -> "i32":
        pass

class Bird(Animal, Flyable):
    def fly(self) -> "i32":
        return 1
```

### `@property`
```
class Circle:
    r: "f32"
    def __init__(self, r):
        self.r = r
    @property
    def area(self) -> "f32":
        return 3.14159 * self.r * self.r
# dung: c.area (KHONG viet c.area())
```

### Closure (hàm lồng bắt biến ngoài, mutation thật)
```
def make_counter_demo() -> "i32":
    count = 0

    def inc() -> "i32":
        nonlocal count
        count = count + 1
        return count

    a = inc()
    b = inc()
    c = inc()
    return a + b + c         # = 1 + 2 + 3 = 6
```
Biến bị bắt (`count`) sống sót qua nhiều lần gọi, mutation thật (không
phải copy giá trị). Xem thêm `test/sample_closure_*.tkv` (closure trả về
ra ngoài, closure nhận tham số, closure lồng nhiều lớp).

### Generator (`yield`) — LAZY THẬT, không phải liệt kê trước
```
def count_up(n: "i32") -> "list[i32]":
    for i in range(n):
        yield i

def use() -> "i32":
    total = 0
    for x in count_up(5):   # PHAI goi truc tiep trong for, khong gan ra bien truoc
        total = total + x
    return total
```
`yield` hỗ trợ lồng trong `if`/`for`/`while` tùy ý (state machine thật,
không giới hạn 1 vòng lặp đơn). Giới hạn: `for x in gen(...):` chỉ nhận
lệnh gọi trực tiếp, chưa hỗ trợ gán generator ra biến rồi mới lặp;
generator kết thúc khi thân hàm chạy hết tự nhiên (chưa hỗ trợ `return`
trần để dừng sớm).

### File I/O
`read_file(path)`, `write_file(path, content)`, `file_exists(path)`,
`with open(path, "r") as f: ... f.write(x)` (StreamWriter/Reader thật).

### Web
`http_get(url) -> str` — HTTP GET thật (`System.Net.WebClient`).

### Database (SQLite thật)
```
h = db_open("data.db")
rc = db_exec(h, "CREATE TABLE t (id INTEGER, name TEXT)")
rc = db_exec(h, "INSERT INTO t VALUES (1, 'Alice')")
name = db_query_text(h, "SELECT name FROM t WHERE id = 1")
cnt = db_query_int(h, "SELECT COUNT(*) FROM t")
rc = db_close(h)
```
Cần file `sqlite3.dll` (bản chính thức từ sqlite.org, đã có sẵn cạnh
`tkvc.exe`) nằm CẠNH file `.exe` đã biên dịch lúc chạy. Giới hạn: chỉ đọc
cột 0 của hàng đầu tiên cho `db_query_text`/`db_query_int`; SQL là 1
chuỗi hoàn chỉnh (tự ghép giá trị vào, không có parameterized query).

### Nhập thư viện .NET ngoài (package ecosystem)
```
__tkv_extern_assembly__ = "System.Xml"  # ten assembly .NET Framework GAC chuan
```
Khai báo ở đầu file để dùng các builtin cần assembly ngoài
`mscorlib`/`System`/`System.Core` (mặc định luôn có sẵn).

### Chia nhiều file `.tkv`
```
__tkv_import__ = "shapes"  # gop toan bo ham/class cua shapes.tkv (CUNG thu muc)
```

## 4. Giới hạn thật (không giấu)

- Không có kiểu động (`exec`/`eval`), không async/await — loại bỏ vĩnh
  viễn theo quyết định kiến trúc (xem `ROADMAP.md`).
- Tên hàm/biến trùng từ khóa ILASM (ví dụ `add`, `new`, `call`) có thể
  gây lỗi biên dịch khó hiểu — tránh đặt tên như vậy (đang có việc mở để
  sửa triệt để hơn).
- `db_query_text`/`db_query_int` chỉ lấy cột đầu hàng đầu.
- `for x in gen(...):` chỉ nhận lệnh gọi trực tiếp.
